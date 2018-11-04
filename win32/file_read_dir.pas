{   Subroutine FILE_READ_DIR (CONN, INFO_REQ, NAME, INFO, STAT)
*
*   Read the next entry from the directory previously opened on the connection
*   handle CONN.  NAME is the returned directory entry name.  STAT is the
*   completion status code.  STAT will signal end of file when no more
*   directory entries are available.
}
module file_read_dir;
define file_read_dir;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_read_dir (              {read next directory entry name}
  in      conn: file_conn_t;           {handle to connection to directory}
  in      info_req: file_iflags_t;     {flags for requesting additional info in INFO}
  out     name: univ string_var_arg_t; {name from directory entry}
  out     info: file_info_t;           {returned information requested about file}
  out     stat: sys_err_t);            {error status, got all info if no error}
  val_param;

var
  data_p: file_rdir_data_p_t;          {pointer to our private data block}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

label
  ignore, got_fdata, eof, sys_err;

begin
  sys_error_none (stat);               {init to no error occurred}
  data_p := conn.data_p;               {get pointer to our private data block}

  if data_p^.valid then goto got_fdata; {already have next dir entry available ?}
  if data_p^.eof then goto eof;        {previously hit end of directory ?}

ignore:                                {jump here to ignore last entry read}
  ok := FindNextFileA (                {try to get next directory entry}
    conn.sys,                          {system handle to directory connection}
    data_p^.fdata);                    {returned information about new dir entry}
  if (ok <> win_bool_false_k)          {we now definately have new entry info ?}
    then goto got_fdata;

  stat.sys := GetLastError;            {get reason for failure}
  if stat.sys <> err_no_more_files_k   {not just hit end of directory ?}
    then goto sys_err;
{
*   Just hit end of directory.
}
  ok := FindClose (conn.sys);          {close system connection to directory}
  data_p^.eof := true;                 {indicate system directory handle closed}
  if ok = win_bool_false_k then goto sys_err; {unrecoverable system error ?}

  data_p^.valid := false;              {no pending data present}

eof:                                   {jump here to return END OF FILE status}
  sys_stat_set (file_subsys_k, file_stat_eof_k, stat);
  return;

sys_err:                               {jump here on unrecoverable system error}
  stat.sys := GetLastError;            {get system error code}
  if not data_p^.eof then begin        {system connection to directory still open ?}
    discard( FindClose (conn.sys) );   {try to close system directory connection}
    data_p^.eof := true;               {indicate system connection closed}
    end;
  sys_mem_dealloc (data_p);            {release our private data block}
  return;                              {return with hard error}
{
*   The info for the next directory entry is in DATA_P^.FDATA.
}
got_fdata:
{
*   Ignore the virtual file names "." and "..".
}
  if data_p^.fdata.name[1] = '.' then begin {file name starts with "." ?}
    if data_p^.fdata.name[2] = chr(0)  {name is exactly "." ?}
      then goto ignore;
    if                                 {name is exactly ".." ?}
        (data_p^.fdata.name[2] = '.') and
        (data_p^.fdata.name[3] = chr(0))
      then goto ignore;
    end;
{
*   Try to return the requested additional information.
}
  data_p^.valid := false;              {prevent returning this data again}

  info.flags := [];                    {init to no extra file info returned}
  file_info2 (data_p^.fdata, info_req, info, name, stat); {extract file info}
  if sys_error(stat) then return;      {encountered hard error ?}

  if (info_req - info.flags) <> [] then begin {not get all requested information ?}
    sys_stat_set (file_subsys_k, file_stat_info_partial_k, stat);
    end;
  end;
