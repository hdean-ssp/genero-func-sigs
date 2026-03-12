#-------------------------------------------------------------------------------
#  Makefile : multiline.m3
#  Description: Module with multi-line continuations
#-------------------------------------------------------------------------------

include $(BASE_DEV)/MakeRules

L4GLS=          lib_auth.4gl lib_session.4gl lib_crypto.4gl \
                lib_validate.4gl lib_format.4gl lib_parse.4gl \
                lib_convert.4gl lib_transform.4gl

U4GLS=          util_log.4gl \
                util_debug.4gl \
                util_trace.4gl

4GLS=           multiline.4gl \
                processor.4gl \
                handler.4gl

CFILES=
ECFILES=

4GLOFILES=      $(4GLS:.4gl=.42o) $(L4GLS:.4gl=.42o) $(U4GLS:.4gl=.42o)

all: multiline.4ge

multiline.4ge:  $(4GLOFILES)
        $(COMPILE_PROG) $(4GLOFILES) -o $@
