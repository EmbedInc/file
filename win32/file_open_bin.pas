{   Subroutine FILE_OPEN_BIN (NAME, EXT, RW_MODE, CONN, STAT)
*
*   Open a binary file for sequential read and/or write.
}
module file_open_bin;
define file_open_bin;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_open_bin (              {open binary file for read and/or write}
  in      name: univ string_var_arg_t; {generic file name}
  in      ext: string;                 {file name extensions, separated by blanks}
  in      rw_mode: file_rw_t;          {intended read/write access}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  i: sys_int_machine_t;                {scratch integer}
  flags_access: faccess_t;             {file access mode flags}
  mode_create: fcreate_k_t;            {file creation mode select}
  name_h: file_name_handle_t;          {handle for making possible file names}
  h: win_handle_t;                     {system handle to file connection}

label
  opened;

begin
  sys_error_none (stat);               {init to no errors}
{
*   Set FLG_OPEN.  This is the FLAGS argument to the CreateFile routine.  It
*   selects read/write access mode and other stuff.  Its value is all the
*   appropriate individual flags ORed together.
}
  flags_access := [];                  {init read/write access flags}
  i := 0;                              {init read/write combination flag}

  if file_rw_read_k in rw_mode then begin {READ mode is selected}
    i := i ! 1;
    flags_access := flags_access + [faccess_read_k];
    end;

  if file_rw_write_k in rw_mode then begin {WRITE mode is selected}
    i := i ! 2;
    flags_access := flags_access + [faccess_write_k];
    end;

  case i of
0:  begin                              {neither read nor write mode requested}
      sys_stat_set (file_subsys_k, file_stat_rw_none_open_k, stat);
      sys_stat_parm_vstr (name, stat);
      sys_stat_parm_str (ext, stat);
      return;                          {return with error}
      end;
1:  begin                              {requested READ mode only}
      mode_create := fcreate_existing_k; {file must previously exist}
      end;
2:  begin                              {requested WRITE mode only}
      mode_create := fcreate_overwrite_k; {create new, any existing file ignored}
      end;
3:  begin                              {requested both READ and WRITE mode}
      mode_create := fcreate_open_k;   {use old file if exists, otherwise create one}
      end;
    end;                               {done setting FLG_OPEN to reflect read/write}

  file_name_init (name, ext, rw_mode, conn, name_h); {init for making file names}
  while file_name_next(name_h) do begin {back here for each new file name to try}
    string_terminate_null (conn.tnam); {null terminate for system call}
    h := CreateFileA (                 {try to open file}
      conn.tnam.str,                   {file name}
      flags_access,                    {read/write access flags}
      [fshare_read_k],                 {others may only read this file}
      nil,                             {no special security info supplied}
      mode_create,                     {file creation mode}
      [fattr_normal_k, fattr_sequential_k], {file attributes}
      handle_none_k);                  {no attributes template supplied}
    if h <> handle_invalid_k then goto opened; {file opened successfully ?}
    stat.sys := GetLastError;          {open failed, get system error code}
    if not file_not_found(stat) then return; {other than NOT FOUND error ?}
    end;                               {back and try next file name}
{
*   None of the possible file names worked.  This is now definately a
*   FILE NOT FOUND error.
}
  sys_stat_set (file_subsys_k, file_stat_not_found_k, stat);
  sys_stat_parm_vstr (name, stat);
  sys_stat_parm_str (ext, stat);
  return;                              {return with FILE NOT FOUND error}
{
*   The file has been successfully opened.
}
opened:
  conn.sys := h;                       {save handle to system file connection}
  conn.obty := file_obty_file_k;       {connection is to regular sequential file}
  conn.fmt := file_fmt_bin_k;          {data format is raw binary}
  conn.lnum := file_lnum_nil_k;        {this type of file has no line numbers}
  conn.data_p := nil;                  {set pointer to private data block}
  conn.close_p := nil;                 {no special routine needed to close the file}
  end;
