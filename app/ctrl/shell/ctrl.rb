class Shell < E

  setup :post_invoke do
    before { halt 401 unless user? }
  end

  def post_invoke
    repo, lang, versions, path, cmd =
      params.values_at(:repo, :lang, :versions, :path, :cmd)
    opted_versions(lang, versions).each do |version|
      rt_spawn *[lang, version, user, repo, path, cmd].shellify
    end
  end

end
