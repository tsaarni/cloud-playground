#!/bin/bash -ex

# deploy httpbin and expose it with loadbalancer IP
vagrant ssh kubernetes -c "kubectl apply -f /vagrant/expose-with-external-address.yaml"

# note that the service got assigned external VIP address
vagrant ssh kubernetes -c "kubectl get services"


# re
vagrant ssh oam -c "http http://10.10.11.100/status/418"

vagrant ssh traffic -c "http --timeout=3 http://10.10.11.100/status/418"

vagrant ssh kubernetes -c "kubectl delete -f /vagrant/expose-with-external-address.yaml"
