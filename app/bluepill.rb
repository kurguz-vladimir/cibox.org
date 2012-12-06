require File.expand_path('../boot', __FILE__)

Bluepill.application Cfg.hostname do |app|
  app.working_dir = Cfg.app_path
  Cfg.port.each do |port|
    app.process "#{Cfg.hostname}:#{port}" do |process|
      process.start_command = "ruby #{Cfg.app_path}/run.rb #{Cfg.server} #{port}"
      process.pid_file = Cfg.var_path / "run/#{port}.pid"
      process.stop_command = "kill -9 {{PID}}"
      process.daemonize = true
    end
  end
end
