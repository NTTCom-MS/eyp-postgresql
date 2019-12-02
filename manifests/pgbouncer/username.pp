define postgresql::pgbouncer::username(
                                        $password_md5,
                                        $username = $name,
                                        $order    = '42',
                                      ) {
  concat::fragment{ "postgres pgbouncer userlist ${username}":
    order   => "10-${order}",
    target  => '/etc/pgbouncer/userlist.txt',
    content => template("${module_name}/pgbouncer/user-entry.erb"),
  }
}
