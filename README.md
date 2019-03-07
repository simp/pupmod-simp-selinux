[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/selinux.svg)](https://forge.puppetlabs.com/simp/selinux)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/selinux.svg)](https://forge.puppetlabs.com/simp/selinux)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-selinux.svg)](https://travis-ci.org/simp/pupmod-simp-selinux)

# pupmod-simp-selinux

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with selinux](#setup)
    * [What selinux affects](#what-selinux-affects)
    * [Setup requirements](#setup-requirements)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

Manage active SELinux state and state after a reboot.

## Setup

### What selinux affects

Manages the following:

* The running state of SELinux
* `/etc/selinux/config` file
* SELinux-related packages
    * `mcstrans`
    * `checkpolicy`
    * etc.
* SELinux-related services
    * `mcstrans`
    * `restorecond`

### Setup Requirements

This module requires the following:

* [puppetlabs-stdlib](https://forge.puppet.com/puppetlabs/stdlib)
* [simp-simplib](https://forge.puppet.com/simp/simplib)

## Usage

    class { 'selinux': }

## Reference

### Public Classes

* [selinux](https://github.com/simp/pupmod-simp-selinux/blob/master/manifests/init.pp)

#### Parameters

* **`ensure`** (`Selinux::State`) *(defaults to: 'enforcing')*

The state that SELinux should be in. Since you are calling this class, we assume that you want to enforce.

* **`mode`** (`Enum['targeted','mls']`) *(defaults to: `'targeted'`)*

The SELinux type you want to enforce. Note, it is quite possible that 'mls' will render your system inoperable.

* **`autorelabel`** (`Boolean`) *(defaults to: `false`)*

Automatically relabel the filesystem if needed

* **`manage_utils_package`** (`Boolean`) *(defaults to: `true`)*

If true, ensure policycoreutils-python is installed. This is a supplemental package that is required by semanage.

* **`manage_mcstrans_package`** (`Boolean`)

Manage the `mcstrans` package.

* **`manage_mcstrans_service`** (`Boolean`)

Manage the `mcstrans` service.

* **`mcstrans_service_name`** (`String`)

The `mcstrans` service name.

* **`mcstrans_package_name`** (`String`)

The `mcstrans` package name.

* **`manage_restorecond_package`** (`Boolean`)

Manage the `restorecond` package.

* **`manage_restorecond_service`** (`Boolean`)

Manage the `restorecond` service.

* **`restorecond_package_name`** (`String`)

The `restorecond` package name.

* **`package_ensure`** (`String`) *(defaults to: `simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })`)*

The ensure status of packages to be installed


## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise
Linux and compatible distributions, such as CentOS. Please see the
[`metadata.json` file](./metadata.json) for the most up-to-date list of
supported operating systems, Puppet versions, and module dependencies.

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

If you find any issues, they can be submitted to our
[JIRA](https://simp-project.atlassian.net).
