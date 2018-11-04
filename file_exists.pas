{   Function FILE_EXISTS (FNAM)
*
*   Return TRUE if the arbitrary file name "FNAM" exists.
}
module file_exists;
define file_exists;
%include 'file2.ins.pas';

function file_exists (                 {return TRUE if file exists}
  in      fnam: univ string_var_arg_t): {arbitrary file name}
  boolean;
  val_param;

var
  info: file_info_t;                   {unused}

label
  next_file, finished;

var
  dnam: string_treename_t;             {directory}
  tnam: string_treename_t;             {full treename for directory}
  lnam: string_leafname_t;             {leafname}
  nam: string_leafname_t;              {general leafname}
  conn: file_conn_t;                   {directory file handle}
  stat: sys_err_t;                     {completion status code}
  msg_parm: array[1..1] of sys_parm_msg_t; {message parameter array}

begin
  dnam.max := sizeof(dnam.str); dnam.len := 0; {init directory name string}
  tnam.max := sizeof(tnam.str); tnam.len := 0; {init abs treename string}
  lnam.max := sizeof(lnam.str); lnam.len := 0; {init leaf name string}
  nam.max := sizeof(nam.str); nam.len := 0; {init general leaf name string}
  file_exists := false;                {init returned value}
  string_treename (fnam, tnam);        {get abs treename}
  string_pathname_split (tnam, dnam, lnam); {get directory and leafname}
  file_open_read_dir (dnam, conn, stat); {open the directory for reading}
  if file_not_found (stat) then return; {directory found?}
  sys_msg_parm_vstr (msg_parm[1], dnam); {load up directory in case of error}
  sys_error_abort (stat, 'file', 'open_dir', msg_parm, 1); {some other error?}

next_file:
  file_read_dir (                      {read next directory entry}
    conn,                              {handle to directory connection}
    [],                                {no additional info is being requested}
    nam,                               {returned file name}
    info,                              {additional file info (unused)}
    stat);
  if file_eof(stat) then goto finished; {all files compared?}
  sys_error_abort (stat, 'file', 'read_dir', nil, 0); {some other error?}
  if not string_equal(lnam, nam) then goto next_file; {file name not matched?}
  file_exists := true;                 {file exists}
finished:
  file_close (conn);                   {close the directory for reading}
  end;

