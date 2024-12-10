/*
 * Sender:
 *
 * 1. Create posix shared memory segment
 * 2. Open Unix Domain Socket
 * 3. Send the shm file descriptor over Unix Domain Socket
 *
 * Receiver:
 *
 * 1. Open Unix Domain Socket
 * 2. Receive the file descriptor over Unix Domain Socket
 * 3. Use mmap to map the shared memory segment to the process
 * 4. Read the shared memory segment
 *
 */
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#define SHM_NAME "/my_shm"
#define SHM_SIZE 1024

// From https://gist.github.com/kokjo/75cec0f466fc34fa2922
void uds_send_fd(int sock, int fd) {
  struct msghdr msg;
  struct iovec iov[1];
  struct cmsghdr *cmsg = NULL;
  char ctrl_buf[CMSG_SPACE(sizeof(int))];
  char data[1];

  memset(&msg, 0, sizeof(struct msghdr));
  memset(ctrl_buf, 0, CMSG_SPACE(sizeof(int)));

  data[0] = ' ';
  iov[0].iov_base = data;
  iov[0].iov_len = sizeof(data);

  msg.msg_name = NULL;
  msg.msg_namelen = 0;
  msg.msg_iov = iov;
  msg.msg_iovlen = 1;
  msg.msg_controllen = CMSG_SPACE(sizeof(int));
  msg.msg_control = ctrl_buf;

  cmsg = CMSG_FIRSTHDR(&msg);
  cmsg->cmsg_level = SOL_SOCKET;
  cmsg->cmsg_type = SCM_RIGHTS;
  cmsg->cmsg_len = CMSG_LEN(sizeof(int));

  *((int *)CMSG_DATA(cmsg)) = fd;

  int ret = sendmsg(sock, &msg, 0);
  if (ret < 0) {
    perror("sendmsg");
  }
}

// From https://web.mit.edu/kolya/misc/break-chroot.c
int uds_recv_fd(int sock) {
  struct msghdr msg;
  struct {
    struct cmsghdr cmsg;
    int fd;
  } cmsg;

  memset(&msg, 0, sizeof(msg));
  memset(&cmsg, 0, sizeof(cmsg));

  msg.msg_iov = NULL;
  msg.msg_iovlen = 0;
  msg.msg_control = &cmsg;
  msg.msg_controllen = sizeof(cmsg);

  cmsg.cmsg.cmsg_len = sizeof(cmsg);
  cmsg.cmsg.cmsg_level = SOL_SOCKET;
  cmsg.cmsg.cmsg_type = SCM_RIGHTS;
  cmsg.fd = -1;

  int ret = recvmsg(sock, &msg, MSG_WAITALL);
  if (ret < 0)
    perror("recvmsg");

  return cmsg.fd;
}

int writer(const char *message) {
  int shm_fd = shm_open(SHM_NAME, O_CREAT | O_RDWR, 0666);
  if (shm_fd == -1) {
    perror("shm_open");
    exit(EXIT_FAILURE);
  }

  if (ftruncate(shm_fd, SHM_SIZE) == -1) {
    perror("ftruncate");
    exit(EXIT_FAILURE);
  }

  void *shm_ptr = mmap(0, SHM_SIZE, PROT_WRITE, MAP_SHARED, shm_fd, 0);
  if (shm_ptr == MAP_FAILED) {
    perror("mmap");
    exit(EXIT_FAILURE);
  }

  strncpy((char *)shm_ptr, message, SHM_SIZE);
  printf("Message written to shared memory: %s\n", message);

  return shm_fd;
}

void reader(int shm_fd) {
  void *shm_ptr = mmap(0, SHM_SIZE, PROT_READ, MAP_SHARED, shm_fd, 0);
  if (shm_ptr == MAP_FAILED) {
    perror("mmap");
    exit(EXIT_FAILURE);
  }

  printf("Message from writer: %s\n", (char *)shm_ptr);

  munmap(shm_ptr, SHM_SIZE);
  close(shm_fd);
}

void sender(const char *socket_path, int fd_to_send) {
  // Open unix domain socket for sending (server).
  unlink(socket_path);

  int udsfd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (udsfd == -1) {
    perror("socket");
    exit(EXIT_FAILURE);
  }

  // Bind UDS socket to the path.
  struct sockaddr_un addr;
  memset(&addr, 0, sizeof(addr));
  addr.sun_family = AF_UNIX;
  strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path) - 1);

  if (bind(udsfd, (struct sockaddr *)&addr, sizeof(addr)) == -1) {
    perror("bind");
    exit(EXIT_FAILURE);
  }

  // Wait for the receiver to connect.
  printf("Opening socket %s\n", socket_path);
  if (listen(udsfd, 1) == -1) {
    perror("listen");
    exit(EXIT_FAILURE);
  }

  // Accept the connection.
  printf("Accepting connection\n");
  int connfd = accept(udsfd, NULL, NULL);
  if (connfd == -1) {
    perror("accept");
    exit(EXIT_FAILURE);
  }

  // Send the fd over unix domain socket.
  printf("Sending fd: %d\n", fd_to_send);
  uds_send_fd(connfd, fd_to_send);
}

int receiver(const char *socket_path) {
  // Open unix domain socket for sending (client).
  int udsfd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (udsfd == -1) {
    perror("socket");
    exit(EXIT_FAILURE);
  }

  // Connect UDS socket using the path.
  struct sockaddr_un addr;
  memset(&addr, 0, sizeof(addr));
  addr.sun_family = AF_UNIX;
  strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path) - 1);

  if (connect(udsfd, (struct sockaddr *)&addr, sizeof(addr)) == -1) {
    perror("connect");
    exit(EXIT_FAILURE);
  }

  printf("Connected to %s\n", socket_path);

  // Receive the fd over unix
  int fd = uds_recv_fd(udsfd);
  printf("Received fd: %d\n", fd);

  return fd;
}

int main(int argc, char *argv[]) {

  if (argc < 2) {
    fprintf(stderr, "Usage: %s <send file|receive>\n", argv[0]);
    exit(EXIT_FAILURE);
  }

  if (strcmp(argv[1], "send") == 0) {
    if (argc != 4) {
      fprintf(stderr, "Usage: %s send <UDS_path> <message>\n", argv[0]);
      exit(EXIT_FAILURE);
    }

    int fd_to_send = writer(argv[3]);
    sender(argv[2], fd_to_send);
  }

  if (strcmp(argv[1], "receive") == 0) {
    if (argc != 3) {
      fprintf(stderr, "Usage: %s receive <UDS_path>\n", argv[0]);
      exit(EXIT_FAILURE);
    }
    int received_fd = receiver(argv[2]);
    reader(received_fd);
  }
}
