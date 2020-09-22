[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/selinux.svg)](https://forge.puppetlabs.com/simp/selinux)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/selinux.svg)](https://forge.puppetlabs.com/simp/selinux)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-selinux.svg)](https://travis-ci.org/simp/pupmod-simp-selinux)

# pupmod-simp-selinux

#### Table of Contents

<!-- vim-markdown-toc GFM -->

* [Description](#description)
* [Setup](#setup)
  * [What selinux affects](#what-selinux-affects)
* [Usage](#usage)
* [Reference](#reference)
* [Limitations](#limitations)
* [Development](#development)

<!-- vim-markdown-toc -->

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

## Usage

    include 'selinux'

## Reference

See the [REFERENCE.md][./REFERENCE.md] for a comprehensive overview of the
module components.

## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise
Linux and compatible distributions, such as CentOS. Please see the
[`metadata.json` file](./metadata.json) for the most up-to-date list of
supported operating systems, Puppet versions, and module dependencies.

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

If you find any issues, they can be submitted to our
[JIRA](https://simp-project.atlassian.net).
