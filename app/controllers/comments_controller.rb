#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
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

class CommentsController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy]
  before_filter :find_user_and_repository
  before_filter :find_object
  
  def index
    @comments = @repository.comments.find(:all, :include => :user)
    @merge_request_count = @repository.merge_requests.count_open
    @atom_auto_discovery_url = formatted_project_repository_comments_path(@project, @repository, :atom)
    respond_to do |format|
      format.html { }
      format.atom { }
    end
  end
  
  def commit
    @git = @repository.git
    @commit = @git.commit(params[:sha])
    @comments = @repository.comments.find_all_by_sha1(params[:sha], :include => :user)
  end
  
  def new
    @comment = @repository.comments.new
  end
  
  def create
    @comment = @repository.comments.new(params[:comment])
    @comment.user = current_user
    @comment.project = @project
    respond_to do |format|
      if @comment.save
        @project.create_event(Action::COMMENT, @comment, current_user)
        format.html do
          flash[:success] = I18n.t "comments_controller.create_success"
          redirect_to project_repository_comments_path(@project, @repository)
        end
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  private
  
  def find_object
    puts params.inspect
    @object = @repository.git.commits(params[:commit_id]).first if params[:commit_id]
  end
end
