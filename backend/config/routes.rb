Rails.application.routes.draw do
  # API-only application
  # Frontend is handled by Flutter mobile app
  
  # API routes for transaction management
  namespace :api do
    namespace :v1 do
      resources :transactions, only: [:create, :index, :destroy] do
        collection do
          # POST /api/v1/transactions/create_from_image
          # Upload payment screenshot for AI processing
          post :create_from_image
        end
      end
    end
  end
end