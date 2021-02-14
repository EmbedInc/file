{   Routines that implement the callback object type.  This is a virtual object
*   that causes no actual I/O.  Application routines are called for each I/O
*   operation.
}
module file_call;
define file_open_call_wtxt;
define file_call_set_wtxt;
define file_call_set_close;
define file_call_wtxt;
%include 'file2.ins.pas';

type
  dat_p_t = ^dat_t;
  dat_t = record                       {private data for CALL object types}
    mem_p: util_mem_context_p_t;       {pointer to private memory context}
    case file_fmt_k_t of               {what is the data format type ?}
file_fmt_text_k: (                     {data is lines of text}
      text_write_p: file_call_wtxt_p_t; {text write callback routine pointer}
      text_close_p: file_call_close_p_t; {close connection callback routine pnt}
      );
    end;

procedure file_call_close (            {close I/O object of CALL type}
  in    conn_p: file_conn_p_t);        {pointer to I/O connection to close}
  val_param; forward;
{
********************************************************************************
*
*   Subroutine FILE_OPEN_CALL_WTXT (NAME, CONN, STAT)
*
*   Open a callback object for text write.  The object will be named NAME.  This
*   name is only meaningful to the application.
*
*   No callback routines will be installed.  When no callback routine is
*   installed for a particular I/O operation, that operation is ignored, but no
*   error is generated.
}
procedure file_open_call_wtxt (        {open callback object for writing text lines}
  in      name: univ string_var_arg_t; {name to set callback objec to}
  out     conn: file_conn_t;           {handle to newly created I/O connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  mem_p: util_mem_context_p_t;         {pointer to our private memory context}
  dat_p: dat_p_t;                      {pointer to our private data}

begin
  sys_error_none (stat);               {init to no error encountered}

  file_conn_init (conn);               {initialize the I/O connection descriptor}
  conn.rw_mode := [file_rw_write_k];   {set the fixed fields}
  conn.obty := file_obty_call_k;
  conn.fmt := file_fmt_text_k;
  string_copy (name, conn.fnam);
  string_copy (name, conn.gnam);
  string_copy (name, conn.tnam);
  conn.ext_num := 0;
  conn.lnum := 0;
  conn.close_p := addr(file_call_close);

  util_mem_context_get (               {create private mem context}
    util_top_mem_context, mem_p);
  util_mem_grab (                      {allocate private data for this connection}
    sizeof(dat_p^), mem_p^, false, dat_p);

  dat_p^.mem_p := mem_p;               {fill in our private data}
  dat_p^.text_write_p := nil;
  dat_p^.text_close_p := nil;
  conn.data_p := dat_p;                {save pointer to our private data}
  end;
{
********************************************************************************
*
*   Local subroutine FILE_CALL_CLOSE (CONN_P)
*
*   Close the I/O connection pointed to by CONN_P.
}
procedure file_call_close (            {close I/O object of CALL type}
  in    conn_p: file_conn_p_t);        {pointer to I/O connection to close}
  val_param;

var
  dat_p: dat_p_t;                      {pointer to our private data}
  mem_p: util_mem_context_p_t;         {pointer to mem context for this conn}

begin
  if conn_p = nil then return;         {no connection, nothing to do ?}
  if conn_p^.obty <> file_obty_call_k  {not one of our objects (shouldn't happen) ?}
    then return;

  dat_p := conn_p^.data_p;             {get pointer to our private data}
  case conn_p^.fmt of                  {what is the data format ?}
file_fmt_text_k: begin                 {data is lines of text}
      if dat_p^.text_close_p <> nil then begin {app installed close routine ?}
        dat_p^.text_close_p^ (conn_p^); {call the app callback routine}
        end;
      end;
    end;                               {end of data format cases}

  mem_p := dat_p^.mem_p;               {make local copy of mem context pointer}
  util_mem_context_del (mem_p);        {delete all dynamic memory for this connection}
  end;
{
********************************************************************************
*
*   Subroutine FILE_CALL_SET_WTXT (CONN, CALL_P, STAT)
*
*   Set the callback routine for text write.  The routine pointed to by CALL_P
*   will be called whenever a line of text is written to this I/O connection.
}
procedure file_call_set_wtxt (         {set text write callback routine}
  in out  conn: file_conn_t;           {I/O connection to set callback for}
  in      call_p: file_call_wtxt_p_t;  {pointer to routine to call on text write}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  dat_p: dat_p_t;                      {pointer to our private data}

begin
  sys_error_none (stat);               {init to no error encountered}

  if conn.obty <> file_obty_call_k then begin {not one of our objects ?}
    sys_stat_set (file_subsys_k, file_stat_not_callobj_k, stat);
    sys_stat_parm_vstr (conn.tnam, stat);
    sys_stat_parm_int (ord(conn.obty), stat);
    return;
    end;
  if conn.fmt <> file_fmt_text_k then begin {data format not lines of text ?}
    sys_stat_set (file_subsys_k, file_stat_not_fmttext_k, stat);
    sys_stat_parm_vstr (conn.tnam, stat);
    return;
    end;

  dat_p := conn.data_p;                {get pointer to our private data}
  dat_p^.text_write_p := call_p;       {set text write callback routine}
  end;
{
********************************************************************************
*
*   Subroutine FILE_CALL_SET_CLOSE (CONN, CALL_P, STAT)
*
*   Set the callback routine for the I/O connection being closed.  The routine
*   pointed to by CALL_P will be called when the I/O connection is being before
*   any actual closing operations are performed.  The connection will be closed
*   after the routine returns.
}
procedure file_call_set_close (        {set close object callback routine}
  in out  conn: file_conn_t;           {I/O connection to set callback for}
  in      call_p: file_call_close_p_t; {pointer to routine to call on closing}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  dat_p: dat_p_t;                      {pointer to our private data}

begin
  sys_error_none (stat);               {init to no error encountered}

  if conn.obty <> file_obty_call_k then begin {not one of our objects ?}
    sys_stat_set (file_subsys_k, file_stat_not_callobj_k, stat);
    sys_stat_parm_vstr (conn.tnam, stat);
    sys_stat_parm_int (ord(conn.obty), stat);
    return;
    end;
  if conn.fmt <> file_fmt_text_k then begin {data format not lines of text ?}
    sys_stat_set (file_subsys_k, file_stat_not_fmttext_k, stat);
    sys_stat_parm_vstr (conn.tnam, stat);
    return;
    end;

  dat_p := conn.data_p;                {get pointer to our private data}
  dat_p^.text_close_p := call_p;       {set text write callback routine}
  end;
{
********************************************************************************
*
*   Subroutine FILE_CALL_WTXT (BUF, CONN, STAT)
*
*   Write the string in BUF as a text line.  The object type is guaranteed to be
*   CALL, and STAT has already been initialized to no error.
}
procedure file_call_wtxt (             {write text line to callback object}
  in      buf: univ string_var_arg_t;  {string to write as text line}
  in out  conn: file_conn_t;           {handle to this I/O connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  dat_p: dat_p_t;                      {pointer to our private data}

begin
  if conn.fmt <> file_fmt_text_k then begin {data format not lines of text ?}
    sys_stat_set (file_subsys_k, file_stat_not_fmttext_k, stat);
    sys_stat_parm_vstr (conn.tnam, stat);
    return;
    end;

  dat_p := conn.data_p;                {get pointer to our private data}

  if dat_p^.text_write_p <> nil then begin {callback routine exists ?}
    dat_p^.text_write_p^ (             {call the callback routine}
      buf,                             {string to write as a text line}
      conn,                            {data for this I/O connection}
      stat);                           {completion status}
    end;
  end;
