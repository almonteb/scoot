current_dir = File.expand_path(File.dirname(__FILE__))
# print "=> Syncing Gitorious... "
$stdout.flush
ENV["RAILS_ENV"] ||= "production"
require '/Users/git/gitorious/config/environment'