# DB= host=1.1.1.1 port=5432 user=postuser dbname=DB
define postgresql::pgbouncer::database(
                                        $host,
                                        $username        = undef,
                                        $port            = '5432',
                                        $database        = $name,
                                        $remote_database = $name,
                                        $order           = '42',
                                        $description     = undef,
                                        $auth_user       = undef,
                                        $enable_get_auth = false,
                                      ) {
  concat::fragment{ "postgres pgbouncer database ${database} ${username}":
    order   => "10-${order}",
    target  => '/etc/pgbouncer/pgbouncer-databases.ini',
    content => template("${module_name}/pgbouncer/database-entry.erb"),
  }

  if($enable_get_auth)
  {
    postgresql_psql { 'pgbouncer user_authentication':
      command => '/etc/pgbouncer/.user_authentication.sql',
      unless  => 'SELECT p.proname FROM pg_proc p WHERE p.proname=\'get_auth\'',
      db      => $database,
      require => [ Class['::postgresql::service'], File['/etc/pgbouncer/.user_authentication.sql'] ],
    }
  }
}
