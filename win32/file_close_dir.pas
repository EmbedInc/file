{   Subroutine FILE_CLOSE_DIR (CONN_P)
*
*   Close connection for reading directory entries.  CONN_P points to the
*   connection handle data structure.
}
module file_close_dir;
define file_close_dir;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_close_dir (             {close conn opened with FILE_OPEN_READ_DIR}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param;

var
  data_p: file_rdir_data_p_t;          {pointer to our private data block}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

begin
  data_p := conn_p^.data_p;            {get pointer to our private data block}
  if not data_p^.eof then begin        {system connection not already closed ?}
    ok := FindClose (conn_p^.sys);     {try to close system connection to dir}
    if ok = win_bool_false_k then begin {error ?}
      sys_sys_error_bomb ('file', 'close_dir', nil, 0);
      end;
    end;
  sys_mem_dealloc (conn_p^.data_p);    {deallocate our private memory block}
  end;
