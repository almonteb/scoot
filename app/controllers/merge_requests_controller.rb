#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
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

class MergeRequestsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  before_filter :find_repository
  before_filter :find_merge_request, :except => [:index, :show, :new, :create]
  before_filter :assert_merge_request_ownership, :except => [:index, :show, :new, :create, :resolve]
  before_filter :assert_merge_request_resolvable, :only => [:resolve]
  
  def index
    @merge_requests = @repository.merge_requests
    @comment_count = @repository.comments.count
    #@proposed_merge_requests = @repository.proposed_merge_requests
  end
  
  def show
    @merge_request = @repository.merge_requests.find(params[:id])
    @commits = @merge_request.target_repository.git.commit_deltas_from(
      @merge_request.source_repository.git, 
      @merge_request.target_branch,
      @merge_request.source_branch
    )
  end
  
  def new
    @merge_request = @repository.proposed_merge_requests.new(:user => current_user)
    @repositories = [@repository.parent]
  end
  
  def create
    @merge_request = @repository.proposed_merge_requests.new(params[:merge_request])
    @merge_request.user = current_user
    respond_to do |format|
      if @merge_request.save
        @repository.create_event(Action::REQUEST_MERGE, @merge_request, current_user)
        format.html {
          flash[:success] = I18n.t "merge_requests_controller.create_success", :name => @merge_request.target_repository.name
          redirect_to user_repository_path(@user, @repository) and return
        }
        format.xml { render :xml => @merge_request, :status => :created }
      else
        format.html {
          @repositories = [@repository.parent]
          render :action => "new"
        }
        format.xml { render :xml => @merge_request.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def resolve
    # TODO: put to change status
    @merge_request.status = params[:merge_request][:status]
    if @merge_request.save
      @project.create_event(Action::RESOLVE_MERGE_REQUEST, @merge_request, current_user)
      flash[:notice] = I18n.t "merge_requests_controller.resolve_notice", :status => @merge_request.status_string
    end
    redirect_to [@project, @repository, @merge_request]      
  end
  
  def edit
    @repositories = @project.repositories.find(:all, :conditions => ["id != ?", @repository.id])
  end
  
  def update
    @merge_request.attributes = params[:merge_request]
    if @merge_request.save
      flash[:success] = I18n.t "merge_requests_controller.update_success"
      redirect_to [@project, @repository, @merge_request]
    else
      @repositories = @project.repositories.find(:all, :conditions => ["id != ?", @repository.id])
      render :action => "edit"
    end
  end
  
  def destroy
    @merge_request.destroy
    flash[:success] = I18n.t "merge_requests_controller.destroy_success"
    redirect_to project_repository_path(@project, @repository)
  end
  
  protected
    def find_repository
      @user = User.find_by_permalink(params[:user_id])
      @repository = @user.repositories.find_by_name!(params[:repository_id])
    end
    
    def find_merge_request
      @merge_request = @repository.merge_requests.find(params[:id])
    end
    
    def assert_merge_request_resolvable
      unless @merge_request.resolvable_by?(current_user)
        respond_to do |format|
          flash[:error] = I18n.t "merge_requests_controller.assert_resolvable_error"
          format.html { redirect_to([@project, @repository, @merge_request]) }
          format.xml  { render :text => I18n.t( "merge_requests_controller.assert_resolvable_error"), :status => :forbidden }
        end
        return
      end
    end
    
    def assert_merge_request_ownership
      if @merge_request.user != current_user
        respond_to do |format|
          flash[:error] = I18n.t "merge_requests_controller.assert_ownership_error"
          format.html { redirect_to([@project, @repository]) }
          format.xml  { render :text => I18n.t("merge_requests_controller.assert_ownership_error"), :status => :forbidden }
        end
        return
      end
    end
  
end
