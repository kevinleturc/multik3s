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

_formatFullName() {
  cluster=$1
  type=$2 # could be master or agent
  name=$3

  echo "multik3s-${cluster//_/-}-${type}-${name//_/-}"
}

_getConfigurationFile() {
  cluster=$1

  echo "${multik3s_configuration_dir}/cluster_${cluster//_/-}.yaml"
}

_getK3sConfigurationFile() {
  cluster=$1

  echo "${multik3s_configuration_dir}/cluster_${cluster//_/-}_k3s.yaml"
}

checkConfigurationStatus() { # return with 0 if exist and 1 otherwise
  cluster=$1

  [[ "$(yq read "$(_getConfigurationFile "${cluster}")" status)" == "" ]] && return 1 || return 0
}

deleteConfigurationStatus() {
  cluster=$1

  yq delete -i "$(_getConfigurationFile "${cluster}")" status 2>&5 \
    && rm "$(_getK3sConfigurationFile "${cluster}")"
}

deleteConfigurationNodeStatus() {
  cluster=$1
  node_name=$2 # full name with multik3s prefix

  yq delete -i "$(_getConfigurationFile "${cluster}")" "status.nodeStatuses.${node_name}" 2>&5
}

readConfiguration() {
  cluster=$1

  cat "$(_getConfigurationFile "${cluster}")"
}

readConfigurationAgentName() { # read the agent names from nodes configuration and convert them to multipass name
  cluster=$1

  configuration_file=$(_getConfigurationFile "${cluster}")
  node_names=($(yq read "${configuration_file}" "spec.nodes.*.name" 2>&5))
  for node_name in "${node_names[@]}"; do
    if [[ ! "$(yq read "${configuration_file}" "spec.nodes.(name==${node_name}).master")" ]] 2>&5; then
      _formatFullName "${cluster}" "agent" "${node_name}"
    fi
  done
}

readConfigurationConditionStatus() {
  cluster=$1
  type=$2

  yq read "$(_getConfigurationFile "${cluster}")" "status.conditions.(type==${type}).status" 2>&5
}

readConfigurationMasterName() { # read the master name from nodes configuration and convert it to multipass name
  cluster=$1

  master_name=$(yq read "$(_getConfigurationFile "${cluster}")" "spec.nodes.(master==true).name" 2>&5)
  _formatFullName "${cluster}" "master" "${master_name}"
}

readConfigurationMasterIp() {
  cluster=$1

  yq read "$(_getConfigurationFile "${cluster}" "status.master_ip")" 2>&5
}

writeConfigurationMasterIp() {
  cluster=$1
  master_ip=$2

  yq write -i "$(_getConfigurationFile "${cluster}")" "status.master_ip" "${master_ip}" >&5
}

writeConfigurationCondition() {
  cluster=$1
  type=$2
  status=$3

  configuration_file=$(_getConfigurationFile "${cluster}")
  if [[ ! $(yq read "${configuration_file}" "status.conditions.(type==${type})") ]]; then
    yq write -i "${configuration_file}" "status.conditions[+].type" "${type}" >&5
  fi
  yq write -i "${configuration_file}" "status.conditions.(type==${type}).status" "${status}" >&5
  yq write -i "${configuration_file}" "status.conditions.(type==${type}).lastTransitionTime" "$(date -u +%FT%TZ)" >&5
}

writeConfigurationNodeStatus() {
  cluster=$1
  node_name=$2 # full name with multik3s prefix
  type=$3
  status=$4

  configuration_file=$(_getConfigurationFile "${cluster}")
  if [[ ! $(yq read "${configuration_file}" "status.nodeStatuses.${node_name}.(type==${type})") ]]; then
    yq write -i "$(_getConfigurationFile "${cluster}")" "status.nodeStatuses.${node_name}[+].type" "${type}" >&5
  fi
  yq write -i "${configuration_file}" "status.nodeStatuses.${node_name}.(type==${type}).status" "${status}" >&5
  yq write -i "${configuration_file}" "status.nodeStatuses.${node_name}.(type==${type}).lastTransitionTime" "$(date -u +%FT%TZ)" >&5
}
