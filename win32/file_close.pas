{   Subroutine FILE_CLOSE (CONN)
*
*   Close the file connection indicated by CONN.  CONN will be invalid.
*
}
module file_close;
define file_close;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_close (                 {close a file connection}
  in out  conn: file_conn_t);          {handle to file connection}

var
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

begin
  if conn.close_p = nil
    then begin                         {no explicit close procedure indicated}
      if                               {truncate file before closing ?}
          (file_rw_write_k in conn.rw_mode) and {file open for write ?}
          (conn.obty = file_obty_file_k) {ordinary file ?}
          then begin
        ok := SetEndOfFile (conn.sys); {try to set end of file at current position}
        if ok = win_bool_false_k then begin {error on truncate at curr pos ?}
          sys_sys_error_bomb ('file', 'truncate', nil, 0);
          end;
        end;
      if conn.obty <> file_obty_stream_k then begin {not connection to sys stream ?}
        ok := CloseHandle (conn.sys);
        if ok = win_bool_false_k then begin
          sys_sys_error_bomb ('file', 'close', nil, 0);
          end;
        end;
      end
    else begin
      conn.close_p^ (addr(conn));      {call specific close routine}
      conn.close_p := nil;
      end
    ;

  if conn.data_p <> nil then begin     {need to deallocate private data block ?}
    sys_mem_dealloc (conn.data_p);
    end;
  end;
