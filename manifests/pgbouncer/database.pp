# DB= host=1.1.1.1 port=5432 user=postuser dbname=DB
define postgresql::pgbouncer::database(
                                        $host,
                                        $username,
                                        $port            = '5432',
                                        $database        = $name,
                                        $remote_database = $name,
                                        $order           = '42',
                                        $description     = undef,
                                      ) {
  concat::fragment{ "postgres pgbouncer database ${database} ${user}":
    order   => "10-${order}",
    target  => '/etc/pgbouncer/pgbouncer-databases.ini',
    content => template("${module_name}/pgbouncer/database-entry.erb"),
  }
}
