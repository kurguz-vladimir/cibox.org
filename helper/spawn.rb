module SpawnHelper

  private

  def create_file_cmd name, repo, path = nil
    'REPO="%s" WD="%s" FILE="%s" cibox-repo create_file' % [repo, path, name].shellify
  end

  def upload_file_cmd name, content, repo, path = nil
    
    content = "\n" if content.empty? # making sure ssh will not waiting for data forever

    tmp = Tempfile.open(rand.to_s) { |f| f << content }
    [
      'f="%s"; cat "$f" |' % tmp.path,
      'REPO="%s" WD="%s" FILE="%s" cibox-repo upload_file' % [repo, path, name].shellify,
      '; rm -f "$f"'
    ]
  end

  def delete_file_cmd file, repo, path = nil
    'REPO="%s" WD="%s" FILE="%s" cibox-repo delete_file' % [repo, path, file].shellify
  end

  def rename_file_cmd file, name, repo, path = nil
    'REPO="%s" WD="%s" SRC="%s" DST="%s" cibox-repo rename_file' % [repo, path, file, name].shellify
  end

  def read_file_cmd file, repo, path = nil
    'REPO="%s" WD="%s" FILE="%s" cibox-repo read_file' % [repo, path, file].shellify
  end


  def delete_folder_cmd name, repo, path = nil
    'REPO="%s" WD="%s" FOLDER="%s" cibox-repo delete_folder' % [repo, path, name].shellify
  end

  def rename_folder_cmd current_name, name, repo, path = nil
    'REPO="%s" WD="%s" SRC="%s" DST="%s" cibox-repo rename_folder' % [repo, path, current_name, name].shellify
  end

  def create_folder_cmd name, repo, path = nil
    'REPO="%s" WD="%s" FOLDER="%s" cibox-repo create_folder' % [repo, path, name].shellify
  end


  def delete_repo_cmd repo
    'REPO="%s" cibox-repo delete' % repo.shellify
  end

  def rename_repo_cmd repo, name
    'REPO="%s" SRC="%s" DST="%s" cibox-repo rename' % [repo, repo, name].shellify
  end

  def create_repo_cmd name
    'REPO="%s" cibox-repo create' % name.shellify
  end

  def list_repos_cmd
    'cibox-repo ls'
  end

  def repo_fs_cmd repo
    'REPO="%s" cibox-repo fs' % repo.shellify
  end

  def archive_repo_cmd repo, owner
    'REPO="%s" OWNER="%s" cibox-repo archive' % [repo, owner].shellify
  end

  def download_repo_cmd user, repo, format, dst
    'rsync -e"ssh -p%s" %s@%s:"repos/%s.%s" "%s"' % [
      Cfg.remote[:port],
      user,
      Cfg.remote[:host],
      repo,
      format,
      dst
    ].shellify
  end
  
  def fork_repo_cmd repo, owner
    'bin/fork "%s" "%s" "%s"' % [repo, owner, user].shellify
  end


  def list_users_cmd
    'bin/users'
  end

  def create_user_cmd user
    'bin/create_user "%s" "%s"' % [user, Cfg.ssh_key].shellify(:spaceify)
  end

  def chroot_user_cmd user
    'bin/chroot_user %s' % user.shellify
  end
  def logout_user_cmd user
    'bin/logout_user %s' % user.shellify
  end

  def delete_user_cmd user
    'bin/delete_user %s' % user.shellify
  end


  def ssh_add_key_cmd key, name
    'sudo bin/ssh %s add "%s" "%s"' % [user, name, key].shellify(:spaceify)
  end

  def ssh_remove_key_cmd name
    'sudo bin/ssh %s remove "%s"' % [user, name].shellify(:spaceify)
  end

  def ssh_ls_keys_cmd
    'sudo bin/ssh %s ls' % user.shellify
  end

  def ssh_identity_cmd user
    'sudo bin/ssh %s identity' % user.shellify
  end

  def ssh_pub_key_cmd
    'cibox-ssh pub_key'
  end


  def lang_versions_cmd lang
    'cibox-langs %s' % lang.shellify
  end

  def lang_default_version_cmd lang
    'cibox-langs %s default_version' % lang.shellify
  end


  def invoke_file action = 'run'
    user, repo, lang, versions, path, file =
      params.values_at(:user, :repo, :lang, :versions, :path, :file)
    
    run, compile = '%s "%s"' % [lang, file].shellify, nil
    ext = ::File.extname(file)
    is_coffee = ext == '.coffee'
    is_typescript = ext == '.ts'
    if action == 'compile' || is_coffee || is_typescript
      if is_coffee
        compile = 'coffee -c "%s"' % file.shellify
      elsif is_typescript
        compile = 'tsc "%s"' % file.shellify
      end
    end
    (versions||'default').split.each do |version|
      rt_spawn *[lang, version, user, repo, path].shellify, compile||run
    end
  end

  def crud_spawn cmd = nil, opts = {}, &proc
    halt 401 unless user?

    opts = cmd if cmd.is_a?(Hash)
    stream do
      rpc_stream :progress_bar, :show
      o, e = spawn cmd, opts, &proc
      if e
        rpc_stream :error, e
      else
        clear_cache! [user, :repo_list]
        clear_cache! [user, :repo_fs, params[:repo]]

        data = opts.merge(stdout: o, params: params)
        crud_stream data
        rpc_stream :alert, 'Done'
      end
      rpc_stream :progress_bar, :hide
    end
  end

  def spawn *cmd_and_or_opts
    out, err  = nil
    cmd, opts = nil, {}
    cmd_and_or_opts.each { |a| a.is_a?(Hash) ? opts.update(a) : cmd = a }
    cmd = yield if block_given?
    return [out, 'Please provide a command to be executed'] unless cmd || opts[:cmd]
    prefix, cmd, suffix = cmd.is_a?(Array) ? cmd : [nil, cmd, nil]
    
    user, host, port = 
      opts[:user] || user?,
      opts[:host] || Cfg.remote[:host],
      opts[:port] || Cfg.remote[:port]

    timeout = Cfg.timeout[:filesystem]
    args = ['-p %s' % port]
    args << '-t' if opts[:tty]
    real_cmd = opts[:cmd] || "%s ssh %s %s@%s '%s' %s" % [
      prefix, 
      args.join(' '),
      user, 
      host, 
      cmd, 
      suffix
    ]

    puts real_cmd if Cfg.dev?
    
    pid, stdin, stdout, stderr = POSIX::Spawn.popen4 real_cmd
    begin
      Timeout.timeout timeout do
        out, eventual_error = stdout.read, stderr.read
        stdin.close; stdout.close; stderr.close
        _, status = Process.wait2(pid)
        err = (out + eventual_error) unless status && status.exitstatus == 0
      end
    rescue Timeout::Error
      Process.kill 9, pid
      err = 'Max execution time of %s seconds exceeded' % timeout
    rescue => e
      err = '%s: %s' % [cmd, e.message]
    end
    ErrorModel.create user: user, cmd: real_cmd, error: err if err
    [out, err]
  end

  def rt_spawn lang, version, user, repo, path, cmd
    rpc_stream :progress_bar, :show
    shell_stream '--- %s ---' % version unless lang.empty?

    # string operations are expensive enough, so doing some cache
    remote_env = cache [:rt_spawn, lang, version] do
      env = []
      if lang == 'ruby'
        regex = /\-(\d+)mode\Z/
        if mode = version.scan(regex).flatten.first
          if version =~ /jruby/i
            env << 'export JRUBY_OPTS="--%s $JRUBY_OPTS"' % mode.split('').join('.')
          elsif version =~ /rbx\-2/i
            env << 'export RBXOPT="-X%s $RBXOPT"' % mode
          end
          version = version.sub(regex, '')
        end
      end

      langs_path = lang.empty? ?
        SUPPORTED_LANGS.map { |l| Cfg.remote[:langs_path] % [l, :default] }.join(':') :
        Cfg.remote[:langs_path] % [lang, version]
      
      env << 'export PATH="%s:$PATH"' % langs_path
      env.join(" && ")
    end

    cmd = cache [:rt_spawn, cmd] do
      # if user want to uninstall some gem(s) without providing any flags,
      # adding -aIx flags to get rid of any confirmations.
      regex  = /\Agem\s+uni/
      if cmd =~ regex
         cmd =~ /\s+\-/ || cmd = 'gem uninstall -aIx %s' % cmd.sub(regex, '')
      end
      cmd
    end
    repo.empty? || cmd = 'cd "$HOME/repos/%s/%s" && %s' % [repo, path, cmd]

    real_cmd = "ssh -p%s %s@%s '%s'" % [
      Cfg.remote[:port], 
      user, 
      Cfg.remote[:host], 
      remote_env + ' && ' + cmd
    ]

    puts real_cmd if Cfg.dev?

    timeout, error = Cfg.timeout[:interactive_shell], nil
    
    buffer = [cmd]
    begin
      Timeout.timeout timeout do
        PTY.spawn real_cmd do |r, w, pid|
          begin
            r.sync
            r.each_line { |l| shell_stream(l); buffer << l }
          rescue Errno::EIO => e
            # simply ignoring this
          ensure
            ::Process.wait pid
          end
        end
      end
    rescue Timeout::Error
      error = 'Max execution time of %s seconds exceeded' % timeout
    end
    error = buffer.join("\n") unless $? && $?.exitstatus == 0

    if error
      rpc_stream :error, error
      ErrorModel.create user: user, cmd: real_cmd, error: error
    else
      update, alert = false, nil
      something_installed, something_uninstalled, something_compiled = nil
      e, a = cmd.strip.split(/\s+/)
      case e
      when 'git'
        is_updated = %w[
          add checkout clone fetch init 
          merge mv pull rebase reset rm tag
        ].include?(a)
        is_pulled = a == 'pull' unless is_updated
        update = is_updated || is_pulled
        alert = 'Repo Operations Successfully Completed' if is_updated
        alert = 'Repo Successfully Pulled' if is_pulled
      when 'gem'
        something_uninstalled = a =~ /uni/
        something_installed   = a =~ /in/ unless something_uninstalled
      when 'npm'
        something_installed   = a == 'install'
        something_uninstalled = a == 'uninstall' unless something_installed
        update = something_installed || something_uninstalled
      when 'pip'
        something_installed   = a == 'install'
        something_uninstalled = a == 'uninstall' unless something_installed
      when 'coffee'
        update = a =~ /\-c/
        something_compiled = true
      when 'tsc'
        update = true
        something_compiled = true
      end
      if update
        clear_cache_like! [user]
        rpc_stream :update_repo_list
        rpc_stream :update_repo_fs
      end
      alert = 'Package(s) Successfully Installed'   if something_installed
      alert = 'Package(s) Successfully unInstalled' if something_uninstalled
      alert = 'File Successfully Compiled'          if something_compiled
      rpc_stream :alert, alert if alert
    end
    rpc_stream :progress_bar, :hide
  end

  def admin_spawn cmd, tty = nil
    real_cmd = "ssh -t -p%s %s@%s '%s'" % [
      Cfg.remote[:port],
      Cfg.remote[:admin_user],
      Cfg.remote[:host],
      cmd
    ]
    puts real_cmd if Cfg.dev?
    timeout, output, error = Cfg.timeout[:filesystem], [], nil
    begin
      Timeout.timeout timeout do
        # using PTY cause sudo requires a tty to run
        PTY.spawn real_cmd do |r, w, pid|
          begin
            r.sync
            # stripping cause \r usually causes big troubles in javascript
            r.each_line { |l| output << l.strip }
          rescue Errno::EIO => e
            # simply ignoring this
          ensure
            ::Process.wait pid
          end
          error = output.join("\n") unless $? && $?.exitstatus == 0
        end
      end
    rescue Timeout::Error
      error = 'Max execution time exceeded' % timeout
    end
    # pop-ing output cause it is always equal to "Connection ... closed"
    output.pop
    [output.reject { |l| l.empty? }.join("\n"), error]
  end

end
