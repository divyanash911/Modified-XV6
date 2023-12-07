// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
  int total_count[(PGROUNDUP(PHYSTOP) - KERNBASE)/PGSIZE];
  struct spinlock lock_count;
} kmem;

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  initlock(&kmem.lock_count, "kmem_count");

  acquire(&kmem.lock_count);
  for(int i = 0; i < (PGROUNDUP(PHYSTOP) - KERNBASE)/PGSIZE; ++i) {
      kmem.total_count[i] = 1;
  }
  release(&kmem.lock_count);
  freerange(end, (void*)PHYSTOP);

}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");


  int x=get_count(pa);
  if(x<=0)panic("kfree");
  
  dec_count(pa);
  x=get_count(pa);

  if(x<=0){

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);}
  return;
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if(r){
    memset((char*)r, 5, PGSIZE); // fill with junk

    acquire(&kmem.lock_count);
    kmem.total_count[get_ind(r)]=1;
    release(&kmem.lock_count);}

  return (void*)r;
}

void inc_count(void* pa){

  acquire(&kmem.lock_count);
  kmem.total_count[get_ind(pa)]++;
  release(&kmem.lock_count);

}

void dec_count(void* pa){

  acquire(&kmem.lock_count);
  kmem.total_count[get_ind(pa)]--;
  release(&kmem.lock_count);

}

int get_count(void* pa){

  int count=-1;
  acquire(&kmem.lock_count);
  count = kmem.total_count[get_ind(pa)];
  release(&kmem.lock_count);
  return count;

}

int get_ind(void* pa){

  return ((uint64)pa-KERNBASE)/PGSIZE;

}