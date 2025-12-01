module Api
  module V1
    class EmployeeNumbersController < ApplicationController
      include Authenticated
      before_action :authenticate_admin!, except: [:validate]
      skip_before_action :verify_authenticity_token, only: [:validate], raise: false

      # GET /api/v1/employee_numbers
      def index
        tournament = find_tournament
        return render_tournament_required unless tournament

        employee_numbers = tournament.employee_numbers.includes(:used_by_golfer).order(:employee_number)
        
        render json: {
          employee_numbers: ActiveModelSerializers::SerializableResource.new(employee_numbers),
          stats: {
            total: employee_numbers.count,
            available: employee_numbers.available.count,
            used: employee_numbers.used_numbers.count
          }
        }
      end

      # POST /api/v1/employee_numbers
      def create
        tournament = find_tournament
        return render_tournament_required unless tournament

        employee_number = tournament.employee_numbers.new(employee_number_params)

        if employee_number.save
          ActivityLog.log(
            admin: current_admin,
            action: 'employee_number_created',
            target: employee_number,
            details: "Added employee number: #{employee_number.employee_number}",
            tournament: tournament
          )
          render json: employee_number, serializer: EmployeeNumberSerializer, status: :created
        else
          render json: { errors: employee_number.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/employee_numbers/bulk_create
      def bulk_create
        tournament = find_tournament
        return render_tournament_required unless tournament

        numbers = params[:employee_numbers]
        return render json: { error: "No employee numbers provided" }, status: :bad_request unless numbers.is_a?(Array)

        created = []
        errors = []

        numbers.each do |num_data|
          number = num_data.is_a?(String) ? num_data : num_data[:employee_number]
          name = num_data.is_a?(Hash) ? num_data[:employee_name] : nil

          emp = tournament.employee_numbers.new(employee_number: number, employee_name: name)
          if emp.save
            created << emp
          else
            errors << { employee_number: number, errors: emp.errors.full_messages }
          end
        end

        if created.any?
          ActivityLog.log(
            admin: current_admin,
            action: 'employee_numbers_bulk_created',
            target: tournament,
            details: "Added #{created.count} employee numbers",
            tournament: tournament,
            metadata: { count: created.count }
          )
        end

        render json: {
          created: created.count,
          errors: errors,
          employee_numbers: ActiveModelSerializers::SerializableResource.new(created)
        }, status: errors.any? ? :multi_status : :created
      end

      # PUT /api/v1/employee_numbers/:id
      def update
        employee_number = EmployeeNumber.find(params[:id])

        if employee_number.update(employee_number_params)
          ActivityLog.log(
            admin: current_admin,
            action: 'employee_number_updated',
            target: employee_number,
            details: "Updated employee number: #{employee_number.employee_number}",
            tournament: employee_number.tournament
          )
          render json: employee_number, serializer: EmployeeNumberSerializer
        else
          render json: { errors: employee_number.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/employee_numbers/:id
      def destroy
        employee_number = EmployeeNumber.find(params[:id])
        tournament = employee_number.tournament

        if employee_number.used?
          return render json: { 
            error: "Cannot delete an employee number that has been used. It was used by #{employee_number.used_by_golfer&.name}." 
          }, status: :unprocessable_entity
        end

        employee_number.destroy!

        ActivityLog.log(
          admin: current_admin,
          action: 'employee_number_deleted',
          target: nil,
          details: "Deleted employee number: #{employee_number.employee_number}",
          tournament: tournament
        )

        render json: { success: true, message: "Employee number deleted" }
      end

      # POST /api/v1/employee_numbers/:id/release
      # Release an employee number (e.g., if the golfer cancelled)
      def release
        employee_number = EmployeeNumber.find(params[:id])

        unless employee_number.used?
          return render json: { error: "This employee number is not in use" }, status: :unprocessable_entity
        end

        golfer_name = employee_number.used_by_golfer&.name
        employee_number.release!

        ActivityLog.log(
          admin: current_admin,
          action: 'employee_number_released',
          target: employee_number,
          details: "Released employee number: #{employee_number.employee_number} (was used by #{golfer_name})",
          tournament: employee_number.tournament
        )

        render json: employee_number, serializer: EmployeeNumberSerializer
      end

      # POST /api/v1/employee_numbers/validate
      # Check if an employee number is valid and available (public endpoint - no auth required)
      def validate
        tournament = Tournament.current
        return render json: { valid: false, error: "No active tournament" }, status: :not_found unless tournament

        result = tournament.validate_employee_number(params[:employee_number])
        
        if result[:valid]
          render json: { 
            valid: true, 
            employee_fee: tournament.employee_entry_fee,
            employee_fee_dollars: tournament.employee_entry_fee_dollars,
            message: "Valid employee number - discounted rate applies"
          }
        else
          render json: { valid: false, error: result[:error] }
        end
      end

      private

      def find_tournament
        if params[:tournament_id]
          Tournament.find_by(id: params[:tournament_id])
        else
          Tournament.current
        end
      end

      def render_tournament_required
        render json: { error: "Tournament not found" }, status: :not_found
      end

      def employee_number_params
        params.require(:employee_number).permit(:employee_number, :employee_name)
      end
    end
  end
end

