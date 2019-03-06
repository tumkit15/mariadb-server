/* Copyright (c) 2004, 2010, Oracle and/or its affiliates. All rights reserved.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA */

#include "mysys_priv.h"

#ifdef HAVE_LINUX_LARGE_PAGES

#ifdef HAVE_SYS_IPC_H
#include <sys/ipc.h>
#endif

#ifdef HAVE_SYS_SHM_H
#include <sys/shm.h>
#endif

#include <dirent.h>

static uint my_get_large_page_size_int(void);
static uchar* my_large_malloc_int(size_t size, myf my_flags);
static my_bool my_large_free_int(uchar* ptr);

/* Decending sort - knowing these have been *1024 so reduce overflow */
static int long_cmp(const void *a, const void *b)
{
    const size_t *ia = (const size_t *)a; // casting pointer types
    const size_t *ib = (const size_t *)b;
    return (int) ( ( *ib / 1024L ) - ( *ia / 1024L) );
	/* integer comparison: returns negative if a > b, therefore the bigger a goes first,
	and positive if b > a */
}

uint my_get_large_page_size(void)
{
  uint size;
  DBUG_ENTER("my_get_large_page_size");
  
  if (!(size = my_get_large_page_size_int()))
    fprintf(stderr, "Warning: Failed to determine large page size\n");

  DBUG_RETURN(size);
}

/* Returns the next large page size smaller than passed in size.

 The search starts at my_large_page_sizes[*start]

 Returns the next size found. *start will be incremented to the next
 index within the array afterwards (potentially out of bounds).

 Returns 0 if no size possible.
*/
size_t my_next_large_page_size(size_t sz, int *start)
{
  size_t cur;
  DBUG_ENTER("my_next_large_page_size");

  while (*start < my_large_page_sizes_length
         && my_large_page_sizes[*start] > 0)
  {
    cur= *start;
    (*start)++;
    if (my_large_page_sizes[cur] <= sz)
    {
      DBUG_RETURN(my_large_page_sizes[cur]);
    }
  }
  DBUG_RETURN(0);
}

void my_get_large_page_sizes(size_t sizes[my_large_page_sizes_length])
{
  DIR *dirp;
  struct dirent *r;
  int i= 0;
  DBUG_ENTER("my_get_large_page_sizes");

  dirp= opendir("/sys/kernel/mm/hugepages");
  if (dirp == NULL)
  {
    fprintf(stderr,
            "Warning: failed to open /sys/kernel/mm/hugepages."
            " errno %d\n", errno);
  }
  else
  {
    while (i < my_large_page_sizes_length &&
          (r= readdir(dirp)))
    {
      if (strncmp("hugepages-", r->d_name, 10) == 0)
      {
        sizes[i]= atoll(r->d_name + 10) * 1024L;
        ++i;
      }
    }
    qsort(sizes, i, sizeof(size_t), long_cmp);
  }
  DBUG_VOID_RETURN;
}

/*
  General large pages allocator.
  Tries to allocate memory from large pages pool and falls back to
  my_malloc_lock() in case of failure
*/

uchar* my_large_malloc(size_t size, myf my_flags)
{
  uchar* ptr;
  DBUG_ENTER("my_large_malloc");
  
  if (my_use_large_pages)
  {
    if ((ptr = my_large_malloc_int(size, my_flags)) != NULL)
        DBUG_RETURN(ptr);
    if (my_flags & MY_WME)
      fprintf(stderr, "Warning: Using conventional memory pool\n");
  }
      
  DBUG_RETURN(my_malloc_lock(size, my_flags));
}

/*
  General large pages deallocator.
  Tries to deallocate memory as if it was from large pages pool and falls back
  to my_free_lock() in case of failure
 */

void my_large_free(uchar* ptr)
{
  DBUG_ENTER("my_large_free");
  
  /*
    my_large_free_int() can only fail if ptr was not allocated with
    my_large_malloc_int(), i.e. my_malloc_lock() was used so we should free it
    with my_free_lock()
  */
  if (!my_use_large_pages || !my_large_free_int(ptr))
    my_free_lock(ptr);

  DBUG_VOID_RETURN;
}

#ifdef HUGETLB_USE_PROC_MEMINFO
/* Linux-specific function to determine the size of large pages */

uint my_get_large_page_size_int(void)
{
  MYSQL_FILE *f;
  uint size = 0;
  char buf[256];
  DBUG_ENTER("my_get_large_page_size_int");

  if (!(f= mysql_file_fopen(key_file_proc_meminfo, "/proc/meminfo",
                            O_RDONLY, MYF(MY_WME))))
    goto finish;

  while (mysql_file_fgets(buf, sizeof(buf), f))
    if (sscanf(buf, "Hugepagesize: %u kB", &size))
      break;

  mysql_file_fclose(f, MYF(MY_WME));
  
finish:
  DBUG_RETURN(size * 1024);
}
#endif /* HUGETLB_USE_PROC_MEMINFO */

#if HAVE_DECL_SHM_HUGETLB
/* Linux-specific large pages allocator  */
    
uchar* my_large_malloc_int(size_t size, myf my_flags)
{
  int shmid;
  uchar* ptr;
  struct shmid_ds buf;
  DBUG_ENTER("my_large_malloc_int");

  /* Align block size to my_large_page_size */
  size= MY_ALIGN(size, (size_t) my_large_page_size);
  
  shmid = shmget(IPC_PRIVATE, size, SHM_HUGETLB | SHM_R | SHM_W);
  if (shmid < 0)
  {
    if (my_flags & MY_WME)
      fprintf(stderr,
              "Warning: Failed to allocate %lu bytes from HugeTLB memory."
              " errno %d\n", (ulong) size, errno);

    DBUG_RETURN(NULL);
  }

  ptr = (uchar*) shmat(shmid, NULL, 0);
  if (ptr == (uchar *) -1)
  {
    if (my_flags& MY_WME)
      fprintf(stderr, "Warning: Failed to attach shared memory segment,"
              " errno %d\n", errno);
    shmctl(shmid, IPC_RMID, &buf);

    DBUG_RETURN(NULL);
  }

  /*
    Remove the shared memory segment so that it will be automatically freed
    after memory is detached or process exits
  */
  shmctl(shmid, IPC_RMID, &buf);

  DBUG_RETURN(ptr);
}

/* Linux-specific large pages deallocator */

my_bool my_large_free_int(uchar *ptr)
{
  DBUG_ENTER("my_large_free_int");
  DBUG_RETURN(shmdt(ptr) == 0);
}
#endif /* HAVE_DECL_SHM_HUGETLB */

#endif /* HAVE_LINUX_LARGE_PAGES */
