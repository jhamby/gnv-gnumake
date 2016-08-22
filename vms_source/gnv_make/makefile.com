$!
$! Makefile.com - builds GNU Make for VMS
$!
$! P1 = DEBUG will build an image with debug information
$!
$! In case of problems with the install you might contact me at
$! zinser@decus.decus.de (preferred) or martin_zinser@exchange.de
$!
$!  7-Jul-2015	J. Malmberg - Fix to build with search lists.
$! 16-Aug-2016  J. Malmberg - Fix execvp() and deleting /tmp/make* files.
$!
$! Look for the compiler used
$!
$ lval = ""
$ if f$search("SYS$SYSTEM:DECC$COMPILER.EXE").eqs.""
$  then
$   if f$trnlnm("SYS").eqs."" then def/nolog sys sys$library:
$   ccopt = ""
$  else
$   ccopt = "/decc/prefix=all/nested=none"
$   if f$trnlnm("SYS").eqs.""
$    then
$     if f$trnlnm("DECC$LIBRARY_INCLUDE").nes.""
$      then
$       define sys decc$library_include:
$      else
$       if f$search("SYS$COMMON:[DECC$LIB.REFERENCE]DECC$RTLDEF.DIR").nes."" -
           then lval = "SYS$COMMON:[DECC$LIB.REFERENCE.DECC$RTLDEF],"
$       if f$search("SYS$COMMON:[DECC$LIB.REFERENCE]SYS$STARLET_C.DIR").nes."" -
           then lval = lval+"SYS$COMMON:[DECC$LIB.REFERENCE.SYS$STARLET_C],"
$       lval=lval+"SYS$LIBRARY:"
$       define sys 'lval
$      endif
$   endif
$ endif
$!
$! Should we build a debug image
$!
$ if (p1 .eqs. "DEBUG") .or. (p2 .eqs. "DEBUG")
$  then
$   ccopt = ccopt + "/noopt/debug"
$   lopt = "/debug"
$ else
$   lopt = ""
$ endif
$
$ if "''cc'" .eqs. ""
$    then cc = "cc"
$    else cc = cc
$    endif
$
$ cc sys$disk:vms_crtl_init.c
$
$ filelist1 = "ar arscan commands default dir expand file function"
$ filelist2 = " implicit job main misc read remake remote-stub rule signame"
$ filelist3 = " variable version vmsfunctions vmsify vpath vms_execvp_hack"
$ filelist4 = " vms_get_foreign_cmd [.glob]fnmatch getopt1 getopt"
$ filelist = filelist1 + filelist2 + filelist3 + filelist4
$ arch_name = f$edit(f$getsyi("arch_name"),"lowercase,trim")
$ ! should be based on version, not arch.
$ if arch_name .eqs. "vax"
$ then
$   filelist = filelist + " [.glob]glob"
$ endif
$ copy config.h-vms config.h
$ n=0
$ open/write optf make.opt
$ loop:
$ cfile = f$elem(n," ",filelist)
$ if cfile .eqs. " " then goto linkit
$ write sys$output "Compiling ''cfile'..."
$ call compileit 'cfile'
$ n = n + 1
$ goto loop
$ linkit:
$ close optf
$ link/exe=sys$disk:make sys$disk:make.opt/opt'lopt',sys$disk:vms_crtl_init
$ exit
$!
$ compileit : subroutine
$ ploc = f$locate("]",p1)
$ filnam = p1
$ if ploc .lt. f$length(p1) then filnam=f$extract(ploc+1,100,p1)
$ write optf "''filnam'"
$ cdef1="""""allocated_variable_expand_for_file=alloc_var_expand_for_file"""""
$ cdef2 = """""unlink=remove"""""
$ cdef3 = """""HAVE_CONFIG_H"""""
$ cdef4 = """""VMS"""""
$ cdef5 = """""_POSIX_EXIT"""""
$ cdef = "/define=(''cdef1',''cdef2',''cdef3',''cdef4',''cdef5')"
$ define/user sys$library_include sys$disk:[]
$ cc'ccopt' /include=(sys$disk:[],sys$disk:[.glob])'cdef' sys$disk:'p1'
$ exit
$ endsubroutine : compileit
