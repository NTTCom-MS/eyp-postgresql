class { 'postgresql':
  wal_level           => 'hot_standby',
  max_wal_senders     => '3',
  checkpoint_segments => '8',
  wal_keep_segments   => '8',
  version             => '10',
  port                => '5610'
}

postgresql::hba_rule { 'test':
  user     => 'demopgss',
  database => 'demopgss',
  address  => '192.168.56.0/24',
}

postgresql::role { 'demopgss':
  replication => true,
  password    => 'demopgsspassword',
}

postgresql::schema { 'demopgss':
  owner => 'demopgss',
}

postgresql::db { 'demopgss':
  owner => 'demopgss',
}

class { 'postgresql::pgstatsstatements':
  dbname => 'demopgss',
}
