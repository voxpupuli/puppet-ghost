class ghost::supervisor {

  ensure_packages(['supervisor'])

  case $::operatingsystem {
    'RedHat', 'CentOS': {
      $supervisor_service = 'supervisord'
      $supervisor_conf  = '/etc/supervisord.conf'
      ensure_resource('concat', $supervisor_conf,{
        notify => Service['supervisor']
        })
      ensure_resource('concat::fragment', 'supervisor_base',
      {
        'target'   => $supervisor_conf,
        'content'  => template('ghost/centos_supervisord_base.conf'),
        'order'    => '01',
      }
      )
    }
    'Ubuntu': {
      $supervisor_service = 'supervisor'
    }
    default: {
      fail("${::operatingsystem} is not yet supported, please fork and fix (or
      make an issue).")
    }
  }
  service { 'supervisor':
    ensure    => running,
    name      => $supervisor_service,
    enable    => true,
    require   => Package['supervisor'],
  }
}
