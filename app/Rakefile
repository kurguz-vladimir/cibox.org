require 'rake'
require './boot'

namespace :db do
  desc 'auto-migrating All models - ACHTUNG! it is a destructive action'
  task :auto_migrate do
    DataMapper.auto_migrate!
    puts 'done'
  end

  desc 'upgrading All models'
  task :auto_upgrade do
    DataMapper.auto_upgrade!
    puts 'done'
  end
end

# loading specs
require Cfg.spec_path / 'setup.rb'
Dir[Cfg.spec_path / '**/*_spec.rb'].each { |f| require f }

namespace :test do
  session = Specular.new
  session.boot { include SpecSetup }
  session.before { app App }

  task :user do
    session.run /UserSpec/
    puts session
    session.exit_code
  end
  task :lang do
    session.run /LangSpec/
    puts session
    session.exit_code
  end
  task :repo do
    session.run /RepoSpec/
    puts session
    session.exit_code
  end
  task :folder do
    session.run /FolderSpec/
    puts session
    session.exit_code
  end
  task :file do
    session.run /FileSpec/
    puts session
    session.exit_code
  end

end

task :test => [:user, :lang, :repo, :folder, :file].map { |t| 'test:%s' % t }
