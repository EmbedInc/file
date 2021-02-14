module file_wtxt_file;
define file_wtxt_file;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

var
  eol: array[1..2] of int8u_t :=       {end of line sequence}
    [13, 10];                          {carriage return, line feed}
{
********************************************************************************
*
*   Subroutine FILE_WTXT_FILE (BUF, CONN, STAT)
*
*   Write one line to the text file indicated by CONN.  The string in BUF will
*   become the line of text.  STAT is returned as the completion code, and has
*   already been initialized to no error.
}
procedure file_wtxt_file (             {write text line, obj type is FILE}
  in      buf: univ string_var_arg_t;  {string to write as text line}
  in out  conn: file_conn_t;           {handle to this file connection}
  out     stat: sys_err_t);            {completion code, initialized to no err}
  val_param;

var
  rlen: win_dword_t;                   {requested write length}
  olen: win_dword_t;                   {number of bytes actually written}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

label
  not_enough;

begin
{
*   Write all the data from the caller's buffer to the file.
}
  rlen := buf.len;                     {set number of bytes to write}
  ok := WriteFile (                    {write string characters to the file}
    conn.sys,                          {system handle to file connection}
    buf.str,                           {data to write}
    rlen,                              {number of bytes to write}
    olen,                              {returned number of bytes actually written}
    nil);                              {no overlap or position info supplied}
  if ok = win_bool_false_k then begin  {system call reported error ?}
    stat.sys := GetLastError;
    return;
    end;
  if olen <> rlen then goto not_enough; {didn't write all the requested data ?}
{
*   Write the end of line sequence.
}
  rlen := sizeof(eol);                 {set number of bytes to write}
  ok := WriteFile (                    {write string characters to the file}
    conn.sys,                          {system handle to file connection}
    eol,                               {data to write}
    rlen,                              {number of bytes to write}
    olen,                              {returned number of bytes actually written}
    nil);                              {no overlap or position info supplied}
  if ok = win_bool_false_k then begin  {system call reported error ?}
    stat.sys := GetLastError;
    return;
    end;
  if olen <> rlen then goto not_enough; {didn't write all the requested data ?}

  if conn.lnum >= 0                    {increment line number if valid}
    then conn.lnum := conn.lnum + 1;
  return;                              {normal return}

not_enough:                            {not all requested data got written}
  sys_stat_set (file_subsys_k, file_stat_write_size_k, stat);
  sys_stat_parm_vstr (conn.tnam, stat);
  sys_stat_parm_int (rlen, stat);
  sys_stat_parm_int (olen, stat);
  end;
