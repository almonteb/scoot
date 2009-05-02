class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :repository
  belongs_to :project
  has_many   :events, :as => :target, :dependent => :destroy
  
  define_index do
    indexes body
    indexes user.login, :as => "user"
  end
  
  attr_protected :user_id
    
  validates_presence_of :user_id, :repository_id, :body, :project_id
  
  
end
