require 'fileutils'
require 'digest/sha2'
require 'yaml'
require 'date'
require 'pty'
require 'timeout'
require 'base64'

require 'bundler/setup'
Bundler.require

$:.unshift File.expand_path '..', __FILE__
require 'ext/numeric'
require 'ext/string'
require 'ext/symbol'
require 'ext/array'
require 'conf/conf'
require 'conf/db'

if opted_env = $*[0]
  puts
  puts "Explicitly setting Env to #{opted_env}"
  puts
  Cfg.env = opted_env
end

# Registering Slim engine with Tilt.
# This should be done before controllers loaded
# otherwise will have to use `engine_ext` to explicitly define templates extension
Tilt::SlimTemplate = Slim::Template

# loading helpers
Dir[Cfg.helper_path / '**/*.rb'].each { |f| require f }

# loading models
%w[model assoc].each { |f| Dir[Cfg.model_path  / '**/%s.rb' % f].each { |f| require f } }
DataMapper.finalize

# loading controllers
%w[ctrl crud].each   { |f| Dir[Cfg.ctrl_path  / '**/%s.rb' % f].each { |f| require f } }

SUPPORTED_LANGS = %w[ruby node python php]

# building app
App = EApp.new :automount do

  session :memory
  assets_url :/
  pids do
    Dir[Cfg.app_path / 'tmp/pids/*.pid'].map { |f| File.read f }
  end
  cache_pool Hash.new

  if Cfg.dev?
    use Rack::ShowExceptions
    use Rack::CommonLogger
  end
end

App.setup_controllers do |ctrl|

  include SpawnHelper
  include OutputHelper
  include VersionsHelper

  if [Index, User].include?(ctrl)
    setup :index, /github/ do
      before do
        @users = cache(:users) do
          o, e = admin_spawn list_users_cmd
          e ? nil : o.split(/\r?\n/)
        end || []
      end
    end
  end

  # any controller(well, almost) need to output something
  attr_reader :auth_session, :output_streams, :output_stream

  # this hook should run before any action in all controllers.
  # also it should run before any other hooks in any controller
  # cause many controllers rely on env['REMOTE_USER'] and output_streams.
  # priority option will ensure it is called first in the hooks chain.
  # just make sure other hooks has lower priority.
  before priority: 1000 do
    @auth_session      = session[:auth_session] ||= {}
    env['REMOTE_USER'] = auth_session[:user?]

    @output_streams = session[:output_streams] ||= {}
    @output_stream  = output_streams[params[:__stream_uuid__]] || []
  end

  if Cfg.prod?
    error 404 do |msg|
      render_l :layout do
        "<h2>Well, sometimes is happening ...</h2>
         <h3>The page you are looking for is not here</h3>%s
         <h4>404: Not Found</h4>%s" % [msg, path]
      end
    end

    error 500 do |msg|
      render_l :layout do
        "<h2>Something weird happened ...</h2>
         <h3>Please try again later</h3>%s" % msg
      end
    end
  end

  engine :Slim, :pretty => Cfg.dev?
  layout :layout

end
