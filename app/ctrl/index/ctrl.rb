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
      langs.update lang => lang_versions(lang)
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
    event_stream do |stream|
      output_streams[uuid] = stream
      stream.on_error { output_streams.delete uuid }
    end
  end

  def system__clear_cache
    clear_cache! :users
    clear_cache_like! [:langs]
  end

end
