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

multipassDelete() {
  cluster=$1
  name=$2

  debug "Delete cluster node: ${name}"

  multipass delete "${name}" 2>&5
  result=$?
  if [[ "${result}" == "0" ]]; then
    debug "Cluster node: ${name} deleted"
    deleteConfigurationNodeStatus "${cluster}" "${name}"
  else
    warn "Unable to delete cluster node: ${name}"
    writeConfigurationNodeStatus "${cluster}" "${name}" "Started" "Error"
  fi
  return $result
}

multipassInfoIpv4() {
  name=$1

  multipass info --format yaml "${name}" | yq r - "${name}[0].ipv4[0]" 2>&5
}

multipassLaunch() {
    cluster=$1
    name=$2
    cpu=$3
    memory=$4
    disk=$5

    debug "Launch cluster node: ${name}"
    debug "    cpu:        ${cpu}" # one more space because no unit
    debug "    memory:    ${memory}"
    debug "    disk:      ${disk}"
    debug ""

    # TODO check with k8s status for InProgress
    writeConfigurationNodeStatus "${cluster}" "${name}" "Started" "InProgress"
    multipass launch -n "${name}" -c "${cpu}" -m "${memory}" -d "${disk}"
    result=$?
    if [[ "${result}" == "0" ]]; then
      debug "Cluster node: ${name} launched"
      writeConfigurationNodeStatus "${cluster}" "${name}" "Started" "True"
    else
      warn "Unable to launch cluster node: ${name}"
      writeConfigurationNodeStatus "${cluster}" "${name}" "Started" "Error"
    fi
    return $result
}

multipassStart() {
  cluster=$1
  name=$2

  debug "Start cluster node: ${name}"

  # TODO check with k8s status for Stopping
  writeConfigurationNodeStatus "${cluster}" "${name}" "Started" "InProgress"
  multipass start "${name}" 2>&5
  result=$?
  if [[ "${result}" == "0" ]]; then
    debug "Cluster node: ${name} started"
    writeConfigurationNodeStatus "${cluster}" "${name}" "Started" "True"
  else
    warn "Unable to start cluster node: ${name}"
    writeConfigurationNodeStatus "${cluster}" "${name}" "Started" "Error"
  fi
  return $result
}

multipassStop() {
  cluster=$1
  name=$2

  debug "Stop cluster node: ${name}"

  # TODO check with k8s status for Stopping
  writeConfigurationNodeStatus "${cluster}" "${name}" "Started" "Stopping"
  multipass stop "${name}" 2>&5
  result=$?
  if multipass stop "${name}" 2>&5; then
    debug "Cluster node: ${name} stopped"
    writeConfigurationNodeStatus "${cluster}" "${name}" "Started" "False"
  else
    warn "Unable to stop cluster node: ${name}"
    writeConfigurationNodeStatus "${cluster}" "${name}" "Started" "StopFailed"
  fi
  return $result
}