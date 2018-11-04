{   Subroutine FILE_WRITE_BIN (BUF, CONN, LEN, STAT)
*
*   Write data from BUF to the file open on CONN.  LEN is the amount of data
*   to write.  STAT is returned ast the completion status code.
}
module file_write_bin;
define file_write_bin;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_write_bin (             {write data to binary file}
  in      buf: univ char;              {data to write}
  in      conn: file_conn_t;           {handle to this file connection}
  in      len: sys_int_adr_t;          {number of machine adr increments to write}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  ilen: win_dword_t;                   {requested write length}
  olen: win_dword_t;                   {number of bytes actually written}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

begin
  sys_error_none (stat);               {init to no error}

  ilen := len;                         {set number of bytes to write}
  ok := WriteFile (                    {try to write the data to the file}
    conn.sys,                          {system handle to file connection}
    buf,                               {data to write}
    ilen,                              {number of bytes to write}
    olen,                              {number of bytes actually written}
    nil);                              {no overlap or position info supplied}
  if ok = win_bool_false_k then begin  {system call reported error ?}
    stat.sys := GetLastError;
    return;
    end;

  if olen <> ilen then begin           {didn't write all the requested info ?}
    sys_stat_set (file_subsys_k, file_stat_write_size_k, stat);
    sys_stat_parm_vstr (conn.tnam, stat);
    sys_stat_parm_int (ilen, stat);
    sys_stat_parm_int (olen, stat);
    end;
  end;
