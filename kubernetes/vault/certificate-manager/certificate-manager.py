#!/usr/bin/env python3

import kubernetes
import base64
import hvac
import os
import urllib3
import os.path

# global reference to kubernetes core v1 api
v1 = None


class CertificateManager(object):

    def added(self, pod):
        if 'certificate-manager/kubernetes-secret' in pod.metadata.annotations and 'certificate-manager/cert-san-dnsname' in pod.metadata.annotations:
            hostname   = pod.metadata.annotations['certificate-manager/cert-san-dnsname']
            secretname = pod.metadata.annotations['certificate-manager/kubernetes-secret']
            secretbody = { 'data': self.issue_certificate(hostname) }
            v1.patch_namespaced_secret(secretname, pod.metadata.namespace, secretbody)
            print('updated secret: %s' % secretname)


    def modified(self, pod):
        pass

    def deleted(self, pod):
        pass


    def issue_certificate(self, hostname):
        client = hvac.Client(url=os.environ['VAULT_ADDR'], token=os.environ['VAULT_TOKEN'])
        print('requesting certificate from vault for host=%s' % hostname)
        res = client.write('pki/issue/pods', common_name=hostname)
        data = { 'cert.pem':    base64.b64encode( bytes( res['data']['certificate'], 'utf-8') ).decode('utf-8'),
                 'key.pem':     base64.b64encode( bytes( res['data']['private_key'], 'utf-8') ).decode('utf-8'),
                 'ca-cert.pem': base64.b64encode( bytes( res['data']['issuing_ca'],  'utf-8') ).decode('utf-8') }
        return data


def process_kube_events(listener):

    w = kubernetes.watch.Watch()

    for event in w.stream(v1.list_namespaced_pod, namespace='default'):

        print('k8s event: %s %s' % (event['type'], event['object'].metadata.name))

        if event['type'] == 'ADDED':
            listener.added(event['object'])
        if event['type'] == 'MODIFIED':
            listener.modified(event['object'])
        if event['type'] == 'DELETED':
            listener.deleted(event['object'])


def main():

    if os.path.exists(os.path.expanduser('~/.kube/config')) == True:
        kubernetes.config.load_kube_config()
    else:
        kubernetes.config.load_incluster_config()

    global v1
    v1 = kubernetes.client.CoreV1Api()

    cert_manager = CertificateManager()
    process_kube_events(cert_manager)


if __name__ == '__main__':
    main()
