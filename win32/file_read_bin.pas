{   Subroutine FILE_READ_BIN (CONN, ILEN, BUF, OLEN, STAT)
*
*   Read up to the next ILEN machine address increments from the file open on
*   connection CONN.  The data is read into BUF.  OLEN is returned the amount
*   of data actually read into BUF.  This is only not equal to ILEN only if
*   end of file was encountered.  STAT is the completion status code.
*   It will be set to end of file only if no data could be read at all.
}
module file_read_bin;
define file_read_bin;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_read_bin (              {read data from binary file}
  in      conn: file_conn_t;           {handle to this file connection}
  in      ilen: sys_int_adr_t;         {number of machine adr increments to read}
  out     buf: univ char;              {returned data}
  out     olen: sys_int_adr_t;         {number of machine adresses actually read}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  olen_sys: win_dword_t;               {number of bytes actually read in sys fmt}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}
  errstat: sys_sys_err_t;              {system error status code}

label
  eof;

begin
  sys_error_none (stat);               {init to no error}
  if ilen = 0 then return;             {nothing to do ?}

  ok := ReadFile (                     {try to read the data from the file}
    conn.sys,                          {system handle to file connection}
    buf,                               {buffer to read data into}
    ilen,                              {number of bytes to read}
    olen_sys,                          {number of bytes actually read}
    nil);                              {no overlap and position info supplied}
  if ok = win_bool_false_k then begin  {error on read attempt ?}
    errstat := GetLastError;           {get system error status code}
    if errstat = err_pipe_ended_k then goto eof; {EOF condition for a pipe ?}
    stat.sys := errstat;               {return system error code}
    olen := 0;
    return;
    end;

  olen := olen_sys;                    {pass back number of bytes actually read}
  if olen = 0 then goto eof;           {hit end of file immediately ?}
  if olen < ilen then begin            {hit end of file but read some data first ?}
    sys_stat_set (file_subsys_k, file_stat_eof_partial_k, stat);
    sys_stat_parm_int (ilen, stat);
    sys_stat_parm_int (olen, stat);
    end;
  return;

eof:                                   {end of input encountered}
  olen := 0;                           {no data returned on end of file}
  sys_stat_set (file_subsys_k, file_stat_eof_k, stat); {set EOF status}
  end;
