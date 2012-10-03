require File.expand_path('../boot', __FILE__)
puts App.url_map :v => true
App.run :server => Cfg.server, :Port => $*[0] || Cfg.port
