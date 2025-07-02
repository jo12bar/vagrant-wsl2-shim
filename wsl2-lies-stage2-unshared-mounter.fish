#!/usr/bin/env fish
#
# wsl2-lies-stage2-unshared-mounter.fish
#
# Ran with `sudo` in the `unshare -m` environment.
# Sets up the bind mount, and executes the passed-in command as the original
# user and group.

set -l USAGE "usage: $(basename (status -f)) --orig_user=<ORIG_USER> --orig_group=<ORIG_GROUP> --fake_tempfile=<FAKE_TEMPFILE> -- <COMMAND ...>" 

# split the argument list to everything before and after the first `--` in $argv
set -l dash_dash_idx (contains -i -- '--' $argv)
if test -z "$dash_dash_idx"
  echo "error: missing \"--\" between $(basename (status -f))-specific options and the command to be run" 1>&2
  echo "$USAGE" 1>&2
  exit 1
end

set -l real_argv_end (math $dash_dash_idx - 1)
set -l cmd_passthrough_start (math $dash_dash_idx + 1)

set -l real_argv $argv[1..$real_argv_end]
set -l cmd_passthrough $argv[$cmd_passthrough_start..-1]

# parse flags from the parent script
set -l options "orig_user="
set options $options "orig_group="
set options $options "fake_tempfile="

argparse $options -- $real_argv
or return $status

# make sure those flags were actually passed!
if not set -ql _flag_orig_user
  or not set -ql _flag_orig_group
  or not set -ql _flag_fake_tempfile

  echo 'error: missing required flag' 1>&2
  echo "$USAGE" 1>&2
  exit 1
end

set -l orig_user "$_flag_orig_user"
set -l orig_group "$_flag_orig_group"
set -l tempfile "$_flag_fake_tempfile"

echo "$(set_color -o cyan)🐟 Bind-mounting $(set_color normal)$(set_color magenta)$tempfile$(set_color normal)$(set_color -o cyan) to $(set_color normal)$(set_color magenta)/proc/version$(set_color normal)"
mount --bind "$tempfile" /proc/version

echo "$(set_color -o cyan)🐟 Running command with user:group = $(set_color normal)$(set_color magenta)$orig_user:$orig_group$(set_color normal)$(set_color -o cyan) : $(set_color normal)$(set_color -i white)$cmd_passthrough$(set_color normal)"

setpriv "--reuid=$orig_user" "--regid=$orig_group" --init-groups --inh-caps=-all $cmd_passthrough
exit $status
