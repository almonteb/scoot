#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class RepositoriesController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :writable_by]
  before_filter :find_user
  before_filter :require_adminship, :only => [:edit, :update]
  before_filter :require_user_has_ssh_keys, :only => [:clone, :create_clone]
  session :off, :only => [:writable_by]
  skip_before_filter :public_and_logged_in, :only => [:writable_by]
  
  def index
    if @user
      @repositories = @user.repositories.find(:all, :include => [:user, :events, :project])
    else
      @users = Repository.find(:all, :include => [:user, :events, :project]).group_by(&:user)
    end
  end
    
  def show
    @tree = "master"
    @repository = @user.repositories.find_by_name(params[:id])
    @events = @repository.events.paginate(:all, :page => params[:page], 
      :order => "created_at desc")

    respond_to do |format|
      format.html
      format.xml  { render :xml => @repository }
      format.atom {  }
    end
  end
  
  def new
    @repository = current_user.repositories.build
  end
  
  def create
    @repository = current_user.repositories.build(params[:repository])
    if @repository.save
      flash[:notice] = "Your repository has been created."
      redirect_to user_repository_path(current_user, @repository)
    else
      flash[:error] = "Your repository could not be created."
      render :action => "new"
    end
  end
  
  def clone
    @repository_to_clone = @user.repositories.find_by_name!(params[:id])
    unless @repository_to_clone.has_commits?
      flash[:error] = I18n.t "repositories_controller.new_error"
      redirect_to project_repository_path(@user, @repository_to_clone)
      return
    end
    @repository = Repository.new_by_cloning(@repository_to_clone, current_user)
  end
  
  def create_clone
    @repository_to_clone = @user.repositories.find_by_name!(params[:id])
    unless @repository_to_clone.has_commits?
      target_path = project_repository_path(@user, @repository_to_clone)
      respond_to do |format|
        format.html do
          flash[:error] = I18n.t "repositories_controller.create_error"
          redirect_to target_path
        end
        format.xml do 
          render :text => I18n.t("repositories_controller.create_error"), 
            :location => target_path, :status => :unprocessable_entity
        end
      end
      return
    end

    @repository = Repository.new_by_cloning(@repository_to_clone, current_user)
    @repository.name = params[:repository][:name]
    @repository.user = current_user
    
    respond_to do |format|
      if @repository.save
        
        location = user_repository_path(current_user, @repository)
        format.html { redirect_to location }
        format.xml  { render :xml => @repository, :status => :created, :location => location }        
      else
        format.html { render :action => "clone" }
        format.xml  { render :xml => @repository.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # Used internally to check write permissions by gitorious
  def writable_by
    @repository = @user.repositories.find_by_name!(params[:id])
    user = User.find_by_login(params[:username])
    if user && user.can_write_to?(@repository)
      render :text => "true"
    else
      render :text => "false"
    end
  end
  
  def confirm_delete
    @repository = @user.repositories.find_by_name!(params[:id])
  end
  
  def destroy
    @repository = @user.repositories.find_by_name!(params[:id])
    if @repository.can_be_deleted_by?(current_user)
      repo_name = @repository.name
      flash[:notice] = I18n.t "repositories_controller.destroy_notice"
      @repository.destroy
      @user.create_event(Action::DELETE_REPOSITORY, @user, current_user, repo_name)
    else
      flash[:error] = I18n.t "repositories_controller.destroy_error"
    end
    redirect_to user_path(@user)
  end
  
  private    
    def require_adminship
      unless @user.admin?(current_user)
        respond_to do |format|
          flash[:error] = I18n.t "repositories_controller.adminship_error"
          format.html { redirect_to(user_path(@user)) }
          format.xml  { render :text => I18n.t( "repositories_controller.adminship_error"), :status => :forbidden }
        end
        return
      end
    end
end
