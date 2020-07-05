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

local_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
source "${multik3s_dir:-${local_dir}/..}/utils/logging.sh"

help() {
  info "Usage:"
  info "    $0 [OPTIONS] [COMMAND]"
  info ""
  info "Options:"
  info "    -q               : decrease verbosity level (can be repeated: -qq, -qqq)"
  info "    -v               : increase verbosity level (can be repeated: -vv, -vvv)"
  info ""
  info "Commands:"
  info "    exec             : execute a command with multik3s configuration"
  info "    delete           : delete a cluster resource"
  info "    doctor           : check if multik3s is initialized correctly"
  info "    help             : display this help message"
  info "    init             : initialize the multik3s configuration"
  info "    kubectl          : use kubectl with multik3s configuration"
  info "    start            : start a cluster resource"
  info "    stop             : stop a cluster resource"
}

help
