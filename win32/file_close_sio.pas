{   Subroutine FILE_CLOSE_SIO (CONN_P)
*
*   Close this connection to a serial line.  The connection must have been
*   opened with FILE_OPEN_SIO.  This routine will wait until all characters
*   in the buffer have been sent.
}
module file_close_sio;
define file_close_sio;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_close_sio (             {close connection to serial I/O line}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param;

begin
  discard( FlushFileBuffers (conn_p^.sys) ); {wait for all buffered chars to be sent}
  discard( CloseHandle (conn_p^.sys) ); {close connection to SIO line}
  end;
