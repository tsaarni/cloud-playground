
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



## Demo

The demo can be executed by running the listed commands inside Virtualbox.



### Istio ingress gateway

Store the ingress gateway certificate and key in a Secret

    kubectl create -n istio-system secret tls istio-ingressgateway-certs --key gateway-key.pem --cert gateway.pem


Run service that is exposed externally via Istio Gateway

    kubectl -n inside apply -f manifests/istio-expose-external.yaml


Make request via the Gateway

    http -v --verify server-root.pem https://host1.external.com:31390/status/418 host:host1.external.com


See that the internal traffic is unprotected

    # capture traffic from httpbin pod
    sudo tcpdump -vvvv -s 0 -A -i any -n src port 80 and host $(kubectl -n inside get pod -l app=httpbin -o jsonpath={.items..podIP})

    # make request via gateway
    http -v --verify server-root.pem https://host1.external.com:31390/status/418 host:host1.external.com


Enable mutual TLS policy in Istio

    kubectl apply -f manifests/istio-default-mtls-policy.yaml


Repeat the request and see that traffic is now protected

    # capture traffic from httpbin pod
    sudo tcpdump -vvvv -s 0 -A -i any -n src port 80 and host $(kubectl -n inside get pod -l app=httpbin -o jsonpath={.items..podIP})

    # make request via gateway
    http -v --verify server-root.pem https://host1.external.com:31390/status/418 host:host1.external.com



Delete the demo

    kubectl delete -f manifests/istio-default-mtls-policy.yaml
    kubectl -n inside delete -f manifests/istio-expose-external.yaml


### Internal


TODO



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


## References

* https://istio.io/docs/reference/config/
* explanation for Istio networking https://blog.sebastian-daschner.com/entries/istio-networking-api-explained and https://www.youtube.com/watch?v=qQsZ5Azzqec
