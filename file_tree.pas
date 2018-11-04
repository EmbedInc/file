{   Module of FILE library routines that deal with directory tree structures.
*
*   This module is system independent.
}
module file_tree;
define file_copy_tree;
%include 'file2.ins.pas';
{
************************************************************************
*
*   Local subroutine COPY_FILE (SRC, DEST, OPTS, STAT)
*
*   Copy the file SRC to DEST.  SRC must be the true pathname of an object
*   that can be copied as a regular file.
}
procedure copy_file (                  {copy a regular file}
  in      src: string_treename_t;      {pathname of regular file to copy}
  in      dest: string_treename_t;     {pathname of copied file}
  in      opts: file_copy_t;           {set of option flags}
  out     stat: sys_err_t);            {completion status code}
  val_param; internal;

var
  finfo: file_info_t;                  {info about a file system object}

label
  copy;

begin
  if file_copy_list_k in opts then begin
    writeln ('(file) ', dest.str:dest.len);
    end;

  file_info (                          {get info about dest object, if present}
    dest, [file_iflag_type_k], finfo, stat);
  if sys_error(stat) then goto copy;   {assume dest not exist, do the copy ?}
{
*   The destination object exists since we got its file type without
*   any error.
}
  if not (file_copy_replace_k in opts) then begin {not copy over existing objects ?}
    sys_stat_set (file_subsys_k, file_stat_copy_exists_k, stat);
    sys_stat_parm_vstr (dest, stat);
    return;
    end;

  case finfo.ftype of
file_type_dir_k: begin                 {destination exists as a directory}
      file_delete_tree (dest, [], stat); {delete the directory}
      end;
file_type_link_k: begin                {destination exists as a symbolic link}
      file_link_del (dest, stat);      {delete the symbolic link}
      end;
otherwise                              {assume no special handling required}
    goto copy;
    end;
  if sys_error(stat) then return;      {abort with error if something went wrong}

copy:                                  {jump here to actually do the copy}
  file_copy (src, dest, opts, stat);   {copy the file}
  end;
{
************************************************************************
*
*   Local subroutine COPY_LINK (SRC, DEST, OPTS, STAT)
*
*   Copy the symbolic link SRC to DEST.  SRC must be the true pathname of
*   a symbolic link.
}
procedure copy_link (                  {copy a symbolic link}
  in      src: string_treename_t;      {pathname of symbolic link to copy}
  in      dest: string_treename_t;     {pathname of copied link}
  in      opts: file_copy_t;           {set of option flags}
  out     stat: sys_err_t);            {completion status code}
  val_param; internal;

var
  finfo: file_info_t;                  {info about a file system object}
  lval: string_var8192_t;              {symbolic link value}
  cflags: file_crea_t;                 {link creation flags}

label
  copy;

begin
  lval.max := sizeof(lval.str);        {init local var string}

  if file_copy_list_k in opts then begin
    writeln ('(link) ', dest.str:dest.len);
    end;

  file_info (                          {get info about dest object, if present}
    dest, [file_iflag_type_k], finfo, stat);
  if sys_error(stat) then goto copy;   {assume dest not exist, do the copy ?}
{
*   The destination object exists since we got its file type without
*   any error.
}
  if not (file_copy_replace_k in opts) then begin {not copy over existing objects ?}
    sys_stat_set (file_subsys_k, file_stat_copy_exists_k, stat);
    sys_stat_parm_vstr (dest, stat);
    return;
    end;

  case finfo.ftype of
file_type_dir_k: begin                 {destination exists as a directory}
      file_delete_tree (dest, [], stat); {delete the directory}
      end;
file_type_link_k: begin                {destination exists as a symbolic link}
      file_link_del (dest, stat);      {delete the symbolic link}
      end;
otherwise                              {assume destination exists as a regular file}
    file_delete_name (dest, stat);     {delete the file}
    end;
  if sys_error(stat) then return;      {abort with error if something went wrong}

copy:                                  {jump here to actually do the copy}
  file_link_resolve (src, lval, stat); {get the source link value}
  if sys_error(stat) then return;

  if file_copy_replace_k in opts
    then cflags := [file_crea_overwrite_k] {OK to overwrite existing file}
    else cflags := [];
  file_link_create (dest, lval, cflags, stat); {create the copied link}
  end;
{
************************************************************************
*
*   Local subroutine COPY_DIR (SRC, DEST, OPTS, STAT)
*
*   Copy the directory SRC to DEST.  SRC must be the true pathname of
*   a directory.
}
procedure copy_dir (                   {copy a directory}
  in      src: string_treename_t;      {pathname of directory to copy}
  in      dest: string_treename_t;     {pathname of copied directory}
  in      opts: file_copy_t;           {set of option flags}
  out     stat: sys_err_t);            {completion status code}
  val_param; internal;

var
  finfo: file_info_t;                  {info about a file system object}
  cflags: file_crea_t;                 {directory creation flags}
  conn: file_conn_t;                   {connection handle for reading directory}
  ent: string_leafname_t;              {directory entry name}
  tnams, tnamd: string_treename_t;     {source and dest directory entry treenames}

label
  copy, loop_ent, leave;

begin
  ent.max := sizeof(ent.str);          {init local var strings}
  tnams.max := sizeof(tnams.str);
  tnamd.max := sizeof(tnamd.str);

  if file_copy_list_k in opts then begin
    writeln ('(dir)  ', dest.str:dest.len);
    end;

  file_info (                          {get info about dest object, if present}
    dest, [file_iflag_type_k], finfo, stat);
  if sys_error(stat) then goto copy;   {assume dest not exist, do the copy ?}
{
*   The destination object exists since we got its file type without
*   any error.
}
  if not (file_copy_replace_k in opts) then begin {not copy over existing objects ?}
    sys_stat_set (file_subsys_k, file_stat_copy_exists_k, stat);
    sys_stat_parm_vstr (dest, stat);
    return;
    end;

  case finfo.ftype of
