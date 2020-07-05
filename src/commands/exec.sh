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

execWrapped() {
  cluster="default"

  if [[ "$(readConfigurationConditionStatus "${cluster}" "Initialized")" != "True" ]]; then
    die "Cluster: ${cluster} is not initialized"
  fi
  if [[ "$(readConfigurationConditionStatus "${cluster}" "Started")" != "True" ]]; then
    die "Cluster: ${cluster} is not started"
  fi
  k3s_file="$(_getK3sConfigurationFile "${cluster}")"
  if [ ! -f "${k3s_file}" ]; then
    info "Get K3s configuration for cluster interaction"
    multipass exec "$(readConfigurationMasterName "${cluster}")" sudo cat /etc/rancher/k3s/k3s.yaml 1> "${k3s_file}" 2>&5 \
      || die "Unable to get k3s.yaml" 3
    sed -i '' "s/127.0.0.1/$(readConfigurationMasterIp "${cluster}")}/" "${k3s_file}"
  fi
  KUBECONFIG="${k3s_file}" "$@"
}

execWrapped "$@"
