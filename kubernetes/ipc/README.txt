# Create a Kind cluster.
kind delete cluster --name ipc
kind create cluster --name ipc


# Build the C examples and load the container to Kind cluster.
docker build -t ipc-test-app:latest docker/ipc-test-app
kind load docker-image ipc-test-app:latest --name ipc


# Create pods that act as placeholders to exec into to run the IPC tests.
kubectl delete -f manifests/deployment.yaml --force --grace-period=0
kubectl apply -f manifests/deployment.yaml


# Examples

###
### Open file in one pod and read it in another pod.
###

kubectl exec -it single-container -- /usr/bin/uds-share-file send /data-host/uds.sock /hello-world.txt
# Output:
#   Opening socket /data-host/uds.sock
#   Accepting connection
#   Sending fd: 3

kubectl exec -it two-containers -c container1 -- /usr/bin/uds-share-file receive /data-host/uds.sock
# Output:
#   Connected to /data-host/uds.sock
#   Received fd: 4
#   Hello world!


###
### Create Posix SHM segment in one pod and read it in another pod.
###


kubectl exec -it single-container -- /usr/bin/uds-share-shm send /data-host/uds.sock "This is in shared memory"
# Output:
#   Message written to shared memory: This is in shared memory
#   Opening socket /data-host/uds.sock
#   Accepting connection

kubectl exec -it two-containers -c container1 -- /usr/bin/uds-share-shm receive /data-host/uds.sock
# Output:
#   Connected to /data-host/uds.sock
#   Received fd: 4
#   Message from writer: This is in shared memory




###
### Use container that has no permissioni to write the unix domain socket file.
###

kubectl exec -it non-root-container -- /usr/bin/uds-share-file receive /data-host/uds.sock
# Output:
#   connect: Permission denied
#   command terminated with exit code 1

# Modify the unix domain socket file permissions to allow non-root container to read the file
kubectl exec -it single-container -- chmod go+w /data-host/uds.sock

# Try again, now it should work:
kubectl exec -it non-root-container -- /usr/bin/uds-share-file receive /data-host/uds.sock
# Output:
#   Connected to /data-host/uds.sock
#   Received fd: 4
#   Hello world!



kubectl exec -it two-containers -c container1 -- /usr/bin/uds-share-file send /data-host/uds.sock /hello-world.txt
kubectl exec -it two-containers -c container2 -- /usr/bin/uds-share-file receive /data-host/uds.sock

kubectl exec -it two-containers -c container1 -- /usr/bin/uds-share-file send /data-emptydir/uds.sock /hello-world.txt
kubectl exec -it two-containers -c container2 -- /usr/bin/uds-share-file receive /data-emptydir/uds.sock


###
### Write data to posix shm in one pod and read it in another pod, using pods that share a host volume.
###

kubectl exec -it dev-shm-on-host-volume-1 -- /usr/bin/shm-posix writer "hello world"
kubectl exec -it dev-shm-on-host-volume-2 -- /usr/bin/shm-posix reader
# Output:
#   Message from writer: hello world


# Following fails since user in the container does not have permission
kubectl exec -it dev-shm-on-host-volume-3-non-root -- /usr/bin/shm-posix reader
# Output:
#   shm_open: Permission denied

# Give read permission to all
kubectl exec -it dev-shm-on-host-volume-1 -- chmod go+r /dev/shm/my_shm

# Attempt read again
kubectl exec -it dev-shm-on-host-volume-3-non-root -- /usr/bin/shm-posix reader
# Output:
#   Message from writer: hello world





###
### Write and read data using sysv shm in one pod and read it in another pod
###

# Containers that do not share the same IPC namespace cannot communicate using sysv shm.
kubectl exec -it single-container -- /usr/bin/shm-sysv writer "hello from single-container"
kubectl exec -it two-containers -c container1 -- /usr/bin/shm-sysv reader


# Containers in same pod share the same IPC namespace, so they can communicate using sysv shm.
kubectl exec -it two-containers -c container1 -- /usr/bin/shm-sysv writer "hello from container1"
kubectl exec -it two-containers -c container2 -- /usr/bin/shm-sysv reader



###
### Sysv shm between pods using hostIPC
###
kubectl exec -it host-ipc-1 -- /usr/bin/shm-sysv writer "hello from host-ipc-1"
kubectl exec -it host-ipc-2 -- /usr/bin/shm-sysv reader

# Since the shm segment is created by root with 0600 permissions and the reader is non-root, the reader cannot read the segment.
kubectl exec -it host-ipc-3-non-root -- /usr/bin/shm-sysv reader
# Output
#   shmget: Permission denied
