Rails.application.routes.draw do

  # Sections
  resources :sections, only: [:show, :edit, :update] do
    resources :chapters, only: [:new, :create]
    resources :problems, only: [:new, :create]
  end
  get 'pb_sections/:id', to: 'sections#show_problems', as: :pb_sections

  # Chapters
  resources :chapters, only: [:show, :update, :edit, :destroy] do
    match '/put_online', to: 'chapters#put_online', :via => [:put]
    match '/mark_submission_prerequisite', to: 'chapters#mark_submission_prerequisite', :via => [:put]
    match '/unmark_submission_prerequisite', to: 'chapters#unmark_submission_prerequisite', :via => [:put]
    match '/order', to: 'chapters#order', :via => [:put]
    match '/read', to: 'chapters#read', :via => [:put]

    resources :theories, only: [:new, :create]
    resources :questions, only: [:new, :create]
  end
  match '/chapterstats', to: 'chapters#chapterstats', :via => [:get]
  resources :chaptercreations, only: [] # Must be added manually in the database!

  # Prerequisites
  match '/graph_prerequisites', to: "prerequisites#graph_prerequisites", :via => [:get]
  match '/add_prerequisite', to: "prerequisites#add_prerequisite", :via => [:post]
  match '/remove_prerequisite', to: "prerequisites#remove_prerequisite", :via => [:post]

  # Theories
  resources :theories, only: [:update, :edit, :destroy] do
    match '/order', to: 'theories#order', :via => [:put]
    match '/put_online', to: 'theories#put_online', :via => [:put]
    match '/read', to: 'theories#read', :via => [:put]
    match '/unread', to: 'theories#unread', :via => [:put]
  end

  # Questions
  resources :questions, only: [:update, :edit, :destroy] do
    match '/order', to: 'questions#order', :via => [:put]
    match '/put_online', to: 'questions#put_online', :via => [:put]
    match '/edit_explanation', to: "questions#edit_explanation", :via => [:get]
    match '/update_explanation', to: "questions#update_explanation", :via => [:patch]
    match '/manage_items', to: "questions#manage_items", :via => [:get]
    
    resources :items, only: [:create]
  end
  
  # Items
  resources :items, only: [:update, :destroy] do
    match '/correct', to: "items#correct", :via => [:put]
    match '/uncorrect', to: "items#uncorrect", :via => [:put]
    match '/order', to: "items#order", :via => [:put]
  end

  resources :unsolvedquestions, only: [:create, :update]
  
  # Problems
  resources :problems, only: [:update, :edit, :destroy, :show] do
    match '/delete_prerequisite', to: 'problems#delete_prerequisite', :via => [:put]
    match '/add_prerequisite', to: 'problems#add_prerequisite', :via => [:post]
    match '/order', to: 'problems#order', :via => [:put]
    match '/put_online', to: 'problems#put_online', :via => [:put]
    match '/edit_explanation', to: "problems#edit_explanation", :via => [:get]
    match '/edit_markscheme', to: "problems#edit_markscheme", :via => [:get]
    match '/update_explanation', to: "problems#update_explanation", :via => [:patch]
    match '/update_markscheme', to: "problems#update_markscheme", :via => [:patch]
    match '/add_virtualtest', to: 'problems#add_virtualtest', :via => [:post]
    
    resources :submissions, only: [:create]
    match '/create_intest', to: 'submissions#create_intest', :via => [:post]
  end
  
  resources :solvedproblems, only: [:index]

  # Submissions
  resources :submissions, only: [:index, :destroy] do # 'index' only via JS
    match '/update_intest', to: 'submissions#update_intest', :via => [:post]
    match '/update_draft', to: 'submissions#update_draft', :via => [:post]
    match '/read', to: 'submissions#read', :via => [:put]
    match '/unread', to: 'submissions#unread', :via => [:put]
    match '/star', to: 'submissions#star', :via => [:put]
    match '/unstar', to: 'submissions#unstar', :via => [:put]
    match '/update_score', to: 'submissions#update_score', :via => [:put]
    match '/uncorrect', to: 'submissions#uncorrect', :via => [:put]
    match '/reserve', to: 'submissions#reserve', :via => [:get] # only via JS
    match '/unreserve', to: 'submissions#unreserve', :via => [:get] # only via JS
    match '/search_script', to: 'submissions#search_script', :via => [:post]
    
    resources :corrections, only: [:create]
    resources :suspicions, only: [:create]
    resources :starproposals, only: [:create]
  end

  match '/allsub', to: 'submissions#allsub', :via => [:get]
  match '/allmysub', to: 'submissions#allmysub', :via => [:get]
  match '/allnewsub', to: 'submissions#allnewsub', :via => [:get]
  match '/allmynewsub', to: 'submissions#allmynewsub', :via => [:get]
  
  # Suspicions
  resources :suspicions, only: [:index, :destroy, :update]
  
  # Star proposals
  resources :starproposals, only: [:index, :destroy, :update]
  
  # Virtual tests
  resources :virtualtests do
    match '/put_online', to: 'virtualtests#put_online', :via => [:put]
    match '/begin_test', to: 'virtualtests#begin_test', :via => [:put]
  end
  
  # Contests
  resources :contests do
    match '/put_online', to: 'contests#put_online', :via => [:put]
    match '/cutoffs', to: "contests#cutoffs", :via => [:get]
    match '/define_cutoffs', to: 'contests#define_cutoffs', :via => [:post]
    match '/follow', to: "contests#follow", :via => [:put]
    match '/unfollow', to: "contests#unfollow", :via => [:get] # Get because it should be doable via email link
    match '/add_organizer', to: "contests#add_organizer", :via => [:patch]
    match '/remove_organizer', to: "contests#remove_organizer", :via => [:put]
    
    resources :contestproblems, only: [:new, :create]
  end
  
  # Contest problems
  resources :contestproblems, only: [:show, :edit, :update, :destroy] do
    match '/publish_results', to: 'contestproblems#publish_results', :via => [:put]
    match '/authorize_corrections', to: 'contestproblems#authorize_corrections', :via => [:put]
    match '/unauthorize_corrections', to: 'contestproblems#unauthorize_corrections', :via => [:put]
    
    resources :contestsolutions, only: [:create]
  end
  
  # Contest solutions
  resources :contestsolutions, only: [:update, :destroy] do
    match '/reserve', to: 'contestsolutions#reserve', :via => [:get] # only via JS
    match '/unreserve', to: 'contestsolutions#unreserve', :via => [:get] # only via JS
  end
  
  # Contest corrections
  resources :contestcorrections, only: [:update]
  
  # Subjects
  resources :subjects, only: [:index, :show, :new, :create, :update, :destroy] do
    match '/migrate', to: 'subjects#migrate', :via => [:put]
    match '/follow', to: "subjects#follow", :via => [:put]
    match '/unfollow', to: "subjects#unfollow", :via => [:get] # Get because it should be doable via email link
  
    resources :messages, only: [:create]
  end
  
  # Messages
  resources :messages, only: [:update, :destroy]
  
  # Categories (for subjects)
  resources :categories, only: [:index, :create, :update, :destroy]
  
  # Users
  resources :users do
    match '/set_administrator', to: 'users#set_administrator', :via => [:put]
    match '/set_wepion', to: 'users#set_wepion', :via => [:put]
    match '/unset_wepion', to: 'users#unset_wepion', :via => [:put]
    match '/set_corrector', to: 'users#set_corrector', :via => [:put]
    match '/unset_corrector', to: 'users#unset_corrector', :via => [:put]
    match '/destroydata', to: 'users#destroydata', :via => [:put]
    match '/take_skin', to: 'users#take_skin', :via => [:put]
    match '/leave_skin', to: 'users#leave_skin', :via => [:put]
    match '/change_group', to: 'users#change_group', :via => [:put]
    match '/recup_password', to: 'users#recup_password', :via => [:get]
    match '/change_password', to: 'users#change_password', :via => [:post]
    match '/add_followed_user', to: 'users#add_followed_user', :via => [:put]
    match '/remove_followed_user', to: 'users#remove_followed_user', :via => [:put]
    match '/change_name', to: 'users#change_name', :via => [:put]
    match '/set_can_change_name', to: 'users#set_can_change_name', :via => [:put]
    match '/unset_can_change_name', to: 'users#unset_can_change_name', :via => [:put]
    match '/ban_temporarily', to: 'users#ban_temporarily', :via => [:put]
    match '/validate_name', to: 'users#validate_name', :via => [:get] # only via JS
  end
  match '/accept_legal', to: 'users#accept_legal', :via => [:patch]
  match '/groups', to: 'users#groups', :via => [:get]
  match '/correctors', to: 'users#correctors', :via => [:get]
  match '/followed_users', to: 'users#followed_users', :via => [:get]
  match '/search_user', to: 'users#search_user', :via => [:get]
  match '/notifs', to: 'users#notifs', :via => [:get]
  match '/signup', to: 'users#new', :via => [:get]
  match '/activate', to: 'users#activate', :via => [:get]
  match '/forgot_password', to: 'users#forgot_password', :via => [:get]
  match '/password_forgotten', to: 'users#password_forgotten', :via => [:post]
  match '/validate_names', to: 'users#validate_names', :via => [:get]
  
  # Email subscriptions (subjects, discussions and contests)
  match '/set_follow_message', to: "users#set_follow_message", :via => [:put]
  match '/unset_follow_message', to: "users#unset_follow_message", :via => [:get] # Get because it should be doable via email link
  
  # Privacy policies
  resources :privacypolicies, only: [:index, :show, :new, :edit, :update, :destroy] do
    match '/put_online', to: 'privacypolicies#put_online', :via => [:put]
    match '/edit_description', to: 'privacypolicies#edit_description', :via => [:get]
    match '/update_description', to: 'privacypolicies#update_description', :via => [:patch]
  end
  match '/last_policy', to: 'privacypolicies#last_policy', :via => [:get]
  
  # Pictures
  resources :pictures, only: [:index, :show, :new, :create, :destroy] do
    match '/image', to: "pictures#image", :via => [:get]
  end
  
  # Actualities
  resources :actualities, only: [:update, :edit, :destroy, :new, :create]
  
  # Attached files
  resources :myfiles, only: [:show, :index] do
  	match '/fake_delete', to: 'myfiles#fake_delete', :via => [:put]
  end
  
  # Discussions
  resources :discussions, only: [:new, :create, :show] do # 'show' via HTML or JS 
    match '/unread', to: 'discussions#unread', :via => [:put]
    
    resources :tchatmessages, only: [:create]
  end
  
  # Colors
  resources :colors, only: [:index, :create, :update, :destroy]
  
  # Faqs
  resources :faqs, only: [:index, :new, :create, :edit, :update, :destroy] do
    match '/order', to: 'faqs#order', :via => [:put]
  end
  
  # Sessions
  resources :sessions, only: [:new, :create, :destroy]
  match '/signin', to: 'sessions#new', :via => [:get]
  match '/signout', to: 'sessions#destroy', via: :delete
  
  # Static pages
  root to: 'static_pages#home'
  match '/about', to: 'static_pages#about', :via => [:get]
  match '/contact', to: 'static_pages#contact', :via => [:get]
  match '/stats', to: 'static_pages#stats', :via => [:get]

  # Redirections for important old page names
  get '/frequentation', to: redirect('/stats') # sometimes used in forum
  get '/remove_followingmessage', to: redirect('/unset_follow_message') # in old emails
  get '/remove_followingsubject', to: redirect { |params, request| "/subjects/#{request.params[:subject_id]}/unfollow" } # in old emails
  get '/remove_followingcontest', to: redirect { |params, request| "/contests/#{request.params[:contest_id]}/unfollow" } # in old emails

  # Error pages
  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unacceptable'
  get '/500', to: 'errors#internal_error'
  get '*unmatched_route', to: 'errors#not_found', constraints: lambda { |req| req.path.exclude? 'rails/active_storage' }

end
