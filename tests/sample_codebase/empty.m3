#-------------------------------------------------------------------------------
#  Makefile : empty.m3
#  Description: Module with all empty lists
#-------------------------------------------------------------------------------

include $(BASE_DEV)/MakeRules

L4GLS=

U4GLS=

4GLS=

CFILES=
ECFILES=

4GLOFILES=      $(4GLS:.4gl=.42o) $(L4GLS:.4gl=.42o) $(U4GLS:.4gl=.42o)

all: empty.4ge

empty.4ge:      $(4GLOFILES)
        $(COMPILE_PROG) $(4GLOFILES) -o $@
