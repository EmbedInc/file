{   Module of routines that deal with current directory issues.
*
*   This version is for the Microsoft Win32 API.
}
module file_currdir;
define file_currdir_get;
define file_currdir_set;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';
{
***************************************************************
*
*   Subroutine FILE_CURRDIR_GET (DNAM, STAT)
*
*   Get the current directory name.
}
procedure file_currdir_get (           {get current directory name}
  in out  dnam: univ string_var_arg_t; {returned directory name}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  winlen: win_dword_t;                 {number of chars returned by system call}

begin
  sys_error_none (stat);               {init to no error occurred}

  winlen := GetCurrentDirectoryA (     {get name of current directory}
    dnam.max,                          {max characters allowed to return}
    dnam.str);                         {returned characters}
  if winlen <= 0 then begin            {system error occurred ?}
    stat.sys := GetLastError;          {get system error code}
    return;                            {return with error}
    end;
  dnam.len := winlen;                  {set length of returned directory name}
  end;
{
***************************************************************
*
*   Subroutine FILE_CURRDIR_SET (DNAM, STAT)
*
*   Set a new directory as the current directory.
}
procedure file_currdir_set (           {set current directory}
  in      dnam: univ string_var_arg_t; {name of directory to set as current}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  dir: string_var8192_t;               {directory name in local format}
  tstat: string_tnstat_k_t;            {name translation status}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

begin
  dir.max := size_char(dir.str);       {init local var string}
  sys_error_none (stat);               {init to no error occurred}

  string_treename_opts (               {make directory name in local format}
    dnam,                              {input pathname}
    [ string_tnamopt_flink_k,          {follow symbolic links}
      string_tnamopt_remote_k,         {continue on remote systems if needed}
      string_tnamopt_proc_k,           {translate from point of view of this process}
      string_tnamopt_native_k],        {use native machine naming conventions}
    dir,                               {output pathname}
    tstat);                            {translation status result}
  string_terminate_null (dir);         {make sure .STR field is NULL-terminated}
  ok := SetCurrentDirectoryA (dir.str); {try to set new current directory}
  if ok = win_bool_false_k then begin  {error ?}
    stat.sys := GetLastError;          {get system error code}
    end;
  end;
