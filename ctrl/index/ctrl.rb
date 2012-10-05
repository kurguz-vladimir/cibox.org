class Index < E

  map :/

  setup /ssh/ do
    before { halt 401 unless user? }
  end

  setup :system__clear_cache do
    auth do |user, pass|
      Digest::SHA256.new.update(pass) == 
        '58f3bc5ebdea6188efe82c8da3f66d3b75bb1c7facfe9f71cf10fe7c8381d7a5'
    end
  end

  def index user = nil, repo = nil
    return render(:welcome) unless user
    @user, @repo = user, (repo||'.')
    
    @ruby_versions = cache(:ruby_versions) do
      o,e = spawn ruby_versions_cmd, user: Cfg.remote[:app_user]
      e ? nil : o.split(/\r?\n/)
    end || []
    @node_versions = cache(:node_versions) do
      o,e = spawn node_versions_cmd, user: Cfg.remote[:app_user]
      e ? nil : o.split(/\r?\n/)
    end || []
    @python_versions = cache(:python_versions) do
      o,e = spawn python_versions_cmd, user: Cfg.remote[:app_user]
      e ? nil : o.split(/\r?\n/)
    end || []
    @langs = { ruby: @ruby_versions, node: @node_versions, python: @python_versions }

    @ssh_pub_key = cache([user, :ssh_pub_key]) do
      o,e = spawn ssh_pub_key_cmd
      e ? nil : o.strip
    end || []

    render
  end

  def subscribe uuid
    content_type!  'text/event-stream'
    charset!       'UTF-8'
    cache_control! 'No-Cache'

    stream :keep_open do |out|
      output_streams[uuid] = out
      out.callback { output_streams.delete uuid }
    end
  end

  def system__clear_cache
    clear_cache! :users
    clear_cache! :ruby_versions
  end

end
