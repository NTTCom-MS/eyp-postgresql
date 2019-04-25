class { 'postgresql':
  wal_level           => 'hot_standby',
  max_wal_senders     => '3',
  checkpoint_segments => '8',
  wal_keep_segments   => '8',
  port                => '5432',
  version             => '9.6',
}

postgresql::hba_rule { 'test':
  user     => 'replicator',
  database => 'replication',
  address  => '192.168.56.0/24',
}

postgresql::role { 'replicator':
  replication => true,
  password    => 'replicatorpassword',
}

postgresql::schema { 'jordi':
  owner => 'replicator',
}
