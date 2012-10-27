class Repo
  class CRUD < E
    map Repo.base_url / :crud

    def index placeholder = nil
      @repo = params[:repo]
      render_partial
    end

    def post_index
      params[:name] = (params[:name]||'').to_url
      crud_spawn create_repo_cmd(params[:name]),
        resource: :repo, action: :create
    end

    def put_index placeholder
      params[:name] = (params[:name]||'').to_url
      params[:repo] = (params[:repo]||'').escape_spaces
      crud_spawn rename_repo_cmd(params[:repo], params[:name]),
        resource: :repo, action: :update
    end

    def delete_index placeholder
      params[:repo] = (params[:repo]||'').escape_spaces
      crud_spawn delete_repo_cmd(params[:repo]),
        resource: :repo, action: :delete
    end
  end

  class Folder
    class CRUD < E
      map Repo.base_url / :folder_crud

      def index placeholder = nil
        @name, repo, path = params.values_at(:name, :repo, :path)
        return unless repo && path
        @path = repo / path
        render_p
      end

      def post_index
        crud_spawn create_folder_cmd(*params.values_at(:name, :repo, :path)),
          resource: :folder, action: :create
      end

      def put_index placeholder
        crud_spawn rename_folder_cmd(*params.values_at(:current_name, :name, :repo, :path)),
          resource: :folder, action: :update
      end

      def delete_index placeholder
        crud_spawn delete_folder_cmd(*params.values_at(:name, :repo, :path)),
          resource: :folder, action: :delete
      end
    end
  end

  class File
    class CRUD < E
      map Repo.base_url / :file_crud

      def index placeholder = nil
        repo, path = params.values_at(:repo, :path)
        return unless repo && path
        @path = repo / path
        render_partial
      end

      def post_index
        crud_spawn create_file_cmd(*params.values_at(:name, :repo, :path)),
          resource: :file, action: :create
      end

      def put_index placeholder
        crud_spawn rename_file_cmd(*params.values_at(:file, :name, :repo, :path)),
          resource: :file, action: :update_name
      end

      def delete_index placeholder
        crud_spawn delete_file_cmd(*params.values_at(:file, :repo, :path)),
          resource: :file, action: :delete
      end
    end
  end

end
