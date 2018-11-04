{   Module of routines that manipulate the current file read/write position.
}
module file_pos;
define file_pos_end;
define file_pos_get;
define file_pos_ofs;
define file_pos_set;
define file_pos_start;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';
{
***********************************************************************
*
*   Subroutine FILE_POS_END (CONN, STAT)
*
*   Position the file indicated by the file connection CONN to the end of the
*   file.
}
procedure file_pos_end (               {set current file position to end of file}
  in out  conn: file_conn_t;           {handle to this file connection}
  out     stat: sys_err_t);            {completion status code}

var
  sypos: win_dword_t;                  {new file position}
  data_p: file_textr_data_p_t;         {pointer to our private data}

begin
  sys_error_none (stat);               {init to no error}

  sypos := SetFilePointer (
    conn.sys,                          {system handle to file connection}
    0,                                 {relative displacement}
    nil,                               {we are using 32 bit file offsets only}
    fmove_end_k);                      {displacement is relative to end of file}
  if sypos = func_fail_k then begin    {system call failed ?}
    stat.sys := GetLastError;
    end;

  if                                   {special case for reading text file ?}
      (conn.rw_mode = [file_rw_read_k]) and {open for read ?}
      (conn.obty = file_obty_file_k) and {object is regular file ?}
      (conn.fmt = file_fmt_text_k)     {format is text ?}
      then begin
    data_p := conn.data_p;             {get pointer to our private file conn data}
    data_p^.nbuf := 0;                 {flush all unread buffered data}
    data_p^.nxchar := 0;
    data_p^.ofs := sypos;              {update file offset for buffer start}
    data_p^.eof := false;              {re-discover EOF, if needed}
    end;

  if conn.lnum <> file_lnum_nil_k      {line number are meaninful}
    then conn.lnum := file_lnum_unk_k; {current line number now unknown}
  end;
{
***********************************************************************
*
*   Subroutine FILE_POS_GET (CONN, POS)
*
*   Get the position of the current location in the file into the file position
*   handle POS.
}
procedure file_pos_get (               {return current position within file}
  in      conn: file_conn_t;           {handle to this file connection}
  out     pos: file_pos_t);            {handle to current file position}

var
  sypos: win_dword_t;                  {new file position}
  data_p: file_textr_data_p_t;         {pointer to our private data}

