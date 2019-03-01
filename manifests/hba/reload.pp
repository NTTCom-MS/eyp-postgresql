# SELECT pg_reload_conf();
class postgresql::hba::reload inherits postgresql {
  Postgresql_psql {
    port => $postgresql::port,
  }

  postgresql_psql { "pg_reload_conf":
    command     => "SELECT pg_reload_conf();",
    require     => Class['::postgresql::service'],
    refreshonly => true,
  }
}
