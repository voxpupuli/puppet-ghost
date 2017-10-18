# ghost::setup
#
# @summary This class includes nodejs if not already defined, and creates the
#  ghost user and group. Private class.
#
# Copyright 2014 Andrew Schwartzmeyer
class ghost::setup {

  assert_private()

  if $ghost::include_nodejs {
    include nodejs
  }

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
