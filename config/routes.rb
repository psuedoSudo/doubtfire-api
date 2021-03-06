Doubtfire::Application.routes.draw do
	devise_for :users
  	mount Api::Root => '/'

  	get 'api/submission/unit/:id/portfolio', to: 'portfolio_downloads#index'
  	get 'api/units/:id/all_resources', to: 'lecture_resource_downloads#index'
end
