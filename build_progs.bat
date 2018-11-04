@echo off
rem
rem   BUILD_PROGS [-dbg]
rem
rem   Build the executable programs from this source directory.
rem
setlocal
call build_pasinit

call src_prog %srcdir% test_copy %1
call src_prog %srcdir% test_del %1
call src_prog %srcdir% test_dir %1
call src_prog %srcdir% test_embusb %1
call src_prog %srcdir% test_map %1
call src_prog %srcdir% test_msg %1
call src_prog %srcdir% test_newer %1
call src_prog %srcdir% test_rename %1
call src_prog %srcdir% test_server %1
call src_prog %srcdir% test_streams %1
call src_prog %srcdir% test_tcp %1
call src_prog %srcdir% test_text %1
call src_prog %srcdir% test_txfile %1
