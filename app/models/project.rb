#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
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

class Project < ActiveRecord::Base
  acts_as_taggable

  belongs_to  :user
  has_many    :comments, :dependent => :destroy
  has_many    :repositories, :order => "repositories.mainline desc, repositories.created_at asc",
      :conditions => ["kind = ?", Repository::KIND_PROJECT_REPO], :dependent => :destroy
  has_one     :mainline_repository, 
    :conditions => ["mainline = ? and kind = ?", true, Repository::KIND_PROJECT_REPO],
    :class_name => "Repository"
  has_many    :repository_clones, 
    :conditions => ["mainline = ? and kind = ?", false, Repository::KIND_PROJECT_REPO],
    :class_name => "Repository"
  has_many    :events, :order => "created_at asc", :dependent => :destroy
  has_one     :wiki_repository, :class_name => "Repository", 
    :conditions => ["kind = ?", Repository::KIND_WIKI]

  URL_FORMAT_RE = /^(http|https|nntp):\/\//.freeze
  validates_presence_of :title, :user_id, :slug, :description
  validates_uniqueness_of :slug, :case_sensitive => false, :scope => :user_id
  validates_format_of :slug, :with => /^[a-z0-9_\-]+$/i,
    :message => I18n.t( "project.format_slug_validation")
  validates_format_of :home_url, :with => URL_FORMAT_RE,
    :if => proc{|record| !record.home_url.blank? },
    :message => I18n.t( "project.ssl_required")
  validates_format_of :mailinglist_url, :with => URL_FORMAT_RE,
    :if => proc{|record| !record.mailinglist_url.blank? },
    :message => I18n.t( "project.ssl_required")
  validates_format_of :bugtracker_url, :with => URL_FORMAT_RE,
    :if => proc{|record| !record.bugtracker_url.blank? },
    :message => I18n.t( "project.ssl_required")

  before_validation :downcase_slug
  after_create :create_mainline_repository
  after_create :create_wiki_repository

  LICENSES = [
    'Academic Free License v3.0',
    'MIT License',
    'BSD License',
    'Ruby License',
    'GNU General Public License version 2(GPLv2)',
    'GNU General Public License version 3 (GPLv3)',
    'GNU Lesser General Public License (LGPL)',
    'GNU Affero General Public License (AGPLv3)',
    'Mozilla Public License 1.0 (MPL)',
    'Mozilla Public License 1.1 (MPL 1.1)',
    'Qt Public License (QPL)',
    'Python License',
    'zlib/libpng License',
    'Apache Software License',
    'Apple Public Source License',
    'Perl Artistic License',
    'Microsoft Permissive License (Ms-PL)',
    'ISC License',
    'Lisp Lesser License',
    'Public Domain',
    'Other Open Source Initiative Approved License',
    'Other/Proprietary License',
    'None',
  ]
  
  def self.new_by_cloning(other, user)
    suggested_name = other.name
    project = user.projects.build(other.project.attributes)
    project.repositories.build(:parent => other, :name => suggested_name, :mainline => true)
    project
  end

  def self.find_by_slug!(slug, opts = {})
    find_by_slug(slug, opts) || raise(ActiveRecord::RecordNotFound)
  end

  def self.per_page() 20 end

  def self.top_tags(limit = 10)
    tag_counts(:limit => limit, :order => "count desc")
  end

  def to_param
    slug
  end

  def admin?(candidate)
    candidate == user
  end

  def can_be_deleted_by?(candidate)
    (candidate == user) && (repositories.size == 1)
  end

  def tag_list=(tag_list)
    tag_list.gsub!(",", "")

    super
  end

  def home_url=(url)
    self[:home_url] = clean_url(url)
  end

  def mailinglist_url=(url)
    self[:mailinglist_url] = clean_url(url)
  end

  def bugtracker_url=(url)
    self[:bugtracker_url] = clean_url(url)
  end

  def stripped_description
    description.gsub(/<\/?[^>]*>/, "")
    # sanitizer = HTML::WhiteListSanitizer.new
    # sanitizer.sanitize(description, :tags => %w(str), :attributes => %w(class))
  end

  def to_xml(opts = {})
    info = Proc.new { |options|
      builder = options[:builder]
      builder.owner user.login

      builder.repositories :type => "array" do
        repositories.each { |repo|
          builder.repository do
            builder.id repo.id
            builder.name repo.name
            builder.owner repo.user.login
          end
        }
      end
    }
    super({:procs => [info]}.merge(opts))
  end
  
  def create_event(action_id, target, user, data = nil, body = nil, date = Time.now.utc)
    events.create(:action => action_id, :target => target, :user => user,
                  :body => body, :data => data, :created_at => date)
  end

  protected
    def create_mainline_repository
      self.repositories.create!(:user => self.user, :name => title)
    end
    
    def create_wiki_repository
      self.wiki_repository = Repository.create!({
        :user => self.user, 
        :name => self.slug + Repository::WIKI_NAME_SUFFIX,
        :kind => Repository::KIND_WIKI,
        :project => self,
      })
    end

    def downcase_slug
      slug.downcase! if slug
    end

    # Try our best to guess the url
    def clean_url(url)
      return if url.blank?
      begin
        url = "http://#{url}" if URI.parse(url).class == URI::Generic
      rescue
      end
      url
    end
end
