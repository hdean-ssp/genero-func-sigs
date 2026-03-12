#-------------------------------------------------------------------------------
#  Makefile : test.m3
#  $Header: test.m3 1.4 11/06/08 09:14:52 gbunting$
#  Date : 22/01/2008                                                            Author  : nolanr
#-------------------------------------------------------------------------------
#  Description:
#       This makefile is used to compile test.4ge.
#
#-------------------------------------------------------------------------------
#  Modifications:
#  Ref  Date            Who                     Description
#
# 72995 22/04/2010      N.Robinson      Removed the dependency on PROG_LIBS and added
#                                                               fib_errl.4gl setflag.4gl adperiod.4gl ipt.4gl
#EH011647 08/07/15      Greg            Added lib_covx.4gl
#PM047248 08/08/16      Greg            Added lib_add3.4gl
#EH023919 02/03/20      Greg            Added lib_errm.4gl
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#       Include the electRa's make rules.
#-------------------------------------------------------------------------------

include $(BASE_DEV)/MakeRules
#include $(WORKAREA)/MakeRules

#-------------------------------------------------------------------------------
#       New Globals Definitions
#               (if the old globals are needed then remove the lines referring to
#                GLOBALS and GLOBOFILE)
#-------------------------------------------------------------------------------

GLOBALS=
GLOBOFILE=

NEW_GLOBS=
NEW_GLOBO=      $(NEW_GLOBS:.4gl=.42o)

#-------------------------------------------------------------------------------
#       Libraries Used
#
#       Note:  This note is for information only, so delete this and the following
#                  lines when creating a makefile.
#
#                  $(LIBRARY) includes all libraries and should only be used when
#                                         the quick addressing system is being used.
#                  $(FCLIBRARY) include the Informix 4gl and C libraries.
#                  $(CLIBRARY) only includes the C library
#-------------------------------------------------------------------------------

#PROG_LIBS=             $(LIBRARY)
#PROG_LIBS=     $(QAS) $(LIBRARY) $(FCLIBRARY) $(CLIBRARY)


#-------------------------------------------------------------------------------
#       Source 4GL, C, and EC files.
#-------------------------------------------------------------------------------

L4GLS=          liberr.4gl   lib_esc.4gl  lib_inpt.4gl  lib_menu.4gl lib_scr1.4gl \
                        fib_dfrm.4gl lib_mail.4gl lib_ekey.4gl lib_list.4gl lib_errm.4gl \
                        libdescr.4gl lib_if.4gl lib_empl.4gl lib_brok.4gl fib_fffn.4gl ipt.4gl \
                        lib_bra2.4gl lib_addr.4gl lib_imkl.4gl lib_mad.4gl lib_dmad.4gl sel_mad.4gl \
                        lib_grsk.4gl lib_rrsk.4gl lib_decr.4gl lib_rveh.4gl lib_rdrv.4gl lib_glob.4gl \
                        lib_lob.4gl lib_add3.4gl fib_swin.4gl lib_cuv.4gl lib_frt.4gl lib_evt.4gl \
                        lib_inrp.4gl lib_pacc.4gl fib_wpr.4gl fib_cal.4gl lib_unix.4gl \
                        lib_atrx.4gl lib_jobs.4gl lib_lock.4gl spooler.4gl doc_arch.4gl  lib_run2.4gl \
                        lib_locn.4gl lib_prnt.4gl outiface.4gl bld_emes.4gl lib_darx.4gl win_prog.4gl \
                        fib_inif.4gl lib_scom.4gl lib_edte.4gl lib_keyv.4gl lib_rate.4gl lib_pcf.4gl \
                        lib_prtl.4gl lib_eml.4gl lib_desc.4gl lib_evt2.4gl ms001.4gl ms005.4gl htmledit.4gl \
                        lib_ierr.4gl lib_atth.4gl lib_xml.4gl lib_soap.4gl tagmodel.4gl lib_inet.4gl \
                        lib_tun.4gl lib_cusx.4gl lib_hmac.4gl lib_commshub.4gl lib_curl.4gl lib_jscx.4gl lib_cnam.4gl \
                        lib_curl.4gl lib_sndr.4gl lib_ppd.4gl lib_json.4gl lib_oauth.4gl lib_empx.4gl lib_bdl.4gl browse.4gl

U4GLS=          set_opts.4gl eltrace.4gl lib_strg.4gl setflag.4gl lib_jobt.4gl lib_schr.4gl \

4GLS=           test.4gl jobiface.4gl
CFILES=

ECFILES=

#-------------------------------------------------------------------------------
#       Dependent files.
#-------------------------------------------------------------------------------

4GLOFILES=      $(4GLS:.4gl=.42o) $(L4GLS:.4gl=.42o) $(U4GLS:.4gl=.42o)
COFILES=        $(CFILES:.c=.o)
ECOFILES=       $(ECFILES:.ec=.o)

PROG_OS=        $(4GLOFILES) $(COFILES) $(ECOFILES)
OFILES=         $(NEW_GLOBO) $(GLOBOFILE) $(PROG_OS) $(PROG_LIBS)
DEPENDANTS=     $(OFILES) wordprms.m3

#-------------------------------------------------------------------------------
#       Build rules for the executable.
#-------------------------------------------------------------------------------

all: wordprms.4ge

wordprms.4ge:   $(DEPENDANTS)
        @echo "$(OFILES) -o $@ $(LINK_OPT) $(SYSLIBS) $(GLOB_LD) " > $(OUT_FILE); \
        $(COMPILE_PROG) $(OUT_FILE);

$(PROG_OS):     $(GLOBALS) $(NEW_GLOBO)
