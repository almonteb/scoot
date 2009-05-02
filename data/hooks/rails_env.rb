current_dir = File.expand_path(File.dirname(__FILE__))
$stderr.puts $LOAD_PATH.inspect
print "=> Syncing Gitorious... "
$stdout.flush
ENV["RAILS_ENV"] ||= "production"
require '/Users/git/gitorious/config/environment'