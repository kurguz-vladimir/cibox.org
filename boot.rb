require 'fileutils'
require 'digest/sha2'
require 'yaml'
require 'date'
require 'pty'
require 'timeout'

require 'bundler/setup'
Bundler.require

$:.unshift File.expand_path '..', __FILE__
require 'ext/numeric'
require 'ext/string'
require 'ext/symbol'
require 'conf/conf'
require 'conf/db'

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

# initializing the cache pool used by all controllers
CachePool = Hash.new

# building app
App = EApp.new :automount do

  session :memory
  assets_url :/

  if Cfg.dev?
    use Rack::ShowExceptions
    use Rack::CommonLogger
  end
end

App.setup_controllers do |ctrl|

  include SpawnHelper
  include OutputHelper

  if ctrl.name =~ /CRUD/
    before { halt 401 unless user }
  
    setup /post/, /put/, /delete/ do
      after do
        clear_cache! [user, :repo_list]
        clear_cache! [user, :repo_fs, params[:repo]]
        rpc_stream :alert, 'Done'
      end
    end
  end

  if [Index, User].include?(ctrl)
    setup :index, /github/ do
      before do
        @users = cache(:users) do
          o,e = spawn list_users_cmd, user: Cfg.remote[:app_user]
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

  # all controllers uses same cache pool
  cache_pool! CachePool

  engine :Slim, :pretty => Cfg.dev?
  layout :layout

end
