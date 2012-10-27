# Minimal sample configuration file for Unicorn (not Rack) when used
# with daemonization (unicorn -D) started in your working directory.
#
# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.
# See also http://unicorn.bogomips.org/examples/unicorn.conf.rb for
# a more verbose configuration using more features.

listen 2002 # by default Unicorn listens on port 8080
worker_processes 4 # this should be >= nr_cpus
pid File.expand_path('../../var/run/unicorn', __FILE__)
after_fork do |server, worker|
  p Process.pid
end
