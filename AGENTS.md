# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-selinux` is a SIMP Puppet module that manages **SELinux state** on
Enterprise Linux systems. It writes `/etc/selinux/config`, drives the live and
post-reboot enforcement state through a custom `selinux_state` type, optionally
pins the SELinux kernel boot parameters, installs the supporting userspace
packages (`checkpolicy`, and optionally `mcstrans` / `restorecond`), manages the
`mcstrans` and `restorecond` services, and can create `selinux_login` mappings.
The heavy lifting of the SELinux policy itself is delegated to the
`simp/vox_selinux` module, which this class always `contain`s.

The module is split into the classic SIMP install/config/service layering behind
a single public entry class. Because changing SELinux state (especially
`disabled` ↔ `enforcing`) requires a relabel and a reboot to fully take effect,
the config class emits a `reboot_notify` whenever the state resource changes
(`manifests/config.pp`).

### Business logic

The module has four classes — `selinux` (public entry), and the private
`selinux::install`, `selinux::config`, `selinux::service` — plus a custom
`Selinux::State` data type and two Ruby types/providers (`selinux_state`,
`selinux_login`).

- **`selinux` (`manifests/init.pp`)** — Public entry class (consumers
  `include 'selinux'`; not `assert_private()`'d). Several parameters have **no
  default in the manifest** and are supplied from module data
  (`data/common.yaml`, `data/os/RedHat.yaml`) — see `init.pp`:
  `$manage_mcstrans_package`, `$manage_mcstrans_service`,
  `$mcstrans_package_name`, `$mcstrans_service_name`,
  `$manage_restorecond_package`, `$manage_restorecond_service`,
  `$restorecond_package_name`. Parameters with in-manifest defaults
  (`init.pp`):
  - `$ensure` (`Selinux::State`, default `'enforcing'`) — the master switch. A
    `Boolean` or one of `enforcing` / `permissive` / `disabled`.
  - `$kernel_enforce` (`Boolean`, default `false`) — whether to also pin the
    SELinux kernel boot parameters.
  - `$autorelabel` (`Boolean`, default `false`) — relabel the filesystem on the
    next boot.
  - `$manage_utils_package` (`Boolean`, default `true`).
  - `$package_ensure` (`String`) — defaults to
    `simplib::lookup('simp_options::package_ensure', { 'default_value' => 'present' })`
    (`init.pp`).
  - `$mode` (`Enum['targeted','mls']`, default `'targeted'`) — the docstring
    warns `mls` can render a system inoperable (`init.pp`).
  - `$login_resources` (`Optional[Hash]`, default `undef`).

  Control flow and resources:
  - `$state` selector (`init.pp`) normalises the `Boolean`/enum `$ensure`
    into a bare string: `true => 'enforcing'`, `false => 'disabled'`, otherwise
    the passed enum.
  - `contain`s `selinux::install`, `selinux::config`, `selinux::service`, and
    `vox_selinux` (`init.pp`), with ordering
    `install -> config ~> service` (`init.pp`).
  - **`selinux_login` creation** (`init.pp`): only when `$login_resources`
    is set **and** the fact `os.selinux.current_mode` is present and not
    `disabled`, it `create_resources('selinux_login', $login_resources)`.

- **`selinux::install` (`manifests/install.pp`)** — its own parameters
  re-derive from the parent via `pick(getvar('selinux::manage_utils_package'), true)`
  and `simplib::lookup('selinux::*')` (`install.pp`). `$package_ensure`
  here has a **nested** default:
  `simplib::lookup('selinux::package_ensure', { 'default_value' => simplib::lookup('simp_options::package_ensure', { 'default_value' => 'present' }) })`
  (`install.pp`). It `ensure_packages` the utils packages
  (`['checkpolicy']`, `install.pp`), and conditionally the `mcstrans`
  and `restorecond` packages (`install.pp`).

- **`selinux::config` (`manifests/config.pp`)** — `assert_private()`.
  Declares `reboot_notify { 'selinux' }` (`config.pp`) and the
  `selinux_state { 'set_selinux_state' }` resource carrying `$selinux::ensure` /
  `$selinux::autorelabel`, notifying the reboot (`config.pp`). Computes
  `$_enabling` / `$_disabling` booleans from the live `os.selinux.enabled` fact
  vs. the desired `$state` (`config.pp`). When `$kernel_enforce`
  (`config.pp`): sets `kernel_parameter { 'selinux' }` to `'0'` when
  disabled, else `'1'`, plus `kernel_parameter { 'enforcing' }` = `'0'` for
  permissive / `'1'` otherwise — each notifying the reboot. Finally writes
  `file { '/etc/selinux/config' }` (mode `0644`) from the EPP template
  `selinux/etc/selinux/config` with `state` and `mode` (`config.pp`).

- **`selinux::service` (`manifests/service.pp`)** — `assert_private()`.
  Chooses `$_aux_service_ensure`: `'stopped'` when the desired state is
  `disabled` **or** SELinux is not currently enabled, else `'running'`
  (`service.pp`). When `$manage_mcstrans_service`, and **only on systemd
  systems** (`service.pp`), if `/proc` is mounted with `hidepid > 0` and a
  GID is set, it asserts the optional `puppet/systemd` dependency and writes a
  `systemd::dropin_file` adding that GID to the service's `SupplementaryGroups`
  (`service.pp`) — the mcstrans daemon needs the GID to see hidden
  `/proc` entries. It then declares the `mcstrans` and (if
  `$manage_restorecond_service`) `restorecond` services at `$_aux_service_ensure`
  (`service.pp`), both requiring `Class['selinux::install']`.

### Gotchas / non-obvious details

- **Several `selinux` parameters have no manifest default** and rely entirely on
  module data being present (`init.pp`; `data/common.yaml`,
  `data/os/RedHat.yaml`). Removing or renaming those Hiera keys breaks
  compilation with a "no default" error, not a silent fallback.
- **`mcstrans` and `restorecond` management is off by default.**
  `selinux::manage_mcstrans_package` / `_service` default to `false`
  (`data/common.yaml`); `selinux::manage_restorecond_package` / `_service`
  default to `false` too — but those latter defaults live in
  `data/os/RedHat.yaml`, not `common.yaml`.
- **A reboot is required to fully apply a state change.** The `selinux_state`
  resource and every `kernel_parameter` notify `reboot_notify { 'selinux' }`
  (`config.pp`). This is why the module cannot flip enforcement purely in a
  single `puppet apply`.
- **`selinux_login` resources are silently skipped** unless the
  `os.selinux.current_mode` fact is present and not `disabled` (`init.pp`) —
  you cannot create login mappings on a host where SELinux is off.
- **The hidepid drop-in is systemd-only and doubly-guarded.** It fires only when
  `'systemd' in init_systems`, `/proc` `hidepid > 0`, and a `/proc` GID is set
  (`service.pp`); only then is `puppet/systemd` asserted as an optional
  dependency.
- **`vox_selinux` does the real policy work.** `selinux` always
  `contain 'vox_selinux'` (`init.pp`); this module manages the surrounding
  state/config/services and the login mappings, not the policy modules
  themselves.
- **`$mode => 'mls'` is dangerous** — the class docstring explicitly warns it
  can render a system inoperable (`init.pp`).
- **`simp/simp_options` is NOT a declared dependency** in `metadata.json`, yet
  the manifests consume the `simp_options::package_ensure` seam via
  `simplib::lookup` (provided by `simp/simplib`). `puppet/systemd` is an
  **optional** dependency, asserted at runtime with
  `simplib::assert_optional_dependency` only on the hidepid path
  (`service.pp`).

## The `simp_options` / `simplib::lookup` seam

The module's SIMP feature-toggle seam is `simp_options::package_ensure`, reached
through `simplib::lookup` with an explicit default:

| File | Key | `default_value` |
|------|-----|-----------------|
| `init.pp` | `simp_options::package_ensure` | `'present'` |
| `install.pp` | `selinux::package_ensure` → `simp_options::package_ensure` | `'present'` (nested lookup) |

Keep routing package-ensure through `simplib::lookup('simp_options::*', {
'default_value' => ... })` with an explicit default rather than assuming
`simp_options` is included. `selinux::install` additionally layers a
module-level `selinux::package_ensure` override on top.

## Dependencies

Module dependencies (from `metadata.json`):

- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0` (provides `ensure_packages()`,
  `member()`)
- `simp/simplib` `>= 4.9.0 < 5.0.0` (provides `simplib::lookup`,
  `simplib::assert_optional_dependency`, `reboot_notify`, `kernel_parameter`,
  and the `simplib__mountpoints` fact)
- `simp/vox_selinux` `>= 3.1.0 < 4.0.0` (the SELinux policy module this class
  `contain`s)

Optional dependency (from `metadata.json` `simp.optional_dependencies`):

- `puppet/systemd` `>= 4.0.2 < 9.0.0` — used only on the systemd hidepid path,
  asserted at runtime with `simplib::assert_optional_dependency`
  (`manifests/service.pp`).

Runtime requirement (from `metadata.json` `requirements`): `openvox
>= 8.0.0 < 9.0.0`. This module already names **openvox** (not `puppet`) as its
runtime requirement, reflecting the SIMP Puppet → OpenVox migration; keep this
line matching `metadata.json`.

Supported OS matrix (from `metadata.json`): CentOS 9/10; RedHat 8/9/10;
OracleLinux 8/9/10; Rocky 8/9/10; AlmaLinux 8/9/10.

## Repository layout

- `manifests/init.pp` — the public `selinux` class; parameters, `$state`
  normalisation, `contain` ordering, `selinux_login` creation.
- `manifests/install.pp` — `selinux::install`; the utils / mcstrans /
  restorecond packages.
- `manifests/config.pp` — `selinux::config` (private); `/etc/selinux/config`,
  `selinux_state`, kernel parameters, `reboot_notify`.
- `manifests/service.pp` — `selinux::service` (private); mcstrans / restorecond
  services and the hidepid systemd drop-in.
- `types/state.pp` — the `Selinux::State` data type
  (`Variant[Boolean, Enum['enforcing','permissive','disabled']]`).
- `lib/puppet/type/selinux_state.rb`, `lib/puppet/provider/selinux_state/selinux_state.rb`
  — custom type/provider driving the live + persistent SELinux state.
- `lib/puppet/type/selinux_login.rb`, `lib/puppet/provider/selinux_login/semanage.rb`
  — custom type/provider for SELinux login mappings via `semanage`.
- `templates/etc/selinux/config.epp` — the `/etc/selinux/config` template
  (`SELINUX=` / `SELINUXTYPE=`).
- `data/common.yaml` — default toggles and the `login_resources` deep-merge
  `lookup_options`.
- `data/os/RedHat.yaml` — RedHat-family overrides (mcstrans service name,
  restorecond package/toggles).
- `hiera.yaml` — module data hierarchy (v5): OS family+major → OS family →
  common.
- `metadata.json` — deps, optional deps, OS matrix, OpenVox requirement.
- `spec/classes/init_spec.rb`, `spec/classes/install_spec.rb` — rspec-puppet
  unit tests.
- `spec/unit/puppet/type/`, `spec/unit/puppet/provider/` — unit tests for the
  custom types and providers.
- `spec/acceptance/suites/default/` — beaker acceptance suites
  (`00_default`, `05_kernel_enforce`, `10_selinux_login`, `99_proc_hidepid`);
  nodesets under `spec/acceptance/nodesets/`.
- `REFERENCE.md` — generated Puppet Strings reference.

- **Acceptance does NOT run in CI right now.** In
  `.github/workflows/pr_tests.yml` the `acceptance` job is **commented out**: it targets the `docker_*` nodesets but is disabled because
  the tests require reboots, which Docker cannot perform. The active jobs are
  six: `puppet-syntax`, `puppet-style`, `ruby-style`, `file-checks`,
  `releng-checks`, and `spec-tests`. To exercise acceptance you must run beaker
  locally against a hypervisor-backed nodeset.

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run a single class spec
bundle exec rspec spec/classes/init_spec.rb

# Run the type/provider unit specs
bundle exec rspec spec/unit/puppet/type/selinux_login_spec.rb

# Puppet lint
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run a beaker acceptance suite locally (needs a reboot-capable hypervisor;
# the CI acceptance job is disabled because Docker cannot reboot)
bundle exec rake beaker:suites[default]
```

The `Gemfile` sets `puppet_version` to `['>= 8', '< 9']` and — per an
in-file comment — **installs both the `openvox` and `puppet` gems** "temporarily
until the puppet dependency is removed from other gems" (`openvox_version`
defaults to `puppet_version`; a loop over `['openvox','puppet']`). Relevant gem pins: `puppetlabs_spec_helper ~> 8.0.0`,
`simp-rake-helpers ~> 5.25.0` (note: this module pins **5.25.0**, not the more
common 5.24.0), `simp-beaker-helpers ~> 2.0.0`. Rubocop is pinned to
`~> 1.88.0`. `spec/spec_helper.rb` requires
`puppetlabs_spec_helper/module_spec_helper`.

