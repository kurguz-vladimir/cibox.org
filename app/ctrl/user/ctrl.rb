class User < E

  include SpawnHelper

  setup /ssh/ do
    before { halt 401 unless user? }
  end

  def index
    user ? redirect(Index, user) : render
  end

  def ssh_key placeholder = nil
    @keys, e = admin_spawn ssh_ls_keys_cmd
    render_p
  end

  def post_ssh_key
    o, e = admin_spawn ssh_add_key_cmd(*params.values_at(:key, :name))
    if e
      rpc_stream(:error, e)
      halt
    end
    crud_stream(resource: :ssh_key, action: :add)
  end

  def delete_ssh_key
    o, e = admin_spawn ssh_remove_key_cmd(params[:key])
    if e
      rpc_stream(:error, e)
      halt
    end
    crud_stream(resource: :ssh_key, action: :remove)
  end

  def auth__github
    redirect oauth_client.auth_code.authorize_url
  end

  def auth__github__callback
    
    user, new_user, data = nil, false, {}
    error = catch :login_process_error do
      begin
        token = oauth_client.auth_code.get_token(params[:code])
      rescue OAuth2::Error => e
        throw :login_process_error, "Was unable to perform OAuth request"
      rescue => e
        throw :login_process_error, e.message
      end
      
      begin
        json = RestClient.get Cfg.github_api[:url] / Cfg.github_api[:user_resource],
          :params => { :access_token => token.token }
        data = JSON.parse(json)
      rescue => e
        throw :login_process_error, "Unable to process GitHub response"
      end
      
      user, created_at = data.values_at('login', 'created_at') rescue nil
      created_at = Date.parse(created_at) rescue nil
      unless user && created_at
        throw :login_process_error, "Got invalid data from GitHub. Please try again later" 
      end

      cmd = chroot_user_cmd(user)
      unless @users.include?(user)
        if (Date.today - created_at).to_i >= Cfg.github_account_min_age.to_i
          cmd = create_user_cmd(user)
          new_user = true
          clear_cache! :users
        else
          throw :login_process_error, "Your GitHub account should be at least 
            #{Cfg.github_account_min_age} days old, sorry."
        end
      end
      _, e = admin_spawn cmd
      if e
        ErrorModel.create user: :admin, cmd: cmd, error: e
        throw :login_process_error, e
      end
      nil
    end

    error(500, error) if error

    if user
      auth_session[:user?] = user
      goto = Index.route(user)
      if new_user
        # creating a test repo
        repo_name, file_name = 'test-repo', 'test-file'
        spawn create_repo_cmd(repo_name), user: user
        spawn create_file_cmd(file_name, repo_name), user: user
        goto = Index.route(user, repo_name, file: file_name)
      end
      redirect goto
    else
      error 500, 'Unknown error occurred. Please try again later.'
    end
  end

  def logout
    delayed_redirect Index
    return unless user = user?
    clear_cache_like! [user]
    session.delete :auth_session
    admin_spawn logout_user_cmd(user)
  end

  def post_clear_cache user
    halt 501 unless identity = params[:identity]
    true_identity = (admin_spawn(ssh_identity_cmd, user: user).first||'').strip
    halt 501 unless identity == true_identity
    clear_cache_like! [user]
    puts 'Cache cleared from ' + ip
  end

  private

  def oauth_client site = :github
    setup = Cfg.oauth[site] || raise("Please make sure conf.yml contains :oauth entry for #{site} site")
    OAuth2::Client.new  setup[:client_id], setup[:client_secret],
      :site          => setup[:site],
      :authorize_url => setup[:authorize_url],
      :token_url     => setup[:token_url]
  end
end
