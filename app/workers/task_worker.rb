class TaskWorker < Workling::Base
  
  def do_it(task)
    puts "DOING IT!!!!!!!!!!!!!!!!!"
    log = Logger.new("tasks.log")
    log.info("Performing #{task.inspect}")
    task.peform!(log)
    log.info("Performed #{task.inspect}")
    puts "DID IT!!"
  end
end