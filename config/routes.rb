ActionController::Routing::Routes.draw do |map|

  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  #map.connect ':controller/service.wsdl', :action => 'wsdl'
  VALID_SHA = /[a-zA-Z0-9~\{\}\+\^\.\-_]+/
  map.root :controller => "site", :action => "index"

  map.resource :account, :member => {:password => :get, :update_password => :put} do |account|
    account.resources :keys
  end
  map.connect "users/activate/:activation_code", :controller => "users", :action => "activate"
  map.resources :users, :requirements => {:id => /.+/ }, :collection => {
    :forgot_password => :get,    :reset_password => :post}, :member => { :feed => :get }
  map.resources  :events
  
  map.open_id_complete '/sessions', :controller => "sessions", :action=> "create",:requirements => { :method => :get }
  map.resource  :sessions
  map.with_options(:controller => "projects", :action => "category") do |project_cat|
    project_cat.projects_category "projects/category/:id"
    project_cat.formatted_projects_category "projects/category/:id.:format"
  end
  
  map.resources :repositories
  map.resources :projects, :member => {:confirm_delete => :get} do |projects|
    projects.resources :pages, :member => { :history => :get }
    projects.resources(:repositories, :member => {
      :clone => :get, :create_clone => :post,
      :writable_by => :get, 
      :confirm_delete => :get
    }, :as => "repos") do |repo|
      repo.resources :committers, :name_prefix => nil, :collection => {:auto_complete_for_user_login => :post, :list => :get, :create => :post}
      repo.resources :comments, :member => { :commmit => :get  }
      repo.resources :merge_requests, :member => { :resolve => :put }, :collection => { :create => :post }
      repo.commit_comment "comments/commit/:sha", :controller => "comments", 
        :action => "commit", :conditions => { :method => :get }
      
      repo.resources :logs, :requirements => { :id => VALID_SHA }#, :member => { :feed => :get }
      repo.formatted_log_feed "logs/:id/feed.:format", :controller => "logs", :action => "feed", 
        :conditions => {:feed => :get}, :requirements => {:id => VALID_SHA}
      repo.resources :commits, :requirements => {:id => VALID_SHA }
      repo.trees          "trees/", :controller => "trees", :action => "index"
      repo.with_options(:requirements => { :id => VALID_SHA }) do |r|
        r.tree           "trees/:id/*path", :controller => "trees", :action => "show"
        r.formatted_tree "trees/:id/*path.:format", :controller => "trees", :action => "show"
        r.archive_tree   "archive/:id.tar.gz", :controller => "trees", :action => "archive"
        r.raw_blob       "blobs/raw/:id/*path", :controller => "blobs", :action => "raw"
        r.blob           "blobs/:id/*path", :controller => "blobs", :action => "show"
      end
    end
  end
  
  map.resource :search
  
  map.with_options :controller => 'sessions' do |session|
    session.login    '/login',  :action => 'new'
    session.logout   '/logout', :action => 'destroy'
  end

  map.dashboard "dashboard", :controller => "site", :action => "dashboard"  
  map.about "about", :controller => "site", :action => "about"
  map.faq "about/faq", :controller => "site", :action => "faq"
  
  map.user ':id', :controller => "users", :action => "show"
  
  # As ugly as... all for the sake of prettiness
  map.user_repository ':user_id/:id', :controller => "repositories", :action => "show"
  
  map.user_repository_logs ':user_id/:repository_id/logs', :controller => "logs", :action => "index"
  map.user_repository_log  ':user_id/:repository_id/logs/:id', :controller => "logs", :action => "show"
  map.user_repository_trees ':user_id/:repository_id/trees', :controller => "trees", :action => "index"
  map.user_repository_tree ':user_id/:repository_id/trees/:id/*path', :controller => "trees", :action => "show"
  map.user_repository_tree_logs ':user_id/:repository_id/tree/:id/logs', :controller => "logs", :action => "index"
  
  map.user_repository_comments ':user_id/:repository_id/comments', :controller => "comments", :action => "index"
  
  map.user_repository_raw_blob ':user_id/:repository_id/blobs/:id/raw/*path', :controller => "blobs", :action => "raw"
  map.user_repository_blob ':user_id/:repository_id/blobs/:id/*path', :controller => "blobs", :action => "show"
  
  map.user_repository_commit ':user_id/:repository_id/commits/:id', :controller => "commits", :action => "show"
  map.user_repository_commit_comments ':user_id/:repository_id/commits/:commit_id/comments', :controller => "comments", :action => "index"
  map.user_repository_merge_requests ':user_id/:repository_id/merge_requests', :controller => "merge_requests", :action => "index"
  
  map.clone_user_repository ':user_id/:id/clone', :controller => "repositories", :action => "clone"
  map.create_clone_user_repository ':user_id/:id/create_clone', :controller => "repositories", :action => "create_clone"
  
  map.user_repository_path ':user_id/:repository_id', :controller => "repositories", :action => "show"
  map.connect ':user_id/:id/writable_by', :controller => "repositories", :action => "writable_by"
  map.namespace :admin do |admin|
    admin.resources :users, :member => { :suspend => :put, :unsuspend => :put, :reset_password => :put }
  end

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
