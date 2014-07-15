require "resque_web"

Mathraining::Application.routes.draw do

  match '/notifications_new', to: 'users#notifications_new',
    as: :notifications_new
  match '/notifications_update', to: 'users#notifications_update',
    as: :notifications_update

  match '/notifs', to: 'users#notifs_show',
    as: :notifs_show

  resources :corrections

  resources :solvedexercises
  resources :solvedqcms
  resources :solvedchoices

  resources :pictures

  resources :actualities, only: [:update, :edit, :destroy, :new, :create]
  match '/feed' => 'actualities#feed',
    as: :feed,
    defaults: { :format => 'atom' }

  resources :qcms, only: [:update, :edit, :destroy] do
    match '/order_plus', to: 'qcms#order_plus',
      as: :order_plus
    match '/order_minus', to: 'qcms#order_minus',
      as: :order_minus
    match '/put_online', to: 'qcms#put_online',
      as: :put_online
    match '/explanation', to: "qcms#explanation"
    match '/update_explanation', to: "qcms#update_explanation", as: :update_explanation
    match '/manage_choices', to: "qcms#manage_choices"
    match '/add_choice', to: "qcms#add_choice"
    match '/update_choice/:id', to: "qcms#update_choice", as: :update_choice
    match '/remove_choice/:id', to: "qcms#remove_choice", as: :remove_choice
    match '/switch_choice/:id', to: "qcms#switch_choice", as: :switch_choice
  end

  resources :exercises, only: [:update, :edit, :destroy] do
    match '/order_plus', to: 'exercises#order_plus',
      as: :order_plus
    match '/order_minus', to: 'exercises#order_minus',
      as: :order_minus
    match '/put_online', to: 'exercises#put_online',
      as: :put_online
    match '/explanation', to: "exercises#explanation"
    match '/update_explanation', to: "exercises#update_explanation", as: :update_explanation
  end


  resources :theories, only: [:update, :edit, :destroy] do
    match '/order_plus', to: 'theories#order_plus',
      as: :order_plus
    match '/order_minus', to: 'theories#order_minus',
      as: :order_minus
    match '/put_online', to: 'theories#put_online',
      as: :put_online
    match '/read', to: 'theories#read', as: :read
    match '/unread', to: 'theories#unread', as: :unread
    match '/latex', to: 'theories#latex', as: :latex
  end

  resources :problems, only: [:update, :edit, :destroy] do
    match '/order_plus', to: 'problems#order_plus',
      as: :order_plus
    match '/order_minus', to: 'problems#order_minus',
      as: :order_minus
    match '/put_online', to: 'problems#put_online',
      as: :put_online
    match '/explanation', to: "problems#explanation"
    match '/update_explanation', to: "problems#update_explanation", as: :update_explanation
    resources :submissions, only: [:create] do
      resources :corrections, only: [:create]
      match '/read', to: 'submissions#read',
        as: :read
      match '/unread', to: 'submissions#unread',
        as: :unread
    end
  end
  
  resources :submissionfiles, only: [] do
    match '/fake_delete', to: 'submissionfiles#fake_delete', as: :fake_delete
    member do
      get :download
    end
  end
  
  resources :correctionfiles, only: [] do
    match '/fake_delete', to: 'correctionfiles#fake_delete', as: :fake_delete
    member do
      get :download
    end
  end
  
  resources :subjectfiles, only: [] do
    match '/fake_delete', to: 'subjectfiles#fake_delete', as: :fake_delete
    member do
      get :download
    end
  end
  
  resources :messagefiles, only: [] do
    match '/fake_delete', to: 'messagefiles#fake_delete', as: :fake_delete
    member do
      get :download
    end
  end

 # mathjax 'mathjax'

  resource :prerequisites # missing a 's' here ?
  resources :sections do
    resources :chapters, only: [:new, :create]
  end

  match '/graph_prerequisites', to: "prerequisites#graph_prerequisites"
  match '/add_prerequisite', to: "prerequisites#add_prerequisite"
  match '/remove_prerequisite', to: "prerequisites#remove_prerequisite"

  resources :chapters, only: [:show, :update, :edit, :destroy] do
    match '/warning', to: 'chapters#warning'
    match '/export', to: 'chapters#export', as: :export
    match '/put_online', to: 'chapters#put_online'

    resources :theories, only: [:new, :create]
    resources :exercises, only: [:new, :create]
    resources :qcms, only: [:new, :create]
    resources :problems, only: [:new, :create]
  end

  resources :subjects do
    resources :messages, only: [:update, :edit, :destroy, :new, :create]
  end

  resources :users do
    match '/add_administrator', to: 'users#create_administrator',
      as: :add_administrator
    match '/take_skin', to: 'users#take_skin',
      as: :take_skin
    match '/leave_skin', to: 'users#leave_skin',
      as: :leave_skin
  end
  
  resources :followingsubjects
  
  match '/add_followingsubject', to: "followingsubjects#add_followingsubject"
  match '/remove_followingsubject', to: "followingsubjects#remove_followingsubject"

  resources :sessions, only: [:new, :create, :destroy]

  root to: 'static_pages#home'

  match '/essai', to: 'static_pages#essai'

  match '/about', to: 'static_pages#about'

  match '/contact', to: 'static_pages#contact'
  
  match '/pieces_jointes', to: 'submissionfiles#seeall'

  match '/signup', to: 'users#new'
  match '/signin', to: 'sessions#new'
  match '/signout', to: 'sessions#destroy', via: :delete
  match '/activate', to: 'users#activate'
  match '/forgot_password', to: 'users#forgot_password'
  match '/recup_password', to: 'users#recup_password'
  match '/password_forgotten', to: 'users#password_forgotten'

  match '/recompute_scores', to: 'users#recompute_scores',
      as: :recompute_scores
      
  mount ResqueWeb::Engine => "/resque_web"

end
