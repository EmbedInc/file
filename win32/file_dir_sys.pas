{   Module of system specific routines that contain low level directory
*   manipulation functions.
*
*   This version is for the Microsoft Win32 API.
}
module file_dir_sys;
define file_create_dir;
define file_delete_tree;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';
{
************************************************************************
*
*   Subroutine FILE_CREATE_DIR (NAME, FLAGS, STAT)
*
*   Create a new directory named NAME.  It is an error if a file system object
*   called NAME already exists.  FLAGS is a set of option flags.  The
*   flags relevant to this routine are:
*
*     FILE_CREA_OVERWRITE_K  -  If the target already exists, then the old
*       target is deleted before the new directory is created.
*
*     FILE_CREA_KEEP_K  -  If the target already exists and is a directory,
*       then nothing is done.  This overrides FILE_CREA_OVERWRITE_K in the
*       case where the target exists and is a directory.
}
procedure file_create_dir (            {create a new directory}
  in      name: univ string_var_arg_t; {name of directory to create}
  in      flags: file_crea_t;          {set of creation option flags}
  out     stat: sys_err_t);            {returned completion status code}
  val_param;

var
  finfo: file_info_t;                  {info about existing object, if any}
  tnam: string_treename_t;             {expanded local name of object}
  tnstat: string_tnstat_k_t;           {status of treename expansion}
  ok: win_bool_t;                      {WIN_BOOL_FALSE_K on system call failure}

label
  doit;

