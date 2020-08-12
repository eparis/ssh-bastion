#!/bin/bash

set -e

# Configuration via env. variables:
# Namespace where the bastion should run. The namespace will be created.
SSH_BASTION_NAMESPACE="${SSH_BASTION_NAMESPACE:-openshift-ssh-bastion}"

# Directory with bastion yaml files. Can be either local directory or http(s) URL.
BASEDIR="${BASEDIR:-https://raw.githubusercontent.com/eparis/ssh-bastion/master/deploy}"

clean_up () {
    ARG=$?
    rm -f "${RSATMP}" "${RSATMP}.pub"
    rm -f "${ECDSATMP}" "${ECDSATMP}.pub"
    rm -f "${ED25519TMP}" "${ED25519TMP}.pub"
    rm -f "${CONFIGFILE}"
    exit $ARG
}
trap clean_up EXIT

create_host_keys() {
    RSATMP=$(mktemp -u)
    /usr/bin/ssh-keygen -q -t rsa -f "${RSATMP}" -C '' -N ''
    ECDSATMP=$(mktemp -u)
    /usr/bin/ssh-keygen -q -t ecdsa -f "${ECDSATMP}" -C '' -N ''
    ED25519TMP=$(mktemp -u)
    /usr/bin/ssh-keygen -q -t ed25519 -f "${ED25519TMP}" -C '' -N ''

    CONFIGFILE=$(mktemp)
    echo 'HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
SyslogFacility AUTHPRIV
PermitRootLogin no
AuthorizedKeysFile	/home/core/.ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
GSSAPIAuthentication yes
GSSAPICleanupCredentials no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS
Subsystem	sftp	/usr/libexec/openssh/sftp-server
' > "${CONFIGFILE}"

    oc -n "${SSH_BASTION_NAMESPACE}" create secret generic ssh-host-keys --from-file="ssh_host_rsa_key=${RSATMP},ssh_host_ecdsa_key=${ECDSATMP},ssh_host_ed25519_key=${ED25519TMP},sshd_config=${CONFIGFILE}"
}

# Non-namespaced objects
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${SSH_BASTION_NAMESPACE}
  labels:
    openshift.io/run-level: "0"
EOF
oc apply -f "${BASEDIR}/clusterrole.yaml"
# using oc apply to modifty any already existing clusterrolebinding
oc create clusterrolebinding ssh-bastion --clusterrole=ssh-bastion --user="system:serviceaccount:${SSH_BASTION_NAMESPACE}:ssh-bastion" -o yaml --dry-run=client | oc apply -f -

# Namespaced objects
oc -n "${SSH_BASTION_NAMESPACE}" apply -f "${BASEDIR}/service.yaml"
oc -n "${SSH_BASTION_NAMESPACE}" get secret ssh-host-keys &>/dev/null || create_host_keys
oc -n "${SSH_BASTION_NAMESPACE}" apply -f "${BASEDIR}/serviceaccount.yaml"
oc -n "${SSH_BASTION_NAMESPACE}" apply -f "${BASEDIR}/role.yaml"
oc -n "${SSH_BASTION_NAMESPACE}" create rolebinding ssh-bastion --clusterrole=ssh-bastion --user="system:serviceaccount:${SSH_BASTION_NAMESPACE}:ssh-bastion" -o yaml --dry-run=client | oc apply -f -
oc -n "${SSH_BASTION_NAMESPACE}" apply -f "${BASEDIR}/deployment.yaml"

retry=120
while [ $retry -ge 0 ]
do
    retry=$((retry-1))
    bastion_host=$(oc get service -n "${SSH_BASTION_NAMESPACE}" ssh-bastion -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || true)
    if [ -n "${bastion_host}" ]; then
        break
    fi
    bastion_ip=$(oc get service -n "${SSH_BASTION_NAMESPACE}" ssh-bastion -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || true)
    if [ -n "${bastion_ip}" ]; then
        break
    fi
    sleep 1
done

if [ -n "${bastion_host}" ]; then
    echo "Waiting for ${bastion_host} to show up in DNS"
    retry=120
    while [ $retry -ge 0 ]
    do
        retry=$((retry-1))
        if ! ((retry % 10)); then
            echo "...Still waiting for DNS..."
        fi
        if nslookup "${bastion_host}" > /dev/null ; then
            break
        else
            sleep 2
        fi
    done
else
    bastion_host="${bastion_ip}"
fi

echo "The bastion address is ${bastion_host}"
echo "You may want to use https://raw.githubusercontent.com/eparis/ssh-bastion/master/ssh.sh to easily ssh through the bastion to specific nodes."
