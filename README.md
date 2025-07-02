# Vagrant WSL2 Shim

A set of Fish shell scripts to wrap `vagrant` invocations with, which will
temporarily run Vagrant in an `unshare -m`'ed environment where a fake
`/proc/version` file is bind-mounted in place, hiding the fact that Vagrant is
running inside WSL2.

This works around Vagrant's check for WSL, which works by just scanning
`/proc/version` for the string `microsoft`. Until [hashicorpt/vagrant#12328][vagrant-pull-12328]
gets merged, this is the cleanest way to run Vagrant on WSL2 with nested
virtualization, using VirtualBox _inside_ of WSL2, short of recompiling Vagrant
with that check removed.

[vagrant-pull-12328]: https://github.com/hashicorp/vagrant/pull/12328

The whole point of this is that WSL2 uses Hyper-V, so VirtualBox on Windows is
forced to use slow software emulation. In my testing, it's both easier and more
performant to just use VirtualBox _inside_ of WSL2 through nested virtualization.
However, Vagrant doesn't yet expect this use case, so we need to work around its
check for WSL2 somehow.

## Usage

Prepend all invocations to `vagrant` with `wsl2-lies.fish`. For example:

```shell
wsl2-lies.fish vagrant up
wsl2-lies.fish vagrant ...
```

`vagrant` will be run with whatever user permissions you have (so
`sudo wsl2-lies.fish vagrant ...` should still work as expected.). Most 
environment variables should be preserved (it use's `sudo -E`). Performance
is technically reduced, due to the shim setting up a new `unshare`-ed bind
mount each time it's called, but it shouldn't affect the actual `vagrant` binary
too much.

## Dependencies

- `fish` shell (sorry, but it's what I use)
- `unshare`, which comes from the `util-linux` package and can be downloaded
  from the [Linux Kernel Archive](https://www.kernel.org/pub/linux/utils/util-linux/).
- `setpriv`, which also comes from the `util-linux` package and is installed on
  newer Debian's by default.