## Conventions

- Preserve the `@summary` / `@param` puppet-strings docstrings on the classes —
  they drive `REFERENCE.md`. Regenerate `REFERENCE.md` after changing docs or
  parameters.
- Keep package names, service names, and management toggles in module data
  (`data/common.yaml`, `data/os/*.yaml`), not hard-coded in the manifests. The
  parent `selinux` class deliberately has **no manifest defaults** for the
  mcstrans/restorecond parameters — they must resolve from Hiera.
- Continue routing package-ensure through
  `simplib::lookup('simp_options::package_ensure', { 'default_value' => ... })`
  (and the module-level `selinux::package_ensure` layer) rather than assuming
  `simp_options` is included.
- Guard optional integrations (`puppet/systemd`) with
  `simplib::assert_optional_dependency` and a fact check, as the hidepid path
  does — don't hard-`include` optional modules.
- Keep the private classes private: `selinux::config` and `selinux::service`
  call `assert_private()` (`config.pp`, `service.pp`) — consumers should
  `include 'selinux'`, never the sub-classes directly.
- Several baseline files carry a **puppetsync** notice — e.g. `Gemfile`, `spec/spec_helper.rb`, `.github/workflows/pr_tests.yml`, and the `.gitignore`/`.pdkignore` dotfiles — so they are baseline-managed and the next sync overwrites local edits. Check each file's header for the notice rather than treating this list as exhaustive; push changes to any such file upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used across `manifests/`.
