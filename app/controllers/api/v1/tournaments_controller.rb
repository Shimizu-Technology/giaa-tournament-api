module Api
  module V1
    class TournamentsController < BaseController
      skip_before_action :authenticate_admin!, only: [ :current ]

      # GET /api/v1/tournaments
      # List all tournaments (for admin dropdown)
      def index
        tournaments = Tournament.recent.includes(:employee_numbers)

        # Filter by status if provided
        tournaments = tournaments.where(status: params[:status]) if params[:status].present?

        # Precompute golfer counts in bulk (avoids N+1 count queries per tournament)
        precompute_tournament_counts(tournaments)

        render json: tournaments, each_serializer: TournamentSerializer
      end

      # GET /api/v1/tournaments/current
      # Get the current open tournament (for public registration)
      def current
        tournament = Tournament.current

        if tournament
          precompute_tournament_counts([ tournament ])
          render json: tournament, serializer: TournamentSerializer
        else
          render json: { error: "No active tournament found" }, status: :not_found
        end
      end

      # GET /api/v1/tournaments/:id
      def show
        tournament = Tournament.find(params[:id])
        precompute_tournament_counts([ tournament ])
        render json: tournament, serializer: TournamentSerializer
      end

      # POST /api/v1/tournaments
      def create
        tournament = Tournament.new(tournament_params)

        if tournament.save
          ActivityLog.log(
            admin: current_admin,
            action: "tournament_created",
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
            action: "tournament_updated",
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
          action: "tournament_archived",
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
            action: "tournament_created",
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
        Tournament.where(status: "open").where.not(id: tournament.id).update_all(status: "closed")

        tournament.update!(status: "open", registration_open: true)

        ActivityLog.log(
          admin: current_admin,
          action: "tournament_updated",
          target: tournament,
          details: "Opened tournament for registration: #{tournament.display_name}"
        )

        render json: tournament, serializer: TournamentSerializer
      end

      # POST /api/v1/tournaments/:id/close
      # Close tournament registration
      def close
        tournament = Tournament.find(params[:id])

        tournament.update!(status: "closed", registration_open: false)

        ActivityLog.log(
          admin: current_admin,
          action: "tournament_updated",
          target: tournament,
          details: "Closed tournament: #{tournament.display_name}"
        )

        render json: tournament, serializer: TournamentSerializer
      end

      private

      # Precompute golfer counts for all tournaments in a single query batch
      # This avoids 5 separate COUNT queries per tournament in the serializer
      def precompute_tournament_counts(tournaments)
        tournament_ids = tournaments.map(&:id)
        return if tournament_ids.empty?

        # Single query: get all relevant counts grouped by tournament_id
        # Use raw SQL to avoid any default scope / ORDER BY interference
        rows = ActiveRecord::Base.connection.execute(<<~SQL)
          SELECT
            tournament_id,
            COUNT(*) FILTER (WHERE registration_status = 'confirmed') AS confirmed_count,
            COUNT(*) FILTER (WHERE registration_status = 'waitlist') AS waitlist_count,
            COUNT(*) FILTER (WHERE payment_status = 'paid' AND registration_status != 'cancelled') AS paid_count,
            COUNT(*) FILTER (WHERE checked_in_at IS NOT NULL AND registration_status != 'cancelled') AS checked_in_count
          FROM golfers
          WHERE tournament_id IN (#{tournament_ids.map { |id| ActiveRecord::Base.connection.quote(id) }.join(',')})
          GROUP BY tournament_id
        SQL
        counts_by_tournament = rows.index_by { |r| r["tournament_id"] }

        tournaments.each do |tournament|
          counts = counts_by_tournament[tournament.id]
          tournament.instance_variable_set(:@precomputed_counts, {
            confirmed: (counts&.dig("confirmed_count") || 0).to_i,
            waitlist: (counts&.dig("waitlist_count") || 0).to_i,
            paid: (counts&.dig("paid_count") || 0).to_i,
            checked_in: (counts&.dig("checked_in_count") || 0).to_i
          })
        end
      end

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
