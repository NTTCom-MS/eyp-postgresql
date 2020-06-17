# [root@ip-172-31-33-72 puppet-masterless]# ./localpuppetmaster.sh -d /tmp/postgres -r https://github.com/jordiprats/eyp-postgresql -s /tmp/postgres/modules/postgresql/examples/pgbouncer_standalone_demo.pp
#
# Checking Puppetfile syntax:
# Syntax OK
# Cleanup postgresql module
# Notice: Preparing to uninstall 'eyp-postgresql' ...
# Removed 'eyp-postgresql' (v0.5.1) from /tmp/postgres/modules
# Installing puppet module using a Puppetfile
# Installing dependencies
# Dependencies installed
# Warning: The string '3787.804688' was automatically coerced to the numerical value 3787.804688 (file: /tmp/postgres/modules/postgresql/manifests/init.pp, line: 33, column: 62)
# Warning: The string '3787.804688' was automatically coerced to the numerical value 3787.804688 (file: /tmp/postgres/modules/postgresql/manifests/init.pp, line: 34, column: 70)
# Warning: The string '4096' was automatically coerced to the numerical value 4096 (file: /tmp/postgres/modules/postgresql/manifests/init.pp, line: 34, column: 110)
# Warning: The string '3787.804688' was automatically coerced to the numerical value 3787.804688 (file: /tmp/postgres/modules/postgresql/manifests/init.pp, line: 107, column: 77)
# Warning: The string '946.951172' was automatically coerced to the numerical value 946.951172 (file: /tmp/postgres/modules/postgresql/manifests/init.pp, line: 118, column: 77)
# Notice: Compiled catalog for ip-172-31-33-72.eu-west-1.compute.internal in environment production in 0.37 seconds
# Notice: Applied catalog in 0.73 seconds
# [root@ip-172-31-33-72 puppet-masterless]# psql -U demo -p 6432 -h 127.0.0.1  -d demo
# Password for user demo:
# psql (11.8)
# Type "help" for help.
#
# demo=>


postgresql::role { 'demo':
  password => 'demopass',
}

postgresql::db { 'demo':
  owner         => 'demo',
  pgbouncer_tag => 'demopgbouncer',
}

postgresql::hba_rule { 'postgres trust localhost':
  user        => 'postgres',
  database    => 'all',
  address     => '127.0.0.1/32',
  auth_method => 'trust',
  order       => 0,
}

postgresql::hba_rule { 'all':
  user     => 'all',
  database => 'all',
  address  => "127.0.0.1/32",
}

class { 'postgresql':
  wal_level                       => 'hot_standby',
  max_wal_senders                 => '3',
  checkpoint_segments             => '8',
  wal_keep_segments               => '8',
  version                         => '11',
  add_nagios_checks               => false,
  add_hba_default_localhost_rules => false,
}

class { 'postgresql::pgbouncer':
  pool_mode              => 'transaction',
  default_pool_size      => 20,
  realize_dbs_tag        => 'demopgbouncer',
  set_pgbouncer_password => 'pgbouncer',
  enable_auth_query      => true,
}
