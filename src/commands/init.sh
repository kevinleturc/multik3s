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

init() {
  type=$1 # only cluster is currently handled and not checked
  name=$2 # only default is currently handled

  info "Initialize multik3s"

  # init configuration
  if [ -d "${multik3s_configuration_dir}" ]; then
    debug "Use configuration directory: ${multik3s_configuration_dir}"
  else
    debug "Create configuration directory: ${multik3s_configuration_dir}"
    mkdir -p "${multik3s_configuration_dir}" \
      || die "Impossible to create configuration directory: ${multik3s_configuration_dir}"
  fi

  # init cluster configuration if needed
  cluster="${name:-default}"
  cluster_config_file="$(_getConfigurationFile "${cluster}")"
  if [ -f "${cluster_config_file}" ]; then
    debug "Use the cluster configuration: ${cluster_config_file}"
  else
    debug "Create the '${cluster}' cluster configuration from: ${multik3s_templates_cluster_config_file}"
    cp "${multik3s_templates_cluster_config_file}" "${cluster_config_file}"
  fi

  if checkConfigurationStatus "${cluster}"; then
    die "Cluster already running"
  fi

  info "Start cluster nodes"
  info ""

  # TODO check with k8s status for InProgress
  writeConfigurationCondition "${cluster}" "Started" "InProgress"

  nb_nodes=$(yq r "${cluster_config_file}" --length spec.nodes 2>&5)
  declare -a multipass_names
  result=0
  for (( i = 0; i < nb_nodes; i++ )); do
    name=$(yq r "${cluster_config_file}" spec.nodes[$i].name 2>&5)
    master=$(yq r "${cluster_config_file}" spec.nodes[$i].master 2>&5)
    cpu=$(yq r "${cluster_config_file}" spec.nodes[$i].resources.cpu 2>&5)
    memory=$(yq r "${cluster_config_file}" spec.nodes[$i].resources.memory 2>&5)
    disk=$(yq r "${cluster_config_file}" spec.nodes[$i].resources.disk 2>&5)

    multipass_name=$(_formatFullName "${cluster}" "$([[ "${master}" == "true" ]] && echo "master" || echo "agent")" "${name}")
    multipass_names+=("${multipass_name}")
    multipassLaunch "${cluster}" "${multipass_name}" "${cpu}" "${memory}" "${disk}"
    result=$(( result + $? ))
  done

  if [[ "$result" -gt "0" ]]; then
    writeConfigurationCondition "${cluster}" "Started" "Error"
    die "One or more node refused to start"
  fi
  writeConfigurationCondition "${cluster}" "Started" "True"

  info "Install K3s on cluster nodes"

  writeConfigurationCondition "${cluster}" "Initialized" "InProgress"
  # install master
  for (( i = 0; i < nb_nodes; i++ )); do
    master=$(yq read "${cluster_config_file}" spec.nodes[$i].master 2>&5)
    if [[ "${master}" == "true" ]]; then
      debug ""
      debug "Install K3s on master node: ${multipass_names[$i]}"

      writeConfigurationNodeStatus "${cluster}" "${multipass_names[$i]}" "Initialized" "InProgress"
      multipass exec "${multipass_names[$i]}" -- sh -c "curl -sfL https://get.k3s.io | sh -" \
        || (warn "Unable to install K3s on master node: ${multipass_names[$i]}"; \
           writeConfigurationNodeStatus "${cluster}" "${multipass_names[$i]}" "Initialized" "Error"; \
           break)
      writeConfigurationNodeStatus "${cluster}" "${multipass_names[$i]}" "Initialized" "True"

      master_name=${multipass_names[$i]}
      master_ip=$(multipass info --format yaml "${multipass_names[$i]}" | yq r - "${multipass_names[$i]}[0].ipv4[0]")
      master_k3s_token=$(multipass exec "${multipass_names[$i]}" sudo cat /var/lib/rancher/k3s/server/node-token)

      debug ""
      debug "K3s initialized on master node: ${master_name}"
      debug "    Master IP: ${master_ip}"
      debug "    K3s token: ${master_k3s_token}"

      break
    fi
  done

  if [[ ! ${master_ip} || ! ${master_k3s_token} ]]; then
    writeConfigurationCondition "${cluster}" "Initialized" "Error"
    die "No master node found for cluster: default" 3
  fi

  writeConfigurationMasterIp "${cluster}" "${master_ip}"
  writeConfigurationMasterK3sToken "${cluster}" "${master_k3s_token}"

  # install agents
  for (( i = 0; i < nb_nodes; i++ )); do
    master=$(yq read "$(_getConfigurationFile "${cluster}")" spec.nodes[$i].master 2>&5)
    if [[ "${master}" != "true" ]]; then
      debug ""
      debug "Install K3s on agent node: ${multipass_names[$i]}"

      writeConfigurationNodeStatus "${cluster}" "${multipass_names[$i]}" "Initialized" "InProgress"
      multipass exec "${multipass_names[$i]}" -- sh -c "
          curl -sfL https://get.k3s.io | K3S_URL='https://${master_ip}:6443' K3S_TOKEN='${master_k3s_token}' sh -
        " \
        || warn "Unable to install K3s on agent node: ${multipass_names[$i]}"; \
           writeConfigurationNodeStatus "${cluster}" "${multipass_names[$i]}" "Initialized" "Error";
      writeConfigurationNodeStatus "${cluster}" "${multipass_names[$i]}" "Initialized" "True"

      debug "The node ${multipass_names[$i]} has joined the cluster"
    fi
  done
  writeConfigurationCondition "${cluster}" "Initialized" "True"
  info "Your kubernetes cluster was created"

  cluster_k3s_config_file="$(_getK3sConfigurationFile "${cluster}")"
  debug "Get K3s configuration for cluster interaction"
  multipass exec "${master_name}" sudo cat /etc/rancher/k3s/k3s.yaml 1> "${cluster_k3s_config_file}" 2>&5 \
    || die "Unable to get k3s.yaml" 3
  sed -i '' "s/127.0.0.1/${master_ip}/" "${cluster_k3s_config_file}"
}

init "$@"