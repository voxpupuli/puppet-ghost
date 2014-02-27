class ghost::supervisor {

  ensure_packages(['supervisor'])

  service { 'supervisor':
    ensure    => running,
    enable    => true,
    require   => Package['supervisor'],
  }
}
