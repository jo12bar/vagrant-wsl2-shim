#!/usr/bin/env fish
#
# wsl2-lies.fish
#
# Runs a command in an `unshare -m`'ed environment where `/proc/version`
# is bindmounted to a fake copy with the string "microsoft" removed.
# Does its best to preserve user environment variables.
#
# Usage:
#     wsl2-lies.fish <COMMAND ...>

set -l SCRIPT_DIR (realpath (dirname (status -f)))

set -l orig_user (whoami)
set -l orig_group (id -gn)

echo "$(set_color -o cyan)🐟 Original user:group = $(set_color normal)$(set_color magenta)$orig_user:$orig_group$(set_color normal)"

set -l proc_version_orig (cat /proc/version)

echo "$(set_color -o cyan)🐟 Original /proc/version = $(set_color normal)$(set_color magenta)$proc_version_orig$(set_color normal)"

# remove microsoft from the /proc/version string
set -l proc_version_mod (string replace -a -i "microsoft" "" "$proc_version_orig")

# make the tempfile
set -l tempfile (mktemp)

# write to the tempfile
echo "$proc_version_mod" > "$tempfile"
echo "$(set_color -o cyan)🐟 Wrote $(set_color normal)$(set_color magenta)$proc_version_mod$(set_color normal)$(set_color -o cyan) to $(set_color normal)$(set_color magenta)$tempfile$(set_color normal)"

echo "$(set_color -o cyan)🐟 Starting \"unshare -m\" environment$(set_color normal)"

# start the stage 2 script in an unshared environment via sudo
sudo -E unshare -m "$SCRIPT_DIR/wsl2-lies-stage2-unshared-mounter.fish" \
  "--orig_user=$orig_user" \
  "--orig_group=$orig_group" \
  "--fake_tempfile=$tempfile" \
  -- $argv
set -l unshare_exit_status $status

echo "$(set_color -o cyan)🐟 Exited \"unshare -m\" environment$(set_color normal)"

echo "$(set_color -o cyan)🐟 Deleting $(set_color normal)$(set_color magenta)$tempfile$(set_color normal)"
rm "$tempfile"

echo "$(set_color -o cyan)🐟 Exiting with status $(set_color normal)$(set_color magenta)$unshare_exit_status$(set_color normal)"

exit $unshare_exit_status

