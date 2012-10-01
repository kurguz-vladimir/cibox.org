class Shell < E

  setup :post_invoke do
    before { halt 401 unless user? }
  end

  # users can execute commands only on their account
  def post_invoke
    stream do
      repo, lang, versions, path, cmd =
        params.values_at(:repo, :lang, :versions, :path, :cmd)
      (versions||'default').split.each do |version|
        rt_spawn lang, version, user, repo, path, cmd
      end
    end
  end

  def post_file
    stream do
      user, repo, lang, versions, path, file =
        params.values_at(:user, :repo, :lang, :versions, :path, :file)
      cmd = '%s "%s"' % [lang, file]
      (versions||'default').split.each do |version|
        rt_spawn lang, version, user, repo, path, cmd
      end
    end
  end
end
