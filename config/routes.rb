require 'api_constraints'

Rails.application.routes.draw do
  scope module: :v1,
        defaults: { format: :json },
        constraints: ApiConstraints.new(version: 1, default: true) do
          #resources :users, :only =>
        end
end
