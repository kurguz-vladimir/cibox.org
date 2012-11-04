Spec.new :RepoSpec do

  repo = (rand.to_s + Time.now.to_f.to_s).to_url

  Ensure 'repo does not exists' do
    refute(repos).include? repo
  end

  Should 'create' do
    out, err = spawn create_repo_cmd(repo), user: test_user
    o.error(err) if err
    does(repos).include? repo
  end

  new_name = (rand.to_s + Time.now.to_f.to_s).to_url
  refute(repos).include? new_name
  Should 'rename' do
    out, err = spawn rename_repo_cmd(repo, new_name), user: test_user
    o.error(err) if err
    does(repos).include? new_name
    refute(repos).include? repo
  end

  Should 'delete' do
    out, err = spawn delete_repo_cmd(new_name), user: test_user
    o.error(err) if err
    refute(repos).include? new_name
  end
end
