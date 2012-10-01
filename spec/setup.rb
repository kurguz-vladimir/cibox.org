module SpecSetup

  include Sonar
  include SpawnHelper

  def test_user
    'tst'
  end

  def users
    o, e = spawn list_users_cmd, user: Cfg.remote[:app_user]
    e ? [] : o.split(/\r?\n/)
  end

  def repos
    o, e = spawn list_repos_cmd, user: test_user
    e ? [] : o.split(/\r?\n/)
  end

  def repo_fs repo
    o, e = spawn repo_fs_cmd(repo), user: test_user
    e ? {} : YAML.load(o) rescue {}
  end

  def ruby_versions
    o, e = spawn ruby_versions_cmd, user: Cfg.remote[:app_user]
    e ? [] : o.split(/\r?\n/)
  end

end
