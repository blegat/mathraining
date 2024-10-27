Rails.application.routes.draw do

  # Sections
  resources :sections, only: [:show, :edit, :update] do
    resources :chapters, only: [:new, :create]
    resources :problems, only: [:new, :create]
  end
  get 'pb_sections/:id', to: 'sections#show_problems', as: :pb_sections

  # Chapters
  resources :chapters, only: [:show, :update, :edit, :destroy] do
    member do
      get :all
      put :put_online
      put :mark_submission_prerequisite
      put :unmark_submission_prerequisite
      put :order
      put :read
    end
    resources :theories, only: [:show, :new, :create]
    resources :questions, only: [:show, :new, :create]
  end
  match '/chapterstats', to: 'chapters#chapterstats', :via => [:get]
  resources :chaptercreations, only: [] # Must be added manually in the database!

  # Prerequisites
  resources :prerequisites, only: [:index, :create, :destroy]

  # Theories
  resources :theories, only: [:update, :edit, :destroy] do
    member do
      put :order
      put :put_online
      put :read
      put :unread
    end
  end

  # Questions
  resources :questions, only: [:update, :edit, :destroy] do
    member do
      put :order
      put :put_online
      get :edit_explanation
      patch :update_explanation
      get :manage_items
    end
    
    resources :items, only: [:create]
  end
  
  # Items
  resources :items, only: [:update, :destroy] do
    member do
      put :correct
      put :uncorrect
      put :order
    end
  end

  resources :unsolvedquestions, only: [:create, :update]
  
  # Problems
  resources :problems, only: [:update, :edit, :destroy, :show] do
    member do
      put :delete_prerequisite
      post :add_prerequisite
      put :order
      put :put_online
      get :edit_explanation
      get :edit_markscheme
      patch :update_explanation
      patch :update_markscheme
      post :add_virtualtest
      get :manage_externalsolutions
    end
    
    resources :submissions, only: [:create]
    resources :externalsolutions, only: [:create]
    match '/create_intest', to: 'submissions#create_intest', :via => [:post]
  end
  
  resources :solvedproblems, only: [:index]

  # Submissions
  resources :submissions, only: [:index, :destroy] do # 'index' only via JS
    member do
      patch :update_intest
      patch :update_draft
      put :read
      put :unread
      put :star
      put :unstar
      put :update_score
      put :uncorrect
      get :reserve # only via JS
      get :unreserve # only via JS
      post :search_script # only via JS
    end
   
    resources :corrections, only: [:create]
    resources :suspicions, only: [:create]
    resources :starproposals, only: [:create]
  end

  match '/allsub', to: 'submissions#allsub', :via => [:get]
  match '/allmysub', to: 'submissions#allmysub', :via => [:get]
  match '/allnewsub', to: 'submissions#allnewsub', :via => [:get]
  match '/allmynewsub', to: 'submissions#allmynewsub', :via => [:get]
  
  # External solutions
  resources :externalsolutions, only: [:update, :destroy] do
    resources :extracts, only: [:create]
  end
  
  # Extracts
  resources :extracts, only: [:update, :destroy]
  
  # Suspicions
  resources :suspicions, only: [:index, :destroy, :update]
  
  # Star proposals
  resources :starproposals, only: [:index, :destroy, :update]
  
  # Virtual tests
  resources :virtualtests do
    member do
      put :put_online
      put :begin_test
    end
  end
  
  # Contests
  resources :contests do
    member do
      put :put_online
      get :cutoffs
      post :define_cutoffs
      put :follow
      get :unfollow # Get because it should be doable via email link
      patch :add_organizer
      put :remove_organizer
    end
    
    resources :contestproblems, only: [:new, :create]
  end
  
  # Contest problems
  resources :contestproblems, only: [:show, :edit, :update, :destroy] do
    member do
      put :publish_results
      put :authorize_corrections
      put :unauthorize_corrections
    end
    
    resources :contestsolutions, only: [:create]
  end
  
  # Contest solutions
  resources :contestsolutions, only: [:update, :destroy] do
    member do
      get :reserve # only via JS
      get :unreserve # only via JS
    end
  end
  
  # Contest corrections
  resources :contestcorrections, only: [:update]
  
  # Subjects
  resources :subjects, only: [:index, :show, :new, :create, :update, :destroy] do
    member do
      put :migrate
      put :follow
      get :unfollow # Get because it should be doable via email link
    end
  
    resources :messages, only: [:create]
  end
  
  # Messages
  resources :messages, only: [:update, :destroy] do
    member do
      put :soft_destroy
    end
  end
  
  # Categories (for subjects)
  resources :categories, only: [:index, :create, :update, :destroy]
  
  # Users
  resources :users do
    member do
      put :set_administrator
      put :set_wepion
      put :unset_wepion
      put :set_corrector
      put :unset_corrector
      put :destroydata
      put :take_skin
      put :change_group
      get :recup_password
      patch :change_password
      put :follow
      put :unfollow
      put :set_can_change_name
      put :unset_can_change_name
      put :ban_temporarily
      get :validate_name # only via JS
    end
  end
  match '/leave_skin', to: 'users#leave_skin', :via => [:put]
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
    member do
      put :put_online
      get :edit_description
      patch :update_description
    end
  end
  match '/last_policy', to: 'privacypolicies#last_policy', :via => [:get]
  
  # Pictures
  resources :pictures, only: [:index, :show, :new, :create, :destroy] do
    member do
      get :image
    end
  end
  
  # Actualities
  resources :actualities, only: [:update, :edit, :destroy, :new, :create]
  
  # Attached files
  resources :myfiles, only: [:show, :index] do
    member do
      put :fake_delete
    end
  end
  
  # Discussions
  resources :discussions, only: [:new, :show] do # 'show' via HTML or JS 
    member do
      put :unread
    end
  end
  
  # Tchatmessages
  resources :tchatmessages, only: [:create]
  
  # Colors
  resources :colors, only: [:index, :create, :update, :destroy]
  
  # Faqs
  resources :faqs, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      put :order
    end
  end
  
  # Sessions
  resources :sessions, only: [:create, :destroy]
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
  
  # Redirect all kinds of apple-touch-icon...png requests to the same icon
  get '/:apple_touch_icon' => redirect('/icon-120.png'), constraints: { apple_touch_icon: /apple-touch-icon(-\d+x\d+)?(-precomposed)?\.png/ }

  # Error pages
  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unacceptable'
  get '/500', to: 'errors#internal_error'
  get '*unmatched_route', to: 'errors#not_found', constraints: lambda { |req| req.path.exclude? 'rails/active_storage' }

end
