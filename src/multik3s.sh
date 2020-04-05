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

multik3s_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
source "${multik3s_dir}/utils/constants.sh"
source "${multik3s_dir}/utils/logging.sh"

multik3s_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >&5 && pwd )"

if [[ " ${multik3s_supported_commands[*]} " =~ $1 ]] >&5; then
  command=$1
  shift
  # shellcheck source=/dev/null
  source "${multik3s_dir}/commands/${command}.sh" "$@"
else
  die "Invalid command $1"
fi
