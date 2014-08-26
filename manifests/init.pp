# == Class: ghost
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
# Deprecation notice: the create_resources with hiera_hash has been
# deprecated, see [issue
# #16](https://github.com/andschwa/puppet-ghost/issues/16); please
# setup your own resource creation in your roles/profiles.
#
# === Copyright
#
# Copyright 2014 Andrew Schwartzmeyer

class ghost(
  $user  = 'ghost',       # Ghost should run as its own user
  $group = 'ghost',       # Ghost GID and group to create
  $home  = '/home/ghost', # Ghost user's home directory, default base for blogs
  ) {

  validate_string($user)
  validate_string($group)
  validate_absolute_path($home)

  include ghost::setup

  Ghost::Blog <| |> {
    require => Class['ghost::setup']
  }
}
