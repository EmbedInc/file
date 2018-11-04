{   Module of routines that handle symbolic links.
}
module file_link;
define file_link_create;
define file_link_del;
define file_link_resolve;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';
{
********************************************************
*
*   Subroutine FILE_LINK_CREATE (NAME, VAL, FLAGS, STAT)
*
*   Create a symbolic file link.  NAME is the name of the link to create.
*   VAL will be the pathname the link resolves to.  FLAGS is a set of option
*   flags for creating file system entities.  FLAGS may contain the following
*   values:
*
*     FILE_CREA_OVERWRITE_K  -  It is permissible to overwrite any existing
*       file or link with name NAME.  In this case, the effect is as if the
*       old file were deleted before the new link is created.
}
procedure file_link_create (           {create a symbolic link}
  in      name: univ string_var_arg_t; {name of link to create}
  in      val: univ string_var_arg_t;  {link value (file name link resolves to)}
  in      flags: file_crea_t;          {set of creation option flags}
  out     stat: sys_err_t);            {returned completion status code}
  val_param;

var
  create: fcreate_k_t;                 {file creation behavior}
  h: win_handle_t;                     {handle to link file connection}
  olen: win_dword_t;                   {number of bytes actually written}
  dnam: string_treename_t;             {name of directory where link will go}
  lnam: string_leafname_t;             {link leafname}
  tnam: string_var8192_t;              {link treename}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

label
  syserr, abort;

begin
  dnam.max := sizeof(dnam.str);        {init local var strings}
  lnam.max := sizeof(lnam.str);
  tnam.max := sizeof(tnam.str);
  sys_error_none (stat);               {init to no error occurred}

  string_pathname_split (name, dnam, lnam); {make directory and leaf names}
  string_treename (dnam, dnam);        {make full directory treename}
  string_pathname_join (dnam, lnam, tnam); {make apparent link tree name}

  create := fcreate_new_k;             {init to creating a new file}
  if file_crea_overwrite_k in flags then begin {delete old file first ?}
    create := fcreate_overwrite_k;     {ignore previously existing link file, if any}
    string_terminate_null (tnam);      {make null terminated for system call}
    ok := DeleteFileA (tnam.str);      {delete any existing file of this name}
    if ok = win_bool_false_k then begin {error deleting file with link name ?}
      stat.sys := GetLastError;        {get system error code}
      if not file_not_found(stat) then return; {other than NOT FOUND error ?}
      end;
    end;

  string_appendn (tnam, '.@', 2);      {make true link file name}
  string_terminate_null (tnam);        {make null terminated for system call}
  h := CreateFileA (                   {open link file for write}
    tnam.str,                          {file name}
    [faccess_write_k],                 {we want to write to file}
    [fshare_read_k],                   {others may only read the file}
    nil,                               {no security info supplied}
    create,                            {how to deal with existing file, if any}
    [fattr_normal_k, fattr_sequential_k], {file attribute flags}
    handle_none_k);                    {no attributes template supplied}
  if h = handle_invalid_k then begin   {error opening link file for write ?}
syserr:                                {jump here on system error when file closed}
    stat.sys := GetLastError;          {get system error code}
    return;                            {return with the error}
    end;

  ok := WriteFile (                    {write the expansion text to the file}
    h,                                 {handle to file connection}
    val.str,                           {data to write}
    val.len,                           {number of bytes to write}
    olen,                              {returned number of bytes actually written}
    nil);                              {no overlap and position info supplied}
  if ok = win_bool_false_k then goto abort; {error on write to link ?}

  ok := SetEndOfFile (h);              {truncate file right after link text}
  if ok = win_bool_false_k then goto abort;

  ok := CloseHandle (h);               {close link file}
  if ok = win_bool_false_k then goto syserr;
  return;                              {normal return}
{
*   A system error occurred while the file is open.
}
abort:
  stat.sys := GetLastError;            {get system error code}
  discard( CloseHandle(h) );           {try to close the file}
  discard( DeleteFileA(tnam.str) );    {try to delete the link file}
  end;
{
********************************************************
*
*   Subroutine FILE_LINK_DEL (NAME, STAT)
*
*   Delete the symbolic link at pathname NAME.
}
procedure file_link_del (              {delete a symbolic link}
  in      name: univ string_var_arg_t; {name of link to delete}
  out     stat: sys_err_t);            {returned completion status code}
  val_param;

