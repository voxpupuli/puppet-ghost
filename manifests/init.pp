# ghost
#
# @summary A module to manage the Ghost blog platform
#
# This class sets up a default Ghost user that can be used (and is by
# default) to separate the permissions of blogs. This class is
# optional, but if not used, the dependencies of nodejs, npm, and the
# specified user and group for each blog must be satisfied.
#
# This module includes puppetlabs/nodejs to install node and npm;
# however, on operating systems with out-of-date packages, you may
# need to set nodejs::manage_repo to true.
#
# @param user Default ghost username
# @param group Default ghost group
# @param home Ghost user's home directory, default base for blogs
# @param include_nodejs Whether or not setup should include nodejs module
#
# === Copyright
#
# Copyright 2014 Andrew Schwartzmeyer
#
class ghost (
  String $user               = 'ghost',
  String $group              = 'ghost',
  Stdlib::Absolutepath $home = '/home/ghost',
  Boolean $include_nodejs    = false,
) {
  contain ghost::setup

  Ghost::Blog <| |> {
    require => Class['ghost::setup']
  }
}
