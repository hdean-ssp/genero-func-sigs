#-------------------------------------------------------------------------------
#  Makefile : test_mapping.m3
#  Description: Test module that references files with known signatures
#-------------------------------------------------------------------------------

include $(BASE_DEV)/MakeRules

L4GLS=          complex_types.4gl edge_cases.4gl

U4GLS=          special_types.4gl

4GLS=           simple_functions.4gl multiple_returns.4gl

CFILES=
ECFILES=

4GLOFILES=      $(4GLS:.4gl=.42o) $(L4GLS:.4gl=.42o) $(U4GLS:.4gl=.42o)

all: test_mapping.4ge

test_mapping.4ge: $(4GLOFILES)
        $(COMPILE_PROG) $(4GLOFILES) -o $@
