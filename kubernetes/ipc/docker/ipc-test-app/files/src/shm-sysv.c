#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <unistd.h>

#define SHM_SIZE 1024
#define SHM_KEY 1234

int main(int argc, char *argv[]) {
  int shmid;
  char *shmaddr;

  if (argc < 2) {
    fprintf(stderr, "Usage: %s <reader|writer|delete>\n", argv[0]);
    exit(1);
  }

  if (strcmp(argv[1], "delete") == 0) {
    if ((shmid = shmget(SHM_KEY, SHM_SIZE, 0)) < 0) {
      perror("shmget");
      exit(1);
    }

    if (shmctl(shmid, IPC_RMID, NULL) < 0) {
      perror("shmctl");
      exit(1);
    }

    printf("Shared memory segment deleted.\n");
    return 0;
  }

  // The permissions here will define who can access the shared memory segment.
  if ((shmid = shmget(SHM_KEY, SHM_SIZE, IPC_CREAT | 0600)) < 0) {
    perror("shmget");
    exit(1);
  }

  if ((shmaddr = shmat(shmid, NULL, 0)) == (char *)-1) {
    perror("shmat");
    exit(1);
  }

  if (strcmp(argv[1], "writer") == 0) {
    if (argc != 3) {
      fprintf(stderr, "Usage: %s writer <message>\n", argv[0]);
      exit(1);
    }
    strncpy(shmaddr, argv[2], SHM_SIZE);
    printf("Message written to shared memory: %s\n", argv[2]);
  } else if (strcmp(argv[1], "reader") == 0) {
    printf("Message read from shared memory: %s\n", shmaddr);
  } else {
    fprintf(stderr, "Invalid argument: %s. Use 'reader' or 'writer'.\n",
            argv[1]);
    exit(1);
  }

  if (shmdt(shmaddr) < 0) {
    perror("shmdt");
    exit(1);
  }

  return 0;
}
