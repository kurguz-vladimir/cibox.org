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
    unless user
      redirect user? if user?
      return render(:welcome) 
    end
    error 404, 'User Not Found' unless @users.include?(user)

    @user, @repo = user, repo
    
    @langs = SUPPORTED_LANGS.inject({}) do |langs, lang|
      langs.update lang => lang_setup(lang)
    end

    if user?
      @ssh_pub_key = cache([user, :ssh_pub_key]) do
        o, e = spawn ssh_pub_key_cmd
        e ? nil : o.strip
      end || []
    end

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
    clear_cache_like! [:langs]
  end

  private
  def lang_setup lang
    cache([:langs, lang]) do
      o,e = spawn lang_versions_cmd(lang)
      rv = nil
      unless e
        versions = o.split(/\r?\n/).map { |v| v.strip } rescue nil
        if versions.is_a?(Array)
          o, e = spawn lang_default_version_cmd(lang)
          p [o, e]
          if e
            default = versions.first
          else
            default = o.strip 
          end
          rv = versions.inject({}) { |f,c| f.update c => (default == c) }
        end
      end
      rv
    end || []
  end

end
