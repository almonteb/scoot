#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
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

class LogsController < ApplicationController
  before_filter :find_user_and_repository
  before_filter :check_repository_for_commits
    
  def index
    show
    render :action => "show"
  end
  
  def show
    @git = @repository.git
    @branch = params[:tree_id] || "master"
    @commits = @repository.paginated_commits(@branch, params[:page])
  end
  
  def feed
    @git = @repository.git
    @commits = @repository.git.commits(params[:id])
    respond_to do |format|
      format.html { redirect_to(project_repository_log_path(@project, @repository, params[:id]))}
      format.atom
    end
  end
  
end
