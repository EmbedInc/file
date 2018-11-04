{   Subroutine FILE_MAP_TRUNCATE (CONN, LEN)
*
*   Truncate a mapped file to the specified length.  This is the only way
*   to make a mapped file shorter.  The file must be open for write operations.
}
module file_MAP_TRUNCATE;
define file_map_truncate;
%include 'file2.ins.pas';

procedure file_map_truncate (          {truncate mapped file to specified length}
  in out  conn: file_conn_t;           {handle to file, from FILE_OPEN_MAP}
  in      len: sys_int_adr_t);         {desired length of file}
  val_param;

var
  data_p: file_map_data_p_t;           {pointer to our private data block}

begin
  data_p := conn.data_p;               {get pointer to our private data block}
  data_p^.len_map := len;
  end;
