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

require File.dirname(__FILE__) + '/../spec_helper'

describe BlobsController do
  before(:each) do
    @project = projects(:johans)
    @repository = @project.repositories.first
    @repository.stubs(:full_repository_path).returns(repo_path)

    Project.stubs(:find_by_slug!).with(@project.slug).returns(@project)
    @project.repositories.expects(:find_by_name!) \
      .with(@repository.name).returns(@repository)
    @repository.stubs(:has_commits?).returns(true)

    @git = stub_everything("Grit mock")
    @repository.stubs(:git).returns(@git)
    @head = mock("master branch")
    @head.stubs(:name).returns("master")
    @repository.stubs(:head_candidate).returns(@head)
  end
  
  describe "#show" do
    it "gets the blob data for the sha provided" do
      blob_mock = mock("blob")
      blob_mock.stubs(:contents).returns([blob_mock]) #meh
      blob_mock.stubs(:data).returns("blob contents")
      commit_stub = mock("commit")
      commit_stub.stubs(:id).returns("a"*40)
      commit_stub.stubs(:tree).returns(commit_stub)
      @git.expects(:commit).returns(commit_stub)
      @git.expects(:tree).returns(blob_mock)
      
      get :show, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "a"*40, :path => []}
      
      response.should be_success
      assigns[:git].should == @git
      assigns[:blob].should == blob_mock
    end 
    
    it "redirects to HEAD if provided sha was not found (backwards compat)" do
      @git.expects(:commit).with("a"*40).returns(nil)
      get :show, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "a"*40, :path => ["foo.rb"]}
      
      response.should redirect_to(project_repository_blob_path(@project, @repository, "HEAD", ["foo.rb"]))
    end   
  end
  
  describe "#raw" do
    it "gets the blob data from the sha and renders it as text/plain" do
      blob_mock = mock("blob")
      blob_mock.stubs(:contents).returns([blob_mock]) #meh
      blob_mock.expects(:data).returns("blabla")
      blob_mock.expects(:size).returns(200.kilobytes)
      blob_mock.expects(:mime_type).returns("text/plain")
      commit_stub = mock("commit")
      commit_stub.stubs(:id).returns("a"*40)
      commit_stub.stubs(:tree).returns(commit_stub)
      @git.expects(:commit).returns(commit_stub)
      @git.expects(:tree).returns(blob_mock)
      
      get :raw, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "a"*40, :path => []}
      
      response.should be_success
      assigns[:git].should == @git
      assigns[:blob].should == blob_mock
      response.body.should == "blabla"
      response.content_type.should == "text/plain"
    end
    
    it "redirects to HEAD if provided sha was not found (backwards compat)" do
      @git.expects(:commit).with("a"*40).returns(nil)
      get :raw, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "a"*40, :path => ["foo.rb"]}
      
      response.should redirect_to(project_repository_raw_blob_path(@project, @repository, "HEAD", ["foo.rb"]))
    end
    
    it "redirects if blob is too big" do
      blob_mock = mock("blob")
      blob_mock.stubs(:contents).returns([blob_mock]) #meh
      blob_mock.expects(:size).returns(501.kilobytes)
      commit_stub = mock("commit")
      commit_stub.stubs(:id).returns("a"*40)
      commit_stub.stubs(:tree).returns(commit_stub)
      @git.expects(:commit).returns(commit_stub)
      @git.expects(:tree).returns(blob_mock)
      
      get :raw, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "a"*40, :path => []}
          
      response.should redirect_to(project_repository_path(@project, @repository))
    end
  end

end
