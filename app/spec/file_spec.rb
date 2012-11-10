Spec.new :FileSpec do

  o 'creating random repo'
  repo = (rand.to_s + Time.now.to_f.to_s).to_url
  out, err = spawn create_repo_cmd(repo), user: test_user
  o.error(err) if err
  does(repos).include? repo

  Ensure 'repo is empty(containing only root node)' do
    check { repo_fs(repo).size } == 1
  end

  file = rand.to_s + " " + Time.now.to_f.to_s
  Should 'create new file' do
    out, err = spawn upload_file_cmd(file, "\n", repo), user: test_user
    o.error(err) if err
    files = repo_fs(repo)['.'][:files].keys rescue {}
    does { files }.include? file
  end

  Testing 'read/write API' do
    content = rand.to_s + " " + Time.now.to_f.to_s
    out, err = spawn upload_file_cmd(file, content, repo), user: test_user
    o.error(err) if err
    out, err = spawn read_file_cmd(file, repo), user: test_user
    o.error(err) if err
    does(out) =~ /#{content}/
  end

  new_name = rand.to_s + " " + Time.now.to_f.to_s
  Should 'rename file' do
    out, err = spawn rename_file_cmd(file, new_name, repo), user: test_user
    o.error(err) if err
    files = repo_fs(repo)['.'][:files].keys rescue {}
    does(files).include? new_name
    refute(files).include? file
  end

  Should 'delete file' do
    out, err = spawn delete_file_cmd(new_name, repo), user: test_user
    o.error(err) if err
    files = repo_fs(repo)['.'][:files].keys rescue {}
    refute(files).include? new_name
  end

  o 'deleting repo'
  spawn delete_repo_cmd(repo), user: test_user

end
