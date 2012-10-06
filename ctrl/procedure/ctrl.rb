class Procedure < E
  
  def dropdown user
    @user = user
    @procedures = ProcedureModel.all(user: @user)
    render_p
  end

  def post_invoke
    stream do
      repo, lang, versions, path, procedure_id =
        params.values_at(:repo, :lang, :versions, :path, :procedure_id)

      if p = ProcedureModel.first(id: procedure_id)
        if p.public?
          shell_stream '=== Invoking "%s" Procedure ===' % p.name
          commands = p.commands.split(/\r?\n/).reject { |c| c.strip.size == 0 }
          noexec_issue = false
          (versions||'default').split.each do |version|
            break if noexec_issue
            commands.each do |cmd|
              result = rt_spawn lang, version, p.user, repo, path, cmd
              noexec_issue = true if result == :noexec_issue
            end
          end
        else
          rpc_stream :alert, 'Please Login'
        end
      end
    end
  end
end
