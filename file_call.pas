{   Routines that implement the callback object type.  This is a virtual object
*   that causes no actual I/O.  Application routines are called for each I/O
*   operation.
}
module file_call;
define file_call_wtxt;
%include 'file2.ins.pas';
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

begin
  end;
