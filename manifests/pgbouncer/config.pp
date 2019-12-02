class postgresql::pgbouncer::config inherits postgresql::pgbouncer {

  concat { '/etc/pgbouncer/pgbouncer.ini':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  concat::fragment{ 'base pgbouncer':
    order   => '00',
    target  => '/etc/pgbouncer/pgbouncer.ini',
    content => template("${module_name}/pgbouncer/pgbouncer.erb"),
  }

  concat { '/etc/pgbouncer/pgbouncer-databases.ini':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  concat::fragment{ 'base pgbouncer databases':
    order   => '00',
    target  => '/etc/pgbouncer/pgbouncer-databases.ini',
    content => template("${module_name}/pgbouncer/databases-header.erb"),
  }

    concat { '/etc/pgbouncer/userlist.txt':
      ensure => 'present',
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
    }
}
