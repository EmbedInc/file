{   All the subroutines here are local to FILE_CLOSE_MAP.
*
*   This version is for the Microsoft Win32 API.
*
**********************************************************
*
*   Local subroutine CLOSE_MAP
*
*   Close direct mapped access, if any.
}
procedure close_map;

var
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

begin
  if data_p^.map_p = nil then return;  {file was never mapped ?}

  ok := UnmapViewOfFile (data_p^.map_p); {unmap the mapped section}
  if ok = win_bool_false_k then begin
    sys_sys_error_bomb ('file', 'unmap', nil, 0);
    end;

  ok := CloseHandle (conn_p^.sys);     {close file mapping object}
  if ok = win_bool_false_k then begin
    sys_sys_error_bomb ('file', 'close_map_object', nil, 0);
    end;
  end;
{
**********************************************************
*
*   Local subroutine SETUP_WRITE
*
*   Setup for writing new data back to sequential file.  The file must be
*   positioned where the first write will go.  The following variables must
*   be correctly set by this routine:
*
*     WRITE_LEFT  -  Total amount of data to write to the file
*
*     WRITE_POS_OK  -  TRUE if the file will be positioned correctly for
*       closing after the last write.
*
*     NODE_P  -  Pointer to leaf node for first block to write from.
*
*   These three variables are already set correctly if the file was never
*   directly mapped.  Only the file position needs to be changed in that case.
}
procedure setup_write;

var
  stat: sys_err_t;

begin
  if data_p^.map_p = nil then begin    {file was never mapped ?}
    file_pos_start (data_p^.conn, stat); {re-position to start of sequential file}
    sys_error_abort (stat, 'file', 'pos_bof', nil, 0);
    return;
    end;

  write_left :=                        {original file already "written"}
    max(0, write_left - data_p^.len_file);
  if write_left > 0
    then begin                         {data will actually be written}
      file_pos_end (data_p^.conn, stat); {re-position to end of file}
      sys_error_abort (stat, 'file', 'pos_eof', nil, 0);
      node_p := node_p^.next_p;        {start at first non-mapped node}
      end
    else begin                         {not data will be written to sequential file}
      write_pos_ok := false;           {force explicit file re-position}
      end
    ;
  end;
