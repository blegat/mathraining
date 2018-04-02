require "resque_web"

Mathraining::Application.routes.draw do

  match '/allsub', to: 'users#allsub', :via => [:get], as: :allsub
  match '/allmysub', to: 'users#allmysub', :via => [:get], as: :allmysub
  match '/allnewsub', to: 'users#allnewsub', :via => [:get], as: :allnewsub
  match '/allmynewsub', to: 'users#allmynewsub', :via => [:get], as: :allmynewsub
  
  match '/validate_name', to: 'users#validate_name', :via => [:get], as: :validate_name

  match '/notifs', to: 'users#notifs_show', :via => [:get], as: :notifs_show

  resources :solvedexercises, only: [:create, :update]
  resources :solvedqcms, only: [:create, :update]
  resources :solvedproblems, only: [:index]

  resources :pictures, only: [:index, :show, :new, :create, :destroy]

  resources :actualities, only: [:update, :edit, :destroy, :new, :create]

  resources :qcms, only: [:update, :edit, :destroy] do
    match '/order_plus', to: 'qcms#order_plus', :via => [:get], as: :order_plus
    match '/order_minus', to: 'qcms#order_minus', :via => [:get], as: :order_minus
    match '/put_online', to: 'qcms#put_online', :via => [:get], as: :put_online
    match '/explanation', to: "qcms#explanation", :via => [:get]
    match '/update_explanation', to: "qcms#update_explanation", :via => [:patch], as: :update_explanation
    match '/manage_choices', to: "qcms#manage_choices", :via => [:get]
    match '/add_choice', to: "qcms#add_choice", :via => [:post]
    match '/update_choice/:id', to: "qcms#update_choice", :via => [:patch], as: :update_choice
    match '/remove_choice/:id', to: "qcms#remove_choice", :via => [:get], as: :remove_choice
    match '/switch_choice/:id', to: "qcms#switch_choice", :via => [:get], as: :switch_choice
  end

  resources :exercises, only: [:update, :edit, :destroy] do
    match '/order_plus', to: 'exercises#order_plus', :via => [:get], as: :order_plus
    match '/order_minus', to: 'exercises#order_minus', :via => [:get], as: :order_minus
    match '/put_online', to: 'exercises#put_online', :via => [:get], as: :put_online
    match '/explanation', to: "exercises#explanation", :via => [:get]
    match '/update_explanation', to: "exercises#update_explanation", :via => [:patch], as: :update_explanation
  end

  resources :theories, only: [:update, :edit, :destroy] do
    match '/order_plus', to: 'theories#order_plus', :via => [:get], as: :order_plus
    match '/order_minus', to: 'theories#order_minus', :via => [:get], as: :order_minus
    match '/put_online', to: 'theories#put_online', :via => [:get], as: :put_online
    match '/read', to: 'theories#read', :via => [:get], as: :read
    match '/unread', to: 'theories#unread', :via => [:get], as: :unread
    match '/latex', to: 'theories#latex', :via => [:get], as: :latex
  end

  resources :submissions, only: [:destroy];
  match '/reserve', to: 'submissions#reserve', :via => [:get], as: :reserve
  match '/unreserve', to: 'submissions#unreserve', :via => [:get], as: :unreserve

  resources :problems, only: [:update, :edit, :destroy, :show] do
    match '/delete_prerequsite', to: 'problems#delete_prerequisite', :via => [:get], as: :delete_prerequisite
    match '/add_prerequsite', to: 'problems#add_prerequisite', :via => [:post], as: :add_prerequisite
    match '/order_plus', to: 'problems#order_plus', :via => [:get], as: :order_plus
    match '/order_minus', to: 'problems#order_minus', :via => [:get], as: :order_minus
    match '/put_online', to: 'problems#put_online', :via => [:get], as: :put_online
    match '/explanation', to: "problems#explanation", :via => [:get]
    match '/update_explanation', to: "problems#update_explanation", :via => [:patch], as: :update_explanation
    match '/add_virtualtest', to: 'problems#add_virtualtest', :via => [:post], as: :add_virtualtest
    match '/intest', to: 'submissions#intest', :via => [:get], as: :intest
    match '/create_intest', to: 'submissions#create_intest', :via => [:post], as: :create_intest
    resources :submissions, only: [:create] do
      match '/update_intest', to: 'submissions#update_intest', :via => [:post], as: :update_intest
      match '/update_brouillon', to: 'submissions#update_brouillon', :via => [:post], as: :update_brouillon
      resources :corrections, only: [:create]
      match '/read', to: 'submissions#read', :via => [:get], as: :read
      match '/unread', to: 'submissions#unread', :via => [:get], as: :unread
      match '/star', to: 'submissions#star', :via => [:get], as: :star
      match '/unstar', to: 'submissions#unstar', :via => [:get], as: :unstar
    end
  end
  
  resources :myfiles, only: [:edit, :update, :show, :index] do
  	match '/fake_delete', to: 'myfiles#fake_delete', :via => [:get], as: :fake_delete
  	member do
  		get :download
  	end
  end

 # mathjax 'mathjax'

  resources :prerequisites, only: []

  resources :sections, only: [:show, :edit, :update] do
    resources :chapters, only: [:new, :create]
    resources :problems, only: [:new, :create]
  end

  match '/graph_prerequisites', to: "prerequisites#graph_prerequisites", :via => [:get]
  match '/add_prerequisite', to: "prerequisites#add_prerequisite", :via => [:post]
  match '/remove_prerequisite', to: "prerequisites#remove_prerequisite", :via => [:post]

  resources :chapters, only: [:show, :update, :edit, :destroy] do
    match '/warning', to: 'chapters#warning', :via => [:get]
    match '/put_online', to: 'chapters#put_online', :via => [:get]

    match '/read', to: 'chapters#read', :via => [:get]

    resources :theories, only: [:new, :create]
    resources :exercises, only: [:new, :create]
    resources :qcms, only: [:new, :create]
  end

  resources :subjects, only: [:index, :show, :new, :create, :update, :destroy] do
    resources :messages, only: [:create, :update, :destroy]
    match '/migrate', to: 'subjects#migrate', :via => [:get], as: :migrate
  end

  resources :users do
    match '/add_administrator', to: 'users#create_administrator', :via => [:get], as: :add_administrator
    match '/switch_wepion', to: 'users#switch_wepion', :via => [:get], as: :switch_wepion
    match '/switch_corrector', to: 'users#switch_corrector', :via => [:get], as: :switch_corrector
    match '/switchactivate', to: 'users#switchactivate', :via => [:get], as: :switchactivate
    match '/take_skin', to: 'users#take_skin', :via => [:get], as: :take_skin
    match '/leave_skin', to: 'users#leave_skin', :via => [:get], as: :leave_skin
    match '/change_group', to: 'users#change_group', :via => [:get], as: :change_group
  end
  
  match '/groups', to: 'users#groups', :via => [:get], as: :groups
  match '/correctors', to: 'users#correctors', :via => [:get], as: :correctors

  resources :virtualtests do
    match '/put_online', to: 'virtualtests#put_online', :via => [:get], as: :put_online
    match '/begin_test', to: 'virtualtests#begin_test', :via => [:get], as: :begin_test
  end

  resources :followingsubjects

  match '/add_followingsubject', to: "followingsubjects#add_followingsubject", :via => [:get]
  match '/remove_followingsubject', to: "followingsubjects#remove_followingsubject", :via => [:get]

  match '/add_followingmessage', to: "followingsubjects#add_followingmessage", :via => [:get]
  match '/remove_followingmessage', to: "followingsubjects#remove_followingmessage", :via => [:get]

  resources :sessions, only: [:new, :create, :destroy]

  resources :colors, only: [:index, :create, :update, :destroy]

  resources :discussions, only: [:new, :create, :show] do
    match '/unread', to: 'discussions#unread', :via => [:get], as: :unread
  end
  resources :tchatmessages, only: [:create]
  resources :links, only: []

  root to: 'static_pages#home'

  get 'pb_sections/:id', to: 'sections#showpb', as: :pb_sections

  match '/legal', to: 'static_pages#legal', :via => [:get]
  match '/about', to: 'static_pages#about', :via => [:get]
  match '/contact', to: 'static_pages#contact', :via => [:get]

  match '/stats', to: 'static_pages#statistics', :via => [:get]

  match '/frequentation', to: 'static_pages#frequentation', :via => [:get]
  match '/exostats', to: 'static_pages#exostats', :via => [:get]

  match '/compare', to: 'users#compare', :via => [:get]

  match '/signup', to: 'users#new', :via => [:get]
  match '/signin', to: 'sessions#new', :via => [:get]
  match '/signout', to: 'sessions#destroy', via: :delete
  match '/activate', to: 'users#activate', :via => [:get]
  match '/forgot_password', to: 'users#forgot_password', :via => [:get]
  match '/recup_password', to: 'users#recup_password', :via => [:get]
  match '/password_forgotten', to: 'users#password_forgotten', :via => [:post]

  match '/recompute_scores', to: 'users#recompute_scores', :via => [:get], as: :recompute_scores
  
  resources :categories, only: [:index, :create, :update, :destroy]

  mount ResqueWeb::Engine => "/resque_web"

end
