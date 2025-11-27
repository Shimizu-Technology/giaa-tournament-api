module Api
  module V1
    class GolfersController < BaseController
      skip_before_action :authenticate_admin!, only: [:create, :registration_status]

      # GET /api/v1/golfers
      def index
        golfers = Golfer.includes(:group)

        # Apply filters
        golfers = golfers.where(payment_status: params[:payment_status]) if params[:payment_status].present?
        golfers = golfers.where(payment_type: params[:payment_type]) if params[:payment_type].present?
        golfers = golfers.where(registration_status: params[:registration_status]) if params[:registration_status].present?

        if params[:checked_in].present?
          golfers = params[:checked_in] == "true" ? golfers.checked_in : golfers.not_checked_in
        end

        if params[:assigned].present?
          golfers = params[:assigned] == "true" ? golfers.assigned : golfers.unassigned
        end

        golfers = golfers.where(hole_number: params[:hole_number]) if params[:hole_number].present?
        golfers = golfers.joins(:group).where(groups: { group_number: params[:group_number] }) if params[:group_number].present?

        # Search
        if params[:search].present?
          search_term = "%#{params[:search]}%"
          golfers = golfers.where(
            "name ILIKE :search OR email ILIKE :search OR phone ILIKE :search OR mobile ILIKE :search",
            search: search_term
          )
        end

        # Sorting
        sort_by = params[:sort_by] || "created_at"
        sort_order = params[:sort_order] || "desc"
        allowed_sorts = %w[name email created_at payment_status registration_status checked_in_at]
        sort_by = "created_at" unless allowed_sorts.include?(sort_by)
        sort_order = "desc" unless %w[asc desc].include?(sort_order)

        golfers = golfers.order("#{sort_by} #{sort_order}")

        # Paginate
        golfers = paginate(golfers)

        render json: {
          golfers: ActiveModelSerializers::SerializableResource.new(golfers),
          meta: pagination_meta(golfers)
        }
      end

      # GET /api/v1/golfers/:id
      def show
        golfer = Golfer.includes(:group).find(params[:id])
        render json: golfer
      end

      # POST /api/v1/golfers
      # Public registration endpoint
      def create
        # Check if registration is open
        setting = Setting.instance
        unless setting.registration_open
          render json: { errors: ["Registration is currently closed."] }, status: :unprocessable_entity
          return
        end

        golfer = Golfer.new(golfer_params)
        golfer.waiver_accepted_at = Time.current if params[:waiver_accepted]

        if golfer.save
          # Broadcast to admin dashboard
          broadcast_golfer_update(golfer)

          render json: {
            golfer: GolferSerializer.new(golfer),
            message: golfer.registration_status == "confirmed" ?
              "Your spot is confirmed!" :
              "You have been added to the waitlist."
          }, status: :created
        else
          render json: { errors: golfer.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/golfers/:id
      def update
        golfer = Golfer.find(params[:id])
        old_values = golfer.attributes.slice('group_id', 'payment_status', 'registration_status')

        if golfer.update(golfer_update_params)
          # Log activity for meaningful changes
          log_golfer_update(golfer, old_values)
          broadcast_golfer_update(golfer)
          render json: golfer
        else
          render json: { errors: golfer.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/golfers/:id
      def destroy
        golfer = Golfer.find(params[:id])
        golfer_name = golfer.name
        golfer.destroy
        
        ActivityLog.log(
          admin: current_admin,
          action: 'golfer_deleted',
          target: nil,
          details: "Deleted golfer: #{golfer_name}",
          metadata: { golfer_name: golfer_name }
        )
        
        broadcast_golfer_update(golfer, action: "deleted")
        head :no_content
      end

      # POST /api/v1/golfers/:id/check_in
      def check_in
        golfer = Golfer.find(params[:id])
        was_checked_in = golfer.checked_in_at.present?
        golfer.check_in!

        ActivityLog.log(
          admin: current_admin,
          action: was_checked_in ? 'golfer_unchecked' : 'golfer_checked_in',
          target: golfer,
          details: was_checked_in ? "Unchecked #{golfer.name}" : "Checked in #{golfer.name}"
        )

        broadcast_golfer_update(golfer)
        render json: golfer
      end

      # POST /api/v1/golfers/:id/payment_details
      def payment_details
        golfer = Golfer.find(params[:id])
        old_status = golfer.payment_status

        golfer.update!(
          payment_status: "paid",
          payment_method: params[:payment_method],
          receipt_number: params[:receipt_number],
          payment_notes: params[:payment_notes]
        )

        ActivityLog.log(
          admin: current_admin,
          action: 'payment_marked',
          target: golfer,
          details: "Marked #{golfer.name} as paid (#{params[:payment_method]})",
          metadata: {
            payment_method: params[:payment_method],
            receipt_number: params[:receipt_number],
            previous_status: old_status
          }
        )

        broadcast_golfer_update(golfer)
        render json: golfer
      end

      # POST /api/v1/golfers/:id/promote
      # Promote from waitlist to confirmed
      def promote
        golfer = Golfer.find(params[:id])

        unless golfer.registration_status == "waitlist"
          render json: { error: "Golfer is not on the waitlist" }, status: :unprocessable_entity
          return
        end

        golfer.update!(registration_status: "confirmed")
        GolferMailer.promotion_email(golfer).deliver_later

        ActivityLog.log(
          admin: current_admin,
          action: 'golfer_updated',
          target: golfer,
          details: "Promoted #{golfer.name} from waitlist to confirmed"
        )

        broadcast_golfer_update(golfer)
        render json: golfer
      end

      # POST /api/v1/golfers/:id/demote
      # Move a golfer from confirmed to waitlist
      def demote
        golfer = Golfer.find(params[:id])

        unless golfer.registration_status == "confirmed"
          render json: { error: "Golfer is not confirmed" }, status: :unprocessable_entity
          return
        end

        golfer.update!(registration_status: "waitlist")

        ActivityLog.log(
          admin: current_admin,
          action: 'golfer_updated',
          target: golfer,
          details: "Moved #{golfer.name} to waitlist",
          metadata: { previous_status: 'confirmed', new_status: 'waitlist' }
        )

        broadcast_golfer_update(golfer)
        render json: golfer
      end

      # POST /api/v1/golfers/:id/update_payment_status
      # Change payment status (paid/unpaid)
      def update_payment_status
        golfer = Golfer.find(params[:id])
        new_status = params[:payment_status]

        unless %w[paid unpaid].include?(new_status)
          render json: { error: "Invalid payment status. Must be 'paid' or 'unpaid'" }, status: :unprocessable_entity
          return
        end

        old_status = golfer.payment_status

        if new_status == 'unpaid'
          # Clear payment details when marking as unpaid (but keep payment_type)
          golfer.update!(
            payment_status: 'unpaid',
            payment_method: nil,
            receipt_number: nil,
            payment_notes: nil
          )
        else
          golfer.update!(payment_status: 'paid')
        end

        ActivityLog.log(
          admin: current_admin,
          action: 'payment_updated',
          target: golfer,
          details: "Changed #{golfer.name} payment status from #{old_status} to #{new_status}",
          metadata: { previous_status: old_status, new_status: new_status }
        )

        broadcast_golfer_update(golfer)
        render json: golfer
      end

      # GET /api/v1/golfers/registration_status
      # Public endpoint to check registration capacity
      def registration_status
        setting = Setting.instance

        render json: {
          max_capacity: setting.max_capacity,
          confirmed_count: Golfer.confirmed.count,
          waitlist_count: Golfer.waitlist.count,
          capacity_remaining: setting.capacity_remaining,
          at_capacity: setting.at_capacity?,
          registration_open: setting.registration_open,
          entry_fee_cents: setting.tournament_entry_fee || 12500,
          entry_fee_dollars: (setting.tournament_entry_fee || 12500) / 100.0,
          # Tournament configuration for landing page
          tournament_year: setting.tournament_year,
          tournament_edition: setting.tournament_edition,
          tournament_title: setting.tournament_title,
          tournament_name: setting.tournament_name,
          event_date: setting.event_date,
          registration_time: setting.registration_time,
          start_time: setting.start_time,
          location_name: setting.location_name,
          location_address: setting.location_address,
          format_name: setting.format_name,
          fee_includes: setting.fee_includes,
          checks_payable_to: setting.checks_payable_to,
          contact_name: setting.contact_name,
          contact_phone: setting.contact_phone
        }
      end

      # GET /api/v1/golfers/stats
      def stats
        setting = Setting.instance
        render json: {
          total: Golfer.count,
          confirmed: Golfer.confirmed.count,
          waitlist: Golfer.waitlist.count,
          paid: Golfer.paid.count,
          unpaid: Golfer.unpaid.count,
          checked_in: Golfer.checked_in.count,
          not_checked_in: Golfer.not_checked_in.count,
          assigned_to_groups: Golfer.assigned.count,
          unassigned: Golfer.unassigned.count,
          max_capacity: setting.max_capacity,
          capacity_remaining: setting.capacity_remaining,
          at_capacity: setting.at_capacity?,
          entry_fee_cents: setting.tournament_entry_fee || 12500,
          entry_fee_dollars: (setting.tournament_entry_fee || 12500) / 100.0,
          # Tournament config
          tournament_name: setting.tournament_name
        }
      end

      private

      def golfer_params
        params.require(:golfer).permit(
          :name, :company, :address, :phone, :mobile, :email,
          :payment_type, :payment_status, :notes
        )
      end

      def golfer_update_params
        params.require(:golfer).permit(
          :name, :company, :address, :phone, :mobile, :email,
          :payment_type, :payment_status, :registration_status,
          :group_id, :hole_number, :position, :notes,
          :payment_method, :receipt_number, :payment_notes
        )
      end

      def broadcast_golfer_update(golfer, action: "updated")
        ActionCable.server.broadcast("golfers_channel", {
          action: action,
          golfer: GolferSerializer.new(golfer).as_json
        })
      rescue StandardError => e
        Rails.logger.error("Failed to broadcast golfer update: #{e.message}")
      end

      def log_golfer_update(golfer, old_values)
        return unless current_admin

        # Check for group assignment changes
        if old_values['group_id'] != golfer.group_id
          if golfer.group_id.present? && old_values['group_id'].nil?
            ActivityLog.log(
              admin: current_admin,
              action: 'golfer_assigned_to_group',
              target: golfer,
              details: "Assigned #{golfer.name} to Group #{golfer.group&.group_number}",
              metadata: { group_id: golfer.group_id, group_number: golfer.group&.group_number }
            )
          elsif golfer.group_id.nil? && old_values['group_id'].present?
            ActivityLog.log(
              admin: current_admin,
              action: 'golfer_removed_from_group',
              target: golfer,
              details: "Removed #{golfer.name} from group",
              metadata: { previous_group_id: old_values['group_id'] }
            )
          elsif golfer.group_id.present?
            ActivityLog.log(
              admin: current_admin,
              action: 'golfer_assigned_to_group',
              target: golfer,
              details: "Moved #{golfer.name} to Group #{golfer.group&.group_number}",
              metadata: { 
                group_id: golfer.group_id, 
                group_number: golfer.group&.group_number,
                previous_group_id: old_values['group_id']
              }
            )
          end
        end

        # Check for payment status changes
        if old_values['payment_status'] != golfer.payment_status
          ActivityLog.log(
            admin: current_admin,
            action: 'payment_updated',
            target: golfer,
            details: "Changed #{golfer.name} payment status from #{old_values['payment_status']} to #{golfer.payment_status}",
            metadata: {
              previous_status: old_values['payment_status'],
              new_status: golfer.payment_status
            }
          )
        end
      end
    end
  end
end

