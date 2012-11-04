Spec.new :LangSpec do

  Testing :Ruby do
    versions = []
    Ensure 'versions are fetched properly' do
      versions = ruby_versions
      is(versions.size) > 0
    end

    Ensure 'all versions works properly' do
      versions.each do |version|
        expect do
          cmd = "ruby -e\"puts 1+1\"".escape_spaces
          o, e = spawn("ruby #{version} . . #{cmd}", user: test_user)
          o.split("\n").last
        end == '2'
      end
    end

  end
end