var
  dnam: string_treename_t;             {name of directory where link will go}
  lnam: string_leafname_t;             {link leafname}
  tnam: string_var8192_t;              {link treename}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

begin
  dnam.max := sizeof(dnam.str);        {init local var strings}
  lnam.max := sizeof(lnam.str);
  tnam.max := sizeof(tnam.str);
  sys_error_none (stat);               {init to no error occurred}

  string_pathname_split (name, dnam, lnam); {make directory and leaf names}
  string_treename (dnam, dnam);        {make full directory treename}
  string_pathname_join (dnam, lnam, tnam); {make apparent link tree name}
  string_appendn (tnam, '.@', 2);      {make true link file name}
  string_terminate_null (tnam);        {null terminate for system call}

  ok := DeleteFileA (tnam.str);        {try to delete the link file}
  if ok = win_bool_false_k then begin
    stat.sys := GetLastError;          {get system error code}
    end;
  end;
{
********************************************************
*
*   Subroutine FILE_LINK_RESOLVE (NAME, VAL, STAT)
*
*   Get the pathname expansion of the symbolic link at pathname NAME.  The
*   link expansion is returned in VAL.
}
procedure file_link_resolve (          {get symbolic link expansion}
  in      name: univ string_var_arg_t; {name of link to delete}
  in out  val: univ string_var_arg_t;  {returned link value}
  out     stat: sys_err_t);            {returned completion status code}
  val_param;

var
  h: win_handle_t;                     {handle to link file connection}
  i: sys_int_machine_t;                {scratch integer}
  olen: win_dword_t;                   {number of bytes actually read}
  path: string_var8192_t;              {internal true link pathname}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}
  c: char;

label
  abort2, abort1;

begin
  path.max := sizeof(path.str);        {init local var string}
  sys_error_none (stat);               {init to no error occurred}

  string_copy (name, path);            {make local copy of caller's path name}
  string_appendn (path, '.@', 2);      {make true link file name, if exists}
  string_terminate_null (path);        {null terminate for system call}

  h := CreateFileA (                   {try to open link file}
    path.str,                          {pathname}
    [faccess_read_k],                  {we only want to read the file}
    [fshare_read_k],                   {others may only read file while we have it}
    nil,                               {optional security attributes pointer}
    fcreate_existing_k,                {file must previously exist}
    [fattr_normal_k, fattr_sequential_k], {additional attribute flags}
    handle_none_k);                    {no attributes template supplied}
  if h = handle_invalid_k then goto abort1; {error ?}

  ok := ReadFile (                     {try to read link as text file}
    h,                                 {handle to file connection}
    path.str,                          {input buffer}
    path.max,                          {max number of bytes to read}
    olen,                              {number of bytes actually read}
    nil);                              {no overlap or pos info supplied}
  if ok = win_bool_false_k then goto abort2; {error ?}
  path.len := min(path.max, olen);     {set string length in PATH}
  discard( CloseHandle(h) );           {close connection to link file}

  val.len := min(val.max, path.len);   {max possible return string}
  for i := 1 to val.len do begin       {once for each possible character to copy}
    c := path.str[i];                  {fetch this source character}
    if ((ord(c) >= 0) and (ord(c) <= 31)) or (ord(c) = 127) then begin {bad char ?}
      val.len := i - 1;                {truncate VAL to before bad character}
      return;
      end;
    val.str[i] := c;                   {copy this character to output string}
    end;
  return;

abort2:                                {jump here to abort with handle open}
  stat.sys := GetLastError;
  discard( CloseHandle (h) );          {close handle to link file}
  return;

abort1:                                {jump here to abort on no handle to link file}
  stat.sys := GetLastError;
  end;
