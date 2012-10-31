class Shell < E

  setup :post_invoke do
    before { halt 401 unless user? }
  end

  def post_invoke
    stream do
      repo, lang, versions, path, cmd =
        params.values_at(:repo, :lang, :versions, :path, :cmd)
      versions = 'default' if versions.nil? || versions.empty?
      versions.split.each do |version|
        rt_spawn *[lang, version, user, repo, path, cmd].shellify
      end
    end
  end

  # do not use POST here cause this will break autorun on Mozilla browsers
  def get_file
    stream do
      invoke_file
    end
  end
end
