{   Function FILE_MAP_LENGTH(CONN)
*
*   Return the current length of a mapped file in machine address units.
}
module file_MAP_LENGTH;
define file_map_length;
%include 'file2.ins.pas';

function file_map_length (             {return length of a file open for mapping}
  in      conn: file_conn_t)           {handle to file, from FILE_OPEN_MAP}
  :sys_int_adr_t;                      {current length of file in machine adr units}
  val_param;

var
  data_p: file_map_data_p_t;           {pointer to private data for this connection}

begin
  data_p := conn.data_p;               {get pointer to our private data}
  file_map_length := data_p^.len_map;  {return current mapped file length}
  end;
