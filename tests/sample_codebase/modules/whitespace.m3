#-------------------------------------------------------------------------------
#  Makefile : whitespace.m3
#  Description: Module with various whitespace patterns
#-------------------------------------------------------------------------------

include $(BASE_DEV)/MakeRules

L4GLS=lib_a.4gl   lib_b.4gl	lib_c.4gl    lib_d.4gl

U4GLS=		util_x.4gl		util_y.4gl	

4GLS=  whitespace.4gl  helper.4gl  

CFILES=
ECFILES=

4GLOFILES=      $(4GLS:.4gl=.42o) $(L4GLS:.4gl=.42o) $(U4GLS:.4gl=.42o)

all: whitespace.4ge

whitespace.4ge: $(4GLOFILES)
        $(COMPILE_PROG) $(4GLOFILES) -o $@
