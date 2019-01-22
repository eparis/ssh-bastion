#!/bin/bash

set -e

BASEDIR=$(dirname "$0")

clean_up () {
    ARG=$?
    rm -f ${RSATMP} ${RSATMP}.pub
    rm -f ${ECDSATMP} ${ECDSATMP}.pub
    rm -f ${ED25519TMP} ${ED25519TMP}.pub
    rm -f ${CONFIGFILE}
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
' > ${CONFIGFILE}

    oc create -n openshift-ssh-bastion secret generic ssh-host-keys --from-file="ssh_host_rsa_key=${RSATMP},ssh_host_ecdsa_key=${ECDSATMP},ssh_host_ed25519_key=${ED25519TMP},sshd_config=${CONFIGFILE}"
}

oc apply -f ${BASEDIR}/namespace.yaml
oc get -n openshift-ssh-bastion secret ssh-host-keys &>/dev/null || create_host_keys
oc apply -f ${BASEDIR}/serviceaccount.yaml 
oc apply -f ${BASEDIR}/role.yaml 
oc apply -f ${BASEDIR}/rolebinding.yaml 
oc apply -f ${BASEDIR}/clusterrole.yaml
oc apply -f ${BASEDIR}/clusterrolebinding.yaml
oc apply -f ${BASEDIR}/service.yaml 
oc apply -f ${BASEDIR}/deployment.yaml
