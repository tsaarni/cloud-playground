
# Install Kubernetes locally on Ubuntu

Following instructions are for deploying Kubernetes natively on Ubuntu
machine with minimum number of installation steps.  The purpopse is to
have a local environment for experimentation.
[Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/)
is usually recommended for this purpose. The downside with minikube is
that it runs Kubernetes in a separate virtual machine (although work
is being done for localkube / no-vm minikube).

Only single node is required to run Kubernetes, but the instructions
also show how to add worker nodes.  You can probably manage with 2GB
RAM on master node and 1GB on workers at minimum.

Pre-compiled Kubernetes packages exist also for CentOS.  Refer to
[Kubernetes documentation](https://kubernetes.io/docs/setup/independent/install-kubeadm/#installing-kubelet-and-kubeadm)
for further information.


## Pre-conditions

Install docker, for example using the apt-repository of Docker Inc.:

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    echo deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable > /etc/apt/sources.list.d/docker.list
    apt update
    apt install -y docker-ce


## Install Kubernetes packages on the host system

Most of Kubernetes is executed within containers, but part still need
to be executed on the host system.  Following packages are installed
on host system: kubeadm, kubelet and kubernetes-cni.


### Alternative 1: Use pre-compiled packages

Google provides pre-compiled Kubernetes packages at
http://apt.kubernetes.io.  The packages include `kubectl` for several
distro releases and server packages for Xenial 16.04 LTS.  Note that
as of today (2017-07-17), there is NO client or server packages for 17.04 Zesty.

To add the repository and install packages, run following commands as root:

    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    echo "deb http://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main" > /etc/apt/sources.list.d/kubernetes.list
    apt update
    apt install -y kubeadm kubelet kubernetes-cni


### Alternative 2: Compile your own packages

If packages do not exist for your distro release, you can compile your
own packages.  The environment for compiling Kubernetes packages for
Ubuntu is here https://github.com/kubernetes/release.  Following
instructions are for compiling Kubernetes server packages for Ubuntu
17.04 Zesty Zapus.

Clone the source code and create build environment container:

    git clone https://github.com/kubernetes/release.git
    cd release
    docker build --tag=debian-packager debian


Add support for Ubuntu Zesty into the source code:

    diff --git a/debian/build.go b/debian/build.go
    index 9afed89..42c056b 100644
    --- a/debian/build.go
    +++ b/debian/build.go
    @@ -60,8 +60,8 @@ func (ss *stringList) Set(v string) error {

     var (
            architectures = stringList{"amd64", "arm", "arm64", "ppc64le", "s390x"}
    -       serverDistros = stringList{"xenial"}
    -       allDistros    = stringList{"xenial", "jessie", "precise", "sid", "stretch", "trusty", "utopic", "vivid", "wheezy", "wily", "yakkety"}
    +       serverDistros = stringList{"xenial", "zesty"}
    +       allDistros    = stringList{"xenial", "jessie", "precise", "sid", "stretch", "trusty", "utopic", "vivid", "wheezy", "wily", "yakkety", "zesty"}
            kubeVersion   = ""

            builtins = map[string]interface{}{


Make a env directory for zesty and symbolic links for the packages

    mkdir debian/zesty
    ln -s ../xenial/kubeadm debian/zesty
    ln -s ../xenial/kubectl debian/zesty
    ln -s ../xenial/kubelet debian/zesty
    ln -s ../xenial/kubernetes-cni debian/zesty


Finally start the container and build packages:

    docker run -it --rm --entrypoint=bash --volume="$(pwd)/debian:/src" debian-packager

    root@360ca785a77e:/src# go run /src/build.go -arch amd64 -distros zesty -server-distros zesty
    ... lots of lines removed ...


The compiled packages are stored under `debian/bin/`

    ls -l debian/bin/stable/zesty/
    total 43936
    -rw-r--r-- 1 root root  9798450 Jul 16 21:31 kubeadm_1.7.1-00_amd64.deb
    -rw-r--r-- 1 root root 10141120 Jul 16 21:25 kubectl_1.7.1-00_amd64.deb
    -rw-r--r-- 1 root root 19393002 Jul 16 21:27 kubelet_1.7.1-00_amd64.deb
    -rw-r--r-- 1 root root  5650898 Jul 16 21:29 kubernetes-cni_0.5.1-00_amd64.deb


Install the packages

    dpkg -i debian/bin/stable/zesty/*
    # ignore warnings abaout dependencies, these will be fixed by following command:
    apt-get -f install -y


## Initialize the cluster

In this document the `kubeadm` is used for deployment.  Execute
following command as root:

    kubeadm init


Wait for the command to complete.  The command will write manifests to
`/etc/kubernetes/manifests/` for deploying etcd, kube-apiserver,
kube-controller-manager and kube-scheduler as containers.  Kubelet,
which was installed as .deb package, polls this directory for new
manifests.  It will take a while for it to download and start the
containers.

For single-node installation, un-taint the master node to enable
scheduling pods on the master node too:

    kubectl taint nodes --all node-role.kubernetes.io/master- --kubeconfig /etc/kubernetes/admin.conf


Then deploy CNI networking plugin, for example:

    kubectl apply -f http://docs.projectcalico.org/v2.3/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml --kubeconfig /etc/kubernetes/admin.conf


Run `kubectl get nodes --kubeconfig /etc/kubernetes/admin.conf` and
wait for the node to change to `Ready` status.

Copy or merge /etc/kubernetes/admin.conf to your ~/.kube/config.



## Optional: Adding worker nodes to the cluster

First install docker, kubelet, kubernetes-cni, kubectl and kubeadm.
See previous chapter for details.

A bootstrap token was generated when cluster was first initialized
with `kubeadm init` command. This token is used as shared secret when
joining new nodes to the cluster. You can print the token again by
running following command on the master node:

    kubeadm token list

    TOKEN                     TTL         EXPIRES   USAGES                   DESCRIPTION
    aa2e25.51bc71421ae623e4   <forever>   <never>   authentication,signing   The default bootstrap token generated by 'kubeadm init'.


Next, run following command on the worker node(s):

    kubeadm join --token <token> <ip address of master>:6443


Run `kubectl get nodes` and wait until the status shows `Ready`.  It
will take a while for the worker to download and start the Kubernetes
containers.



## Upgrade

In this example kubernetes is upgraded to v1.7.3. See
[here](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm-upgrade-1-7/)
for more information.

First upgrade the packages and restart kubelet


    # alt 1: using pre-compiled packages
    sudo apt upgrade

    # alt 2: using your own packages
    sudo dpkg -i debian/bin/stable/zesty/*

    sudo systemctl restart kubelet


Then upgrade the containers

    kubectl delete daemonset kube-proxy -n kube-system

    sudo kubeadm init --skip-preflight-checks --kubernetes-version v1.7.3

    # untaint again to enable container scheduling in single-node installation
    kubectl taint nodes --all node-role.kubernetes.io/master-




## Remove installation

Execute following to remove Kubernetes:

    kubeadm reset
    apt purge -y kubeadm kubelet kubernetes-cni

    # Assuming Calico CNI plugin was installed:
    rm -r /opt/cni/bin/
    rm -r /var/etcd/calico-data/



## Errors and workarounds

### Kubeadm join fails

With Kubernetes 1.7.1 you may get following error when running `kubeadm join`:

    [preflight] Some fatal errors occurred:
        hostname "" a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
        /var/lib/kubelet is not empty
    [preflight] If you know what you are doing, you can skip pre-flight checks with `--skip-preflight-checks`


As a workaround, use command `kubeadm join --skip-preflight-checks` to ignore the error.


### DNS does not resolve external names

Kube-dns fails to resolve external DNS names, for example:

    / # ping www.google.com
    ping: bad address 'www.google.com'


Following error can be found in dnsmasq side-car:

    $ kubectl logs -f  --namespace=kube-system kube-dns-NNNNNNNNNN dnsmasq
    ...
    I0806 15:36:54.017032      32 nanny.go:108] dnsmasq[55]: Maximum number of concurrent DNS queries reached (max: 150)
    I0806 15:37:04.034068      32 nanny.go:108] dnsmasq[55]: Maximum number of concurrent DNS queries reached (max: 150)
    I0806 15:37:14.049436      32 nanny.go:108] dnsmasq[55]: Maximum number of concurrent DNS queries reached (max: 150)
    ...


The problem is that Ubuntu Desktop (not server) uses dnsmasq and
later versions use systemd-resolv which puts localhost address in
/etc/resolv.conf.  This gets copied to kube-dns and causes recursive
queries to itself:

    $ kubectl exec --namespace=kube-system kube-dns-NNNNNNNNNN cat /etc/resolv.conf
    nameserver 127.0.0.53


See ticket https://github.com/kubernetes/kubeadm/issues/273.

As a workaround you can create separate resolv.conf for Kubernetes `/etc/kubernetes/resolv.conf` with following content (assuming Google DNS server)

    nameserver 8.8.8.8


Alternatively, if your system is running systemd-resolv you can
re-use `/run/systemd/resolve/resolv.conf`.
Then point out configuration file to be used by creating file
`/etc/systemd/system/kubelet.service.d/override.conf` with following
content:

    [Service]
    Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain=cluster.local --resolv-conf=/etc/kubernetes/resolv.conf"


Execute following to take the new configuration into use

    systemctl daemon-reload
    systemctl restart kubelet

    # delete kube-dns in order to restart it
    kubectl delete pod --namespace=kube-system kube-dns-NNNNNNNNNN