begin
  pos.conn_p := addr(conn);            {fill in static part of position handle}

  if                                   {special case for reading text file ?}
      (conn.rw_mode = [file_rw_read_k]) and {open for read ?}
      (conn.obty = file_obty_file_k) and {object is regular file ?}
      (conn.fmt = file_fmt_text_k)     {format is text ?}
      then begin
    data_p := conn.data_p;             {get pointer to our private file conn data}
    pos.sys := data_p^.ofs + data_p^.nxchar;
    return;
    end;

  sypos := SetFilePointer (            {get current file offset}
    conn.sys,                          {system handle to file connection}
    0,                                 {relative displacement}
    nil,                               {we are using 32 bit file offsets only}
    fmove_rel_k);                      {displacment is relative to curr position}
  if sypos = func_fail_k then begin    {system call failed ?}
    sys_sys_error_bomb ('file', 'pos_get', nil, 0);
    end;
  pos.sys := sypos;
  end;
{
***********************************************************************
*
*   Subroutine FILE_POS_OFS (CONN, OFS, STAT)
*
*   Change the current file position to a fixed offset from the start of the
*   file.  The offset is in machine address units.  This call is only allowed
*   on binary files open for sequential read and/or write access.
}
procedure file_pos_ofs (               {position binary file to fixed file offset}
  in out  conn: file_conn_t;           {handle to this file connection}
  in      ofs: sys_int_adr_t;          {offset from file start in machine adr units}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  sypos: win_dword_t;                  {new file position}

begin
  sys_error_none (stat);               {init to no error occurred}
  if                                   {wrong file type or connection type ?}
      (conn.obty <> file_obty_file_k) or
      (conn.fmt <> file_fmt_bin_k)
      then begin
    sys_stat_set (file_subsys_k, file_stat_posofs_ftype_k, stat);
    sys_stat_parm_vstr (conn.tnam, stat);
    sys_stat_parm_int (ofs, stat);
    return;                            {return with error}
    end;

  sypos := SetFilePointer (
    conn.sys,                          {system handle to file connection}
    ofs,                               {relative displacement}
    nil,                               {we are using 32 bit file offsets only}
    fmove_abs_k);                      {displacement is absolute file offset}
  if sypos = func_fail_k then begin    {system call failed ?}
    stat.sys := GetLastError;
    end;

  if conn.lnum <> file_lnum_nil_k      {line numbers are meaninful ?}
    then conn.lnum := file_lnum_unk_k; {current line number now unknown}
  end;
{
***********************************************************************
*
*   Subroutine FILE_POS_SET (POS, STAT)
*
*   Set the file position to the point it was when the position handle POS
*   was last set with a call to FILE_POS_GET.
}
procedure file_pos_set (               {set file to fixed position}
  in out  pos: file_pos_t;             {position handle obtained with FILE_POS_GET}
  out     stat: sys_err_t);            {completion status code}

var
  sypos: win_dword_t;                  {new file position}
  data_p: file_textr_data_p_t;         {pointer to our private data}

begin
  sys_error_none (stat);               {init to no error occurred}

  with pos.conn_p^: conn do begin      {CONN is our file connection handle}
    if                                 {special case for reading text file ?}
        (conn.rw_mode = [file_rw_read_k]) and {open for read ?}
        (conn.obty = file_obty_file_k) and {object is regular file ?}
        (conn.fmt = file_fmt_text_k)   {format is text ?}
        then begin
      data_p := conn.data_p;           {get pointer to private file connection data}
      data_p^.nbuf := 0;               {flush all unread characters}
      data_p^.nxchar := 0;
      data_p^.ofs := pos.sys;          {adjust file position}
      data_p^.eof := false;            {reset to not hit end of file}
      end;

    sypos := SetFilePointer (
      conn.sys,                        {system handle to file connection}
      pos.sys,                         {relative displacement}
      nil,                             {we are using 32 bit file offsets only}
      fmove_abs_k);                    {displacement is absolute file offset}
    if sypos = func_fail_k then begin  {system call failed ?}
      stat.sys := GetLastError;
      end;

    if conn.lnum <> file_lnum_nil_k    {line numbers are meaninful ?}
      then conn.lnum := file_lnum_unk_k; {current line number now unknown}
    end;                               {done with CONN abbreviation}
  end;
{
***********************************************************************
*
*   Subroutine FILE_POS_START (CONN, STAT)
*
*   Position the file indicated by the file connection CONN to the start of the
*   file.
}
procedure file_pos_start (             {set current file position to start of file}
  in out  conn: file_conn_t;           {handle to this file connection}
  out     stat: sys_err_t);            {completion status code}

var
  sypos: win_dword_t;                  {new file position}
  data_p: file_textr_data_p_t;         {pointer to our private data}

begin
  sys_error_none (stat);               {init to no error}

  sypos := SetFilePointer (
    conn.sys,                          {system handle to file connection}
    0,                                 {relative displacement}
    nil,                               {we are using 32 bit file offsets only}
    fmove_abs_k);                      {displacement is absolute file offset}
  if sypos = func_fail_k then begin    {system call failed ?}
    stat.sys := GetLastError;
    end;

  if                                   {special case for reading text file ?}
      (conn.rw_mode = [file_rw_read_k]) and {open for read ?}
      (conn.obty = file_obty_file_k) and {object is regular file ?}
      (conn.fmt = file_fmt_text_k)     {format is text ?}
      then begin
    data_p := conn.data_p;             {get pointer to our private file conn data}
    data_p^.nbuf := 0;                 {flush all unread buffered data}
    data_p^.nxchar := 0;
    data_p^.ofs := sypos;              {update file offset for buffer start}
    data_p^.eof := false;              {reset to not hit EOF}
    end;

  if conn.lnum <> file_lnum_nil_k      {line number are meaninful}
    then conn.lnum := 0;               {reset line numbers to start of file}
  end;
