#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 August Lilleaas <augustlilleaas@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  include UsersHelper
  
  def feed_icon(url, alt_title = "Atom feed", size = :small)
    link_to image_tag("feed_12.png", :class => "feed_icon"), url, 
      :alt => alt_title, :title => alt_title
  end
  
  def default_css_tag_sizes
    %w(tag_size_1 tag_size_2 tag_size_3 tag_size_4)
  end
  
  def linked_tag_list_as_sentence(tags)
    tags.map do |tag|
      link_to(h(tag.name), search_path(:q => "category:#{h(tag.name)}"))
    end.to_sentence
  end
  
  def build_notice_for(object)
    out =  %Q{<div class="being_constructed">}
    out << %Q{  <p>#{I18n.t( "application_helper.notice_for").call(object.class.name.humanize.downcase)}</p>}
    out << %Q{</div>}
    out
  end
  
  def render_if_ready(object)
    if object.respond_to?(:ready?) && object.ready?
      yield
    else
      concat(build_notice_for(object))
    end
  end  
  
  def selected_if_current_page(url_options, slack = false)
    if slack
      if controller.request.request_uri.index(CGI.escapeHTML(url_for(url_options))) == 0
        "selected"
      end
    else
      "selected" if current_page?(url_options)
    end
  end
  
  def submenu_selected_class_if_current?(section)
    case section
    when :overview
     if %w[repositorys].include?(controller.controller_name )
       return "selected"
     end
    when :repositories
      if %w[repositories trees logs commits comitters comments merge_requests 
            blobs committers].include?(controller.controller_name )
        return "selected"
      end
    when :pages
      if %w[pages].include?(controller.controller_name )
        return "selected"
      end
    end
  end
  
  def link_to_with_selected(name, options = {}, html_options = nil)
    html_options = current_page?(options) ? {:class => "selected"} : nil
    link_to(name, options = {}, html_options)
  end
  
  def syntax_themes_css
    out = []
    if @load_syntax_themes
      # %w[ active4d all_hallows_eve amy blackboard brilliance_black brilliance_dull 
      #     cobalt dawn eiffel espresso_libre idle iplastic lazy mac_classic 
      #     magicwb_amiga pastels_on_dark slush_poppies spacecadet sunburst 
      #     twilight zenburnesque 
      # ].each do |syntax|
      #   out << stylesheet_link_tag("syntax_themes/#{syntax}")
      # end
      return stylesheet_link_tag("syntax_themes/idle")
    end
    out.join("\n")
  end
  
  def base_url(full_url)
    URI.parse(full_url).host
  end
  
  def gravatar_url_for(email, options = {})
    "http://www.gravatar.com/avatar.php?gravatar_id=" << 
    (email.nil? ? "" : Digest::MD5.hexdigest(email)) <<
    "&amp;default=" <<
    u("http://#{request.host}:#{request.port}/images/default_face.gif") <<
    options.map { |k,v| "&amp;#{k}=#{v}" }.join
  end
  
  def gravatar(email, options = {})
    size = options[:size]
    image_options = { :alt => "avatar" }
    if size
      image_options.merge!(:width => size, :height => size)
    end
    image_tag(gravatar_url_for(email, options), image_options)
  end
  
  def gravatar_frame(email, options = {})
    extra_css_class = options[:style] ? " gravatar_#{options[:style]}" : ""
    %{<div class="gravatar#{extra_css_class}">#{gravatar(email, options)}</div>}
  end
  
  def flashes
    flash.map { |type, content| content_tag(:div, content_tag(:p, content), :class => "flash_message #{type}")}
  end
  
  def commit_graph_tag(repository, ref = "master")
    filename = Gitorious::Graphs::CommitsBuilder.filename(repository, ref)
    if File.exist?(File.join(Gitorious::Graphs::Builder.graph_dir, filename))
      image_tag("graphs/#{filename}")
    end
  end
  
  def commit_graph_by_author_tag(repository, ref = "master")    
    filename = Gitorious::Graphs::CommitsByAuthorBuilder.filename(repository, ref)
    if File.exist?(File.join(Gitorious::Graphs::Builder.graph_dir, filename))
      image_tag("graphs/#{filename}")
    end
  end
  
  def action_and_body_for_event(event)
    target = event.target
    action = ""
    body = ""
    category = ""

    if target.nil?
      return [action, body, category]
    end

    # FIXME: I'm screaming for some refactoring!
    case event.action
      when Action::CREATE_REPOSITORY
        action = "<strong>Repository created</strong> #{link_to h(target.title), repository_path(event.repository)}"
        body = truncate(target.stripped_description, :length => 100)
        category = "repository"
      when Action::DELETE_REPOSITORY
        action = "<strong>#{I18n.t("application_helper.event_status_deleted")}</strong> #{h(event.data)}"
        category = ""
      when Action::UPDATE_REPOSITORY
        action = "<strong>#{I18n.t("application_helper.event_status_updated")}</strong> #{link_to h(target.title), repository_path(target)}"
        category = "repository"
      when Action::CLONE_REPOSITORY
        original_repo = Repository.find_by_id(event.data.to_i)
        next if original_repo.nil?
        
        repository = target.repository
        
        action = "<strong>#{I18n.t("application_helper.event_status_cloned")}</strong> #{link_to h(repository.slug), repository_path(repository)}/#{link_to h(original_repo.name), repository_repository_url(repository, original_repo)} in #{link_to h(target.name), repository_repository_url(repository, target)}"
        category = "repository"
      when Action::DELETE_REPOSITORY
        action = "<strong>#{I18n.t("application_helper.event_status_deleted")}</strong> #{link_to h(target.title), repository_path(target)}/#{event.data}"
        category = "repository"
      when Action::COMMIT
        repository = event.repository
        case target.kind
        when Repository::KIND_repository_REPO
          action = "<strong>#{I18n.t("application_helper.event_status_pushed")}</strong> #{link_to event.data[0,8], repository_repository_commit_path(repository, target, event.data)} to #{link_to h(repository.slug), repository_path(repository)}/#{link_to h(target.name), repository_repository_url(repository, target)}"
          body = link_to(h(truncate(event.body, :length => 150)), repository_repository_commit_path(repository, target, event.data))
          category = "commit"
        when Repository::KIND_WIKI
          action = "<strong>#{I18n.t("application_helper.event_status_push_wiki")}</strong> to #{link_to h(repository.slug), repository_path(repository)}/#{link_to h(t("views.layout.pages")), repository_pages_url(repository)}"
          body = h(truncate(event.body, :length => 150))
          category = "wiki"
        end
      when Action::CREATE_BRANCH
        repository = target.repository
        if event.data == "master"
          action = "<strong>#{I18n.t("application_helper.event_status_started")}</strong> of #{link_to h(repository.slug), repository_path(repository)}/#{link_to h(target.name), repository_repository_url(repository, target)}"
          body = event.body
        else
          action = "<strong>#{I18n.t("application_helper.event_branch_created")}</strong> #{link_to h(event.data), repository_repository_tree_path(repository, target, event.data)} on #{link_to h(repository.slug), repository_path(repository)}/#{link_to h(target.name), repository_repository_url(repository, target)}"
        end
        category = "commit"
      when Action::DELETE_BRANCH
        repository = target
        action = "<strong>#{I18n.t("application_helper.event_branch_deleted")}</strong> #{event.data} on #{link_to h(repository.slug), repository_path(repository)}/#{link_to h(target.name), repository_repository_url(repository, target)}"
        category = "commit"
      when Action::CREATE_TAG
        repository = target
        action = "<strong>#{I18n.t("application_helper.event_tagged")}</strong> #{link_to h(repository.slug), repository_path(repository)}/#{link_to h(target.name), repository_repository_url(repository, target)}"
        body = "#{link_to event.data, repository_repository_commit_path(repository, target, event.data)}<br/>#{event.body}"
        category = "commit"
      when Action::DELETE_TAG
        repository = target
        action = "<strong>#{I18n.t("application_helper.event_tag_deleted")}</strong> #{event.data} on #{link_to h(repository.slug), repository_path(repository)}/#{link_to h(target.name), repository_repository_url(repository, target)}"
        category = "commit"
      when Action::ADD_COMMITTER
        user = target.user
        repo = target
        action = "<strong>#{I18n.t("application_helper.event_committer_added")}</strong> #{link_to user.login, user_path(user)} to #{link_to h(repo.repository.slug), repository_path(repo.repository)}/#{link_to h(repo.name), repository_repository_url(repo.repository, repo)}"
        category = "repository"
      when Action::REMOVE_COMMITTER
        user = User.find_by_id(event.data.to_i)
        next unless user
        
        repository = target.repository
        action = "<strong>#{I18n.t("application_helper.event_committer_removed")}</strong> #{link_to user.login, user_path(user)} from #{link_to h(repository.slug), repository_path(repository)}/#{link_to h(target.name), repository_repository_url(repository, target)}"
        category = "repository"
      when Action::COMMENT
        repository = target.repository
        repo = target.repository
        
        action = "<strong>#{I18n.t("application_helper.event_commented")}</strong> on #{link_to h(repository.slug), repository_path(repository)}/#{link_to h(repo.name), repository_repository_url(repository, repo)}"
        body = truncate(h(target.body), :length => 150)
        category = "comment"
      when Action::REQUEST_MERGE
        body = "Hey"

        source_repository = target.source_repository
        target_repository = target.target_repository
        
        action = "<strong>requested a merge</strong> between <strong>" +
        link_to("#{source_repository.user}/#{source_repository.name}", user_repository_path(source_repository.user, source_repository)) +
        "</strong> and <strong>" +
        link_to("#{target_repository.user}/#{target_repository.name}", user_repository_path(target_repository.user, target_repository)) +
        "</strong>"
        body = "#{link_to truncate(h(target.proposal), :length => 100), [target_repository.user, target_repository, target]}"
        category = "merge_request"
      when Action::RESOLVE_MERGE_REQUEST
        source_repository = target.source_repository
        repository = source_repository.repository
        target_repository = target.target_repository
        
        action = "<strong>#{I18n.t("application_helper.event_resolved_merge_request")}</strong> as [#{target.status_string}] from #{link_to h(repository.slug), repository_path(repository)}/#{link_to h(source_repository.name), repository_repository_url(repository, source_repository)}"
        body = "#{link_to truncate(h(target.proposal), :length => 100), [repository, target_repository, target]}"
        category = "merge_request"
      when Action::UPDATE_MERGE_REQUEST
        source_repository = target.source_repository
        repository = source_repository.repository
        target_repository = target.target_repository
        
        action = "<strong>#{I18n.t("application_helper.event_updated_merge_request")}</strong> from #{link_to h(repository.title), repository_path(repository)}/#{link_to h(source_repository.name), repository_repository_url(repository, source_repository)}"
        category = "merge_request"
      when Action::DELETE_MERGE_REQUEST
        repository = target.repository
        
        action = "<strong>#{I18n.t("application_helper.event_deleted_merge_request")}</strong> from #{link_to h(repository.slug), repository_path(repository)}/#{link_to h(target.name), repository_repository_url(repository, target)}"
        category = "merge_request"
      # when Action::UPDATE_WIKI_PAGE
      #         repository = event.target
      #         action = "<strong>#{I18n.t("application_helper.event_updated_wiki_page")}</strong> #{link_to h(repository.slug), repository_path(repository)}/#{link_to(h(event.data), repository_page_path(repository, event.data))}"
      #         category = "wiki"
    end
      
    [action, body, category]
  end
  
  def sidebar_content?
    !@content_for_sidebar.blank?
  end
  
  def markdown(text)
    textilize(text)
  end
  
  def render_readme(repository)
    possibilities = []
    repository.git.git.ls_tree({:name_only => true}, "master").each do |line|
      possibilities << line[0, line.length-1] if line =~ /README.*/
    end
    
    return "" if possibilities.empty?
    text = repository.git.git.show({}, "master:#{possibilities.first}")
    markdown(text) rescue simple_format(sanitize(text))
  end
  
  def file_path(repository, filename, head = "master")
    user_repository_blob_path(repository.user, repository, head, filename)
  end
  
  def commit_for_tree_path(repository, path)
    repository.git.log(params[:id], path, {:max_count => 1}).first
  end
end
