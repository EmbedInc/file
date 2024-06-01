@echo off
rem
rem   BUILD_PROGS [-dbg]
rem
rem   Build the executable programs from this source directory.
rem
setlocal
call build_pasinit

call src_progl test_copy
call src_progl test_del
call src_progl test_dir
call src_progl test_embusb
call src_progl test_map
call src_progl test_msg
call src_progl test_newer
call src_progl test_rename
call src_progl test_server
call src_progl test_streams
call src_progl test_tcp
call src_progl test_text
call src_progl test_txfile
