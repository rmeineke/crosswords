/******************************************************************
 * libpuz - A .PUZ crossword library
 * Copyright(c) 2006 Josh Myer <josh@joshisanerd.com>
 * 
 * This code is released under the terms of the GNU General Public
 * License version 2 or later.  You should have receieved a copy as
 * along with this source as the file COPYING.
 ******************************************************************/

/*
 * puzzle.c -- Implements the puzzle accessor routines
 */



#include <puz.h>

/**
 * puz_init - initialize a puzzle
 *
 * @puz: pointer to the struct puzzle_t to init.  If NULL, one will be malloc'd for you.
 *
 * This function is used to initialize a new struct puzzle_t to sane defaults.
 *
 * Return Value: NULL on error, else a pointer to the filled-in struct
 * puzzle_t.  If puz was NULL, this is a pointer to the
 * newly-allocated structure.
 */
struct puzzle_t *puz_init(struct puzzle_t *puz) {
  int didmalloc;

  unsigned char file_magic[12] = FILE_MAGIC;
  unsigned char magic_18[4] = VER_MAGIC;

 if(NULL == puz) {
    puz = (struct puzzle_t *)malloc(sizeof(struct puzzle_t));
    if(NULL == puz) {
      perror("malloc");
      return NULL;
    }
    didmalloc = 1;
  }

  memset(puz, 0, sizeof(struct puzzle_t));

  memcpy(puz->header.magic, file_magic, 12);
  memcpy(puz->header.magic_18, magic_18, 4);
  puz->header.x_unk_30 = 0x0001;

  return puz;
}

/**
 * puz_size - calculate the size of a puzzle as a PUZ file
 *
 * @puz: a pointer to the struct puzzle_t to size
 *
 * This function is used to calculate the size of the PUZ file for a
 * given puzzle.
 *
 * Return value: -1 on error, a positive (non-zero) integer size on
 * success.
 */
int puz_size(struct puzzle_t *puz) {
  int i, sz;

  if(!puz)
    return -1;

  sz = 0x34; // header
  sz += puz_width_get(puz) * puz_height_get(puz); // solution
  sz += puz_width_get(puz) * puz_height_get(puz); // grid
  sz += Sstrlen(puz_title_get(puz)) + 1;  // title
  sz += Sstrlen(puz_author_get(puz)) + 1; // author
  sz += Sstrlen(puz_copyright_get(puz)) + 1; // copyright

  for(i = 0; i < puz_clue_count_get(puz); i++) {
    sz += Sstrlen(puz_clue_get(puz, i)) + 1;
  }

  if(puz->notes_sz)
    sz += puz->notes_sz;

  return sz;
}


/**
 * puz_width_get - get the puzzle's width
 *
 * @puz: a pointer to the struct puzzle_t to read from (required)
 *
 * Returns -1 on error; else a non-negative value
 */
int puz_width_get(struct puzzle_t *puz) {
  if(NULL == puz)
    return -1;

  return(puz->header.width);
}

/**
 * puz_width_set - set the puzzle's width
 *
 * @puz: a pointer to the struct puzzle_t to write to (required)
 * @val: the (positive) value to set width to (required)
 * 
 * returns -1 on error, else the old value of width
 */
int puz_width_set(struct puzzle_t *puz, unsigned char val) {
  int i;

  if(NULL == puz)
    return -1;

  i = puz->header.width;

  puz->header.width = val;

  return(i);
}

/**
 * puz_height_get - get the puzzle's height
 *
 * @puz: a pointer to the struct puzzle_t to read from (required)
 *
 * Returns -1 on error; else a non-negative value
 */
int puz_height_get(struct puzzle_t *puz) {
  if(NULL == puz)
    return -1;

  return(puz->header.height);
}

/**
 * puz_height_set - set the puzzle's height
 *
 * @puz: a pointer to the struct puzzle_t to write to (required)
 * @val: the (positive) value to set height to (required)
 * 
 * returns -1 on error, else the old value of height
 */
int puz_height_set(struct puzzle_t *puz, unsigned char val) {
  int i;

  if(NULL == puz)
    return -1;

  i = puz->header.height;

  puz->header.height = val;

  return(i);
}

