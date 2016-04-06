define postgresql::role (
                          $rolename    = $name,
                          $superuser   = false,
                          $replication = false,
                        ) {
  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }


}
