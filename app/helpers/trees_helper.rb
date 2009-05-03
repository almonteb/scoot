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

module TreesHelper
  include RepositoriesHelper
  
  def current_path
    (params[:path] || "").dup
  end
  
  def build_tree_path(path)
    current_path << path
  end
  
  def breadcrumb_path(root_name = "root", commit_id = params[:id])
    out = %Q{<ul class="path_breadcrumbs">\n}
    visited_path = []
    out <<  %Q{  <li>/ #{link_to(root_name, tree_path(commit_id, []))}</li>\n}
    current_path.each_with_index do |path, index|
      visited_path << path
      if visited_path == current_path
        out << %Q{  <li>/ #{path}</li>\n}
      else
        out << %Q{  <li>/ #{link_to(path, tree_path(commit_id, visited_path))}</li>\n}
      end
    end
    out << "</ul>"
    out
  end
    
  def render_tag_box_if_match(sha, tags_per_sha)
    tags = tags_per_sha[sha]
    return if tags.blank?
    out = ""
    tags.each do |tagname|
      out << %Q{<span class="tag"><code>}
      out << tagname
      out << %Q{</code></span>}
    end
    out
  end

end
