postgresql::role { 'demo':
  password => 'demopass',
}

postgresql::db { 'demo':
  owner         => 'demo',
  pgbouncer_tag => 'demopgbouncer',
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
  realize_dbs_tag        => 'demopgbouncer',
  set_pgbouncer_password => 'pgbouncer',
  enable_auth_query      => true,
  verbose                => 2,
}
