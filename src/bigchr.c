#include "includes.h"

//CHR ROM larger than 256K (Action 52, large multicarts).
//
//nes_chr_map, the BG and sprite tile caches, and the per-scanline bank buffers
//all store 1K CHR page numbers in single bytes, which only reaches 256K.  For
//bigger CHR ROMs, real pages get 8-bit "virtual" page numbers on demand
//(0-254; 255 already means "no page").  When the numbers run out, the oldest
//one not currently mapped is recycled, and the GBA tile caches holding it are
//invalidated so they re-render from the new page.
//
//The CHR bank switch functions in cart.s live in IWRAM, which is full, so
//instead of adding a check to each of them, bigchr_setup() patches their first
//two instructions into a jump to the ROM-side versions in chrram.s, and puts
//the original instructions back when a normal game is loaded.

#define BIGCHR_MAX_PAGES 2048	//2MB of CHR ROM
#define VIRTUAL_PAGES 255
#define LDR_PC_PC_MINUS_4 0xE51FF004
#define SAVED_MAGIC 0x42474348

extern u8 _agb_real_bg_map[16];

extern void big_chr0_(void), big_chr1_(void), big_chr2_(void), big_chr3_(void);
extern void big_chr4_(void), big_chr5_(void), big_chr6_(void), big_chr7_(void);
extern void big_chr01_(void), big_chr23_(void), big_chr45_(void), big_chr67_(void);
extern void big_chr0123_(void), big_chr4567_(void), big_chr01234567_(void);

#define NUM_PATCHES 15
//chr*_ are declared in asmcalls.h
static void *const patch_from[NUM_PATCHES]=
{
	(void*)chr0_,(void*)chr1_,(void*)chr2_,(void*)chr3_,
	(void*)chr4_,(void*)chr5_,(void*)chr6_,(void*)chr7_,
	(void*)chr01_,(void*)chr23_,(void*)chr45_,(void*)chr67_,
	(void*)chr0123_,(void*)chr4567_,(void*)chr01234567_
};
static void *const patch_to[NUM_PATCHES]=
{
	(void*)big_chr0_,(void*)big_chr1_,(void*)big_chr2_,(void*)big_chr3_,
	(void*)big_chr4_,(void*)big_chr5_,(void*)big_chr6_,(void*)big_chr7_,
	(void*)big_chr01_,(void*)big_chr23_,(void*)big_chr45_,(void*)big_chr67_,
	(void*)big_chr0123_,(void*)big_chr4567_,(void*)big_chr01234567_
};

EWRAM_BSS u8 bigchr_real_to_virtual[BIGCHR_MAX_PAGES] __attribute__((aligned(4)));	//0xFF = no virtual page
EWRAM_BSS u16 bigchr_virtual_to_real[VIRTUAL_PAGES];
EWRAM_BSS u8 *bigchr_base;
EWRAM_BSS u8 bigchr_cursor;
EWRAM_BSS u8 bigchr_patched;
//EWRAM is not cleared at boot, so the saved original instructions carry a magic number
EWRAM_BSS u32 bigchr_saved_magic;
EWRAM_BSS u32 bigchr_saved[NUM_PATCHES][2];

static void set_patches(int on)
{
	int i;
	if (bigchr_saved_magic!=SAVED_MAGIC)
	{
		//first call since power-on: the IWRAM code is unpatched
		for (i=0;i<NUM_PATCHES;i++)
		{
			u32 *code=(u32*)patch_from[i];
			bigchr_saved[i][0]=code[0];
			bigchr_saved[i][1]=code[1];
		}
		bigchr_saved_magic=SAVED_MAGIC;
	}
	for (i=0;i<NUM_PATCHES;i++)
	{
		u32 *code=(u32*)patch_from[i];
		if (on)
		{
			code[0]=LDR_PC_PC_MINUS_4;
			code[1]=(u32)patch_to[i];
		}
		else
		{
			code[0]=bigchr_saved[i][0];
			code[1]=bigchr_saved[i][1];
		}
	}
	bigchr_patched=on;
}

//Called by init_cache after the CHR page table is built.
void bigchr_setup(u8 *chr_base, int chr_1k_pages)
{
	int i;
	if (chr_1k_pages<=256 || chr_1k_pages>BIGCHR_MAX_PAGES)
	{
		if (bigchr_patched==1 || bigchr_saved_magic!=SAVED_MAGIC)
		{
			set_patches(0);
		}
		return;
	}
	bigchr_base=chr_base;
	bigchr_cursor=0;
	//start with virtual page = real page for the first 255 pages
	memset32(bigchr_real_to_virtual,0xFFFFFFFF,BIGCHR_MAX_PAGES);
	for (i=0;i<VIRTUAL_PAGES;i++)
	{
		bigchr_real_to_virtual[i]=i;
		bigchr_virtual_to_real[i]=i;
		instant_chr_banks[i]=chr_base+i*1024;
	}
	set_patches(1);
}

static int page_is_mapped(int v)
{
	int i;
	for (i=0;i<8;i++)
	{
		if (nes_chr_map[i]==v) return 1;
	}
	return 0;
}

//Called from the ROM-side CHR switch functions when a real page has no
//virtual page yet.  Returns the virtual page now assigned to it.
int bigchr_page(int real)
{
	int v;
	int i;
	do
	{
		v=bigchr_cursor;
		bigchr_cursor=(v+1>=VIRTUAL_PAGES)?0:v+1;
	} while (page_is_mapped(v));

	bigchr_real_to_virtual[bigchr_virtual_to_real[v]]=0xFF;
	bigchr_virtual_to_real[v]=real;
	bigchr_real_to_virtual[real]=v;
	instant_chr_banks[v]=bigchr_base+real*1024;

	//anything already converted to GBA tiles from this number is now stale
	for (i=0;i<16;i++)
	{
		if (_agb_real_bg_map[i]==v) _agb_real_bg_map[i]=0xFF;
		if (spr_cache_disp[i]==v) spr_cache_disp[i]=0xFF;
	}
	return v;
}
