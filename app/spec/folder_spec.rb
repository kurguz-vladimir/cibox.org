Spec.new :FolderSpec do

  o 'creating random repo'
  repo = (rand.to_s + Time.now.to_f.to_s).to_url
  out, err = spawn create_repo_cmd(repo), user: test_user
  o.error(err) if err
  does(repos).include? repo

  Ensure 'repo is empty(containing only root node)' do
    check { repo_fs(repo).size } == 1
  end

  folder = rand.to_s + " " + Time.now.to_f.to_s
  Should 'create new folder' do
    out, err = spawn create_folder_cmd(folder, repo), user: test_user
    o.error(err) if err
    does { repo_fs(repo).keys }.include? folder
  end

  new_name = rand.to_s + " " + Time.now.to_f.to_s
  Should 'rename folder' do
    out, err = spawn rename_folder_cmd(folder, new_name, repo), user: test_user
    o.error(err) if err
    folders = repo_fs(repo).keys
    does(folders).include? new_name
    refute(folders).include? folder
  end

  Should 'delete folder' do
    out, err = spawn delete_folder_cmd(new_name, repo), user: test_user
    o.error(err) if err
    folders = repo_fs(repo).keys
    refute(folders).include? new_name
  end

  o 'deleting repo'
  spawn delete_repo_cmd(repo), user: test_user

end
