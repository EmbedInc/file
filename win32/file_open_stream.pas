{   Module of routines that connect system streams to Cognivision file
*   connection handles.
*
*   This is the main line of decent.  It just copies the passed stream ID
*   into the SYS field of the connection handle.
}
module file_open_streams;
define file_open_stream_bin;
define file_open_stream_text;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';
{
******************************************************
*
*   Subroutine FILE_OPEN_STREAM_BIN (STREAM_ID, RW_MODE, CONN, STAT)
*
*   Create Cognivision file connection handle CONN so that it does I/O
*   to/from system stream STREAM_ID.  RW_MODE specifies the required
*   read/write access to the stream thru CONN.
*
*   The new connection will support binary read/write thru routines
*   FILE_WRITE_BIN and FILE_READ_BIN.
}
procedure file_open_stream_bin (       {create binary connection to system stream}
  in      stream_id: sys_sys_iounit_t; {system stream ID to connect to}
  in      rw_mode: file_rw_t;          {intended read/write access}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  stdstream: win_dword_t;              {interal system ID for this stream}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  sys_error_none (stat);

  case stream_id of
sys_sys_iounit_stdin_k: stdstream := stdstream_in_k;
sys_sys_iounit_stdout_k: stdstream := stdstream_out_k;
sys_sys_iounit_errout_k: stdstream := stdstream_err_k;
otherwise
    sys_message_bomb ('file', 'stdstream_id_bad', nil, 0);
    end;
  conn.sys := GetStdHandle (stdstream); {get internal handle to selected stream}
  if conn.sys = handle_invalid_k then begin
    sys_msg_parm_int (msg_parm[1], stream_id);
    sys_sys_error_bomb ('file', 'open_stream', msg_parm, 1);
    end;

  conn.rw_mode := rw_mode;             {fill in remainder of connection handle}
  conn.obty := file_obty_stream_k;
  conn.fmt := file_fmt_bin_k;
  conn.fnam.max := sizeof(conn.fnam.str);
  conn.fnam.len := 0;
  conn.gnam.max := sizeof(conn.gnam.str);
  conn.gnam.len := 0;
  conn.tnam.max := sizeof(conn.tnam.str);
  conn.tnam.len := 0;
  conn.ext_num := 0;
  conn.lnum := file_lnum_nil_k;
  conn.data_p := nil;
  conn.close_p := addr(file_close_stream);
  end;
{
******************************************************
*
*   Subroutine FILE_OPEN_STREAM_TEXT (STREAM_ID, RW_MODE, CONN, STAT)
*
*   Create Cognivision file connection handle CONN so that it does I/O
*   to/from system stream STREAM_ID.  RW_MODE specifies the required
*   read/write access to the stream thru CONN.
*
*   The new connection will support text read/write thru routines
*   FILE_WRITE_TEXT and FILE_READ_TEXT.
}
procedure file_open_stream_text (      {create text connection to system stream}
  in      stream_id: sys_sys_iounit_t; {system stream ID to connect to}
  in      rw_mode: file_rw_t;          {intended read/write access}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  data_p: file_textr_data_p_t;         {pointer to our private data block}

begin
  sys_error_none (stat);

  sys_mem_alloc (sizeof(data_p^), data_p); {allocate memory for private data block}
  sys_mem_error (data_p, '', '', nil, 0);

  file_open_stream_bin (stream_id, rw_mode, data_p^.conn, stat); {open as binary}
  if sys_error(stat) then begin        {error opening file ?}
    sys_mem_dealloc (data_p);          {deallocate private data block}
    return;                            {return with error}
    end;

  conn.rw_mode := rw_mode;
  conn.obty := file_obty_stream_k;
  conn.fmt := file_fmt_text_k;
  conn.fnam.max := sizeof(conn.fnam.str);
  conn.fnam.len := 0;
  conn.gnam.max := sizeof(conn.gnam.str);
  conn.gnam.len := 0;
  conn.tnam.max := sizeof(conn.tnam.str);
  conn.tnam.len := 0;
  conn.ext_num := 0;
  conn.lnum := 0;
  conn.data_p := data_p;
  conn.close_p := addr(file_close_textr);
  conn.sys := data_p^.conn.sys;
{
*   Fill in the rest of our private data block.
}
  data_p^.nxchar := 0;
  data_p^.nbuf := 0;
  data_p^.ofs := 0;
  data_p^.eof := false;
  end;
