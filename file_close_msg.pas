{   Subroutine FILE_CLOSE_MSG (CONN_P)
*
*   Close a connection opened with FILE_OPEN_READ_MSG.  CONN_P points to the
*   connection handle.
}
module file_CLOSE_MSG;
define file_close_msg;
%include 'file2.ins.pas';

procedure file_close_msg (             {close connection to message in .msg file}
  in      conn_p: file_conn_p_t);
  val_param;

var
  data_p: file_msg_data_p_t;           {pointer to our private data block}

begin
  data_p := conn_p^.data_p;            {get pointer to our private data block}
  file_close (data_p^.conn);           {close connection to environment files}
  sys_mem_dealloc (conn_p^.data_p);    {deallocate our private data block}
  conn_p^.close_p := nil;              {no longer any need to call here}
  end;
