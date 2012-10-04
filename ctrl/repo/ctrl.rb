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
      o, e = spawn fork_repo_cmd(repo, owner)
      if e
        rpc_stream :error, e
      else
        clear_cache! [user, :repo_list]
        rpc_stream :alert, 'Repo successfully forked. See it in your account.'
      end
      rpc_stream :progress_bar, :hide
    end
  end

  def download user, repo, format
    stream do
      rpc_stream :progress_bar, :show
      o, e = spawn 'repos archive %s' % repo, user: user
      if e
        rpc_stream(:error, e)
      else
        dst = Cfg.var_path / :downloads / user
        FileUtils.mkdir_p dst
        cmd = 'rsync -e"ssh -p%s" %s@%s:"%s.%s" "%s"' % [
          Cfg.remote[:port],
          user,
          Cfg.remote[:host],
          repo,
          format,
          dst
        ]
        o, e = spawn cmd: cmd
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
        o, e = spawn repo_fs_cmd(repo), user: user
        e ? nil : YAML.load(o)
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
            invoke_file action
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
  end

end
