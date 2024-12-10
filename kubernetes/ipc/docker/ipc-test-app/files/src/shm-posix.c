#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#define SHM_NAME "/my_shm"
#define SHM_SIZE 1024

void writer(const char *message) {
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

  munmap(shm_ptr, SHM_SIZE);
  close(shm_fd);
}

void reader() {
  int shm_fd = shm_open(SHM_NAME, O_RDONLY, 0666);
  if (shm_fd == -1) {
    perror("shm_open");
    exit(EXIT_FAILURE);
  }

  void *shm_ptr = mmap(0, SHM_SIZE, PROT_READ, MAP_SHARED, shm_fd, 0);
  if (shm_ptr == MAP_FAILED) {
    perror("mmap");
    exit(EXIT_FAILURE);
  }

  printf("Message from writer: %s\n", (char *)shm_ptr);

  munmap(shm_ptr, SHM_SIZE);
  close(shm_fd);
}

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stderr, "Usage: %s <reader|writer>\n", argv[0]);
    exit(EXIT_FAILURE);
  }

  if (strcmp(argv[1], "writer") == 0) {
    if (argc != 3) {
      fprintf(stderr, "Usage: %s writer <message>\n", argv[0]);
      exit(EXIT_FAILURE);
    }
    writer(argv[2]);
  } else if (strcmp(argv[1], "reader") == 0) {
    reader();
  } else {
    fprintf(stderr, "Invalid argument: %s\n", argv[1]);
    exit(EXIT_FAILURE);
  }

  return 0;
}
