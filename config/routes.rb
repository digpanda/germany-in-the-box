Rails.application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => 'users/omniauth_callbacks',registrations: "registrations" }


  resources :notifications
  resources :posts
  resources :brands
  resources :messages
  resources :chats
  resources :collections
  resources :products, except: [:index]

  resources :users, except: [:destroy]

  # user

  get '/',to: 'pages#home', as: 'home'
  
  get 'popular_products',to: 'products#indexr', as: 'popular_products'
  
  get 'profile/:id', to: 'users#pshow', as: "profile"
  post '/getuser', to: 'users#getuserbyemail'
  post '/follow/:id/:target_id', to: 'users#follow'
  post '/unfollow/:id/:target_id', to: 'users#unfollow'
  post '/savecol/:id/:col_id', to: 'users#savecol', as: 'savecoll'
  post '/likecol/:id/:col_id', to: 'users#likecol'
  post '/unsavecol/:id/:col_id', to: 'users#unsavecol', as: 'unsavecoll'
  post '/dislikecol/:id/:col_id', to: 'users#dislikecol'
  post '/saveprod/:id/:prod_id', to: 'users#saveprod', as: 'saveprod'
  post '/likeprod/:id/:prod_id', to: 'users#likeprod'
  post '/unsaveprod/:id/:prod_id', to: 'users#unsaveprod', as: 'unsaveprod'
  post '/dislikeprod/:id/:prod_id', to: 'users#dislikeprod'
  post '/joinprivatechat/:id/:chat_id', to: 'users#joinprivatechat'
  post '/joinpublicchat/:id/:chat_id', to: 'users#joinpublicchat'
  post '/leaveprivatechat/:id/:chat_id', to: 'users#leaveprivatechat'
  post '/leavepublicchat/:id/:chat_id', to: 'users#leavepublicchat'
  post '/addprodtocol/:col_id/:prod_id', to: 'users#addprodtocol'
  post '/removeprodtocol/:col_id/:prod_id', to: 'users#removeprodtocol'
  post '/getuserbyid/:parse_id', to: 'users#getuserbyid'

  get '/getfollowers/:id', to: 'users#getfollowers'

  get '/getfollowings/:id', to: 'users#getfollowings'

  get 'userssearch/:keyword/:folds' => 'users#userssearch'

  get 'search/:keyword/:folds' => 'products#search'

  get 'user/openmailnoti' => 'users#openmailnoti'


  # collection
  post '/newcol/:owner_id' => 'collections#create'
  get 'collectionsi/:from/:to' => 'collections#indexft'
  get '/userinit/:user_id' => 'collections#userinit'
  get 'similarcoli/:id/:num' => 'collections#similarcoli'
  get 'collection/:id' => 'collections#getinfo'
  get 'matchedcollections/:id/:num' => 'collections#matchedcollections'
  get 'mycolls/:owner_id' => 'collections#mycolls'
  get 'savedcolls/:owner_id' => 'collections#savedcolls'
  get 'likedcolls/:owner_id' => 'collections#likedcolls'
  get 'colsearch/:keyword/:folds' => 'collections#colsearch'

  get 'gsearch/' => 'collections#gsearch', as: "gsearch"


  # proudcts
  post '/newprod/:owner_id' => 'products#create'
  get 'productsi/:num' => 'products#indexr', as: 'productsi'
  get 'productsi/:from/:to' => 'products#indexft'
  get 'similarproductsi/:id/:num' => 'products#similarproductsi'
  get 'prodsearch/:keyword/:folds' => 'products#prodsearch'
  get 'searchp/:searchtext' => 'products#search'
  get 'showindex/:col_id' => 'products#showindex', as: 'colprods'
  get 'savedprods/:owner_id' => 'products#savedprods'
  get 'searchprodcat/:keyword/:folds' => "products#prodsearchcat"
  get 'searchprodbrand/:keyword/:folds' => "products#prodsearchbrand"
  get 'getpostedprods/:owner_id' => "products#getpostedprods"


  #brands
  get '/getversion' => 'brands#getversion'

  #chats
  post 'message/:chat_id' => 'messages#create'
  get 'chatmessages/:chat_id' => 'messages#index'
  get 'chatsearch/:keyword/:folds' => 'chats#chatsearch'
  get 'usernotifications/:user_id' => 'notifications#index'

  #messages
  get 'messagesi/:chat_id/:id' => 'messages#messages'

  #chats
  get 'privatechats' => 'chats#privatechats'
  get 'publicchats' => 'chats#publicchats'

end
