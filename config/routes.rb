require "resque_web"

Mathraining::Application.routes.draw do

  match '/notifications_new', to: 'users#notifications_new', :via => [:get], as: :notifications_new
  match '/notifications_update', to: 'users#notifications_update', :via => [:get], as: :notifications_update

  match '/notifs', to: 'users#notifs_show', :via => [:get], as: :notifs_show

  resources :corrections

  resources :solvedexercises
  resources :solvedqcms
  resources :solvedchoices

  resources :pictures

  resources :actualities, only: [:update, :edit, :destroy, :new, :create]
  match '/feed' => 'actualities#feed', :via => [:get], as: :feed, defaults: { :format => 'atom' }

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
      resources :corrections, only: [:create]
      match '/read', to: 'submissions#read', :via => [:get], as: :read
      match '/unread', to: 'submissions#unread', :via => [:get], as: :unread
      match '/reserve', to: 'submissions#reserve', :via => [:get], as: :reserve
      match '/unreserve', to: 'submissions#unreserve', :via => [:get], as: :unreserve
    end
  end
  
  resources :submissionfiles, only: [] do
    match '/fake_delete', to: 'submissionfiles#fake_delete', :via => [:get], as: :fake_delete
    member do
      get :download
    end
  end
  
  resources :correctionfiles, only: [] do
    match '/fake_delete', to: 'correctionfiles#fake_delete', :via => [:get], as: :fake_delete
    member do
      get :download
    end
  end
  
  resources :subjectfiles, only: [] do
    match '/fake_delete', to: 'subjectfiles#fake_delete', :via => [:get], as: :fake_delete
    member do
      get :download
    end
  end
  
  resources :messagefiles, only: [] do
    match '/fake_delete', to: 'messagefiles#fake_delete', :via => [:get], as: :fake_delete
    member do
      get :download
    end
  end

 # mathjax 'mathjax'

  resource :prerequisites # missing a 's' here ?
  resources :sections, only: [:show, :update, :edit] do
    resources :chapters, only: [:new, :create]
    resources :problems, only: [:new, :create]
  end

  match '/graph_prerequisites', to: "prerequisites#graph_prerequisites", :via => [:get]
  match '/add_prerequisite', to: "prerequisites#add_prerequisite", :via => [:post]
  match '/remove_prerequisite', to: "prerequisites#remove_prerequisite", :via => [:post]

  resources :chapters, only: [:show, :update, :edit, :destroy] do
    match '/warning', to: 'chapters#warning', :via => [:get]
    match '/export', to: 'chapters#export', :via => [:post], as: :export
    match '/put_online', to: 'chapters#put_online', :via => [:get]
    
    match '/read', to: 'chapters#read', :via => [:get], as: :read

    resources :theories, only: [:new, :create]
    resources :exercises, only: [:new, :create]
    resources :qcms, only: [:new, :create]
    resources :problems, only: [:new, :create]
  end

  resources :subjects do
    resources :messages, only: [:update, :edit, :destroy, :new, :create]
  end

  resources :users do
    match '/add_administrator', to: 'users#create_administrator', :via => [:get], as: :add_administrator
    match '/unactivate', to: 'users#unactivate', :via => [:get], as: :unactivate
    match '/reactivate', to: 'users#reactivate', :via => [:get], as: :reactivate
    match '/take_skin', to: 'users#take_skin', :via => [:get], as: :take_skin
    match '/leave_skin', to: 'users#leave_skin', :via => [:get], as: :leave_skin
  end
  
  resources :virtualtests do
    match '/put_online', to: 'virtualtests#put_online', :via => [:get], as: :put_online
    match '/begin_test', to: 'virtualtests#begin_test', :via => [:get], as: :begin_test
  end
  
  resources :followingsubjects
  
  match '/add_followingsubject', to: "followingsubjects#add_followingsubject", :via => [:get]
  match '/remove_followingsubject', to: "followingsubjects#remove_followingsubject", :via => [:get]

  resources :sessions, only: [:new, :create, :destroy]
  
  resources :colors, only: [:index, :create, :update, :destroy]

  root to: 'static_pages#home'

  get 'pb_sections/:id', to: 'sections#showpb', as: :pb_sections

  match '/about', to: 'static_pages#about', :via => [:get]

  match '/contact', to: 'static_pages#contact', :via => [:get]
  
  match '/stats', to: 'static_pages#statistics', :via => [:get]
  
  match '/pieces_jointes', to: 'submissionfiles#seeall', :via => [:get]

  match '/signup', to: 'users#new', :via => [:get]
  match '/signin', to: 'sessions#new', :via => [:get]
  match '/signout', to: 'sessions#destroy', via: :delete
  match '/activate', to: 'users#activate', :via => [:get]
  match '/forgot_password', to: 'users#forgot_password', :via => [:get]
  match '/recup_password', to: 'users#recup_password', :via => [:get]
  match '/password_forgotten', to: 'users#password_forgotten', :via => [:post]

  match '/recompute_scores', to: 'users#recompute_scores', :via => [:get], as: :recompute_scores
      
  mount ResqueWeb::Engine => "/resque_web"

end
