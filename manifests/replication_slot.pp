# [root@centos7 ~]# psql -U postgres
# psql (9.6.10)
# Type "help" for help.
#
# postgres=# select * from pg_create_physical_replication_slot('standby_replication_slot');
#         slot_name         | xlog_position
# --------------------------+---------------
#  standby_replication_slot |
# (1 row)
#
# postgres=# SELECT slot_name FROM pg_replication_slots;
#         slot_name
# --------------------------
#  standby_replication_slot
# (1 row)
#
# postgres=#
define postgresql::replication_slot (
                                      $slot_name = $name,
                                      $port      = undef,
                                    ) {
  Postgresql_psql {
    port => $port,
  }

  postgresql_psql { "pg_create_physical_replication_slot ${slot_name}":
    command => "select * from pg_create_physical_replication_slot('${slot_name}')",
    unless  => "SELECT slot_name FROM pg_replication_slots WHERE slot_name='${slot_name}'",
    require => Class['::postgresql::service'],
  }

}
