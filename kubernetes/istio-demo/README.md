
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


## Executing the demos

Each demo constists of a shell script and a yaml file.  The shell
script contains description of the demo and commands to setup required
Kubernetes and Istio resources and commands to execute the demo.  The
resources are defined in the associated yaml file. At the end of each
script the resources are deleted to cleanup the environment for the
next demo.


Security related demos

* sec-ingress--terminate-tls-in-ingress-gateway [sh](sec-ingress--terminate-tls-in-ingress-gateway.sh), [yaml](sec-ingress--terminate-tls-in-ingress-gateway.yaml)
* sec-ingress--terminate-tls-in-ingress-gateway-using-sni [sh](sec-ingress--terminate-tls-in-ingress-gateway-using-sni.sh), [yaml](sec-ingress--terminate-tls-in-ingress-gateway-using-sni.yaml)
* sec-ingress--terminate-mutual-tls-in-ingress-gateway [sh](sec-ingress--terminate-mutual-tls-in-ingress-gateway.sh), [yaml](sec-ingress--terminate-mutual-tls-in-ingress-gateway.yaml)
* sec-ingress--passthrough-and-terminate-tls-in-service [sh](sec-ingress--passthrough-and-terminate-tls-in-service.sh), [yaml](sec-ingress--passthrough-and-terminate-tls-in-service.yaml)
* sec-ingress--passthrough-and-terminate-ssh-in-service [sh](sec-ingress--passthrough-and-terminate-ssh-in-service.sh), [yaml](sec-ingress--passthrough-and-terminate-ssh-in-service.yaml)
* sec-ingress--use-ingress-gateway-for-service-outside-mesh [sh](sec-ingress--use-ingress-gateway-for-service-outside-mesh.sh), [yaml](sec-ingress--use-ingress-gateway-for-service-outside-mesh.yaml)
* sec-mixed--client-inside-mesh-accesses-service-outside-mesh [sh](sec-mixed--client-inside-mesh-accesses-service-outside-mesh.sh), [yaml](sec-mixed--client-inside-mesh-accesses-service-outside-mesh.yaml)
* sec-mixed--client-outside-mesh-accesses-service-inside-mesh-no-tls [sh](sec-mixed--client-outside-mesh-accesses-service-inside-mesh-no-tls.sh), [yaml](sec-mixed--client-outside-mesh-accesses-service-inside-mesh-no-tls.yaml)
* sec-mixed--client-outside-mesh-accesses-service-inside-mesh-passthrough-tls [sh](sec-mixed--client-outside-mesh-accesses-service-inside-mesh-passthrough-tls.sh), [yaml](sec-mixed--client-outside-mesh-accesses-service-inside-mesh-passthrough-tls.yaml)
* sec-mixed--client-outside-mesh-accesses-service-inside-mesh-using-spiffe-cert [sh](sec-mixed--client-outside-mesh-accesses-service-inside-mesh-using-spiffe-cert.sh), [yaml](sec-mixed--client-outside-mesh-accesses-service-inside-mesh-using-spiffe-cert.yaml)
* sec-explore--istio-proxy-internals [sh](sec-explore--istio-proxy-internals.sh), [yaml](sec-explore--istio-proxy-internals.yaml)
* sec-explore--istio-proxy-no-tls-by-default [sh](sec-explore--istio-proxy-no-tls-by-default.sh), [yaml](sec-explore--istio-proxy-no-tls-by-default.yaml)
* sec-auth--rbac-on-namespace-level [sh](sec-auth--rbac-on-namespace-level.sh), [yaml](sec-auth--rbac-on-namespace-level.yaml)
* sec-auth--rbac-on-service-level [sh](sec-auth--rbac-on-service-level.sh), [yaml](sec-auth--rbac-on-service-level.yaml)


## To be studied and tested

Demos still to be written

