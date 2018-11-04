{   Subroutine FILE_OPEN_WRITE_TEXT (NAME, EXT, CONN, STAT)
*
*   Open a text file for write.  NAME is the file name.  EXT is an optional
*   file name extension when not set to all-blank.  It is permissible for NAME to
*   already have the extensions on it.  In that case it will be ignored
*   in making the the non-extended name.  CONN is returned as the file connection
*   handle.  STAT is returned as the status completion code.
}
module file_open_write_text;
define file_open_write_text;
%include 'file2.ins.pas';

procedure file_open_write_text (       {open text file for write}
  in      name: univ string_var_arg_t; {generic file name}
  in      ext: string;                 {file name extension, blank if not used}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}

var
  p: string_index_t;                   {parse index into EXT}
  extv: string_var80_t;                {extensions in a var string}
  ex: string_var80_t;                  {one extension from list}
  i, j: sys_int_machine_t;             {scratch integers and loop counters}
  tnstat: string_tnstat_k_t;           {treename translation status}

label
  add_ext, done_ext;

begin
  extv.max := sizeof(extv.str);        {init local var strings}
  ex.max := sizeof(ex.str);

  conn.fnam.max := sizeof(conn.fnam.str); {init CONN static fields}
  conn.gnam.max := sizeof(conn.gnam.str);
  conn.tnam.max := sizeof(conn.tnam.str);
  sys_error_none (stat);               {init to no error}

  if name.len <= 0 then begin          {file name string empty ?}
    sys_stat_set (file_subsys_k, file_stat_no_fnam_open_k, stat);
    return;                            {return with error}
    end;

  p := 1;                              {init parse index for extracting raw name}
  string_token (name, p, conn.fnam, stat); {init full file name}
  if sys_error(stat) then return;

  string_vstring (extv, ext, sizeof(ext)); {get extensions string in nice format}
  p := 1;                              {init parse index for extracting extension}
  string_token (extv, p, ex, stat);    {get extension in EX}
  sys_error_none (stat);               {reset unused STAT to no error}
  conn.ext_num := 0;                   {init to no extension exists}
  if ex.len > 0 then begin             {extension exists ?}
    conn.ext_num := 1;                 {indicate extension was used}
    if ex.len > conn.fnam.len          {extension definately not already here ?}
      then goto add_ext;
    j := conn.fnam.len;                {init to last character of name}
    for i := ex.len downto 1 do begin  {loop backwards thru extension chars}
      if conn.fnam.str[j] <> ex.str[i] {this extension char doesn't match ?}
        then goto add_ext;
      j := j - 1;                      {make next name char to check}
      end;
    goto done_ext;                     {file name already has extension on it}
add_ext:                               {need to add extension to file name}
    string_append (conn.fnam, ex);     {add extension to file name}
done_ext:                              {CONN.FNAM contains fully extended file name}
    end;                               {done handling extension exists}
{
*   The complete file name, with extension, is in CONN.FNAM.
}
  string_generic_fnam (conn.fnam, ext, conn.gnam);

  string_treename_opts (               {convert file name to true treename}
    conn.fnam,                         {input file name}
    [ string_tnamopt_flink_k,          {follow symbolic links}
      string_tnamopt_remote_k,         {translate on remote systems as needed}
      string_tnamopt_proc_k,           {this process owns the pathname}
      string_tnamopt_native_k],        {we want the result in native OS format}
    conn.tnam,                         {output treename}
    tnstat);                           {returned output treename translation status}
  if tnstat <> string_tnstat_native_k then begin {file is on remote machine ?}
    file_csrv_txw_open (conn, stat);   {handle remote files in separate routine}
    return;
    end;

  file_open_write_bin (name, ext, conn, stat); {open as binary file}
  if sys_error(stat) then return;      {error opening file ?}
  conn.fmt := file_fmt_text_k;         {this is really a text file}
  conn.lnum := 0;                      {init line number counter}
  end;
