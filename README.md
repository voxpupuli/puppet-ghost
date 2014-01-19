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

    include ghost

### Usage

This module has one class, `ghost`, with the following
parameters:

    $user             = 'ghost',
    $group            = 'ghost',
    $archive          = '/tmp/ghost.zip',
    $source           = 'https://ghost.org/zip/ghost-latest.zip',
    $home             = '/opt/ghost',
    $manage_nodejs    = true, # Install PPA and package
    $use_supervisor   = true, # Use supervisor to manage Ghost
    $autostart        = true, # Supervisor - Start at boot
    $autorestart      = true, # Supervisor - Keep running
    $environment      = 'production', # Supervisor - Ghost config environment to run
    $stdout_logfile   = '/var/log/supervisor/ghost.log',
    $stderr_logfile   = '/var/log/supervisor/ghost_err.log',
    $supervisor_conf  = '/etc/supervisor/conf.d/ghost.conf',

    # Parameters below affect Ghost's config through the template
    $manage_config    = true, # Manage Ghost's config.js
    $development_url  = 'http://my-ghost-blog.com',
    $development_host = '127.0.0.1',
    $development_port = 2368,

    $production_url   = 'http://my-ghost-blog.com',
    $production_host  = '127.0.0.1',
    $production_port  = 2368,

## Limitations

This module currently only supports Ubuntu. It is working on my
Vagrant box, Ubuntu 12.04.4 LTS with Puppet 3.4.1, and as such it's
development is on hold. If interest is expressed, I'd like to make it
cross-platform, with built-in nginx proxying, along with alternatives
to supervisor, such as [forever](https://npmjs.org/package/forever)
and/or an init script.

## Development

Fork on
[GitHub](https://github.com/andschwa/puppet-ghost), make
a Pull Request.
