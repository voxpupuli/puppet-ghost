class ghost::setup {
  group { $ghost::group:
    ensure => present,
  }

  user { $ghost::user:
    ensure     => present,
    gid        => $ghost::group,
    home       => $ghost::home,
    managehome => true,
    require    => Group[$ghost::group],
  }
}
