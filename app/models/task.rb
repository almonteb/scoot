class Task < ActiveRecord::Base
  serialize :arguments, Array
  
  def perform!(log=RAILS_DEFAULT_LOGGER)
    transaction do
      log.info("Performing Task #{self.id}: #{target_class}(#{target_id.inspect})::#{command}(#{arguments.inspect}..)")
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
    end
  end
  
end