/**
 * puz_solution_get - get the puzzle's solution
 *
 * @puz: a pointer to the struct puzzle_t to read from (required)
 *
 * Returns NULL on error or if field is unset.
 */
unsigned char * puz_solution_get(struct puzzle_t *puz) {
  if(NULL == puz)
    return NULL;

  return(puz->solution);
}

/**
 * puz_solution_set - set the puzzle's solution
 *
 * @puz: a pointer to the struct puzzle_t to write to (required)
 * @val: a pointer to the string to st the value to (required)
 * 
 * returns NULL on error, else a pointer to the struct's copy of the string
 */
unsigned char * puz_solution_set(struct puzzle_t *puz, unsigned char *val) {
  if(NULL == puz || NULL == val)
    return NULL;

  free(puz->solution);

  puz->solution = Sstrdup(val);

  return puz->solution;
}


/**
 * puz_grid_get - get the puzzle's grid
 *
 * @puz: a pointer to the struct puzzle_t to read from (required)
 *
 * Returns NULL on error or if field is unset.
 */
unsigned char * puz_grid_get(struct puzzle_t *puz) {
  if(NULL == puz)
    return NULL;

  return(puz->grid);
}

/**
 * puz_grid_set - set the puzzle's grid
 *
 * @puz: a pointer to the struct puzzle_t to write to (required)
 * @val: a pointer to the string to st the value to (required)
 * 
 * returns NULL on error, else a pointer to the struct's copy of the string
 */
unsigned char * puz_grid_set(struct puzzle_t *puz, unsigned char *val) {
  if(NULL == puz || NULL == val)
    return NULL;

  free(puz->grid);

  puz->grid = Sstrdup(val);

  return puz->grid;
}


/**
 * puz_title_get - get the puzzle's title
 *
 * @puz: a pointer to the struct puzzle_t to read from (required)
 *
 * Returns NULL on error or if field is unset.
 */
unsigned char * puz_title_get(struct puzzle_t *puz) {
  if(NULL == puz)
    return NULL;

  return(puz->title);
}

/**
 * puz_title_set - set the puzzle's title
 *
 * @puz: a pointer to the struct puzzle_t to write to (required)
 * @val: a pointer to the string to st the value to (required)
 * 
 * returns NULL on error, else a pointer to the struct's copy of the string
 */
unsigned char * puz_title_set(struct puzzle_t *puz, unsigned char *val) {
  if(NULL == puz || NULL == val)
    return NULL;

  free(puz->title);

  puz->title = Sstrdup(val);

  return puz->title;
}


/**
 * puz_author_get - get the puzzle's author
 *
 * @puz: a pointer to the struct puzzle_t to read from (required)
 *
 * Returns NULL on error or if field is unset.
 */
unsigned char * puz_author_get(struct puzzle_t *puz) {
  if(NULL == puz)
    return NULL;

  return(puz->author);
}

/**
 * puz_author_set - set the puzzle's author
 *
 * @puz: a pointer to the struct puzzle_t to write to (required)
 * @val: a pointer to the string to st the value to (required)
 * 
 * returns NULL on error, else a pointer to the struct's copy of the string
 */
unsigned char * puz_author_set(struct puzzle_t *puz, unsigned char *val) {
  if(NULL == puz || NULL == val)
    return NULL;

  free(puz->author);

  puz->author = Sstrdup(val);

  return puz->author;
}


/**
 * puz_copyright_get - get the puzzle's copyright
 *
 * @puz: a pointer to the struct puzzle_t to read from (required)
 *
 * Returns NULL on error or if field is unset.
 */
unsigned char * puz_copyright_get(struct puzzle_t *puz) {
  if(NULL == puz)
    return NULL;

  return(puz->copyright);
}

/**
 * puz_copyright_set - set the puzzle's copyright
 *
 * @puz: a pointer to the struct puzzle_t to write to (required)
 * @val: a pointer to the string to st the value to (required)
 * 
 * returns NULL on error, else a pointer to the struct's copy of the string
 */
