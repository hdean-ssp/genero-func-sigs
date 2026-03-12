#-------------------------------------------------------------------------------
#  Makefile : minimal.m3
#  Description: Minimal module with only 4GLS files, no libraries
#-------------------------------------------------------------------------------

include $(BASE_DEV)/MakeRules

L4GLS=

U4GLS=

4GLS=           minimal.4gl main.4gl

CFILES=
ECFILES=

4GLOFILES=      $(4GLS:.4gl=.42o)
COFILES=        $(CFILES:.c=.o)
ECOFILES=       $(ECFILES:.ec=.o)

all: minimal.4ge

minimal.4ge:    $(4GLOFILES)
        $(COMPILE_PROG) $(4GLOFILES) -o $@
