# ssh-bastion
An ssh-bastion pod to make access to openshift clusters easy

1. Make sure that `oc` is configured to talk to the cluster
1. Optionally configure the namespace where the bastion will run:
    ```
    export SSH_BASTION_NAMESPACE=openshift-ssh-bastion
    ```
   By default `openshift-ssh-bastion` is used.
1. Run:
    ```
    curl https://raw.githubusercontent.com/eparis/ssh-bastion/master/deploy/deploy.sh | bash
    ```

    This will create a new pod running an sshd server.  The sshd server is exposed via a k8s service backed
    by a loadbalancer(based on your cloud platform).  The service hostname will provide access to the
    sshd server.  (See below for how to get the hostname)

    The sshd server is configured to allow login as user `core` using the same private key that was used
    to create the cluster.

1. SSH as the `core` user to/through the bastion.
    * You can use [a helper script][ssh-script] to ssh directly to a node by the node's name (from `oc get node`).
      This script uses ssh authentication forwarding so you can directly hop from the bastion to the cluster nodes.
    > If you need to use a non-default SSH key, you can:
    > * Export the `SSH_KEY_PATH` environment variable to change its location. For example:
    >   ```
    >   export SSH_KEY_PATH=~/.ssh/my_kustom_cey.pem
    >   ```
    > * Run something like `ssh-agent` and add your key to that utility
    > * Directly add or update the SSH keys in your OCP deployment see [Update SSH Keys][update-ssh-keys].
1. The bastion address can be found by running:
    ```
    oc get service -n openshift-ssh-bastion ssh-bastion -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    ```

[ssh-script]: https://raw.githubusercontent.com/eparis/ssh-bastion/master/ssh.sh
[update-ssh-keys]: https://github.com/openshift/machine-config-operator/blob/master/docs/Update-SSHKeys.md
