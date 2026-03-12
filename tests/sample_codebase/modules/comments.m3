#-------------------------------------------------------------------------------
#  Makefile : comments.m3
#  Description: Module with inline comments
#-------------------------------------------------------------------------------

include $(BASE_DEV)/MakeRules

# Library files section
L4GLS=          lib_report.4gl lib_export.4gl  # Core reporting libraries

# Utility files section
U4GLS=          util_file.4gl  # File utilities

# Module files section
4GLS=           comments.4gl output.4gl  # Main module files

CFILES=
ECFILES=

4GLOFILES=      $(4GLS:.4gl=.42o) $(L4GLS:.4gl=.42o) $(U4GLS:.4gl=.42o)

all: comments.4ge

comments.4ge:   $(4GLOFILES)
        $(COMPILE_PROG) $(4GLOFILES) -o $@
