#!/bin/bash -ex
#
# Description
#
# Check that all control plane components implement TLS
#
# Note: To see what each control plane component does,
# read https://istio.io/docs/concepts/what-is-istio/
#

# create resources
kubectl apply -f sec-explore--istio-proxy-internals.yaml

# check what is running
kubectl -n istio-system get pods

# note that pilot and mixer (istio-policy and istio-telemetry) are running with sidecars


#############################################
#
# Citadel
#
#  - command line parameters https://istio.io/docs/reference/commands/istio_ca/
#  - source code https://github.com/istio/istio/tree/master/security
#

# check the ports that are open
#   - 8060 and 9093
kubectl -n istio-system describe pod -l istio=citadel
sudo nsenter -t $(pidof istio_ca) -n netstat --all --program --numeric

# Port 8060 is Citadel GRPC server
echo Q | openssl s_client -connect $(kubectl -n istio-system get pod -l istio=citadel -o jsonpath={..podIP}):8060 | openssl x509 -text -noout

# Port 9093 is unprotected HTTP server for prometheus monitoring (can be disabled)
http http://$(kubectl -n istio-system get pod -l istio=citadel -o jsonpath={..podIP}):9093/metrics
http http://$(kubectl -n istio-system get pod -l istio=citadel -o jsonpath={..podIP}):9093/version


#############################################
#
# Pilot
#
#  - command line parameters
#    - https://istio.io/docs/reference/commands/pilot-agent/
#    - https://istio.io/docs/reference/commands/pilot-discovery/
#

# check the ports that are open
#    - 8080, 9093, 15010 (discovery)
#    - 15003, 15005, 15007, 15011 (envoy/istio-proxy)

kubectl -n istio-system describe pod -l istio=pilot
sudo nsenter -t $(pidof pilot-discovery) -n netstat --all --program --numeric

# 8080 (for istioctl) and 9093 (for prometheus) is unprotected discovery servcice HTTP
# source code
#  - https://github.com/istio/istio/tree/master/pilot/pkg/proxy/envoy/v2
#  - https://github.com/istio/istio/blob/master/pilot/pkg/proxy/envoy/v2/debug.go
http http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):8080/debug/adsz  # listeners and routes
http http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):8080/debug/edsz  # endpoints
http http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):8080/debug/cdsz  # clusters
http http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):8080/debug/syncz

http http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):8080/debug/registryz
http http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):8080/debug/endpointz
http http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):8080/debug/endpointShardz
http http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):8080/debug/workloadz
http http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):8080/debug/configz

http http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):8080/debug/authenticationz
http "http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):8080/debug/config_dump?proxyID=istio-ingressgateway-5b6f6f75b9-spps4.istio-system" # see "istioctl proxy-status" for proxyIDs
http http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):8080/debug/push_status

http http://$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):9093/metrics # for prometheus

# 15010 is unprotected discovery service GRPC address - can be protected by envoy when mTLS enabled
# 15012 is protected discovery service GRPC address
#   - GRPC protocol https://github.com/envoyproxy/data-plane-api/blob/master/XDS_PROTOCO
echo Q | openssl s_client -connect $(kubectl -n istio-system get pod -l istio=pilot -o jsonpath={..podIP}):15012 | openssl x509 -text -noout


#############################################
#
# Galley
#
#  - command line parameters https://istio.io/docs/reference/commands/galley/
#  - source code https://github.com/istio/istio/tree/master/galley
#

# check the ports that are open
#  - 443 and 9093
kubectl -n istio-system describe pod -l istio=galley
sudo nsenter -t $(pidof galley) -n netstat --all --program --numeric

# 443 is HTTPS port for CRD validation webhook
#  - https://github.com/istio/istio/tree/master/galley/pkg/crd/validation
# check the certificate
echo Q | openssl s_client -connect $(kubectl -n istio-system get pod -l istio=galley -o jsonpath={..podIP}):443 | openssl x509 -text -noout

# 9093 is unprotected HTTP server for prometheus monitoring
#    - parameter --monitoringPort <uint> Port to use for the exposing self-monitoring information (default `9093`)
# code is here
#    - https://github.com/istio/istio/blob/master/galley/pkg/server/monitoring.go
#
# following data is exposed
http http://$(kubectl -n istio-system get pod -l istio=galley -o jsonpath={..podIP}):9093/metrics
http http://$(kubectl -n istio-system get pod -l istio=galley -o jsonpath={..podIP}):9093/version



#############################################
#
# Sidecar injector
#

# check the ports that are open
#   - 443
kubectl -n istio-system describe pod -l istio=sidecar-injector
sudo nsenter -t $(pidof sidecar-injector) -n netstat --all --program --numeric

# 443 is HTTPS port for mutating webhook calls
echo Q | openssl s_client -connect $(kubectl -n istio-system get pod -l istio=sidecar-injector -o jsonpath={..podIP}):443 | openssl x509 -text -noout


#############################################
#
# Mixer
#
#  - command line parameters https://istio.io/docs/reference/commands/mixs/
#  - source code https://github.com/istio/istio/tree/master/mixer
#

# out-of-process Mixer plugin GRPC interface is not protected currently
# https://github.com/istio/api/pull/606
#  - can be alternatively protected by running adapter within mesh

# mixer policy
# check the ports that are open
#   - 9091 is unprotected Mixer GRPC
#   - 9093 is unprotected HTTP server for prometheus monitoring
#   - 42422 is unprotected mixer prometheus listener
# envoy proxy ports
#   - 15004 incoming policy check calls
#   - 15090 prometheus
kubectl -n istio-system describe pod -l istio-mixer-type=policy

containerid=$(kubectl -n istio-system get pod -l istio-mixer-type=policy -o jsonpath='{..containerStatuses[0].containerID}')
containerid=${containerid#docker://}  # strip out the docker:// prefix
containerpid=$(docker inspect --format '{{ .State.Pid }}' $containerid)
sudo nsenter -t $containerpid -n netstat --all --program --numeric

http http://$(kubectl -n istio-system get pod -l istio-mixer-type=policy -o jsonpath={..podIP}):15090/stats/prometheus

# mixer telemetry
# check the ports that are open
#   - 9093 is unprotected HTTP server for prometheus monitoring
#   - 9091 is unprotected Mixer GRPC
#   - 42422 is unprotected mixer prometheus listener
# envoy proxy ports
#   - 15004 incoming policy check calls
kubectl -n istio-system describe pod -l istio-mixer-type=telemetry

containerid=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{..containerStatuses[0].containerID}')
containerid=${containerid#docker://}  # strip out the docker:// prefix
containerpid=$(docker inspect --format '{{ .State.Pid }}' $containerid)
sudo nsenter -t $containerpid -n netstat --all --program --numeric

http http://$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath={..podIP}):15090/stats/prometheus

# delete resources
kubectl delete -f sec-explore--istio-proxy-internals.yaml