unsigned char * puz_copyright_set(struct puzzle_t *puz, unsigned char *val) {
  if(NULL == puz || NULL == val)
    return NULL;

  free(puz->copyright);

  puz->copyright = Sstrdup(val);

  return puz->copyright;
}


/**
 * puz_notes_get - get the puzzle's notes
 *
 * @puz: a pointer to the struct puzzle_t to read from (required)
 *
 * Returns NULL on error or if field is unset.
 */
unsigned char * puz_notes_get(struct puzzle_t *puz) {
  if(NULL == puz)
    return NULL;

  return(puz->notes);
}

/**
 * puz_notes_set - set the puzzle's notes
 *
 * @puz: a pointer to the struct puzzle_t to write to (required)
 * @val: a pointer to the string to st the value to (required)
 * 
 * returns NULL on error, else a pointer to the struct's copy of the string
 */
unsigned char * puz_notes_set(struct puzzle_t *puz, unsigned char *val) {
  if(NULL == puz || NULL == val)
    return NULL;

  free(puz->notes);

  puz->notes = Sstrdup(val);

  return puz->notes;
}





/**
 * puz_clue_count_get - get the puzzle's clue_count
 *
 * @puz: a pointer to the struct puzzle_t to read from (required)
 *
 * Returns -1 on error; else a non-negative value
 */
int puz_clue_count_get(struct puzzle_t *puz) {
  if(NULL == puz)
    return -1;

  return(puz->header.clue_count);
}

/**
 * puz_clue_count_set - set the puzzle's clue_count
 *
 * @puz: a pointer to the struct puzzle_t to write to (required)
 * @val: the (positive) value to set clue_count to (required)
 * 

 * This function can only be used to set the number of clues for a
 * blank puzzle.  If a puzzle has been filled in and you want to set
 * the number of clues to a different value, you'll need to first
 * clear the clues with puz_clear_clues(), then set the number of
 * clues, and finally fill the clues back in.
 *
 * returns -1 on error, 0 on success.
 */
int puz_clue_count_set(struct puzzle_t *puz, int val) {
  if(NULL == puz || 0 > val)
    return -1;

  if(puz->header.clue_count != 0)
    return -1;

  puz->clues = (unsigned char **)malloc(val * sizeof(unsigned char *));
  memset(puz->clues, 0, val * sizeof(unsigned char *));

  puz->header.clue_count = val;

  return(0);
}

/**
 * puz_clear_clues - clear out a puzzle's clues
 *
 * @puz: a pointer to the struct puzzle_t to clear clues from (required)
 *
 * This function clears out the clues.  Specifically, it frees all
 * clues, the clues storage, and sets the number of clues to zero.
 *
 * Note that any pointers you have to clues will become invalid after
 * calling this function.
 *
 * Returns -1 on error, 0 on success.
 */
int puz_clear_clues(struct puzzle_t *puz) {
  int i;

  if(NULL == puz)
    return -1;

  for(i = 0; i < puz->header.clue_count; i++)
    free(puz->clues[i]);
  
  free(puz->clues);

  puz->clues = NULL;
  puz->header.clue_count = 0;

  return 0;
}
/**
 * puz_clue_get -- get the nth clue of a puzzle
 * 
 * @puz: a pointer to the struct puzzle_t to read from (required)
 * @n: the index (between zero and n_clues) to get
 *
 * Returns NULL on error, pointer to the nth clue on success.
 */
unsigned char * puz_clue_get(struct puzzle_t *puz, int n) {
  if(NULL == puz || n < 0 || n > puz->header.clue_count)
    return NULL;

  return puz->clues[n];
}


/**
 * puz_clue_set -- set the nth clue of a puzzle
 * 
 * @puz: a pointer to the struct puzzle_t to read from (required)
 * @n: the index (between zero and n_clues) to get
 * @val: the value to set it to
 *
 * Returns NULL on error, pointer to the puzzle's new copy on success.
 */
unsigned char * puz_clue_set(struct puzzle_t *puz, int n, unsigned char * val) {
  if(NULL == puz || n < 0 || n > puz->header.clue_count || NULL == val)
    return NULL;

  free(puz->clues[n]);
  puz->clues[n] = Sstrdup(val);

  return puz->clues[n];
}

