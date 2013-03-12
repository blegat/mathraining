Ombtraining::Application.routes.draw do

  mathjax 'mathjax'
  resources :prerequisites

  resources :sections

  resources :chapters do
    match '/manage_sections', to: 'chapters#new_section'
    match '/add_section/:id', to: 'chapters#create_section',
      as: :add_section
    match '/remove_section/:id', to: 'chapters#destroy_section',
      as: :remove_section
  end

  resources :users do
    match '/add_administrator', to: 'users#create_administrator',
      as: :add_administrator
  end
  
  resources :sessions, only: [:new, :create, :destroy]

  root to: 'static_pages#home'

  match '/help', to: 'static_pages#help'

  match '/about', to: 'static_pages#about'

  match '/contact', to: 'static_pages#contact'

  match '/signup', to: 'users#new'
  match '/signin', to: 'sessions#new'
  match '/signout', to: 'sessions#destroy', via: :delete

end