begin
  tnam.max := sizeof(tnam.str);        {init local var string}

  string_treename_opts (               {expand NAME to full local treename}
    name,                              {input pathname}
    [ string_tnamopt_remote_k,         {continue on remote systems if needed}
      string_tnamopt_proc_k,           {expansion is for this process}
      string_tnamopt_native_k],        {we need result in native format}
    tnam,                              {returned tree name}
    tnstat);                           {returned name expansion status}

  file_info (                          {get info about existing object, if any}
    tnam,                              {name inquiring about}
    [file_iflag_type_k],               {we want to know the file type}
    finfo,                             {returned info about the file}
    stat);
  if file_not_found(stat) then goto doit; {target doesn't exist ?}
  if sys_error(stat) then return;      {hard error ?}

  if
      (finfo.ftype = file_type_dir_k) and {existing object is a directory ?}
      (file_crea_keep_k in flags) then begin {keep old object if a directory ?}
    return;
    end;

  if file_crea_overwrite_k in flags then begin {OK to overwrite any old object ?}
    file_delete_tree (tnam, [], stat); {delete the existing object}
    if sys_error(stat) then return;
    goto doit;                         {go create the directory}
    end;

  sys_stat_set (file_subsys_k, file_stat_crea_exists_k, stat);
  sys_stat_parm_vstr (tnam, stat);
  return;                              {return with already exists error}

doit:                                  {create the new directory}
  string_terminate_null (tnam);        {make sure STR field is C-style string}
  ok := CreateDirectoryA (             {create the new directory}
    tnam.str,                          {null terminated directory name}
    nil);                              {no security attributes supplied}
  if ok = win_bool_false_k then begin  {system call failed ?}
    stat.sys := GetLastError;
    end;
  end;
{
************************************************************************
*
*   Subroutine FILE_DELETE_TREE (NAME, OPTS, STAT)
*
*   Delete the complete file system object at NAME.  If NAME is a directory,
*   then its entire contents will be deleted.  OPTS is a set of flags.  The
*   following flags are relevant to this routine:
*
*     FILE_DEL_ERRGO_K  -  Continue on error.  Normally the routine returns
*       immediately whenever any error is encountered.  When this flag is
*       set, the routine will continue on some types of errors.  For example,
*       if a file in a directory can't be deleted (due to permission problems
*       maybe), attempts are still made to delete the other files in the
*       directory.  STAT will still be returned with an error.  STAT is only
*       returned OK if everything at NAME was successfully deleted.
*
*     FILE_DEL_LIST_K  -  List activity to standard output.
}
procedure file_delete_tree (           {delete a whole directory tree}
  in      name: univ string_var_arg_t; {name of tree to delete}
  in      opts: file_del_t;            {additional option flags}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  finfo: file_info_t;                  {info about existing object, if any}
  tnam: string_treename_t;             {expanded local name of object}
  tnstat: string_tnstat_k_t;           {status of treename expansion}
  ndel: sys_int_machine_t;             {number of objects not deleted}
  ok: win_bool_t;                      {WIN_BOOL_FALSE_K on system call failure}
{
********************
*
*   Local subroutine DEL_DIR (NAME, OPTS, STAT)
*   This routine is local to FILE_DELETE_TREE.
*
*   Delete the directory at NAME.  This routine calls itself recursively to
*   delete subdirectories.  Directories are emptied first before being deleted.
*   the STR field in NAME must be null terminated.
}
procedure del_dir (                    {delete directory}
  in      name: string_treename_t;     {name of directory to delete}
  in      opts: file_del_t;            {additional option flags}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  conn: file_conn_t;                   {handle for reading directory entries}
  ent: string_leafname_t;              {directory entry name}
  tnam: string_treename_t;             {full treename of directory entry}
  finfo: file_info_t;                  {info about existing object, if any}

label
  loop, abort, eof;

begin
  ent.max := sizeof(ent.str);          {init local var strings}
  tnam.max := sizeof(tnam.str);

  file_open_read_dir (name, conn, stat); {open directory for reading entries}
  if sys_error(stat) then return;

loop:                                  {back here to read each new directory entry}
  file_read_dir (                      {read next directory entry}
    conn,                              {handle to directory connection}
    [file_iflag_type_k],               {we want to know the file type}
    ent,                               {returned directory entry name}
    finfo,                             {returned info about this entry}
    stat);
  if file_eof(stat) then goto eof;     {hit end of directory ?}
  if sys_error(stat) then goto abort;

  string_pathname_join (name, ent, tnam); {make directory entry full treename}

  case finfo.ftype of                  {what kind of file is it ?}

file_type_link_k: begin                {symbolic link}
      if file_del_list_k in opts then begin {list activity to standard output ?}
        writeln ('(link) ', tnam.str:tnam.len);
        end;
      file_link_del (tnam, stat);      {delete the link}
      end;
file_type_dir_k: begin                 {directory}
      string_terminate_null (tnam);    {make sure STR field is NULL terminated}
      del_dir (tnam, opts, stat);      {delete subordinate directory recursively}
      end;
otherwise                              {assume normal file}
    if file_del_list_k in opts then begin {list activity to standard output ?}
      writeln ('(file) ', tnam.str:tnam.len);
      end;
    file_delete_name (tnam, stat);
    end;

  if sys_error(stat) then begin        {an error occurred ?}
    if file_del_errgo_k in opts
      then begin                       {continue on error ?}
        sys_error_print (stat, '', '', nil, 0);
        ndel := ndel + 1;              {count one more undeleted object}
        sys_error_none (stat);         {reset to no hard error}
        end
      else begin                       {abort immediately on any error ?}
abort:                                 {jump here on error with dir open, STAT set}
        file_close (conn);             {close directory}
        return;
        end
      ;
    end;
  goto loop;                           {back to do next directory entry}

eof:                                   {hit end of directory}
  file_close (conn);                   {close the directory}

  if file_del_list_k in opts then begin {list activity to standard output ?}
    writeln ('(dir)  ', name.str:name.len);
    end;
  ok := RemoveDirectoryA (name.str);   {delete the supposedly empty directory}
  if ok = win_bool_false_k then begin  {directory delete failed ?}
    stat.sys := GetLastError;
    end;
  end;
{
********************
*
*   Start of main routine.
}
begin
  tnam.max := sizeof(tnam.str);        {init local var string}

  string_treename_opts (               {expand NAME to full local treename}
    name,                              {input pathname}
    [ string_tnamopt_remote_k,         {continue on remote systems if needed}
      string_tnamopt_proc_k,           {expansion is for this process}
      string_tnamopt_native_k],        {we need result in native format}
    tnam,                              {returned tree name}
    tnstat);                           {returned name expansion status}

  file_info (                          {get info about existing object, if any}
    tnam,                              {name inquiring about}
    [file_iflag_type_k],               {we want to know the file type}
    finfo,                             {returned info about the file}
    stat);
  if file_not_found(stat) then begin
    sys_stat_set (file_subsys_k, file_stat_not_found_k, stat);
    sys_stat_parm_vstr (tnam, stat);
    sys_stat_parm_str ('', stat);
    return;
    end;
  if sys_error(stat) then return;      {hard error ?}

  ndel := 0;                           {init to no objects with delete errors}

  case finfo.ftype of                  {what kind of object is this ?}
file_type_link_k: begin                {symbolic link}
      if file_del_list_k in opts then begin {list activity to standard output ?}
        writeln ('(link) ', tnam.str:tnam.len);
        end;
      file_link_del (tnam, stat);      {delete the link}
      end;
file_type_dir_k: begin                 {directory}
      string_terminate_null (tnam);    {make sure STR field is NULL terminated}
      del_dir (tnam, opts, stat);      {delete the directory}
      if
          (not sys_error(stat)) and    {not signalling a hard error ?}
          (ndel <> 0)                  {not able to delete all objects ?}
          then begin
        sys_stat_set (file_subsys_k, file_stat_ndel_k, stat);
        sys_stat_parm_int (ndel, stat);
        end;
      end;
otherwise                              {assume regular file}
    if file_del_list_k in opts then begin {list activity to standard output ?}
      writeln ('(file) ', tnam.str:tnam.len);
      end;
    file_delete_name (tnam, stat);
    end;
  end;
