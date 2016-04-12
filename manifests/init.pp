# == Class: postgresql
#
# === postgresql documentation
#
class postgresql(
                  #general
                  $version                         = $postgresql::params::version_default,
                  $datadir                         = $postgresql::params::datadir_default,
                  # install
                  $initdb                          = true,
                  $overcommit_memory               = '2',
                  $shmmax                          = undef,
                  $shmall                          = undef,
                  # config
                  $listen                          = [ '*' ],
                  $port                            = $postgresql::params::port_default,
                  $max_connections                 = '100',
                  $wal_level                       = 'hot_standby',
                  $max_wal_senders                 = '0',
                  $checkpoint_segments             = '10',
                  $wal_keep_segments               = '0',
                  $hot_standby                     = false,
                  $pidfile                         = $postgresql::params::servicename[$version],
                  $log_directory                   = $postgresql::params::log_directory_default,
                  $log_filename                    = $postgresql::params::log_filename_default,
                  $track_activities                = true,
                  $track_counts                    = true,
                  $autovacuum                      = true,
                  $autovacuum_vacuum_scale_factor  = '0.0',
                  $autovacuum_vacuum_threshold     = '5000',
                  $autovacuum_analyze_scale_factor = '0.0',
                  $autovacuum_analyze_threshold    = '5000',
                  $timezone                        = $postgresql::params::timezone_default,
                  $log_timezone                    = $postgresql::params::timezone_default,
                  $superuser_reserved_connections  = '5',
                  $archive_mode                    = false,
                  $archive_command_custom          = undef,
                  $archive_dir                     = undef,
                  $archive_timeout                 = '0',
                  $archived_wals_retention         = '+7',
                  $archived_wals_hour              = '0',
                  $archived_wals_minute            = '0',
                  $archived_wals_month             = '*',
                  $archived_wals_monthday          = '*',
                  $archived_wals_weekday           = '*',
                  $maintenance_work_mem            = '10MB',
                  $wal_buffers                     = '-1',
                  $work_mem                        = '8MB',
                  # service
                  $manage_service                  = true,
                ) inherits postgresql::params {

  validate_array($listen)

  if($archive_dir!=undef)
  {
    validate_absolute_path($archive_dir)

    exec { "mkdir -p ${archive_dir} postgres archive command ${version} ${datadir}":
      command => "mkdir -p ${archive_dir}",
      creates => $archive_dir,
      before  => Class['::postgresql::config'],
    }

    if($archive_dir!=undef and $archive_command_custom==undef)
    {
      $archive_comand="test ! -f ${archive_dir}/%f && cp %p ${archive_dir}/%f"
    }

    if($archive_dir!=undef and $archive_command_custom!=undef)
    {
      $archive_comand=$archive_command_custom
    }

    if($archived_wals_retention!=undef)
    {
      cron { "cronjob purge walls ${$archived_wals_retention} postgres ${archive_dir}":
        ensure   => 'present',
        command  => "find ${archive_dir} -type f -mtime ${archived_wals_retention} -delete",
        user     => 'root',
        hour     => $archived_wals_hour,
        minute   => $archived_wals_minute,
        month    => $archived_wals_month,
        monthday => $archived_wals_monthday,
        weekday  => $archived_wals_weekday,
        before   => Class['::postgresql::config'],
      }
    }
  }
  else
  {
    $archive_comand=undef
  }


  class { '::postgresql::install':
    version           => $version,
    datadir           => $datadir,
    initdb            => $initdb,
    overcommit_memory => $overcommit_memory,
    shmmax            => $shmmax,
    shmall            => $shmall,
  } ->

  class { '::postgresql::config':
    version                         => $version,
    datadir                         => $datadir,
    listen                          => $listen,
    port                            => $port,
    max_connections                 => $max_connections,
    wal_level                       => $wal_level,
    max_wal_senders                 => $max_wal_senders,
    checkpoint_segments             => $checkpoint_segments,
    wal_keep_segments               => $wal_keep_segments,
    hot_standby                     => $hot_standby,
    log_directory                   => $log_directory,
    log_filename                    => $log_filename,
    track_activities                => $track_activities,
    track_counts                    => $track_counts,
    autovacuum                      => $autovacuum,
    autovacuum_vacuum_scale_factor  => $autovacuum_vacuum_scale_factor,
    autovacuum_vacuum_threshold     => $autovacuum_vacuum_threshold,
    autovacuum_analyze_scale_factor => $autovacuum_analyze_scale_factor,
    autovacuum_analyze_threshold    => $autovacuum_analyze_threshold,
    timezone                        => $timezone,
    log_timezone                    => $log_timezone,
    superuser_reserved_connections  => $superuser_reserved_connections,
    archive_mode                    => $archive_mode,
    archive_command                 => $archive_comand,
    archive_timeout                 => $archive_timeout,
    maintenance_work_mem            => $maintenance_work_mem,
    wal_buffers                     => $wal_buffers,
    work_mem                        => $work_mem,
  } ~>

  class { '::postgresql::service':
    version        => $version,
    manage_service => $manage_service,
  } ->

  Class['::postgresql']

}
