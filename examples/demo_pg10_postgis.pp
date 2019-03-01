class { 'postgresql':
  wal_level           => 'hot_standby',
  max_wal_senders     => '3',
  checkpoint_segments => '8',
  wal_keep_segments   => '8',
  version             => '10',
  port                => '5436'
}

postgresql::hba_rule { 'test':
  user     => 'demopostgis',
  database => 'demopostgis',
  address  => '192.168.56.0/24',
}

postgresql::role { 'demopostgis':
  replication => true,
  password    => 'demopostgispassword',
  port        => '5436'
}

postgresql::schema { 'demopostgis':
  owner => 'demopostgis',
  port  => '5436'
}

postgresql::db { 'demopostgis':
  owner => 'demopostgis',
}

class { 'postgresql::postgis':
  dbname => 'demopostgis',
}
