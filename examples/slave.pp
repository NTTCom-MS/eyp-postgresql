class { 'postgresql':
  wal_level           => 'hot_standby',
  max_wal_senders     => '3',
  checkpoint_segments => '8',
  wal_keep_segments   => '8' ,
  hot_standby         => true,
  initdb              => false,
  version             => '11',
}

class { 'postgresql::recoveryconf':
  masterhost     => '192.168.56.11',
  masterusername => 'replicator',
  masterpassword => 'replicatorpassword',
}
