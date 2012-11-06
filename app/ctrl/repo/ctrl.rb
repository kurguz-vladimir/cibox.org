class Repo < E

  setup :dropdown, :fs do
    before do
      @repos = cache([action_params[:user], :repo_list]) do
        # compensating synchronous operations by cache
        o, e = spawn list_repos_cmd, user: action_params[:user]
        e ? nil : o.split(/\r?\n/)
      end || []
    end
  end

  def post_fork repo, owner
    stream do
      rpc_stream :progress_bar, :show
      o, e = admin_spawn fork_repo_cmd(repo, owner)
      if e
        rpc_stream :error, e
      else
        rpc_stream :alert, 'Repo successfully forked. See it in your account.'
        clear_cache! [user, :repo_list]
      end
      rpc_stream :progress_bar, :hide
    end
  end

  def download user, repo, format
    stream do
      rpc_stream :progress_bar, :show
      o, e = spawn archive_repo_cmd(repo, user), user: user
      if e
        rpc_stream(:error, e)
      else
        dst = Cfg.var_path / :downloads / user
        FileUtils.mkdir_p dst
        o, e = spawn cmd: download_repo_cmd(user, repo, format, dst)
        e ? rpc_stream(:error, e) :
          rpc_stream(:download, '/downloads/%s/%s.%s' % [user, repo, format])
      end
      rpc_stream :progress_bar, :hide
    end
  end

  def dropdown user, repo = nil
    @user, @repo = user, repo
    render_p
  end

  def fs user, repo = nil
    return unless repo
    halt 404 unless @repos.include?(repo)
    stream do |out|

      rpc_stream :progress_bar, :show
      @user, @repo = user, repo
    
      @repo_fs = cache([user, :repo_fs, repo]) do
        o, e   = spawn repo_fs_cmd(repo), user: user
        if e
          nil # do not cache anything on errors
        else
          if (fs = YAML.load(o) rescue nil).is_a?(Hash)
            fs.inject({}) do |f,c|
              f.update c.first => {
                folders: Hash[((c.last||{})[:folders] || {}).sort_by {|e| (e.last||{})[:name]||''}],
                files:   Hash[((c.last||{})[:files]   || {}).sort_by {|e| (e.last||{})[:name]||''}],
              }
            end
          end
        end
      end
      @repo_fs ||= {}
      
      out << render_p
      rpc_stream :progress_bar, :hide
    end
  end

  class File < E
    map Repo.base_url / :file

    def post_save
      stream do
        rpc_stream :progress_bar, :show
        o, e = spawn do
          upload_file_cmd *params.values_at(:file, :content, :repo, :path)
        end
        if e 
          rpc_stream :error, e
        else
          if action = params[:after_save]
            invoke action
          end
          rpc_stream :alert, 'File Successfully Updated'
        end
        rpc_stream :progress_bar, :hide
      end
    end

    def post_read user, repo
      stream do |out|
        rpc_stream :progress_bar, :show
        o, e = spawn read_file_cmd(params[:file], repo, params[:path]), user: user
        e ?
          rpc_stream(:error, e) :
          out << o
        rpc_stream :progress_bar, :hide
      end
    end

    # do not use POST here cause this will break autorun on Mozilla browsers
    def get_invoke action = 'run'
      stream { invoke action }
    end

    private
    def invoke action = 'run'
      user, repo, lang, versions, path, file =
        params.values_at(:user, :repo, :lang, :versions, :path, :file)
      return unless file
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
      opted_versions(lang, versions).each do |version|
        rt_spawn *[lang, version, user, repo, path].shellify, compile||run
      end
    end
  end

end
