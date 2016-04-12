
pagesize=Facter::Util::Resolution.exec('bash -c \'getconf PAGE_SIZE 2>/dev/null \'')

unless pagesize.nil? or pagesize.empty?
  Facter.add('eyp_postgresql_pagesize') do
      setcode do
          pagesize
      end
  end
end
