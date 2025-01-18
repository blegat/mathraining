Rails.application.routes.draw do

  # Sections
  resources :sections, only: [:show, :edit, :update] do
    resources :chapters, only: [:new, :create]
    resources :problems, only: [:index, :new, :create]
  end

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
    collection do
      get :stats
    end
    resources :theories, only: [:show, :new, :create]
    resources :questions, only: [:show, :new, :create]
  end

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
    resources :submissions, only: [:create] do
      collection do
        post :create_intest
      end
    end
    resources :externalsolutions, only: [:create]
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
      get :next_good
      get :prev_good
    end
    collection do
      get :all
      get :allmy
      get :allnew
      get :allmynew
    end
    resources :corrections, only: [:create]
    resources :suspicions, only: [:create]
    resources :starproposals, only: [:create]
  end
  
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
      get :validate_name # only via JS
    end
    collection do
      get :groups
      get :correctors
      get :followed
      get :search
      get :validate_names
    end
    resources :sanctions, only: [:index, :new, :create]
  end
  
  # Paths relative to current user
  put '/leave_skin', to: 'users#leave_skin'
  patch '/accept_legal', to: 'users#accept_legal'
  get '/notifs', to: 'users#notifs'
  get '/signup', to: 'users#new'
  get '/activate', to: 'users#activate'
  get '/forgot_password', to: 'users#forgot_password'
  post '/password_forgotten', to: 'users#password_forgotten'
  put '/set_follow_message', to: "users#set_follow_message"
  get '/unset_follow_message', to: "users#unset_follow_message" # Get because it should be doable via email link
  
  # Privacy policies
  resources :privacypolicies, only: [:index, :show, :new, :edit, :update, :destroy] do
    member do
      put :put_online
      get :edit_description
      patch :update_description
    end
    collection do
      get :last
    end
  end
  
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
  
  # Sanctions
  resources :sanctions, only: [:edit, :update, :destroy]
  
  # Savedreplies
  resources :savedreplies, only: [:new, :create, :edit, :update, :destroy]
  
  # Puzzles (10 years)
  resources :puzzles, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      put :order
      get :attempt # only via JS
    end
    collection do
      get :graph
    end
  end
  get '/ten_years', to: 'puzzles#main'
  
  # Sessions (singular resource, to call destroy without an id!)
  resource :sessions, only: [:create, :destroy]
  
  # Static pages
  root to: 'static_pages#home'
  get '/about', to: 'static_pages#about'
  get '/contact', to: 'static_pages#contact'
  get '/stats', to: 'static_pages#stats'

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
