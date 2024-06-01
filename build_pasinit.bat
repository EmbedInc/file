@echo off
rem
rem   Set up for building a Pascal module.
rem
call build_vars

call src_get %srcdir% %libname%.ins.pas
call src_get %srcdir% %libname%2.ins.pas
call src_get %srcdir% %libname%_sys2.ins.pas
call src_get %srcdir% %libname%_map2.ins.pas
call src_get %srcdir% %libname%_close_map.ins.pas
call src_get %srcdir% %libname%_open_map.ins.pas
call src_get %srcdir% %libname%_inet.ins.pas
call src_get %srcdir% %libname%_inet2.ins.pas
call src_get %srcdir% cogserve.ins.pas
call src_get %srcdir% test_server.ins.pas
call src_get %srcdir% embusb_driver.h

call src_getbase
call src_getfrom sys sys_sys2.ins.pas
copya (cog)lib/sys.h
copya (cog)lib/util.h
copya (cog)lib/string.h

call src_builddate "%srcdir%"
