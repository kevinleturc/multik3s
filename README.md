# multik3s
A command-line tool that makes k3s easier to use with multipass.

Work in progress, see [help](./src/commands/help.sh) for usage.

Requirements:
- [multipass](https://multipass.run/)
- [yq](https://mikefarah.gitbook.io/yq/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

To start a [K3s](https://github.com/rancher/k3s) cluster with [multipass](https://github.com/canonical/multipass), just type:
```bash
bash multik3s.sh init
```
if succeed and after a moment all nodes should be available, to check their statuses:
```bash
bash multik3s.sh kubectl top node
```

Content of this CLI code is grandly inspired from:
- [Kit de survie Kubernetes pour les développeurs (avec K3S)](https://k33g.gitlab.io/articles/2020-02-21-K3S-01-CLUSTER.html)
