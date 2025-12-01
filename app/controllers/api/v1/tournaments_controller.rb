module Api
  module V1
    class TournamentsController < BaseController
      skip_before_action :authenticate_admin!, only: [:current]

      # GET /api/v1/tournaments
      # List all tournaments (for admin dropdown)
      def index
        tournaments = Tournament.recent
        
        # Filter by status if provided
        tournaments = tournaments.where(status: params[:status]) if params[:status].present?
        
        render json: tournaments, each_serializer: TournamentSerializer
      end

      # GET /api/v1/tournaments/current
      # Get the current open tournament (for public registration)
      def current
        tournament = Tournament.current
        
        if tournament
          render json: tournament, serializer: TournamentSerializer
        else
          render json: { error: "No active tournament found" }, status: :not_found
        end
      end

      # GET /api/v1/tournaments/:id
      def show
        tournament = Tournament.find(params[:id])
        render json: tournament, serializer: TournamentSerializer
      end

      # POST /api/v1/tournaments
      def create
        tournament = Tournament.new(tournament_params)
        
        if tournament.save
          ActivityLog.log(
            admin: current_admin,
            action: 'tournament_created',
            target: tournament,
            details: "Created tournament: #{tournament.display_name}"
          )
          render json: tournament, serializer: TournamentSerializer, status: :created
        else
          render json: { errors: tournament.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/tournaments/:id
      def update
        tournament = Tournament.find(params[:id])
        
        if tournament.update(tournament_params)
          ActivityLog.log(
            admin: current_admin,
            action: 'tournament_updated',
            target: tournament,
            details: "Updated tournament: #{tournament.display_name}"
          )
          render json: tournament, serializer: TournamentSerializer
        else
          render json: { errors: tournament.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/tournaments/:id
      def destroy
        tournament = Tournament.find(params[:id])
        
        if tournament.golfers.any? || tournament.groups.any?
          render json: { 
            error: "Cannot delete tournament with existing golfers or groups. Archive it instead." 
          }, status: :unprocessable_entity
          return
        end
        
        tournament.destroy!
        head :no_content
      end

      # POST /api/v1/tournaments/:id/archive
      def archive
        tournament = Tournament.find(params[:id])
        
        tournament.archive!
        
        ActivityLog.log(
          admin: current_admin,
          action: 'tournament_archived',
          target: tournament,
          details: "Archived tournament: #{tournament.display_name}"
        )
        
        render json: tournament, serializer: TournamentSerializer
      end

      # POST /api/v1/tournaments/:id/copy
      # Create a new tournament based on this one (for next year)
      def copy
        original = Tournament.find(params[:id])
        new_tournament = original.copy_for_next_year
        
        if new_tournament.save
          ActivityLog.log(
            admin: current_admin,
            action: 'tournament_created',
            target: new_tournament,
            details: "Created tournament #{new_tournament.display_name} (copied from #{original.display_name})"
          )
          render json: new_tournament, serializer: TournamentSerializer, status: :created
        else
          render json: { errors: new_tournament.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/tournaments/:id/open
      # Open tournament for registration
      def open
        tournament = Tournament.find(params[:id])
        
        # Close any other open tournaments first
        Tournament.where(status: 'open').where.not(id: tournament.id).update_all(status: 'closed')
        
        tournament.update!(status: 'open', registration_open: true)
        
        ActivityLog.log(
          admin: current_admin,
          action: 'tournament_updated',
          target: tournament,
          details: "Opened tournament for registration: #{tournament.display_name}"
        )
        
        render json: tournament, serializer: TournamentSerializer
      end

      # POST /api/v1/tournaments/:id/close
      # Close tournament registration
      def close
        tournament = Tournament.find(params[:id])
        
        tournament.update!(status: 'closed', registration_open: false)
        
        ActivityLog.log(
          admin: current_admin,
          action: 'tournament_updated',
          target: tournament,
          details: "Closed tournament: #{tournament.display_name}"
        )
        
        render json: tournament, serializer: TournamentSerializer
      end

      private

      def tournament_params
        params.require(:tournament).permit(
          :name, :year, :edition, :status,
          :event_date, :registration_time, :start_time,
          :location_name, :location_address,
          :max_capacity, :reserved_slots, :entry_fee, :employee_entry_fee,
          :format_name, :fee_includes, :checks_payable_to,
          :contact_name, :contact_phone,
          :registration_open
        )
      end
    end
  end
end

