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

describe LogsController do

  before(:each) do
    @project = projects(:johans)
    @repository = @project.repositories.first
    @repository.stubs(:full_repository_path).returns(repo_path)

    Project.expects(:find_by_slug!).with(@project.slug) \
      .returns(@project)
    @project.repositories.expects(:find_by_name!) \
      .with(@repository.name).returns(@repository)
    @repository.stubs(:has_commits?).returns(true)

    @git = stub_everything("Grit mock")
    @repository.stubs(:git).returns(@git)
    @head = mock("master branch")
    @head.stubs(:name).returns("master")
    @repository.stubs(:head_candidate).returns(@head)
  end
  
  describe "#index" do
    it "redirects to the master head, if not :id given" do
      head = mock("a branch")
      head.stubs(:name).returns("somebranch")
      @repository.expects(:head_candidate).returns(head)

      get :index, :project_id => @project.slug, :repository_id => @repository.name
      response.should redirect_to(project_repository_log_path(@project, @repository, "somebranch"))
    end
  end

  describe "#show" do
    def do_get(opts = {})
      get :show, {:project_id => @project.slug, 
        :repository_id => @repository.name, :page => nil, :id => "master"}.merge(opts)
    end

    it "GETs page 1 successfully" do
      @git.expects(:commits).with("master", 30, 0).returns([mock("commits")])
      do_get
    end

    it "GETs page 3 successfully" do
      @git.expects(:commits).with("master", 30, 60).returns([mock("commits")])
      do_get(:page => 3)
    end

    it "GETs the commits successfully" do
      commits = [mock("commits")]
      @git.expects(:commits).with("master", 30, 0).returns(commits)
      do_get
      response.should be_success
      assigns[:git].should == @git
      assigns[:commits].should == commits
    end
    
    
    describe "atom feed" do
      integrate_views
      
      it "has a proper id in the atom feed" do
        #(repo, id, parents, tree, author, authored_date, committer, committed_date, message)
        commit = Grit::Commit.new(mock("repo"), "mycommitid", [], stub_everything("tree"), 
                      stub_everything("author"), Time.now, 
                      stub_everything("comitter"), Time.now, 
                      "my commit message".split(" "))
        @git.expects(:commits).returns([commit])
        commit.stubs(:stats).returns(stub_everything("stats", :files => []))
        
        get :feed, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "master", :format => "atom"}
        response.body.should include(%Q{<id>tag:test.host,2005:Grit::Commit/mycommitid</id>})
      end
    end
  end

end
