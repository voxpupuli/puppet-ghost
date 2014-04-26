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

It is in alpha development and tested on Ubuntu 12.04.

## Module Description

This module is intended for Ubuntu. It essentially follows the
[Linux docs](http://docs.ghost.org/installation/linux/) and
[deployment instructions](http://docs.ghost.org/installation/deploy/)
by using wget to grab the latest Ghost distribution, unzips it, runs
`npm --install`, configures the config file via a template, installs
and configures supervisor to keep Ghost running, adds Chris Lea's
nodejs PPA, installs the nodejs package, adds the ghost user and
group, and finally starts ghost.

## Setup

### What andschwa-ghost affects

* Packages
    * `nodejs`
	* `unzip`
	* `supervisor`
* PPAs
    * `ppa:chris-lea/node.js`
* Services
    * `supervisor`
* Files
    * `/opt/ghost`
    * `/etc/supervisor/conf.d/ghost.conf`
* User
    * `ghost`
* Group
    * `ghost`

### Beginning with andschwa-ghost

The simplest use of this module is:

```puppet
class { ghost:
  blogs => {
    # The name, url, and port must be different per instance!
    'blog_one' => {
      'production_url'  => 'http://my-first-ghost-blog.com',
      'production_port' => 2368
    }
}
```

### Usage

This module has one main class, `ghost`, with the following
parameters:

```puppet
$user          = 'ghost',
$group         = 'ghost',
$home          = '/opt/ghost',
$archive       = "${home}/ghost.zip",
$source        = 'https://ghost.org/zip/ghost-latest.zip',
$manage_nodejs = true, # Install PPA and package
$blogs         = {},   # Hash of blog resources to create
$blog_defaults = {},   # Hash of defaults to apply to blog resources
```

You can set `$manage_nodejs` to false if you wish to manually install
`nodejs`.

The module has one main resource, `ghost::blog`, with the following
parameters:

```puppet
$blog             = $title,       # Subdirectory and conf name for blog
$use_supervisor   = true,         # Use supervisor to manage Ghost
$autostart        = true,         # Supervisor - Start at boot
$autorestart      = true,         # Supervisor - Keep running
$environment      = 'production', # Supervisor - Ghost config environment to run
 # Parameters below affect Ghost's config through the template
$manage_config    = true, # Manage Ghost's config.js

 # For a working blog, these must be specified and different per instance
$production_url   = 'http://my-ghost-blog.com',
$production_host  = '127.0.0.1',
$production_port  = 2368,

 # These are used when ${environment} is set to 'development'
$development_url  = 'http://my-ghost-blog.com',
$development_host = '127.0.0.1',
$development_port = 2368,

 # Mail settings (see http://docs.ghost.org/mail/)
$transport        = undef, # Mail transport
$fromaddress      = undef, # Mail from address
$mail_options     = {},    # Hash for mail options
```

These resources can be declared using Hiera by providing a hash to
`ghost::blogs` specifying the blog resources and their parameters,
like this:

```yaml
ghost::blogs:
  blog_one:
    production_url: http://my-first-ghost-blog.com
    transport: SMTP
	fromaddress: myemail@address.com
	mail_options:
	  auth:
        user: youremail@gmail.com
        pass: yourpassword
  blog_two:
    production_url: http://my-second-ghost-blog.com
    production_port: 2369
```

It is *imperative* that each separate instance has a different URL and
port. If not using the development environment, it is not necessary to
change its URL and port.

You can disable management of the `config.js` file by setting
`$manage_config` to false.

You can disable the use and setup of `supervisor` by setting
`$use_supervisor` to false.

You will likely want to proxy these using, say, `nginx`. Although the
inclusion of `nginx` is outside the scope of this module, if you are
using the [jfryman/nginx](https://forge.puppetlabs.com/jfryman/nginx)
module, you can declare the virtual hosts to proxy the blogs via Hiera
like so:

```yaml
nginx::nginx_vhosts:
  my-first-ghost-blog.com:
    proxy: http://127.0.0.1:2368
    proxy_set_header:
      - Host $http_host
      - X-Forwarded-Proto $scheme
      - X-Forwarded-For $proxy_add_x_forwarded_for
      - X-Real-IP $remote_addr
  my-second-ghost-blog.com:
    proxy: http://127.0.0.1:2369
    proxy_set_header:
      - Host $http_host
      - X-Forwarded-Proto $scheme
      - X-Forwarded-For $proxy_add_x_forwarded_for
      - X-Real-IP $remote_addr
```

## Limitations

This module currently only supports Ubuntu. It is working on my
Vagrant box, Ubuntu 12.04.4 LTS with Puppet 3.4.2, and as such it's
development is on hold. If interest is expressed, I'd like to make it
cross-platform, with built-in nginx proxying, along with alternatives
to supervisor, such as [forever](https://npmjs.org/package/forever)
and/or an init script.

If managing the blog's `config.js` via this module, you cannot
currently setup Postgres. There is also no mail setup via the
template.

If supervisor is not registering the blogs, restarting your system is
the easiest solution.

## Upgrading from 0.x

To upgrade to 0.1.x from 0.x, you need to be aware of several changes:
instead of the class setting up one blog, it now sets up the necessary
framework to use the `ghost::blog` resource to set up multiple
blogs. You will need to move the class's blog-dependent parameters into a new
declaration of said resource.

## Development

Fork on
[GitHub](https://github.com/andschwa/puppet-ghost), make
a Pull Request.
