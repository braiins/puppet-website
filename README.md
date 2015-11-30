# website

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with website](#setup)
    * [What website affects](#what-website-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with website](#beginning-with-website)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module configures Django + nginx + postgres based websites.

## Module Description

Django requires robust webserver (nginx) that takes care of processing
http requests and forwarding them to the Django server - served by
gunicorn.

The module configures the each website as follows:

* nginx site
* gunicorn takes care of running the actual django application.
* supervisor configuration manages gunicorn
* database is setup only if it should be present locally. Remote
  configurations rely on the database to be already available on the
  remote machine

## Setup

### What website affects

* the module deploys a new database with admin user only if the
  specified database host points to localhost

### Setup Requirements **OPTIONAL**

If local database setup is use, postgres instance should be already present.

### Beginning with website

The following snippet shows how to instantiate a basic website:

```
    class { 'website': } ->
    website::django_web { 'example.net':
      aliases              => 'example.com',
      http_port            => '80',
      https_port           => undef,
      redirect_to_https    => false,
      main_project_git_uri => 'http://main.project.net/example-project.git',
      main_project_name    => 'example-project,
      main_module_name     => 'example',
      revision             => 'master',
      db_host              => 'localhost',
      db_port              => '5432',
      db_name              => 'db_name',
      db_user              => 'db_user',
      db_password          => 'password',
      nginx_priority       => '60',
      admin_allowed_hosts  => ['1.2.3.4/32'],
    }
```


## Reference

Resources:

* [website::django_web](#resource-websitedjango_web)
* [website::vhost_nginx](#resource-websitevhost_nginx)
* [website::gunicorn](#resource-websitevgunicorn)

## Limitations

The module currently supports only postgres backend and has been
tested on Debian Jessie and puppet 3.8.0

## Development

Patches and improvements are welcome as pull requests for the central
project github repository.
