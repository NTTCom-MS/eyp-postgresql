postgresql::role { 'demo':
  password => 'demopass',
}

postgresql::db { 'demo':
  owner         => 'demo',
  pgbouncer_tag => 'demopgbouncer',
}

class { 'postgresql':
  wal_level           => 'hot_standby',
  max_wal_senders     => '3',
  checkpoint_segments => '8',
  wal_keep_segments   => '8',
  version             => '11',
  add_nagios_checks   => false,
}

class { 'postgresql::pgbouncer':
  realize_dbs_tag        => 'demopgbouncer',
  set_pgbouncer_password => 'pgbouncer',
  enable_auth_query      => true,
}
