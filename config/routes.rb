Rails.application.routes.draw do
  # Página de inicio
  authenticated :user do
    devise_scope :user do
      root to: "users#wall"
    end
  end

  unauthenticated do
    devise_scope :user do
      root to: "users/sessions#new", :as => "unauthenticated"
    end
  end

  # root :to => 'devise/sessions#new'


  # Creación y login de usuarios
  # match "auth/:provider/callback", :to => "sessions#create", :via => "post"
  # match "auth/failure", :to => "sessions#failure", :via => "get"

  # match "login" => "sessions#new", :via => ["get", "post"]
  # match "logout" => "sessions#destroy", :via => "get"

  # Namespace específico para administración
  namespace :admin do 
    resources :comments
    resources :configurations
    resources :dashboard, except: [:create, :destroy, :edit, :new, :update]
    resources :events
    resources :routes
    resources :users
  end

  resources :contacts do 
    collection do
      get 'contact'
      post 'send_contact'
    end
  end

  resources :comments, only: [:edit, :show] do
    member do 
      post 'destroy'
      post 'mark_as_offensive'
      post 'update'
    end
  end

  # Recursos para los eventos
  resources :events do
    member do
      post 'add_comment'
      put 'add_visit'
      post 'destroy_event'
      get 'download'
      post 'remove'
      post 'remove_favorite'
      post 'share_email'
      post 'update'
    end
  end

  # Recursos para las rutas
  resources :routes do
    collection do
      post 'import'
    end

    member do
      post 'add_comment'
      put 'add_visit'
      post 'destroy_route'
      get 'download'
      post 'remove'
      post 'remove_favorite'
      post 'share_email'
      post 'update'
    end
  end

  devise_for :users, controllers: {
    passwords: 'users/passwords',
    registrations: 'users/registrations',
    sessions: 'users/sessions'
    }

  # Recursos para los usuarios
  resources :users, :except => [:create, :destroy, :edit, :new, :update] do
    collection do
      get 'all'
      get 'change_password'
      get 'reload_menu'
      get 'remember_password'
      post 'remember_password'
      get 'search'
      get 'search_friends'
      post 'search_friends'
      put 'update_password'
      get 'user'
    end

    member do
      post 'add_answer_to_comments'
      post 'add_comment'
      post 'add_favorite'
      post 'add_follow'
      post 'add_message'
      get 'albums'
      get 'answer_comment'
      get 'close_comment'
      get 'conversation'
      get 'conversations'
      post 'del_follow'
      post 'destroy_user'
      get 'edit_user'
      get 'events'
      get 'favorites'
      get 'follows'
      get 'followers'
      get 'inbox'
      get 'open_comment'
      get 'routes'
      get 'send_comment_by_email'
      get 'tutorial'
      put 'unfriendship'
      post 'update_user'
      get 'wall'
    end
  end

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id))(.:format)', :via => [:get]
end

