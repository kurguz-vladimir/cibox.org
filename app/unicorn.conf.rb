require File.expand_path('../boot', __FILE__)

# Minimal sample configuration file for Unicorn (not Rack) when used
# with daemonization (unicorn -D) started in your working directory.
#
# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.
# See also http://unicorn.bogomips.org/examples/unicorn.conf.rb for
# a more verbose configuration using more features.

listen Cfg.port
worker_processes 5

pids_path = Cfg.pids_path + 'unicorn/'
FileUtils.rm_rf pids_path
FileUtils.mkdir_p pids_path

# pid for master process
pid pids_path + 'master'

# workers pids
after_fork do |server, worker|
  File.open( '%s/worker-%s.pid' % [pids_path, worker.nr], 'w') { |f| f << Process.pid; f.rewind }
end
logger Logger.new(Cfg.var_path / 'log/unicorn')
