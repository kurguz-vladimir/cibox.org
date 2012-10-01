Spec.new :UserSpec do

  o 'deleting test account'
  out, err = admin_spawn delete_user_cmd(test_user)

  Ensure 'user does not exists' do
    refute(users).include? test_user
  end
  
  Ensure 'new account properly created' do
    out, err = admin_spawn create_user_cmd(test_user)
    o.error(err) if err
    does(users).include? test_user

    Ensure 'SSH login Enabled and Wrapped' do
      out, err = spawn '', user: test_user
      o.error(err) if err
      check(out) =~ /#{test_user}/
      check(out) =~ /welcome/i
    end

    Ensure 'quota enabled' do
      out, err = admin_spawn "sudo /bin/quota -v #{test_user} | grep /dev"
      o.error(err) if err
      out.split("\n").select { |l| l.strip =~ /\A\/dev/ }.each do |p|
        limits = p.strip.split(/\s+/)
        check{ limits[2].to_i } > 0
        check{ limits[3].to_i } > 0
      end
    end
  end
end
