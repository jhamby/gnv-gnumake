$! File: remove_old_make.com
$!
$! This is a procedure to remove the old make images that were installed
$! by the GNV kits and replace them with links to the new image.
$!
$! 01-Jan-2016  J. Malmberg	Make version
$!
$!==========================================================================
$!
$vax = f$getsyi("HW_MODEL") .lt. 1024
$old_parse = ""
$if .not. VAX
$then
$   old_parse = f$getjpi("", "parse_style_perm")
$   set process/parse=extended
$endif
$!
$old_cutils = "make"
$!
$!
$ i = 0
$cutils_loop:
$   file = f$element(i, ",", old_cutils)
$   if file .eqs. "" then goto cutils_loop_end
$   if file .eqs. "," then goto cutils_loop_end
$   call update_old_image "''file'" "[bin]"
$   call update_old_image "''file'" "[usr.bin]"
$   call update_old_image "''file'" "[lib]"
$   i = i + 1
$   goto cutils_loop
$cutils_loop_end:
$!
$!
$!
$if .not. VAX
$then
$   set process/parse='old_parse'
$endif
$!
$all_exit:
$  exit
$!
$! Remove old image or update it if needed.
$!-------------------------------------------
$update_old_image: subroutine
$!
$ file = p1
$ path = p2
$ if path .eqs. "" then path = "[bin]"
$! First get the FID of the new gnv$make.exe image.
$! Don't remove anything that matches it.
$ new_make = f$search("gnv$gnu:[usr.bin]gnv$make.exe")
$!
$ new_make_fid = "No_new_make_fid"
$ if new_make .nes. ""
$ then
$   new_make_fid = f$file_attributes(new_make, "FID")
$ endif
$!
$!
$!
$! Now get check the "''file'." and "''file'.exe"
$! May be links or copies.
$! Ok to delete and replace.
$!
$!
$ old_make_fid = "No_old_make_fid"
$ old_make = f$search("gnv$gnu:''path'''file'.")
$ old_make_exe_fid = "No_old_make_fid"
$ old_make_exe = f$search("gnv$gnu:''path'''file'.exe")
$ if old_make_exe .nes. ""
$ then
$   old_make_exe_fid = f$file_attributes(old_make_exe, "FID")
$ endif
$!
$ if old_make .nes. ""
$ then
$   fid = f$file_attributes(old_make, "FID")
$   if fid .nes. new_make_fid
$   then
$       if fid .eqs. old_make_exe_fid
$       then
$           set file/remove 'old_make'
$       else
$           delete 'old_make'
$       endif
$       if new_make .nes. ""
$       then
$           if (file .nes. "gcc") .and. (file .nes. "g^+^+") .and. -
               (path .eqs. "[usr.bin]")
$           then
$               set file/enter='old_make' 'new_make'
$           endif
$       endif
$   endif
$ endif
$!
$ if old_make_exe .nes. ""
$ then
$   if old_make_fid .nes. new_make_fid
$   then
$       delete 'old_make_exe'
$       if new_make .nes. ""
$       then
$           if (file .nes. "gcc") .and. (file .nes. "g^+^+") .and. -
               (path .eqs. "[usr.bin]")
$           then
$               set file/enter='old_make_exe' 'new_make'
$           endif
$       endif
$   endif
$ endif
$!
$ exit
$ENDSUBROUTINE ! Update old image
