#-------------------------------------------------------------------------------
#  Makefile : single_line.m3
#  Description: Module with single-line variable assignments (no backslash continuation)
#-------------------------------------------------------------------------------

include $(BASE_DEV)/MakeRules

L4GLS=          lib_util.4gl lib_common.4gl lib_db.4gl

U4GLS=          util_str.4gl

4GLS=           single.4gl

CFILES=
ECFILES=

4GLOFILES=      $(4GLS:.4gl=.42o) $(L4GLS:.4gl=.42o) $(U4GLS:.4gl=.42o)

all: single.4ge

single.4ge:     $(4GLOFILES)
        $(COMPILE_PROG) $(4GLOFILES) -o $@
