class ghost::setup {

  group { $ghost::group:
    ensure => present,
  }

  user { $ghost::user:
    ensure     => present,
    gid        => $ghost::group,
    home       => $ghost::home,
    managehome => true,
    shell      => $ghost::shell,
    require    => Group[$ghost::group],
  }

  wget::fetch { 'ghost':
    source      => $ghost::source,
    destination => $ghost::archive,
    user        => $ghost::user,
  }
}
