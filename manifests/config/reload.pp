# SELECT pg_reload_conf();
class postgresql::config::reload inherits postgresql {
  Postgresql_psql {
    port => $postgresql::port,
  }

  #TODO: contemplar servei no gestionat

  postgresql_psql { 'pg_reload_conf':
    command     => 'SELECT pg_reload_conf();',
    refreshonly => true,
    require     => Class['::postgresql::service'],
    notify      => Class['::postgresql::service'],
  }
}
