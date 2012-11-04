class Procedure < E
  
  def dropdown user
    @user = user
    @procedures = ProcedureModel.all(user: @user)
    render_p
  end

  # do not use POST here cause this will break autorun on Mozilla browsers
  def get_invoke
    stream do
      repo, lang, versions, path, procedure_id =
        params.values_at(:repo, :lang, :versions, :path, :procedure_id)

      if p = ProcedureModel.first(id: procedure_id)
        if p.public? || user? == p.user
          shell_stream escape_path( "=== Invoking \"%s\" Procedure ===\n" % p.name )
          
          commands = p.commands.split(/\r?\n/).reject { |c| c.strip.size == 0 }

          opted_versions(lang, versions).each do |version|
            commands.each do |cmd|
              rt_spawn *[lang, version, p.user, repo, path, cmd].shellify
            end
          end
        else
          rpc_stream :error, '=== Please Login ==='
        end
      end
    end
  end
end
