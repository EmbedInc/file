{   Subroutine FILE_CLOSE_STREAM (CONN_P)
*
*   Close Cognivision file connection that is open to a system stream.
*
*   This is the main line of decent, which assumes nothing needs to be
*   done.  The stream existed before the FILE_OPEN_STREAM call, and
*   should continue to exist after the FILE_CLOSE call.
}
module file_close_stream;
define file_close_stream;
%include 'file2.ins.pas';

procedure file_close_stream (          {close connection to system stream}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param;

begin
  end;
