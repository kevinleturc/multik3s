#!/bin/bash
#
# Copyright 2020 - Multik3s
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if ! { true >&4; } 2<> /dev/null; then
  exec 4>&2 # logging stream (file descriptor 4) defaults to STDERR
  exec 5>/dev/null # execution stream (file descriptor 5) defaults to /dev/null
fi
verbosity=${verbosity:-4} # default to show debugs
silent_lvl=${silent_lvl:-0}
err_lvl=${err_lvl:-1}
wrn_lvl=${wrn_lvl:-2}
inf_lvl=${inf_lvl:-3}
dbg_lvl=${dbg_lvl:-4}
trc_lvl=${dbg_lvl:-5}

notify() { log "$silent_lvl" "$1"; } # Always prints
error() { log "$err_lvl" "ERROR" "$1"; }
warn() { log "$wrn_lvl" "WARN" "$1"; }
info() { log "$inf_lvl" "INFO" "$1"; }
debug() { log "$dbg_lvl" "DEBUG" "$1"; }
trace() { log "$trc_lvl" "TRACE" "$1"; }
log() {
  curr_lvl=$1
  curr_lvl_string=$2
  msg=$3

  color=""
  normal=""
  if tput colors > /dev/null; then
    color="$(tput sgr0)"
    normal="$(tput sgr0)"
    case "$curr_lvl" in
      1) color="\033[1;31m";; # red
      2) color="\033[1;33m";; # yellow
      3) color="\033[1;34m";; # blue
      4) color="\033[36m";; # cyan
    esac
  fi
  if [ "$verbosity" -ge "$curr_lvl" ]; then
    # Expand escaped characters
    echo -e "[$color$curr_lvl_string$normal] $msg" >&4
  fi
}

die() {
  msg=$1
  code=$2

  error "${msg}"
  exit "${code:-1}"
}
