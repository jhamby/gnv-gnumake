$! File: build_make_release_notes.com
$!
$! Build the release note file from the three components:
$!    1. The make_release_note_start.txt
$!    2. The make_build_steps.txt.
$!
$! Set the name of the release notes from the GNV_PCSI_FILENAME_BASE
$! logical name.
$!
$!
$! 01-Jan-2016  J. Malmberg
$!
$!===========================================================================
$!
$ base_file = f$trnlnm("GNV_PCSI_FILENAME_BASE")
$ if base_file .eqs. ""
$ then
$   write sys$output "@[.vms]make_pcsi_make_kit_name.com has not been run."
$   goto all_exit
$ endif
$!
$!
$ make_readme = f$search("sys$disk:[]readme.")
$ if make_readme .eqs. ""
$ then
$   make_readme = f$search("sys$disk:[]$README.")
$ endif
$ if make_readme .eqs. ""
$ then
$   write sys$output "Can not find make readme file."
$   goto all_exit
$ endif
$!
$ make_copying = f$search("sys$disk:[]copying.")
$ if make_copying .eqs. ""
$ then
$   make_copying = f$search("sys$disk:[]$COPYING.")
$ endif
$ if make_copying .eqs. ""
$ then
$   write sys$output "Can not find make copying file."
$   goto all_exit
$ endif
$!
$ type/noheader sys$disk:[.vms]make_release_note_start.txt,-
        'make_readme', 'make_copying', -
        sys$disk:[.vms]make_build_steps.txt -
        /out='base_file'.release_notes
$!
$ purge 'base_file'.release_notes
$ rename 'base_file.release_notes ;1
$!
$all_exit:
$   exit
