module Api
  module V1
    class BaseController < ApplicationController
      include Authenticated

      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
      rescue_from ActionController::ParameterMissing, with: :parameter_missing

      private

      def record_not_found(exception)
        render json: { error: "Record not found: #{exception.message}" }, status: :not_found
      end

      def record_invalid(exception)
        render json: { error: exception.message, details: exception.record.errors.full_messages }, status: :unprocessable_entity
      end

      def parameter_missing(exception)
        render json: { error: exception.message }, status: :bad_request
      end

      def paginate(collection)
        collection.page(params[:page] || 1).per(params[:per_page] || 25)
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          per_page: collection.limit_value
        }
      end
    end
  end
end

