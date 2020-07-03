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

line_length=$(( $(tput cols || echo 80) / 2 ))

logDot() {
  msg=$1
  ok=$2

  # ok is 1 for OK and 0 for KO
  dots=$(for ((i=${#msg};i<=line_length;i+=1)); do echo -n '.'; done)
  if (( ok )); then
    info "    ${msg}${dots}OK"
  else
    error "   ${msg}${dots}KO"
  fi
}

testCommand() {
  command=$1

  command_exist=$(type "${command}" 1>&5 2>&5 && echo 1 || echo 0)
  logDot "${command}" "${command_exist}"
}

testDirectory() {
  directory=$1

  directory_exist=$([ -d "${directory}" ] 1>&5 2>&5 && echo 1 || echo 0)
  logDot "${directory}" "${directory_exist}"
}

info "Testing multik3s installation state"
info ""
info "Dependencies:"
testCommand kubectl
testCommand multipass
testCommand yq
info ""
info "Configuration:"
testDirectory "${multik3s_configuration_dir}"
info ""
