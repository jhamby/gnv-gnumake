$! File: build_make.com
$!
$!
$!
$ my_def = f$environment("default")
$ on control_y then goto done
$ on error then goto done
$ my_proc = f$environment("procedure")
$ my_dev = f$parse(my_proc,,,"DEVICE")
$ my_dir = f$parse(my_proc,,,"DIRECTORY")
$ set def sys$disk:'my_dir'
$ set def [-]
$!
$ if p1 .eqs. "CLEAN" then goto clean
$ if p1 .eqs. "REALCLEAN" then goto realclean
$!
$ @makefile.com
$ rename make.exe gnv$make.exe
$!
$!
$done:
$ set noverify
$!
$ set default 'my_def'
$ exit
$!
$realclean:
$clean:
$ file = "*.lis"
$ if f$search(file) .nes. "" then delete 'file';*
$ file = "*.obj"
$ if f$search(file) .nes. "" then delete 'file';*
$ file = "*.exe"
$ if f$search(file) .nes. "" then delete 'file';*
$ set default 'my_def'
$ exit
