module VersionsHelper

  def lang_versions lang
    cache([:langs, lang]) do
      o, e = spawn lang_versions_cmd(lang), user: :admin
      if e
        puts "error getting lang versions! lang: %s, params: %s, user: %s" % [lang, params, user]
        nil # cache nothing on failures
      else
        versions = o.split(/\r?\n/).map { |v| v.strip } rescue nil
        if versions.is_a?(Array)
          o, e = spawn lang_default_version_cmd(lang), user: :admin
          if e
            default = versions.first
          else
            default = o.strip 
          end
          versions.inject({}) { |f,c| f.update c => (default == c) }
        end
      end
    end || {}
  end

  def opted_versions lang, opted_versions
    versions = lang_versions lang
    return versions.keys if opted_versions == '*'
    return [versions.key(true)] if opted_versions.nil? || opted_versions.empty?
    unescape(opted_versions).split
  end
end
