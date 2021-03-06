CFLAGS=-W -Wall -finline-functions -fPIC -std=gnu99

CLIB=-lpthread -lz -lm

OS := $(shell uname)
ifeq ($(OS),  Darwin)
  CFLAGS += -Wno-unused-function
else
	CLIB += -lrt
endif

INCLUDE = include

LSAM0119D = lib/libsamtools-0.1.19
LSAM0119 = $(LSAM0119D)/libsam.a

LUTILSD = lib/utils
LUTILS = lib/utils/libutils.a

########### program ##########

# detect :
# 	@echo "$$CFLAGS" $(CFLAGS)

PROG = bin/biscuit
# PROG = bin/hemifinder bin/correct_bsstrand bin/get_unmapped bin/sample_trinuc

release : CFLAGS += -O3
release : $(PROG)

debug : CFLAGS += -g
debug : $(PROG)

LIBS=lib/aln/libaln.a src/pileup.o src/markdup.o src/ndr.o src/vcf2bed.o src/epiread.o lib/klib/klib.a $(LSAM0119) $(LUTILS)
bin/biscuit: $(LIBS) src/main.o
	mkdir -p bin
	gcc $(CFLAGS) src/main.o -o $@ -I$(INCLUDE)/aln -I$(INCLUDE)/klib $(LIBS) $(CLIB)
clean_biscuit:
	rm -f bin/biscuit

######### external ###########

$(LSAM0119) :
	make -C $(LSAM0119D) libsam.a

.PHONY: klib
klib: lib/klib/klib.a
KLIBD = lib/klib
KLIBOBJ = $(KLIBD)/kstring.o $(KLIBD)/kopen.o $(KLIBD)/kthread.o $(KLIBD)/ksw.o
lib/klib/klib.a: $(KLIBOBJ)
	ar -csru $@ $(KLIBOBJ)
$(KLIBD)/%.o: $(KLIBD)/%.c
	gcc -c $(CFLAGS) -I$(INCLUDE)/klib $< -o $@
clean_klib:
	rm -f $(KLIBD)/*.o lib/klib/klib.a

####### libraries #######

.PHONY: utils
utils: $(LUTILS)
LUTILSOBJ = $(LUTILSD)/encode.o $(LUTILSD)/stats.o $(LUTILSD)/wzhmm.o
$(LUTILS): $(LUTILSOBJ)
	ar -csru $@ $(LUTILSOBJ)
$(LUTILSD)/%.o: $(LUTILSD)/%.c
	gcc -c $(CFLAGS) -I$(INCLUDE) $< -o $@
clean_utils:
	rm -f $(LUTILSD)/*.o $(LUTILS)

####### subcommands #######

src/main.o: src/main.c
	gcc -c $(CFLAGS) src/main.c -o $@ -I$(INCLUDE) -I$(INCLUDE)/aln -I$(INCLUDE)/klib
clean_main:
	rm -f src/main.o

LALND = lib/aln
LALNOBJ = $(LALND)/bntseq.o $(LALND)/bwamem.o $(LALND)/bwashm.o $(LALND)/bwt_gen.o $(LALND)/bwtsw2_chain.o $(LALND)/bwtsw2_pair.o $(LALND)/malloc_wrap.o $(LALND)/bwamem_extra.o $(LALND)/bwt.o $(LALND)/bwtindex.o $(LALND)/bwtsw2_core.o $(LALND)/fastmap.o  $(LALND)/QSufSort.o $(LALND)/bwa.o $(LALND)/bwamem_pair.o $(LALND)/bwtgap.o $(LALND)/bwtsw2_aux.o $(LALND)/bwtsw2_main.o $(LALND)/is.o $(LALND)/utils.o
lib/aln/libaln.a: $(LALNOBJ)
	ar -csru $@ $(LALNOBJ)
$(LALND)/%.o: $(LALND)/%.c
	gcc -c $(CFLAGS) -I$(INCLUDE) -I$(INCLUDE)/aln -I$(INCLUDE)/klib $< -o $@
clean_aln:
	rm -f $(LALND)/*.o lib/aln/libaln.a

src/pileup.o: src/pileup.c
	gcc -c $(CFLAGS) -o $@ -I$(LSAM0119D) -I$(INCLUDE) src/pileup.c
clean_pileup:
	rm -f src/pileup.o

src/markdup.o: src/markdup.c
	gcc -c $(CFLAGS) -o $@ -I$(LSAM0119D) -I$(INCLUDE) src/markdup.c
clean_markdup:
	rm -f src/markdup.o

src/ndr.o: src/ndr.c
	gcc -c $(CFLAGS) -I$(INCLUDE) -I$(INCLUDE)/klib $< -o $@
clean_ndr:
	rm -f src/ndr.o

src/vcf2bed.o: src/vcf2bed.c
	gcc -c $(CFLAGS) -I$(INCLUDE) -I$(INCLUDE)/klib $< -o $@
clean_vcf2bed:
	rm -f src/vcf2bed.o

src/epiread.o: src/epiread.c
	gcc -c $(CFLAGS) -I$(INCLUDE) -I$(LSAM0119D) -I$(INCLUDE)/klib $< -o $@
clean_epiread:
	rm -f src/epiread.o

####### general #######

.c.o :
	gcc -c $(CFLAGS) $< -o $@

####### clean #######

CLEAN_TARGETS=clean_biscuit clean_main clean_aln clean_utils clean_pileup clean_klib clean_markdup clean_ndr clean_vcf2bed clean_epiread
.PHONY: clean
clean : $(CLEAN_TARGETS)
	make -C $(LSAM0119D) clean

####### archived #######

.PHONY: correct_bsstrand
correct_bsstrand : bin/correct_bsstrand
bin/correct_bsstrand: $(LSAM0119)
	gcc $(CFLAGS) -o $@ -I$(INCLUDE) -I$(LSAM0119D) src/correct_bsstrand/correct_bsstrand.c $(LSAM0119) -lz -lpthread
clean_correct_bsstrand:
	rm -f bin/correct_bsstrand

# get unmapped reads from bam
.PHONY: get_unmapped
get_unmapped : bin/get_unmapped
bin/get_unmapped : $(LSAM0119)
	gcc $(CFLAGS) -o $@ -I$(LSAM0119D) src/get_unmapped/get_unmapped.c $(LSAM0119) -lz -lpthread
clean_get_unmapped:
	rm -f bin/get_unmapped

# get trinuc spectrum
.PHONY: sample_trinuc
sample_trinuc : bin/sample_trinuc
bin/sample_trinuc: $(LSAM0119) src/sample_trinuc/sample_trinuc.c
	gcc $(CFLAGS) -o $@ -I$(LSAM0119D) -I$(INCLUDE) src/sample_trinuc/sample_trinuc.c -lpthread $(LSAM0119) $(LUTILS) -lz
clean_sample_trinuc:
	rm -f bin/sample_trinuc

# find hemi methylation
.PHONY: hemifinder
hemifinder : bin/hemifinder
bin/hemifinder: $(LSAM0119) $(LUTILS) src/hemifinder/hemifinder.c
	gcc $(CFLAGS) -o $@ -I$(LSAM0119D) -I$(INCLUDE) src/hemifinder/hemifinder.c $(LSAM0119) $(LUTILS) -lpthread  -lz
clean_hemifinder:
	rm -f bin/hemifinder
