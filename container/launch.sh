#!/bin/bash

set -e

user=core

# get the name of the machineconfig used by the first master
machineconfig=$(oc get node -l 'node-role.kubernetes.io/master' -o json | jq -r '.items[0].metadata.annotations."machineconfiguration.openshift.io/desiredConfig"')

# make sure the user exists
id -u "${user}" &>/dev/null || useradd ${user}

# make sure the ssh dir exists
sshdir="/home/${user}/.ssh"
mkdir -p "${sshdir}"

# get the list of all keys
IFS=$'\n' keys=($(oc get machineconfig -o json "${machineconfig}" | jq -r '[.spec.config.passwd.users[] | select(.name == "core")] | .[-1].sshAuthorizedKeys[]'))

keyfile="${sshdir}/authorized_keys"
for key in ${keys[@]};
do
  echo "Adding key: ${key}"
  echo "${key}" >> "${keyfile}"
done

# make sure the authorized_keys file has the right owners and perms
chown "${user}":"${user}" "${keyfile}"
chmod 600 "${keyfile}"
sort -u -o "${keyfile}" "${keyfile}"

# forward kubernetes env to ssh sessions (so oc/kubectl works with service account)
mapfile -t kube_vars < <(env | grep '^KUBERNETES_')
[ ${#kube_vars[@]} -gt 0 ] && OPTIONS="-o SetEnv '${kube_vars[@]}'"

exec /usr/sbin/sshd -D ${OPTIONS}
