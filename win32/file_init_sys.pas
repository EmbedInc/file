{   Routines to do initialze the system-dependent part of various data
*   structures internal to the FILE library.
}
module file_init_sys;
define file_conn_init_sys;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';
{
********************************************************************************
*
*   Subrouinte FILE_CONN_INIT_SYS (CONN)
*
*   Initialize the system-dependent part of the I/O connection descriptor CONN.
*   The system-independent parts have already been initialized.
}
procedure file_conn_init_sys (         {init system-dependent part of I/O connection}
  in out  conn: file_conn_t);          {initialized to default or benign values}
  val_param;

begin
  conn.sys := handle_none_k;
  end;
