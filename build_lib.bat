@echo off
rem
rem   BUILD_LIB [-dbg]
rem
rem   Build the FILE library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_pas %srcdir% csrv_client %1
call src_pas %srcdir% %libname%_call %1
call src_pas %srcdir% %libname%_close %1
call src_pas %srcdir% %libname%_close_dir %1
call src_pas %srcdir% %libname%_close_env %1
call src_pas %srcdir% %libname%_close_map %1
call src_pas %srcdir% %libname%_close_msg %1
call src_pas %srcdir% %libname%_close_sio %1
call src_pas %srcdir% %libname%_close_stream %1
call src_pas %srcdir% %libname%_close_textr %1
call src_pas %srcdir% %libname%_comblock %1
call src_pas %srcdir% %libname%_copy %1
call src_pas %srcdir% %libname%_csrv %1
call src_pas %srcdir% %libname%_currdir %1
call src_pas %srcdir% %libname%_delete_name %1
call src_pas %srcdir% %libname%_embusb %1
call src_pas %srcdir% %libname%_embusb_sys %1
call src_c   %srcdir% %libname%_embusb_sysc %1
call src_pas %srcdir% %libname%_dir_sys %1
call src_pas %srcdir% %libname%_eof %1
call src_pas %srcdir% %libname%_eof_partial %1
call src_pas %srcdir% %libname%_exists %1
call src_pas %srcdir% %libname%_inet %1
call src_pas %srcdir% %libname%_inet2 %1
call src_pas %srcdir% %libname%_info %1
call src_pas %srcdir% %libname%_init %1
call src_pas %srcdir% %libname%_init_sys %1
call src_pas %srcdir% %libname%_inuse %1
call src_pas %srcdir% %libname%_link %1
call src_pas %srcdir% %libname%_map %1
call src_pas %srcdir% %libname%_map_add_block %1
call src_pas %srcdir% %libname%_map_done %1
call src_pas %srcdir% %libname%_map_length %1
call src_pas %srcdir% %libname%_map_truncate %1
call src_pas %srcdir% %libname%_name_init %1
call src_pas %srcdir% %libname%_name_next %1
call src_pas %srcdir% %libname%_not_found %1
call src_pas %srcdir% %libname%_open_bin %1
call src_pas %srcdir% %libname%_open_map %1
call src_pas %srcdir% %libname%_open_read_bin %1
call src_pas %srcdir% %libname%_open_read_dir %1
call src_pas %srcdir% %libname%_open_read_env %1
call src_pas %srcdir% %libname%_open_read_msg %1
call src_pas %srcdir% %libname%_open_read_text %1
call src_pas %srcdir% %libname%_open_sio %1
call src_pas %srcdir% %libname%_open_stream %1
call src_pas %srcdir% %libname%_open_write_bin %1
call src_pas %srcdir% %libname%_open_write_text %1
call src_pas %srcdir% %libname%_pos %1
call src_pas %srcdir% %libname%_pos_text %1
call src_pas %srcdir% %libname%_read_bin %1
call src_pas %srcdir% %libname%_read_dir %1
call src_pas %srcdir% %libname%_read_env %1
call src_pas %srcdir% %libname%_read_msg %1
call src_pas %srcdir% %libname%_read_sio_rec %1
call src_pas %srcdir% %libname%_read_text %1
call src_pas %srcdir% %libname%_rename %1
call src_pas %srcdir% %libname%_set_env_bkwds %1
call src_pas %srcdir% %libname%_sio %1
call src_pas %srcdir% %libname%_skip_text %1
call src_pas %srcdir% %libname%_tree %1
call src_pas %srcdir% %libname%_usb %1
call src_pas %srcdir% %libname%_write_bin %1
call src_pas %srcdir% %libname%_write_sio_rec %1
call src_pas %srcdir% %libname%_write_text %1
call src_pas %srcdir% %libname%_wtxt_file %1

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%

copya file_map.ins.pas (cog)lib/file_map.ins.pas
