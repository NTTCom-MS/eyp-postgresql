
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

  $packagename10  = 'postgresql10'
  $servicename10  = 'postgresql-10'
  $postgresconf10 = '/var/lib/pgsql/10/data/postgresql.conf'
  $pghba10        = '/var/lib/pgsql/10/data/pg_hba.conf'

  $packagename11  = 'postgresql11'
  $servicename11  = 'postgresql-11'
  $postgresconf11 = '/var/lib/pgsql/11/data/postgresql.conf'
  $pghba11        = '/var/lib/pgsql/11/data/pg_hba.conf'

when 'Debian'
  $packagename92 = ''
  $servicename92 = ''

else
  $packagename92 = '-_-'
  $servicename92 = '-_-'

end
