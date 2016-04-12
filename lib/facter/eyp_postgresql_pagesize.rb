
pagesize=Facter::Util::Resolution.exec('bash -c \'getconf PAGE_SIZE 2>/dev/null \'')

if pagesize.nil? or pagesize.empty?
  Facter.add('eyp_postgresql_pagesize') do
      setcode do
          1
      end
  end
else
  Facter.add('eyp_postgresql_pagesize') do
      setcode do
          pagesize
      end
  end
end
