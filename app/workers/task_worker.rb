# This, ideally, replaces script/task_performer which has to be ran using Cron... which is dodgy.
# Asynch processing ftw

class TaskWorker < Workling::Base
  def perform(task)
    log = Logger.new(File.join(RAILS_ROOT, "log", "tasks.log"))
    log.formatter = Logger::Formatter.new
    log.level = Logger::INFO
    log.formatter.datetime_format = "%d/%m/%Y %H:%M:%S"
    task.perform!(log)
  end
end