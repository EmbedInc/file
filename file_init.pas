{   Routines to initialize various data structures internal to the FILE library.
}
module file_init;
define file_conn_init;
%include 'file2.ins.pas';
{
********************************************************************************
*
*   Subrouinte FILE_CONN_INIT (CONN)
*
*   Initialize the I/O connection descriptor CONN.  All the fields will be
*   initialized to default or benign values to the extent possible.  The
*   previous state of CONN is irrelevant.
*
*   Routines that create a I/O connection descriptor should first call this
*   routine, then fill in and set any fields they know and care about.
}
procedure file_conn_init (             {initialize I/O connection descriptor}
  out     conn: file_conn_t);          {initialized to default or benign values}
  val_param;

begin
  conn.rw_mode := [];                  {neither read nor write}
  conn.obty := file_obty_file_k;
  conn.fmt := file_fmt_bin_k;
  conn.fnam.max := size_char(conn.fnam.str);
  conn.fnam.len := 0;
  conn.gnam.max := size_char(conn.gnam.str);
  conn.gnam.len := 0;
  conn.tnam.max := size_char(conn.tnam.str);
  conn.tnam.len := 0;
  conn.ext_num := 0;
  conn.lnum := file_lnum_nil_k;
  conn.data_p := nil;
  conn.close_p := nil;

  file_conn_init_sys (conn);           {init the system-dependent part}
  end;
