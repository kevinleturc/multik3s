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
source "${multik3s_dir:-${local_dir}/..}/utils/constants.sh"
source "${multik3s_dir:-${local_dir}/..}/utils/logging.sh"
source "${multik3s_dir:-${local_dir}/..}/lib/configuration.sh"
source "${multik3s_dir:-${local_dir}/..}/lib/wrapper_multipass.sh"

start() {
  type=$1 # only cluster is currently handled
  name=$2

  if [[ "${type}" == "cluster" ]]; then
    cluster=${name:-default}
    info "Start cluster: ${cluster}"

    master_name=$(readConfigurationMasterName "${cluster}")
    writeConfigurationCondition "${cluster}" "Started" "InProgress"
    if ! multipassStart "${cluster}" "${master_name}"; then
      writeConfigurationCondition "${cluster}" "Started" "Error"
      die "Unable to start master node: ${master_name}"
    fi
    writeConfigurationCondition "${cluster}" "Started" "True"

    # update master_ip in case it changes
    master_ip=$(multipassInfoIpv4 "${master_name}")
    writeConfigurationMasterIp "${cluster}" "${master_ip}"

    agent_names=($(readConfigurationAgentName "${cluster}"))
    for agent_name in "${agent_names[@]}"; do
      multipassStart "${cluster}" "${agent_name}"
    done

    info "Cluster: ${cluster} started"
  else
    die "Unknown object: ${type}" 2
  fi
}

start "$@"
