class postgresql::service (
                        $manage_service        = true,
                        $manage_docker_service = true,
                        $ensure                = 'running',
                        $enable                = true,
                        $version               = $postgresql::params::version_default,
                      ) inherits postgresql::params {

  #
  validate_bool($manage_docker_service)
  validate_bool($manage_service)
  validate_bool($enable)

  validate_re($ensure, [ '^running$', '^stopped$' ], "Not a valid daemon status: ${ensure}")

  if($manage_service)
  {
    #https://docs.puppet.com/puppet/latest/reference/function.html#defined
    if(defined('$::eyp_docker_iscontainer'))
    {
      if(getvar('::eyp_docker_iscontainer')==false or
          getvar('::eyp_docker_iscontainer') =~ /false/ or
          $manage_docker_service)
      {
        service { $postgresql::params::servicename[$version]:
          ensure => $ensure,
          enable => $enable,
        }
      }
    }
    else
    {
      service { $postgresql::params::servicename[$version]:
        ensure => $ensure,
        enable => $enable,
      }
    }
  }

}
