class postgresql::params {

  case $::osfamily
  {
    'redhat':
    {
      case $::operatingsystemrelease
      {
        /^6.*$/:
        {
        }
        default: { fail("Unsupported RHEL/CentOS version! - ${::operatingsystemrelease}")  }
      }
    }
    default: { fail('Unsupported OS!')  }
  }
}
