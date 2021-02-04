{   Program TEST_DIR [<directory name>]
*
*   List the contents of the directory.
}
program test_dir;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';

var
  dir_name:                            {directory name from command line}
    %include '(cog)lib/string_treename.ins.pas';
  conn: file_conn_t;                   {connection handle to environment files}
  ent_name:                            {one directory entry name}
    %include '(cog)lib/string_leafname.ins.pas';
  info: file_info_t;                   {additional info about file in directory}
  msg: string_var8192_t;               {one line message for each file in dir}
  tk: string_var32_t;                  {scratch token for building message string}
  msg_parms:                           {parameters to messages}
    array[1..1] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

label
  next_ent, eof;

begin
  msg.max := sizeof(msg.str);          {init local var strings}
  tk.max := sizeof(tk.str);

  string_cmline_init;                  {init for reading the command line}
  string_cmline_token (dir_name, stat); {get name of directory to list}
  if string_eos(stat) then begin       {no argument, use default directory ?}
    string_vstring (dir_name, '.', 1);
    end;
  string_cmline_end_abort;             {no additional command line args allowed}

  file_open_read_dir (dir_name, conn, stat); {open connection for reading directory}
  sys_msg_parm_vstr (msg_parms[1], dir_name);
  sys_error_abort (stat, 'file', 'open_dir', msg_parms, 1);
  writeln ('Directory ', conn.tnam.str:conn.tnam.len);

next_ent:                              {back here each new directory entry}
  file_read_dir (                      {read next entry from directory}
    conn,                              {handle to directory read connection}
    [                                  {info requested to be returned in INFO}
      file_iflag_dtm_k,                {date/time of last modification}
      file_iflag_len_k,                {length of file}
      file_iflag_perm_k,               {our current permissions}
      file_iflag_type_k],              {what type of file this is}
    ent_name,                          {returned directory entry name}
    info,                              {returned info about this file system object}
    stat);
  if file_eof(stat) then goto eof;     {exhausted directory ?}
  discard(                             {partial info isn't an error, handled later}
    sys_stat_match (file_subsys_k, file_stat_info_partial_k, stat) );
  sys_error_abort (stat, 'file', 'read_dir', nil, 0);

  msg.len := 0;                        {init message string for this file}
{
*   Show file type.
}
  if file_iflag_type_k in info.flags
    then begin                         {file type was returned}
      case info.ftype of               {what kind of file system object is this ?}
file_type_other_k: string_appends (msg, 'other'(0));
file_type_data_k:  string_appends (msg, 'file '(0));
file_type_dir_k:   string_appends (msg, 'dir  '(0));
file_type_link_k:  string_appends (msg, 'link '(0));
otherwise
        string_appends (msg, 'unk  '(0));
        end;
      end
    else begin                         {no file type was returned}
      string_appends (msg, 'notyp'(0));
      end
    ;
{
*   Show our permissions.
}
  string_append1 (msg, ' ');
  if file_iflag_perm_k in info.flags
    then begin                         {file permission was returned}
      if file_perm_read_k in info.perm_us
        then string_append1 (msg, 'R')
        else string_append1 (msg, '-');
      if file_perm_write_k in info.perm_us
        then string_append1 (msg, 'W')
        else string_append1 (msg, '-');
      if file_perm_exec_k in info.perm_us
        then string_append1 (msg, 'X')
        else string_append1 (msg, '-');
      if file_perm_perm_k in info.perm_us
        then string_append1 (msg, 'P')
        else string_append1 (msg, '-');
      if file_perm_del_k in info.perm_us
        then string_append1 (msg, 'D')
        else string_append1 (msg, '-');
      if file_perm_crea_k in info.perm_us
        then string_append1 (msg, 'C')
        else string_append1 (msg, '-');
      end
    else begin                         {no permission info available}
      string_appends (msg, 'noperm');
      end
    ;
{
*   Show file length.
}
  string_append1 (msg, ' ');
  if file_iflag_len_k in info.flags
    then begin                         {file length info was returned}
      string_f_fp (                    {convert file length to string}
        tk,                            {output string}
        info.len,                      {input number}
        15,                            {fixed field width}
        0,                             {exponent field width}
        0,                             {min required significant digits}
        15,                            {max allowed digits left of point}
        0,                             {min required digits right of point}
        0,                             {max allowed digits right of point}
        [                              {set of option flags}
          string_ffp_exp_no_k,         {don't use exponential notation}
          string_ffp_group_k],         {group the digits}
        stat);
      if sys_error(stat)
        then begin                     {couldn't convert length to a string}
          string_appendn (msg, '***********', 11);
          end
        else begin                     {yes, we have file length string}
          string_append (msg, tk);
          end
        ;
      end
    else begin                         {no file length info available}
      string_appends (msg, '   nolength'(0));
      end
    ;
{
*   Show last modified date/time.
}
  string_append1 (msg, ' ');
  if file_iflag_dtm_k in info.flags
    then begin                         {file date/time info was returned}
      sys_clock_str1 (                 {make date/time string from modified time}
        info.modified,                 {file modified clock time}
        tk);                           {returned 19 char YYYY/MM/DD.MM:HH:SS}
      string_append (msg, tk);
      end
    else begin                         {no file modified time available}
      string_appends (msg, '-no-time-available-'(0));
      end
    ;
{
*   Show file name.
}
  writeln (msg.str:msg.len, ' ', ent_name.str:ent_name.len);
  goto next_ent;                       {back and process next directory entry}

eof:                                   {no more entries left in directory}
  file_close (conn);                   {close our connection to the directory}
  end.
