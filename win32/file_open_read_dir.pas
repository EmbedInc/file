{   Subroutine FILE_OPEN_READ_DIR (NAME, CONN, STAT)
*
*   Open a directory for reading.  NAME is the name of the directory.  CONN is
*   the returned connection handle.  STAT is the returned completion code.
}
module file_open_read_dir;
define file_open_read_dir;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_open_read_dir (         {open directory for reading file names}
  in      name: univ string_var_arg_t; {generic directory name}
  out     conn: file_conn_t;           {handle to newly created connection}
  out     stat: sys_err_t);            {completion status code}

var
  attr: fattr_t;                       {set of file attribute flags}
  data_p: file_rdir_data_p_t;          {pointer to our private CONN data}
  tnam: string_var8192_t;              {treename used in system calls}

label
  leave_no_err, empty;

begin
  tnam.max := size_char(tnam.str);     {init local var string}
  sys_error_none (stat);               {init to no error occurred}

  conn.fnam.max := sizeof(conn.fnam.str); {init var strings in connection handle}
  conn.gnam.max := sizeof(conn.gnam.str);
  conn.tnam.max := sizeof(conn.tnam.str);
  if name.len <= 0 then begin          {file name string empty ?}
    sys_stat_set (file_subsys_k, file_stat_no_fnam_open_k, stat);
    return;                            {return with error}
    end;

  string_treename (name, conn.tnam);   {make full directory tree name}
  string_copy (name, conn.fnam);       {save directory name as supplied}
  string_generic_fnam (name, '', conn.gnam); {save just the directory leafname}

  string_copy (conn.tnam, tnam);       {make directory name in system format}
  string_terminate_null (tnam);
  attr := GetFileAttributesA (tnam.str); {get attribute flags for this object}
  if win_dword_t(attr) = func_fail_k then begin {call failed, not found, etc.}
    stat.sys := GetLastError;
    return;
    end;

  if not (fattr_dir_k in attr) then begin {NAME is not name of a directory ?}
    sys_stat_set (file_subsys_k, file_stat_not_dir_k, stat);
    sys_stat_parm_vstr (conn.tnam, stat);
    return;                            {return with NOT A DIRECTORY error}
    end;
{
*   The object specified by NAME exists and is actually a directory.
}
  if tnam.str[tnam.len] <> '\' then begin {path separator not already present ?}
    string_append1 (tnam, '\');
    end;
  string_append1 (tnam, '*');          {make wildcard for finding names in dir}
  string_terminate_null (tnam);

  sys_mem_alloc (sizeof(data_p^), data_p); {allocate our private data block}
  sys_mem_error (data_p, '', '', nil, 0); {abort if didn't get memory}

  conn.sys := FindFirstFileA (         {open directory for read and get first entry}
    tnam.str,                          {directory name in system format}
    data_p^.fdata);                    {returned data about first entry}
  if conn.sys = handle_invalid_k
    then begin                         {system call failed}
      stat.sys := GetLastError;        {save reason for failure}
      if stat.sys = err_no_more_files_k then begin {just an empty directory ?}
        goto empty;
        end;
      if                               {directory is a raw drive ?}
          (conn.tnam.len = 3) and      {exactly 3 characters long ?}
          (conn.tnam.str[1] >= 'A') and (conn.tnam.str[1] <= 'Z') and {A-Z ?}
          (conn.tnam.str[2] = ':') and (conn.tnam.str[3] = '\') {followed by ":\" ?}
          then begin
        goto empty;                    {empty floppy shouldn't be an error}
        end;
      sys_mem_dealloc (data_p);        {release our private data block memory}
      return;                          {return with error}
      end
    else begin                         {we successfully read first dir entry}
      data_p^.valid := true;           {we have data not returned to user yet}
      data_p^.eof := false;            {system handle to directory is open}
      end
    ;

leave_no_err:                          {common exit point when no error occurred}
  conn.rw_mode := [file_rw_read_k];    {fill in rest of connection handle}
  conn.obty := file_obty_dir_k;
  conn.fmt := file_fmt_text_k;
  conn.ext_num := 0;
  conn.lnum := file_lnum_nil_k;
  conn.data_p := data_p;
  conn.close_p := addr(file_close_dir); {need special close routine for directories}
  return;                              {normal return when directory not empty}
{
*   Directory is empty.  This is not an error.
}
empty:
  sys_error_none (stat);               {empty directory isn't an error}
  data_p^.valid := false;              {we don't have any pending data to return}
  data_p^.eof := true;                 {system connection to directory is closed}
  goto leave_no_err;                   {to common code for non-error exit}
  end;
