#include <puz.h>

#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#include <errno.h>


#ifdef _POSIX_MAPPED_FILES
void  *mmap(void  *start,  size_t length, int prot , int flags, int fd, off_t offset);
int munmap(void *start, size_t length);
#endif
/* ************************************************************************
   Main
   **** */
int main(int argc, char *argv[]) {
  int fd;

  void *base;

  struct stat buf;
  int i, sz;

  struct puzzle_t p;

  char *destfile = NULL;

  if(argc < 2) {
    printf("Usage: %s <file.puz>\n", argv[0]);
    return 0;
  }

  if(argc == 3) {
    destfile = argv[2];
    printf("Will regurgitate into %s as binary after reading\n", argv[2]);
  }

  i = stat(argv[1], &buf);
  if(i != 0) {
    perror("stat:");
    return -1;
  }

  sz = buf.st_size;

  if(!(fd = open(argv[1], O_RDONLY))) {
    perror("open:");
    return -1;
  }

  if(!(base = mmap(NULL, sz, PROT_READ, MAP_SHARED, fd, 0))) {
    perror("mmap");
    return -1;
  }

  if(NULL == puz_load(&p, PUZ_FILE_UNKNOWN, base, sz)) {
    printf("There was an error loading the puzzle file.  See above for details\n");
    return -1;
  }

  puz_cksums_calc(&p);

  i = puz_cksums_check(&p);

  if(0 == i) {
    printf("Checksums look good.\n");
  } else {
    printf("*** Error: %d errors in checksums.\n", i);
  }
#define PRINT_ALL_CONTENT 1
#if PRINT_ALL_CONTENT
  printf("Loaded Puzzle: %s / %s / %s\n\n", 
	 puz_title_get(&p), 
	 puz_author_get(&p),
	 puz_copyright_get(&p));

  printf("  %d x %d, %d clues\n", 
	 puz_width_get(&p), 
	 puz_height_get(&p), 
	 puz_clue_count_get(&p));

  printf("Solution:\n%s\n\n", puz_solution_get(&p));
  printf("Grid:\n%s\n\n", puz_grid_get(&p));

  printf("Clues:\n");
  for(i = 0; i < puz_clue_count_get(&p); i++) {
    printf("  %s\n", puz_clue_get(&p, i));
  }
#endif

  munmap(base, sz);
  close(fd);

  if(destfile) {
    int wfd;
    int wsz;
    void *wbase;

    wsz = puz_size(&p);

    if(wsz == -1) {
      printf("Error sizing puzzle, sorry!\n");
      return -1;
    }

#ifdef O_BINARY /* Yay Windows and VMS */
    wfd = open(destfile, O_CREAT|O_TRUNC|O_RDWR|O_BINARY, S_IRUSR|S_IWUSR);
#else
    wfd = open(destfile, O_CREAT|O_TRUNC|O_RDWR, S_IRUSR|S_IWUSR);
#endif
    if(-1 == wfd) {
      perror("open:");
      return -1;
    }

    i = ftruncate(wfd, wsz);
    if(-1 == i) {
      perror("ftruncate");
      return -1;
    }	

    wbase = NULL;
    wbase = mmap(NULL, wsz, PROT_READ|PROT_WRITE, MAP_SHARED, wfd, 0);

    errno = 0;

    if(0 != errno || MAP_FAILED == wbase) {
      perror("mmap");
      return -1;
    }    

    puz_cksums_calc(&p);
    puz_cksums_commit(&p);
    puz_save(&p, PUZ_FILE_BINARY, wbase, wsz);


    if(i != 0) {
      perror("msync");
      return -1;
    }
    i = msync(wbase, wsz, MS_SYNC);

    //write(wfd, wbase, wsz);

    munmap(wbase, wsz);
    close(wfd);
  }



  return 0;
}
