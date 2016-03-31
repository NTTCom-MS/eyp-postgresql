# == Class: postgresql
#
# === postgresql documentation
#
class postgresql inherits postgresql::params{

  # service definition and notification:
  #
  # notify => Class['postgresql::service'],
  # class { 'postgresql::service': }

}
