# multik3s
A command-line tool that makes k3s easier to use with multipass.

Work in progress, see [help](./src/commands/help.sh) for usage.

Requirements:
- [multipass](https://multipass.run/)
- [yq](https://mikefarah.gitbook.io/yq/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

Once the requirements are installed, just clone this repository somewhere on your computer and add an alias to `multik3s` script, such as below:

```bash
alias multik3s='bash /PATH/TO/REPOSITORY/src/multik3s.sh
```

To start a [K3s](https://github.com/rancher/k3s) cluster with [multipass](https://github.com/canonical/multipass), just type:

```bash
multik3s init
```

if succeed and after a moment all nodes should be available, to check their statuses:

```bash
multik3s kubectl top node
```

This has created a _default_ cluster with specification from [cluster template](./src/templates/cluster.yaml).

To interract with your cluster, you can grab the k8s configuration file under `~/.multik3s/cluster_default_k3s.yaml` or use the exec feature:

```bash
multik3s kubectl get pod
multik3s exec kubectl get pod
multik3s exec helm delete --purge release
```

Content of this CLI code is grandly inspired from:
- [Kit de survie Kubernetes pour les développeurs (avec K3S)](https://k33g.gitlab.io/articles/2020-02-21-K3S-01-CLUSTER.html)
