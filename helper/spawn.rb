module SpawnHelper

  private

  def upload_file_cmd name, content = "\n", repo = '.', path = '.'
    # making sure ssh will not wait for data forever
    content = "\n" if content.nil? || content.empty?

    tmp = Tempfile.open(rand.to_s) { |f| f << content }
    [
      'f=%s; cat "$f" |' % tmp.path,
      'repos upload_file %s %s %s' % [repo, path, name].map { |c| c.to_s.escape_spaces },
      '; rm -f "$f"'
    ]
  end

  def delete_file_cmd file, repo = '.', path = '.'
    'repos delete_file %s %s %s' % [repo, path, file].map { |c| c.to_s.escape_spaces }
  end

  def rename_file_cmd file, name, repo = '.', path = '.'
    'repos rename_file %s %s %s %s' % [repo, path, file, name].map { |c| c.to_s.escape_spaces }
  end

  def read_file_cmd file, repo = '.', path = '.'
    'repos read_file %s %s %s' % [repo, path, file].map { |c| c.to_s.escape_spaces }
  end

  def delete_folder_cmd name, repo = '.', path = '.'
    'repos delete_folder %s %s %s' % [repo, path, name].map { |c| c.to_s.escape_spaces }
  end

  def rename_folder_cmd current_name, name, repo = '.', path = '.'
    'repos rename_folder %s %s %s %s' % [repo, path, current_name, name].map { |c| c.to_s.escape_spaces }
  end

  def create_folder_cmd name, repo = '.', path = '.'
    'repos create_folder %s %s %s' % [repo, path, name].map { |c| c.to_s.escape_spaces }
  end

  def delete_repo_cmd repo
    'repos delete %s' % repo
  end

  def rename_repo_cmd repo, name
    'repos rename %s %s' % [repo, name]
  end

  def create_repo_cmd name
    'repos create %s' % name
  end

  def list_repos_cmd
    'repos ls'
  end

  def repo_fs_cmd repo
    'repos fs %s' % repo
  end

  def fork_repo_cmd repo, owner
    'repos fork %s %s' % [repo, owner]
  end

  def list_users_cmd
    'users ls'
  end

  def create_user_cmd user
    'bin/create_user %s "%s"' % [user, Cfg.ssh_key.escape_spaces]
  end

  def delete_user_cmd user
    'bin/delete_user %s' % user
  end

  def user_identity_cmd
    'users identity'
  end

  def ruby_versions_cmd
    'ruby versions'
  end

  def node_versions_cmd
    'node versions'
  end

  def python_versions_cmd
    'python versions'
  end

  def ssh_pub_key_cmd
    'ssh pub_key'
  end

  def invoke_file action = 'run'
    user, repo, lang, versions, path, file =
      params.values_at(:user, :repo, :lang, :versions, :path, :file)
    
    run, compile = '%s "%s"' % [lang, file], nil
    ext = ::File.extname(file)
    is_coffee = ext == '.coffee'
    is_typescript = ext == '.ts'
    if action == 'compile' || is_coffee || is_typescript
      if is_coffee
        compile = 'coffee -c "%s"' % file
      elsif is_typescript
        compile = 'tsc "%s"' % file
      end
    end
    (versions||'default').split.each do |version|
      rt_spawn lang, version, user, repo, path, compile||run
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
    return [out, 'Please provide a command to execute'] unless cmd || opts[:cmd]
    prefix, cmd, suffix = cmd.is_a?(Array) ? cmd : [nil, cmd, nil]
    
    user, host, port = 
      opts[:user] || user? || Cfg.remote[:app_user],
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

    pid, stdin, stdout, stderr = POSIX::Spawn.popen4 real_cmd
    begin
      Timeout.timeout timeout do
        out, potential_error = stdout.read, stderr.read
        stdin.close; stdout.close; stderr.close
        _, status = Process.wait2(pid)
        err = (out + potential_error) unless status.exitstatus == 0
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

    real_cmd = "ssh -p %s %s@%s '%s %s %s %s %s' 2>&1" % [
      Cfg.remote[:port],
      user,
      Cfg.remote[:host],
      lang,
      version,
      repo,
      path.escape_spaces,
      cmd.gsub("'", "'\\\\''").escape_spaces
    ]
    puts real_cmd if Cfg.dev?

    timeout, error = Cfg.timeout[:interactive_shell], nil
    
    begin
      Timeout.timeout timeout do
        PTY.spawn real_cmd do |r, w, pid|
          r.sync
          buffer = [cmd]
          r.each { |l| shell_stream(l); buffer << l }
          _, status = Process.wait2 pid
          error = buffer.join("\n") unless status && status.exitstatus == 0
        end
      end
    rescue Timeout::Error
      spawn "kill %s" % timeout, user: user
      error = 'Max execution time of %s seconds exceeded' % timeout
    rescue Errno::EIO => e
      # simply ignoring this
    end
    if error
      rpc_stream :error, error
      ErrorModel.create user: user, cmd: real_cmd, error: error
    else
      update, alert = false, nil
      something_compiled = nil
      e, a = cmd.strip.split(/\s+/)
      case e
      when 'git'
        is_cloned = a == 'clone'
        is_pulled = a == 'pull' unless is_cloned
        update = is_cloned || is_pulled
        alert = 'Repo Successfully Cloned' if is_cloned
        alert = 'Repo Successfully Pulled' if is_pulled
      when 'npm'
        update = %w[install uninstall].include?(a)
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
      alert = 'File Successfully Compiled' if something_compiled
      rpc_stream :alert, alert if alert
    end
    rpc_stream :progress_bar, :hide
  end

  def admin_spawn cmd
    cmd = "ssh -p%s -t %s@%s '%s'" % [
      Cfg.remote[:port],
      Cfg.remote[:sys_user],
      Cfg.remote[:host],
      cmd
    ]
    timeout, output, error = Cfg.timeout[:filesystem], '', nil
    begin
      Timeout.timeout timeout do
        # using PTY cause sudo requires a tty to run
        PTY.spawn cmd do |r, w, pid|
          output = r.read
          # close FIFOs before start waiting,
          # otherwise it will wait forever on non-zero exit statuses
          r.close; w.close
          _, s = Process.wait2 pid
          error = output unless s.exitstatus == 0
        end
      end
    rescue Timeout::Error
      error = 'Max execution time exceeded' % timeout
    rescue Errno::EIO => e
      # simply ignoring this
    end
    [output, error]
  end

end
