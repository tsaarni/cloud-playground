
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


The command will automatically download Ubuntu 16.04 image, launch it,
and then install Kubernetes and Istio.

You can either connect to the VM to use tools such as `kubectl`, `helm` and
`docker`:

    vagrant ssh


or alternatively you can use the tools from host OS by setting following environment
variables (Linux and MacOS):

    export KUBECONFIG=$PWD/admin.conf
    export DOCKER_HOST=tcp://localhost:2375


To remove the VM run following on host OS:

    vagrant destroy



## Build and deploy demo-services

Build container image with the demo services included.

    docker build -t httpbin:latest docker/httpbin
    docker build -t demo:latest docker/demo


Create namespaces `inside` and `outside`.  The first is where
automatic istio sidecar injection is enabled and second is hosting
microservices outside service mesh


    kubectl create ns inside
    kubectl create ns outside

    kubectl label namespace inside istio-injection=enabled


Declare [authentication policy to enable mutual TLS](https://istio.io/docs/tasks/security/authn-policy/)

    kubectl apply -f manifests/istio-default-mtls-policy.yaml


Deploy the microservices.  Note that the Services must have
[named ports](https://istio.io/docs/setup/kubernetes/spec-requirements/)
in order to work with Istio.

    kubectl -n inside  apply -f manifests/httpbin.yaml
    kubectl -n outside apply -f manifests/httpbin.yaml
    kubectl -n inside  apply -f manifests/client.yaml
    kubectl -n outside apply -f manifests/client.yaml
    kubectl -n inside  apply -f manifests/echo.yaml
    kubectl -n outside apply -f manifests/echo.yaml


Start shell on the client pods

    kubectl -n inside  exec -it $(kubectl -n inside  get pod -l app=client -o jsonpath={.items..metadata.name}) ash
    kubectl -n outside exec -it $(kubectl -n outside get pod -l app=client -o jsonpath={.items..metadata.name}) ash


Test connectivity by running following on the client shells

    # test http service
    http http://httpbin.inside/ip
    http http://httpbin.outside/ip

    # test echo service
    telnet echo.inside echo
    telnet echo.outside echo


To allow non-TLS traffic to services running on namespace `outside`:

    kubectl apply -f manifests/istio-outside-destination-rule.yaml


To show Istio's TLS authentication rules

    istioctl authn tls-check httpbin.inside.svc.cluster.local


## Certificates

Use following commands to generate certificates

    cfssl genkey -initca configs/cfssl-csr-root-ca-server.json | cfssljson -bare server-root
    cfssl certinfo -cert server-root.pem

    cfssl genkey -initca configs/cfssl-csr-root-ca-client.json | cfssljson -bare client-root
    cfssl certinfo -cert client-root.pem

    cfssl gencert -ca server-root.pem -ca-key server-root-key.pem configs/cfssl-csr-endentity-httpbin.json | cfssljson -bare httpbin
    cfssl certinfo -cert httpbin.pem

    cfssl gencert -ca client-root.pem -ca-key client-root-key.pem configs/cfssl-csr-endentity-client.json | cfssljson -bare client
    cfssl certinfo -cert httpbin.pem


## References

* https://istio.io/docs/reference/config/
