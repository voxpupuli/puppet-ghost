# andschwa-ghost

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup - The basics of getting started with andschwa-ghost](#setup)
    * [What andschwa-ghost affects](#what-andschwa-ghost-affects)
    * [Beginning with andschwa-ghost](#beginning-with-andschwa-ghost)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module installs the Ghost Blogging Platform.

It is in beta development and tested on Ubuntu 12.04 and 14.04,
loosely tested on CentOS.

## Module Description

This module is intended for Ubuntu. It essentially follows the
[Linux docs](http://docs.ghost.org/installation/linux/) and
[deployment instructions](http://docs.ghost.org/installation/deploy/)
by using wget to grab the latest Ghost distribution, unzips it, runs
`npm install --production`, configures the config file via a template
(if desired), adds a
[proletaryo/supervisor](https://github.com/proletaryo/puppet-supervisor/)
program to run Ghost, includes
[puppetlabs/nodejs](https://github.com/puppetlabs/puppetlabs-nodejs/)
class, adds the ghost user and group, and finally starts ghost.

## Setup

### What andschwa-ghost affects

* Packages
  * `nodejs`
	* `npm`
	* `unzip`
	* `curl`
	* `supervisor`
* Services
    * `supervisor`
* Files
    * `/home/ghost/`
    * `/etc/supervisor/conf.d/ghost_<blog>.conf`
* User
    * `ghost`
* Group
    * `ghost`

### Beginning with andschwa-ghost

The simplest use of this module is:

```puppet
class { 'ghost':
  include_nodejs => true,
} -> ghost::blog { 'my_blog': }
```

#### Ghost Blog Profile

If you just want a working ghost instance, and just want some sensible
defaults and hosted by nginx, you can use the
[ghost_blog_profile](https://github.com/petems/petems-ghost_blog_profile). This
uses this module and sets up a ghost blog to work end-to-end.

```
class { 'ghost_blog_profile::basic':
  blog_name => 'my_blog',
}
```

Here is an alternative
[Puppet profile](https://github.com/andschwa/puppet-profile/blob/master/manifests/ghost.pp)
for a Ghost blog with Nginx.

### Usage

This module has one main class, `ghost`, with the following
parameters:

```puppet
$user           = 'ghost',                       # Ghost should run as its own user
$group          = 'ghost',                       # Ghost GID and group to create
$home           = '/home/ghost',                 # Ghost user's home directory, default base for blogs
$include_nodejs = false,                         # Whether or not setup should include nodejs module
```

It delegates the user and group resources to `ghost::setup`, which
creates the user and group you specify (ghost by default) and installs
nodejs and `npm` using the
[puppetlabs-nodejs](https://forge.puppetlabs.com/puppetlabs/nodejs)
module.

Ghost requires an up-to-date nodejs, which can be done automatically
by setting that class's `manage_repo` parameter to true. If the
`nodejs` class is not defined elsewhere, this module will simply
include it.

The module has one main resource, `ghost::blog`, with the following
parameters:

```puppet
$user   = 'ghost',                          # Ghost instance should run as its own user
$group  = 'ghost',
$home   = "/home/ghost/${title}",           # Root of Ghost instance (will be created if itdoesnot already exist)
$source = 'https://ghost.org/zip/ghost-latest.zip', # Source for ghost distribution
$use_supervisor = true, # User supervisor module to setup service for blog
$autorestart    = true, # Restart on crash
$stdout_logfile = "/var/log/ghost_${title}.log",
$stderr_logfile = "/var/log/ghost_${title}_err.log",
$manage_config = true, # Manage Ghost's config.js
$url    = 'https://my-ghost-blog.com', # Required URL of blog
$host   = '127.0.0.1',                 # Host to listen on if not using socket
$port   = '2368',                      # Port of host to listen on
$socket = false,                       # Set to false to use host and port
$transport    = '', # Mail transport
$fromaddress  = '', # Mail from address
$mail_options = {}, # Hash for mail options
```

Note that at least on my Ubuntu test systems, the `supervisor`
module's execution of `supervisorctl update` fails; this can be fixed
by manually running that command, letting it do its thing, and then
re-provisioning.

You will likely want to proxy the Ghost instance using, say,
`nginx`. The setup of `nginx` is outside the scope of this module.

## Limitations

* This module only officially supports Ubuntu, but ought to work with
other operating systems as well.

* If managing the blog's `config.js` via this module, you cannot
currently setup custom databases

* The socket file created by Ghost must be readable by the web server
(perhaps Nginx) for communication to take place, but its default
permissions of 660 do not allow this. Because the Ghost server creates
the socket file on each launch, it is impossible to control its
permissions through Puppet. The best solution to this predicament
[(see issue #14)](https://github.com/andschwa/puppet-ghost/issues/14)
is to add your web server's user to Ghost's group (e.g. `usermod -a -G
ghost www-data`), which will allow it to read the socket.

* If supervisor is not registering the blogs, restarting your system is
the easiest solution (as always), but you should also try
`supervisorctrl reread && supervisorctl reload`.

## Upgrading from 0.3.x

The `npm` registry management has been removed. If more advanced setup
of Node.js is required, use the
[puppetlabs/nodejs](https://forge.puppetlabs.com/puppetlabs/nodejs)
module directly.

The blog resource now uses host and port by default, same as Ghost's
defaults. If you were using sockets and would like to continue to do
so, set the appropriate parameter explicitly:

```
ghost::blog { 'my_blog':
    socket => true
}
```

Beware that supervisord will be replaced with systemd in the 1.0.0
release.

## Upgrading from 0.2.x

There are not many changes from 0.2.0 except the following:

* npm registry management is now done in the `ghost::blog` type, and
is controlled by the `npm_registry` parameter
* setting up node using the pupppetlabs-nodejs module is now disabled
by default, and can be enabled by the use of the `manage_nodejs` parameter


## Upgrading from 0.1.x

To upgrade to 0.2.x from 0.1.x, you need to be aware of some major
changes:

- The license has changed from MIT to GNU Affero
- The Ghost source parameter has been moved to `ghost::blog`
- Blog's can have different settings for `home` (root of Ghost)
- The
  [proletaryo/supervisor](https://github.com/proletaryo/puppet-supervisor/)
  module is now used to create a supervisor program in a
  cross-platform manner
- The
  [puppetlabs/nodejs](https://github.com/puppetlabs/puppetlabs-nodejs/)
  module is now used to install nodejs and npm in a cross-platform
  manner
- The 'development' config settings have been removed, in favor of
  setting up only production `url`, `host`, and `port` parameters
- By default, Ghost is now setup to listen on a Unix socket at the
  location of the `socket` parameter (false disables this and falls
  back to host and port)
- For most common uses, the socket file must have 'other' read/write
  permissions, and this is done with an exec because Ghost creates the
  socket file (Puppet is incapable of this)
- Mail parameters `transport`, `fromaddress`, and a `mail_options`
  hash can be specified for each blog
- The `wget` module dependency has been deprecated in favor of a
  simple call to `curl`

## Development

Fork on [GitHub](https://github.com/andschwa/puppet-ghost), make a
Pull Request.
