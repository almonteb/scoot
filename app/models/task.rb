#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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

class Task < ActiveRecord::Base
  serialize :arguments, Array
  after_create :perform!
  
  def perform!(log=RAILS_DEFAULT_LOGGER)
    log.info("Performing Task #{self.id.inspect}: #{target_class}(#{target_id.inspect})::#{command}(#{arguments.inspect}..)")
    target_class.constantize.send(command, *arguments)
    self.performed = true
    self.performed_at = Time.now
    save!
    unless target_id.blank?
      obj = target_class.constantize.find_by_id(target_id)
      if obj && obj.respond_to?(:ready)
        obj.ready = true
        obj.save!
      end
    end
  rescue Exception => e
    log.info e.backtrace
    log.info e.inspect
  end
  
end
