#
# compatibility - please use postgresql::recoveryconf instead
#
class postgresql::streaming_replication (
                                          $masterhost               = undef,
                                          $masterusername           = undef,
                                          $masterpassword           = undef,
                                          $masterport               = $postgresql::params::port_default,
                                          $datadir                  = $postgresql::datadir,
                                          $restore_command          = undef,
                                          $archive_cleanup_command  = undef,
                                          $recovery_min_apply_delay = undef,
                                          $primary_slot_name        = undef,
                                        ) inherits postgresql::params {
  class { 'postgresql::recoveryconf':
    masterhost               => $masterhost,
    masterusername           => $masterusername,
    masterpassword           => $masterpassword,
    masterport               => $masterport,
    datadir                  => $datadir,
    restore_command          => $restore_command,
    archive_cleanup_command  => $archive_cleanup_command,
    recovery_min_apply_delay => $recovery_min_apply_delay,
    primary_slot_name        => $primary_slot_name,
  }
}
