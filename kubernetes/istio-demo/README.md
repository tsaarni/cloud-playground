
# Istio demo environment

## Prerequisites

Download [Vagrant](https://www.vagrantup.com/downloads.html),
[VirtualBox](https://www.virtualbox.org/wiki/Downloads).

Optionally you may download also
[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/),
[docker](https://www.docker.com/community-edition#/download) and
[helm](https://github.com/kubernetes/helm/releases) for your
host OS. These tools are also available inside the VM.


## Starting the environment

Run following to start the VM:

    vagrant up


The command will automatically download Ubuntu image, launch it, and
then install Kubernetes and Istio. After the installation has
succeeded you can take snapshot of the VM in order to easily revert
into initial state after the installation.

    vagrant snapshot push


To restore the state to latest snapshot use

    vagrant snapshot pop


The demos can be executed by running the scripts inside Virtualbox.
Connect to vagrant box and change to workdir:

    vagrant ssh
    cd /vagrant


Command line commands such as `kubectl`, `helm` and `docker` are
available to be executed as user `vagrant`.

To stop the VM temporarily run following

    vagrant halt


To remove the VM completely run following:

    vagrant destroy


## Executing demos

   * [01-expose-service-externally-with-tls.sh](01-expose-service-externally-with-tls.sh)
   * [02-expose-service-externally-with-internal-tls.sh](02-expose-service-externally-with-internal-tls.sh)
   * [03-expose-service-externally-with-tls-passthrough.sh](03-expose-service-externally-with-tls-passthrough.sh)
   * [04-explore-envoy-tls-proxy-within-cluster.sh](04-explore-envoy-tls-proxy-within-cluster.sh)
   * [05-mixed-client-inside-mesh-accesses-tls-service-outside-mesh.sh](05-mixed-client-inside-mesh-accesses-tls-service-outside-mesh.sh)


## TODO

TODO
To show Istio's TLS authentication rules

    istioctl authn tls-check <HOSTNAME>


## References

* https://istio.io/docs/reference/config/
* The Life of a Packet Through Istio - Deep dive https://mt165.co.uk/speech/life-of-a-packet-istio-devoxx/, https://www.youtube.com/watch?v=cB611FtjHcQ
