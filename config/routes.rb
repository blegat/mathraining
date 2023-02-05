require "resque_web"

Rails.application.routes.draw do

  # Sections
  resources :sections, only: [:show, :edit, :update] do
    resources :chapters, only: [:new, :create]
    resources :problems, only: [:new, :create]
  end
  get 'pb_sections/:id', to: 'sections#showpb', as: :pb_sections

  # Chapters
  resources :chapters, only: [:show, :update, :edit, :destroy] do
    match '/warning', to: 'chapters#warning', :via => [:get]
    match '/put_online', to: 'chapters#put_online', :via => [:put]
    match '/order_plus', to: 'chapters#order_plus', :via => [:put], as: :order_plus
    match '/order_minus', to: 'chapters#order_minus', :via => [:put], as: :order_minus

    match '/read', to: 'chapters#read', :via => [:put]

    resources :theories, only: [:new, :create]
    resources :questions, only: [:new, :create]
  end
  resources :chaptercreations, only: [] # Must be added manually!

  # Prerequisites
  resources :prerequisites, only: []
  match '/graph_prerequisites', to: "prerequisites#graph_prerequisites", :via => [:get]
  match '/add_prerequisite', to: "prerequisites#add_prerequisite", :via => [:post]
  match '/remove_prerequisite', to: "prerequisites#remove_prerequisite", :via => [:post]

  # Theories
  resources :theories, only: [:update, :edit, :destroy] do
    match '/order_plus', to: 'theories#order_plus', :via => [:put], as: :order_plus
    match '/order_minus', to: 'theories#order_minus', :via => [:put], as: :order_minus
    match '/put_online', to: 'theories#put_online', :via => [:put], as: :put_online
    match '/read', to: 'theories#read', :via => [:put], as: :read
    match '/unread', to: 'theories#unread', :via => [:put], as: :unread
  end

  # Questions
  resources :questions, only: [:update, :edit, :destroy] do
    match '/order_plus', to: 'questions#order_plus', :via => [:put], as: :order_plus
    match '/order_minus', to: 'questions#order_minus', :via => [:put], as: :order_minus
    match '/put_online', to: 'questions#put_online', :via => [:put], as: :put_online
    match '/explanation', to: "questions#explanation", :via => [:get]
    match '/update_explanation', to: "questions#update_explanation", :via => [:patch], as: :update_explanation
    match '/manage_items', to: "questions#manage_items", :via => [:get]
    match '/add_item', to: "questions#add_item", :via => [:post]
    match '/update_item/:id', to: "questions#update_item", :via => [:patch], as: :update_item
    match '/remove_item/:id', to: "questions#remove_item", :via => [:put], as: :remove_item
    match '/switch_item/:id', to: "questions#switch_item", :via => [:put], as: :switch_item
    match '/up_item/:id', to: "questions#up_item", :via => [:put], as: :up_item
    match '/down_item/:id', to: "questions#down_item", :via => [:put], as: :down_item
  end

  resources :solvedquestions, only: [:create, :update]
  
  # Problems
  resources :problems, only: [:update, :edit, :destroy, :show] do
    match '/delete_prerequsite', to: 'problems#delete_prerequisite', :via => [:put], as: :delete_prerequisite
    match '/add_prerequsite', to: 'problems#add_prerequisite', :via => [:post], as: :add_prerequisite
    match '/order_plus', to: 'problems#order_plus', :via => [:put], as: :order_plus
    match '/order_minus', to: 'problems#order_minus', :via => [:put], as: :order_minus
    match '/put_online', to: 'problems#put_online', :via => [:put], as: :put_online
    match '/explanation', to: "problems#explanation", :via => [:get]
    match '/markscheme', to: "problems#markscheme", :via => [:get]
    match '/update_explanation', to: "problems#update_explanation", :via => [:patch], as: :update_explanation
    match '/update_markscheme', to: "problems#update_markscheme", :via => [:patch], as: :update_markscheme
    match '/add_virtualtest', to: 'problems#add_virtualtest', :via => [:post], as: :add_virtualtest
    match '/create_intest', to: 'submissions#create_intest', :via => [:post], as: :create_intest
    
    # Submissions
    resources :submissions, only: [:create] do
      match '/update_intest', to: 'submissions#update_intest', :via => [:post], as: :update_intest
      match '/update_draft', to: 'submissions#update_draft', :via => [:post], as: :update_draft
      match '/read', to: 'submissions#read', :via => [:put], as: :read
      match '/unread', to: 'submissions#unread', :via => [:put], as: :unread
      match '/star', to: 'submissions#star', :via => [:put], as: :star
      match '/unstar', to: 'submissions#unstar', :via => [:put], as: :unstar
      match '/update_score', to: 'submissions#update_score', :via => [:put], as: :update_score
      match '/uncorrect', to: 'submissions#uncorrect', :via => [:put], as: :uncorrect
      
      resources :corrections, only: [:create]
    end
  end
  
  resources :solvedproblems, only: [:index]

  # Submissions
  resources :submissions, only: [:index, :destroy] do
    match '/search_script', to: 'submissions#search_script', :via => [:post], as: :search_script
    
    resources :suspicions, only: [:create]
  end

  match '/allsub', to: 'users#allsub', :via => [:get], as: :allsub
  match '/allmysub', to: 'users#allmysub', :via => [:get], as: :allmysub
  match '/allnewsub', to: 'users#allnewsub', :via => [:get], as: :allnewsub
  match '/allmynewsub', to: 'users#allmynewsub', :via => [:get], as: :allmynewsub
  match '/reserve', to: 'submissions#reserve', :via => [:get], as: :reserve
  match '/unreserve', to: 'submissions#unreserve', :via => [:get], as: :unreserve
  
  # Suspicions
  resources :suspicions, only: [:index, :destroy, :update]
  
  # Virtual tests
  resources :virtualtests do
    match '/put_online', to: 'virtualtests#put_online', :via => [:put], as: :put_online
    match '/begin_test', to: 'virtualtests#begin_test', :via => [:put], as: :begin_test
  end
  
  # Contests
  resources :contests do
    match '/put_online', to: 'contests#put_online', :via => [:put], as: :put_online
    match '/cutoffs', to: "contests#cutoffs", :via => [:get]
    match '/define_cutoffs', to: 'contests#define_cutoffs', :via => [:get], as: :define_cutoffs
    
    resources :contestproblems, only: [:new, :create]
  end
  resources :contestorganizations, only: [:create, :destroy]
  
  # Contest problems
  resources :contestproblems, only: [:show, :edit, :update, :destroy] do
    match '/publish_results', to: 'contestproblems#publish_results', :via => [:put], as: :publish_results
    match '/authorize_corrections', to: 'contestproblems#authorize_corrections', :via => [:put], as: :authorize_corrections
    match '/unauthorize_corrections', to: 'contestproblems#unauthorize_corrections', :via => [:put], as: :unauthorize_corrections
    resources :contestsolutions, only: [:create]
  end
  
  # Contest solutions
  resources :contestsolutions, only: [:update, :destroy]
  match '/reserve_sol', to: 'contestsolutions#reserve_sol', :via => [:get], as: :reserve_sol
  match '/unreserve_sol', to: 'contestsolutions#unreserve_sol', :via => [:get], as: :unreserve_sol
  
  # Contest corrections
  resources :contestcorrections, only: [:update]
  
  # Subjects
  resources :subjects, only: [:index, :show, :new, :create, :update, :destroy] do
    resources :messages, only: [:create, :update, :destroy]
    match '/migrate', to: 'subjects#migrate', :via => [:put], as: :migrate
  end
  
  # Categories (for subjects)
  resources :categories, only: [:index, :create, :update, :destroy]
  
  # Users
  resources :users do
    match '/add_administrator', to: 'users#create_administrator', :via => [:put], as: :add_administrator
    match '/switch_wepion', to: 'users#switch_wepion', :via => [:put], as: :switch_wepion
    match '/switch_corrector', to: 'users#switch_corrector', :via => [:put], as: :switch_corrector
    match '/destroydata', to: 'users#destroydata', :via => [:put], as: :destroydata
    match '/take_skin', to: 'users#take_skin', :via => [:put], as: :take_skin
    match '/leave_skin', to: 'users#leave_skin', :via => [:put], as: :leave_skin
    match '/change_group', to: 'users#change_group', :via => [:put], as: :change_group
    match '/recup_password', to: 'users#recup_password', :via => [:get], as: :recup_password
    match '/change_password', to: 'users#change_password', :via => [:post]
    match '/add_followed_user', to: 'users#add_followed_user', :via => [:put], as: :add_followed_user
    match '/remove_followed_user', to: 'users#remove_followed_user', :via => [:put], as: :remove_followed_user
    match '/change_name', to: 'users#change_name', :via => [:put], as: :change_name
    match '/switch_can_change_name', to: 'users#switch_can_change_name', :via => [:put], as: :switch_can_change_name
  end
  match '/accept_legal', to: 'users#accept_legal', :via => [:patch], as: :accept_legal
  match '/groups', to: 'users#groups', :via => [:get], as: :groups
  match '/correctors', to: 'users#correctors', :via => [:get], as: :correctors
  match '/followed_users', to: 'users#followed_users', :via => [:get], as: :followed_users
  match '/notifs', to: 'users#notifs_show', :via => [:get], as: :notifs_show
  match '/signup', to: 'users#new', :via => [:get]
  match '/activate', to: 'users#activate', :via => [:get]
  match '/forgot_password', to: 'users#forgot_password', :via => [:get]
  match '/password_forgotten', to: 'users#password_forgotten', :via => [:post]
  
  # Email subscriptions (subjects, discussions and contests)
  resources :followingsubjects, only: []
  match '/add_followingsubject', to: "followingsubjects#add_followingsubject", :via => [:put]
  match '/remove_followingsubject', to: "followingsubjects#remove_followingsubject", :via => [:get] # Get because it should be doable via email link
  match '/add_followingmessage', to: "users#add_followingmessage", :via => [:put]
  match '/remove_followingmessage', to: "users#remove_followingmessage", :via => [:get] # Get because it should be doable via email link
  resources :followingcontests, only: []
  match '/add_followingcontest', to: "followingcontests#add_followingcontest", :via => [:put]
  match '/remove_followingcontest', to: "followingcontests#remove_followingcontest", :via => [:get] # Get because it should be doable via email link
  
  # Privacy policies
  resources :privacypolicies, only: [:index, :show, :new, :edit, :update, :destroy] do
    match '/put_online', to: 'privacypolicies#put_online', :via => [:put], as: :put_online
    match '/edit_description', to: 'privacypolicies#edit_description', :via => [:get]
    match '/update_description', to: 'privacypolicies#update_description', :via => [:patch], as: :update_description
  end
  match '/last_policy', to: 'privacypolicies#last_policy', :via => [:get], as: :last_policy
  
  # Pictures
  resources :pictures, only: [:index, :show, :new, :create, :destroy]
  
  # Actualities
  resources :actualities, only: [:update, :edit, :destroy, :new, :create]
  
  # Attached files
  resources :myfiles, only: [:show, :index] do
  	match '/fake_delete', to: 'myfiles#fake_delete', :via => [:put], as: :fake_delete
  	#member do
  	#	get :download
  	#end
  end
  
  # Discussions
  resources :discussions, only: [:new, :create, :show] do
    match '/unread', to: 'discussions#unread', :via => [:put], as: :unread
    resources :tchatmessages, only: [:create]
  end
  resources :links, only: []
  
  # Names validation
  match '/validate_names', to: 'users#validate_names', :via => [:get], as: :validate_names
  match '/validate_name', to: 'users#validate_name', :via => [:get], as: :validate_name
  
  # Colors
  resources :colors, only: [:index, :create, :update, :destroy]
  
  # Sessions
  resources :sessions, only: [:new, :create, :destroy]
  match '/signin', to: 'sessions#new', :via => [:get]
  match '/signout', to: 'sessions#destroy', via: :delete
  
  # Static pages
  root to: 'static_pages#home'
  match '/about', to: 'static_pages#about', :via => [:get]
  match '/contact', to: 'static_pages#contact', :via => [:get]
  match '/frequentation', to: 'static_pages#frequentation', :via => [:get]
  match '/exostats', to: 'static_pages#exostats', :via => [:get]

  # Error pages
  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unacceptable'
  get '/500', to: 'errors#internal_error'
  get '*unmatched_route', to: 'errors#not_found', constraints: lambda { |req| req.path.exclude? 'rails/active_storage' }

  mount ResqueWeb::Engine => '/resque_web'

end
