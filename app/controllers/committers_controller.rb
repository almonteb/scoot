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

class CommittersController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :destroy, :list]
  before_filter :find_repository, 
    :only => [:show, :new, :create, :edit, :update, :destroy, :list]
    
  def new
    @committer = User.new
  end
  
  def create
    @committer = User.find_by_login(params[:user][:login])
    unless @committer
      flash[:error] = I18n.t "committers_controller.create_error_not_found"
      respond_to do |format|
        format.html { redirect_to(new_repository_committer_url(@repository)) }
        format.xml  { render :text => I18n.t( "committers_controller.create_error_not_found"), :status => :not_found }
      end
      return
    end

    respond_to do |format|
      if @repository.add_committer(@committer)
        @committership = @repository.committerships.find_by_user_id(@committer.id)
        flash[:notice] = "#{@committer.fullname} (#{@committer.login}) has been added to the commiters list for this repository."
        format.html { redirect_to([@repository.user, @repository]) }
        format.xml do 
          render :xml => @committer
        end
      else
        flash[:error] = I18n.t "committers_controller.create_error_already_commiter"
        format.html { redirect_to(new_repository_committer_url(@repository)) }
        format.xml  { render :text => I18n.t("committers_controller.create_error_already_commiter"), :status => :not_found }
      end
    end
  end
  
  def destroy
    @committership = @repository.committerships.find_by_user_id(params[:id])
    
    respond_to do |format|
      if @committership.destroy
        flash[:success] = I18n.t "committers_controller.destroy_success"
        format.html { redirect_to [@repository.user, @repository] }
        format.xml  { render :nothing, :status => :ok }
      else
        flash[:error] = I18n.t "committers_controller.destroy_error≈"
        format.html { redirect_to [@repository.user, @repository] }
        format.xml  { render :nothing, :status => :unprocessable_entity }
      end    
      
    end
  end
  
  def list
    @committers = @repository.committers
    respond_to do |format|
      format.xml { render :xml => @committers }
    end
  end
  
  def auto_complete_for_user_login
    login = params[:user][:login]
    @users = User.find(:all, 
      :conditions => [ 'LOWER(login) LIKE ?', '%' + login.downcase + '%' ],
      :limit => 10)
    render :layout => false
  end
  
  private
    def find_repository
      @user = current_user
      @repository = current_user.repositories.find_by_name!(params[:repository_id])
    end
end