file_type_dir_k: ;                     {destination exists as a directory}
file_type_link_k: begin                {destination exists as a symbolic link}
      file_link_del (dest, stat);      {delete the symbolic link}
      end;
otherwise                              {assume destination exists as a regular file}
    file_delete_name (dest, stat);     {delete the file}
    end;
  if sys_error(stat) then return;      {abort with error if something went wrong}
{
*   Copy the directory by copying each directory entry individually.
}
copy:
  if file_copy_replace_k in opts
    then begin                         {OK to merge new files into existing dir}
      cflags := [
        file_crea_overwrite_k,         {overwrite old object if not a directory}
        file_crea_keep_k];             {keep old object if it is a directory}
      end
    else begin                         {dest object must not previously exist}
      cflags := [];
      end
    ;
  file_create_dir (dest, cflags, stat); {make sure target directory exists}
  if sys_error(stat) then return;

  file_open_read_dir (src, conn, stat); {open source directory for reading entries}

loop_ent:                              {back here each new source dir entry}
  file_read_dir (                      {read next source directory entry}
    conn,                              {directory reading connection handle}
    [file_iflag_type_k],               {we want to know file type}
    ent,                               {returned directory entry name}
    finfo,                             {returned info about this entry}
    stat);
  if file_eof(stat) then goto leave;   {exhausted source directory ?}
  if sys_error(stat) then goto leave;  {abort on error}
  string_pathname_join (src, ent, tnams); {make source file full pathname}
  string_pathname_join (dest, ent, tnamd); {make dest file full pathname}

  case finfo.ftype of                  {what type of file system object is this ?}
file_type_dir_k: begin                 {directory}
      copy_dir (tnams, tnamd, opts, stat); {copy directory recursively}
      end;
file_type_link_k: begin                {symbolic link}
      copy_link (tnams, tnamd, opts, stat); {copy the link}
      end;
otherwise                              {assume regular file}
    copy_file (tnams, tnamd, opts, stat); {copy the file}
    end;                               {end of file type cases}
  if sys_error(stat) then goto leave;  {abort on copy error}
  goto loop_ent;                       {back to do next directory entry}

leave:                                 {common exit point after dir open}
  file_close (conn);                   {close connection to source directory}
  end;
{
************************************************************************
*
*   Subroutine FILE_COPY_TREE (SRC, DEST, OPTS, STAT)
*
*   Copy a file system tree from one place to another.  SRC is the source
*   tree, and DEST is the pathname of where to copy it to.  OPTS is a
*   set of option flags that provide additional control over the copying
*   process.  OPTS may contain the following flags:
*
*     FILE_COPY_REPLACE_K  -  It is permissible to copy a file or directory
*       onto an existing file system object.  If the source and destination
*       objects are different types (files, directory, links), then the
*       destination object is effectively deleted first.  If the source
*       and destination objects are both directories, then the files from
*       the source directory are added to or copied into the destination
*       directory.  Files in the destination directory not found in the
*       source directory are left alone.
*
*     FILE_COPY_LIST_K  -  List progress to standard output.
}
procedure file_copy_tree (             {copy a whole directory tree}
  in      src: univ string_var_arg_t;  {source tree name}
  in      dest: univ string_var_arg_t; {destination tree name}
  in      opts: file_copy_t;           {set of option flags}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  finfo: file_info_t;                  {info about a file system object}
  tnams, tnamd: string_treename_t;     {source and dest treenames}
  tnstat: string_tnstat_k_t;           {treename translation status}

begin
  tnams.max := sizeof(tnams.str);      {init local var strings}
  tnamd.max := sizeof(tnamd.str);
  sys_error_none (stat);               {init to no error encountered}

  string_treename_opts (               {resolve full source pathname}
    src,                               {input name}
    [ string_tnamopt_flink_k,          {follow all symbolic links}
      string_tnamopt_remote_k,         {continue on remote systems as needed}
      string_tnamopt_proc_k,           {tranlsation is relative to this process}
      string_tnamopt_native_k],        {use native file system naming when possible}
    tnams,                             {returned full pathname}
    tnstat);                           {returned TNAMS translation status}
  string_treename_opts (               {resolve full destination pathname}
    dest,                              {input name}
    [ string_tnamopt_remote_k,         {continue on remote systems as needed}
      string_tnamopt_proc_k,           {tranlsation is relative to this process}
      string_tnamopt_native_k],        {use native file system naming when possible}
    tnamd,                             {returned full pathname}
    tnstat);                           {returned TNAMS translation status}

  if string_equal (tnamd, tnams) then begin {source and dest the same ?}
    return;
    end;

  file_info (                          {get info about the source object}
    tnams,                             {source object name}
    [file_iflag_type_k],               {we need to know the file type}
    finfo,                             {returned info about the object}
    stat);
  if sys_error(stat) then return;

  case finfo.ftype of                  {what type of object is the source ?}
{
*   The source object is a directory.
}
file_type_dir_k: begin                 {source object is a directory}
      copy_dir (tnams, tnamd, opts, stat); {copy whole directory}
      end;
{
*   The source object is a symbolic link.  This can only happen if the link
*   is not pointing to an existing object, otherwise it would have been
*   resolved by STRING_TREENAME above.  In that case, all we can do is to
*   copy the link.
}
file_type_link_k: begin                {source object is symbolic link}
      copy_link (tnams, tnamd, opts, stat); {copy the link}
      end;
{
*   Assume all other types of objects are regular files.
}
otherwise
    copy_file (tnams, tnamd, opts, stat); {copy as a regular file}
    end;
  end;
