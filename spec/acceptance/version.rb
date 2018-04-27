
_osfamily               = fact('osfamily')
_operatingsystem        = fact('operatingsystem')
_operatingsystemrelease = fact('operatingsystemrelease').to_f

case _osfamily
when 'RedHat'
  $packagename92  = 'postgresql92'
  $servicename92  = 'postgresql-9.2'
  $postgresconf92 = '/var/lib/pgsql/9.2/data/postgresql.conf'
  $pghba92        = '/var/lib/pgsql/9.2/data/pg_hba.conf'
  $packagename96  = 'postgresql96'
  $servicename96  = 'postgresql-9.6'
  $postgresconf96 = '/var/lib/pgsql/9.6/data/postgresql.conf'
  $pghba96        = '/var/lib/pgsql/9.6/data/pg_hba.conf'

when 'Debian'
  $packagename92 = ''
  $servicename92 = ''

else
  $packagename92 = '-_-'
  $servicename92 = '-_-'

end
