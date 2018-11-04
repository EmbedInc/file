{   Module of routines for getting information about a file.
*
*   This version is for the Microsoft Win32 API.
}
module file_info;
define file_info;
define file_info2;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';
{
************************************************************************
*
*   Subroutine FILE_INFO (NAME, REQUEST, INFO, STAT)
*
*   Return information about a file.  NAME is the name of the file to get info
*   about.  REQUEST indicates which information is desired.  INFO is the returned
*   information.  Only the requested fields will be filled in.  The FLAGS
*   field in INFO will be set to indicate which information is present.
*   All requested information is returned when STAT indicates no error.
}
procedure file_info (                  {get information about a file}
  in      name: univ string_var_arg_t; {name of file to get information about}
  in      request: file_iflags_t;      {indicates which information is requested}
  out     info: file_info_t;           {returned information}
  out     stat: sys_err_t);            {error status, got all info if no error}
  val_param;

var
  dnam: string_treename_t;             {name of directory containing file}
  lnam: string_leafname_t;             {file leaf name}
  tnam: string_var8192_t;              {full file tree name}
  fdata: fdata_find_t;                 {system info about a file}
  h: win_handle_t;                     {handle for getting file info}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

label
  nfound_app, sys_err, got_fdata;

begin
  dnam.max := sizeof(dnam.str);        {init local var strings}
  lnam.max := sizeof(lnam.str);
  tnam.max := sizeof(tnam.str);
  sys_error_none (stat);               {init to no error occurred}
  info.flags := [];                    {init to no info returned about file}

  string_pathname_split (name, dnam, lnam); {make directory and leaf names}
  string_treename (dnam, dnam);        {make full directory treename}
  string_pathname_join (dnam, lnam, tnam); {make apparent system file name}
  string_terminate_null (tnam);        {make sure string is in system format}
{
*   Try apparent file name.
}
  h := FindFirstFileA (tnam.str, fdata); {try to get info about raw file name}
  if h = handle_invalid_k then begin   {apparent file name not found ?}
    stat.sys := GetLastError;          {get system error code}
    if file_not_found(stat) then goto nfound_app; {apparent file name not found}
    return;                            {return with hard error}
    end;
  goto got_fdata;                      {got system FDATA about file}
{
*   No file was found using the apparent file name.  This could still be
*   a symbolic link, since these have a hidden ".@" appended to the apparent
*   file name.
}
nfound_app:                            {file with apparent name not found}
  string_appendn (tnam, '.@', 2);      {make link true file name}
  string_terminate_null (tnam);        {make sure string is in system format}
  h := FindFirstFileA (tnam.str, fdata); {try to get info about link file}
  if h = handle_invalid_k then begin   {link file name not found ?}
sys_err:
    stat.sys := GetLastError;          {get system error code}
    return;                            {return with hard error}
    end;
{
*   FDATA is filled in for this file.
}
got_fdata:
  ok := FindClose (h);                 {close FIND... connection to directory}
  if ok = win_bool_false_k then goto sys_err;

  file_info2 (fdata, request, info, dnam, stat); {extract info from system FDATA}
  if sys_error(stat) then return;

  if (request - info.flags) <> [] then begin {not get all requested information ?}
    sys_stat_set (file_subsys_k, file_stat_info_partial_k, stat);
    end;
  end;
{
************************************************************************
*
*   Subroutine FILE_INFO2 (FDATA, INFO_REQ, INFO, NAME, STAT)
*
*   This routine is internal to the Win32 implementation.  Return the
*   requested file info given FDATA, the structure returned by FindNextFile.
}
procedure file_info2 (                 {extract file info from system structure}
  in      fdata: fdata_find_t;         {info about file from FindNextFileW}
  in      info_req: file_iflags_t;     {info requested to return}
  out     info: file_info_t;           {returned file info}
  in out  name: univ string_var_arg_t; {returned apparent file name}
  out     stat: sys_err_t);
  val_param;

var
  time_sys: sys_sys_time_t;            {standard system time descriptor}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

label
  done_type, no_dtm;

begin
  sys_error_none (stat);               {init to no error}

  string_vstring (name, fdata.name, sizeof(fdata.name)); {extract raw file name}
{
*   We always return the file type because we need to determine it for our
*   own reasons.
}
  info.flags := info.flags + [file_iflag_type_k]; {indicate file type returned}

  if fattr_dir_k in fdata.attr then begin {directory ?}
    info.ftype := file_type_dir_k;
    goto done_type;
    end;

  if                                   {check for special symbolic link file name}
      (name.len > 2) and
      (name.str[name.len - 1] = '.') and (name.str[name.len] = '@')
      then begin
    name.len := name.len - 2;          {truncate hidden ".@" from file name}
    info.ftype := file_type_link_k;    {indicate file is a symbolic link}
    goto done_type;
    end;

  if fattr_system_k in fdata.attr then begin {special system file ?}
    info.ftype := file_type_other_k;
    goto done_type;
    end;

  info.ftype := file_type_data_k;      {default to regular data file}
done_type:                             {done setting returned file type}
{
*   Return date/time of last modification, if requested.
}
  if file_iflag_dtm_k in info_req then begin {return date/time modified ?}
    if                                 {date/time info not available ?}
        (fdata.time_write.low32 = 0) and
        (fdata.time_write.high32 = 0)
      then goto no_dtm;
    ok := FileTimeToSystemTime (       {convert file time to standard system time}
      fdata.time_write, time_sys);
    if ok = win_bool_false_k then begin
      stat.sys := GetLastError;
      return;
      end;
    info.modified := sys_clock_from_sys_abs (time_sys); {return final modified time}
    info.flags := info.flags + [file_iflag_dtm_k]; {indicate DTM is being returned}
    end;
no_dtm:                                {skip to here if modified time not available}
{
*   Return file length, if requested.
}
  if file_iflag_len_k in info_req then begin {file length requested ?}
    info.len := fdata.size_low;
    info.flags := info.flags + [file_iflag_len_k];
    end;
  end;
