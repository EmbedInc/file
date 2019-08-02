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
  finished;

var
  dnam: string_treename_t;             {directory}
  tnam: string_treename_t;             {full treename for directory}
  lnam: string_leafname_t;             {leafname}
  nam: string_leafname_t;              {general leafname}
  conn: file_conn_t;                   {directory file handle}
  stat: sys_err_t;                     {completion status code}
  msg_parm: array[1..1] of sys_parm_msg_t; {message parameter array}

begin
  dnam.max := size_char(dnam.str);     {init local var strings}
  tnam.max := size_char(tnam.str);
  lnam.max := size_char(lnam.str);
  nam.max := size_char(nam.str);
  file_exists := false;                {init returned value}

  string_treename (fnam, tnam);        {get abs treename}
  string_pathname_split (tnam, dnam, lnam); {get directory and leafname}
  if not sys_fnam_case then begin      {file name are case-insensitive ?}
    string_upcase (lnam);              {make upper case}
    end;

  file_open_read_dir (dnam, conn, stat); {open the directory for reading}
  if file_not_found (stat) then return; {no such directory ?}
  if sys_error(stat) then begin        {hard error ?}
    sys_msg_parm_vstr (msg_parm[1], dnam);
    sys_error_abort (stat, 'file', 'open_dir', msg_parm, 1);
    end;

  while true do begin                  {back here each new directory entry}
    file_read_dir (                    {read next directory entry}
      conn,                            {handle to directory connection}
      [],                              {no additional info is being requested}
      nam,                             {returned directory entry name}
      info,                            {additional file info (unused)}
      stat);
    if file_eof(stat) then goto finished; {all ents compared, didn't find file ?}
    sys_error_abort (stat, 'file', 'read_dir', nil, 0);

    if not sys_fnam_case then begin    {file names are not case sensitive ?}
      string_upcase (nam);             {make this directory entry upper case}
      end;
    if string_equal(lnam, nam) then exit; {found the file ?}
    end;                               {back to check next directory entry}

  file_exists := true;                 {file exists}

finished:                              {function value is all set}
  file_close (conn);                   {close the directory for reading}
  end;
