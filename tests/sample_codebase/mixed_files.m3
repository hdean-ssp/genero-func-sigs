#-------------------------------------------------------------------------------
#  Makefile : mixed_files.m3
#  Description: Module with mixed file types (should only extract .4gl files)
#-------------------------------------------------------------------------------

include $(BASE_DEV)/MakeRules

L4GLS=          lib_core.4gl lib_base.4gl

U4GLS=          util_main.4gl

4GLS=           mixed.4gl interface.4gl

CFILES=         helper.c utils.c
ECFILES=        database.ec query.ec

4GLOFILES=      $(4GLS:.4gl=.42o) $(L4GLS:.4gl=.42o) $(U4GLS:.4gl=.42o)
COFILES=        $(CFILES:.c=.o)
ECOFILES=       $(ECFILES:.ec=.o)

all: mixed.4ge

mixed.4ge:      $(4GLOFILES) $(COFILES) $(ECOFILES)
        $(COMPILE_PROG) $(4GLOFILES) $(COFILES) $(ECOFILES) -o $@
