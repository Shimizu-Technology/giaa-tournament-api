module Api
  module V1
    class GroupsController < BaseController
      # GET /api/v1/groups
      def index
        groups = Group.with_golfers

        render json: groups, each_serializer: GroupSerializer, include: "golfers"
      end

      # GET /api/v1/groups/:id
      def show
        group = Group.includes(:golfers).find(params[:id])
        render json: group, include: "golfers"
      end

      # POST /api/v1/groups
      def create
        # Auto-assign next group number
        next_number = (Group.maximum(:group_number) || 0) + 1
        group = Group.new(group_number: next_number, hole_number: params[:hole_number])

        if group.save
          broadcast_groups_update
          render json: group, status: :created
        else
          render json: { errors: group.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/groups/:id
      def update
        group = Group.find(params[:id])

        if group.update(group_params)
          broadcast_groups_update
          render json: group, include: "golfers"
        else
          render json: { errors: group.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/groups/:id
      def destroy
        group = Group.find(params[:id])

        # Remove all golfers from the group first
        group.golfers.update_all(group_id: nil, position: nil)

        group.destroy
        broadcast_groups_update
        head :no_content
      end

      # POST /api/v1/groups/:id/set_hole
      def set_hole
        group = Group.find(params[:id])

        unless (1..18).include?(params[:hole_number].to_i)
          render json: { error: "Hole number must be between 1 and 18" }, status: :unprocessable_entity
          return
        end

        if group.update(hole_number: params[:hole_number])
          broadcast_groups_update
          render json: group, include: "golfers"
        else
          render json: { errors: group.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/groups/:id/add_golfer
      def add_golfer
        group = Group.find(params[:id])
        golfer = Golfer.find(params[:golfer_id])

        if group.full?
          render json: { error: "Group is full (max #{Group::MAX_GOLFERS} golfers)" }, status: :unprocessable_entity
          return
        end

        if group.add_golfer(golfer)
          broadcast_groups_update
          render json: group, include: "golfers"
        else
          render json: { error: "Failed to add golfer to group" }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/groups/:id/remove_golfer
      def remove_golfer
        group = Group.find(params[:id])
        golfer = Golfer.find(params[:golfer_id])

        unless golfer.group_id == group.id
          render json: { error: "Golfer is not in this group" }, status: :unprocessable_entity
          return
        end

        group.remove_golfer(golfer)
        broadcast_groups_update
        render json: group, include: "golfers"
      end

      # POST /api/v1/groups/update_positions
      # For drag-and-drop reordering
      def update_positions
        updates = params[:updates] || []

        ActiveRecord::Base.transaction do
          updates.each do |update|
            golfer = Golfer.find(update[:golfer_id])

            golfer.update!(
              group_id: update[:group_id],
              position: update[:position]
            )
          end
        end

        broadcast_groups_update
        render json: { message: "Positions updated successfully" }
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: e.message }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/groups/batch_create
      # Create multiple groups at once
      def batch_create
        count = params[:count].to_i
        count = 1 if count < 1
        count = 40 if count > 40 # Max 40 groups (160 golfers / 4)

        groups = []
        next_number = (Group.maximum(:group_number) || 0) + 1

        count.times do |i|
          groups << Group.create!(group_number: next_number + i)
        end

        broadcast_groups_update
        render json: groups, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/groups/auto_assign
      # Automatically assign unassigned golfers to groups
      def auto_assign
        unassigned = Golfer.confirmed.unassigned.order(:created_at)

        if unassigned.empty?
          render json: { message: "No unassigned confirmed golfers" }
          return
        end

        assigned_count = 0

        unassigned.each do |golfer|
          # Find or create a group with space
          group = Group.includes(:golfers)
                       .select { |g| g.golfers.count < Group::MAX_GOLFERS }
                       .first

          unless group
            next_number = (Group.maximum(:group_number) || 0) + 1
            group = Group.create!(group_number: next_number)
          end

          group.add_golfer(golfer)
          assigned_count += 1
        end

        broadcast_groups_update
        render json: {
          message: "Auto-assigned #{assigned_count} golfers",
          assigned_count: assigned_count
        }
      end

      private

      def group_params
        params.require(:group).permit(:group_number, :hole_number)
      end

      def broadcast_groups_update
        groups = Group.with_golfers
        ActionCable.server.broadcast("groups_channel", {
          action: "updated",
          groups: ActiveModelSerializers::SerializableResource.new(groups, each_serializer: GroupSerializer, include: "golfers").as_json
        })
      rescue StandardError => e
        Rails.logger.error("Failed to broadcast groups update: #{e.message}")
      end
    end
  end
end