* sec-auth--end-user-authorization-with-jwt
* sec-egress--access-external-service
  * configure trusted CA certs https://istio.io/blog/2018/egress-https/
  * configure client cert

Related material to study
* https://github.com/srinandan/istio-workshop

DestinationRule
* use subset by label (see if autoinject could be also using label on pod instead of namespace https://istio.io/help/ops/setup/injection/)
 * default webhook configuration will inject per namespace but it is possible to disable injection per pod
 * in general it seems that many things in istio are related to namespaces, going against it causes problems
 * this does not seem to work, see [sh](todo-sec-explore--subsets-to-select-tls-mode.sh) [yaml](todo-sec-explore--subsets-to-select-tls-mode.yaml)

TLS
* study rotation of root CA certificate and workload certificates
  * potential expiration time related problems are reported in github
  * https://github.com/istio/istio/issues/7630, https://github.com/istio/istio/issues/7479
* any other hooks in Citadel than configuring it as sub-CA?

Authorization
* https://istio.io/blog/2018/istio-authorization/
* https://istio.io/docs/concepts/security/#authorization
* end user authentication with JWT https://istio.io/help/ops/security/end-user-auth/  (see also https://github.com/istio/istio/issues/7290)
  * http://blog.keycloak.org/2018/02/keycloak-and-istio.html and https://issues.jboss.org/browse/KEYCLOAK-5891
  * https://stackoverflow.com/questions/51263388/how-to-set-up-istio-rbac-based-on-groups-from-jwt-claims

Mixer adapters
* authorization adapters
* https://istio.io/docs/reference/config/policy-and-telemetry/adapters/, https://sysdig.com/blog/monitor-istio/
* out-of-tree adapters https://github.com/istio/istio/wiki/Mixer-Out-Of-Process-Adapter-Dev-Guide
* https://github.com/apigee/istio-mixer-adapter

Miscellaneous
* configure several ingress gateways https://stackoverflow.com/questions/51835752/how-to-create-custom-istio-ingress-gateway-controller?rq=1
* show envoy configuration https://istio.io/help/ops/traffic-management/proxy-cmd/

## Findings

TLS
* default validity period of workload certificates is 3 month, root CA certificate 1 year
  * controlled by citadel command line parameters (see [cmd line reference](https://istio.io/docs/reference/commands/istio_ca/) and [faq](https://istio.io/help/faq/security/#cert-lifetime-config))
* RSA 2048
* root key in Secret `istio-ca-secret` in namespace `istio-system`
* provisioning client identities for validating client certs (ingress) or for outbound mutual TLS connections (egress) is not very convenient
  * ingress: whitelisting SANs ([Server.TLSOptions](https://istio.io/docs/reference/config/istio.networking.v1alpha3/#Server-TLSOptions) in Gateway resource)
  * egress: need to modify sidecar / istio-egressgateway to mount client credentials from Secrets
* Certificate handling will change soon with the introduction of Istio Node Agent (see [here](https://istio.io/docs/concepts/security/#node-agent-in-kubernetes-in-development) for short intro)
* Citadel [can act as sub-CA](https://istio.io/docs/tasks/security/plugin-ca-cert/) or in future node agent can use [Vault to issue workload certificates](https://github.com/istio/istio/pull/10638)


## Tips and tricks

To capture traffic from a proxy use the following command. After capturing, open the capture.pcap file to Wireshark.

    sudo tcpdump -s 0 -i any -w capture.pcap port 80 and host $(kubectl -n <NAMESPACE> get pod -l <LABEL> -o jsonpath={.items..podIP})



## References

* Istio configuration reference manual https://istio.io/docs/reference/config/
* The Life of a Packet Through Istio - Deep dive https://mt165.co.uk/speech/life-of-a-packet-istio-devoxx/, https://www.youtube.com/watch?v=cB611FtjHcQ
* Introducing the Istio v1alpha3 routing API https://istio.io/blog/2018/v1alpha3-routing/
