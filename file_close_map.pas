{   Subroutine FILE_CLOSE_MAP (CONN_P)
*
*   Close a file opened with FILE_OPEN_MAP.
}
module file_CLOSE_MAP;
define file_close_map;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_close_map (             {close connection to mapped file}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param;

var
  data_p: file_map_data_p_t;           {pointer to our private data block}
  write_left: sys_int_adr_t;           {amount left to write to the file}
  write_now: sys_int_adr_t;            {amount of data to write with this call}
  node_p: file_map_ofs_node_p_t;       {points to node for current memory block}
  buf_p: ^char;                        {pointer to start of data to write}
  mem_p: util_mem_context_p_t;         {points to mem context for all our dyn mem}
  write_pos_ok: boolean;               {TRUE if file pos OK at end of write}
  stat: sys_err_t;

label
  file_pos_done;
{
**********************************************************
*
*   Local subroutine CLOSE_MAP
*
*   Close direct mapped access, if any.
*
*   This subroutine is implemented in FILE_CLOSE_MAP.INS.PAS, below.
*
**********************************************************
*
*   Local subroutine SETUP_WRITE.
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
*
*   This subroutine is implemented in FILE_CLOSE_MAP.INS.PAS, below.
}
%include 'file_close_map.ins.pas';
{
**********************************************************
*
*   Start of main routine.
}
begin
  data_p := conn_p^.data_p;            {get pointer to our private data}

  close_map;                           {close mapped access, if any}
{
*   Write the in-memory copy of the data back to the file if any of the
*   in-memory data might have been altered.
}
  if data_p^.written then begin        {file contents may have gotten changed ?}
    write_left := data_p^.len_map;     {init amount of data to write to file}
    if data_p^.len_read < data_p^.len_file then begin {never read the whole file ?}
      write_left := data_p^.len_read;
      end;
    write_pos_ok := write_left = data_p^.len_map; {TRUE if OK position after write}
    node_p := data_p^.first_p;         {init pointer to node for first mem block}
    setup_write;                       {do final setup for writing to file}
    while write_left > 0 do begin      {loop until all data written}
      write_now := min(write_left, node_p^.len); {amount of data to write this block}
      buf_p := univ_ptr(node_p^.adr);  {get pointer to start of this block data}
      file_write_bin (                 {write data from this block to the file}
        buf_p^,                        {source buffer for data}
        data_p^.conn,                  {connection handle to sequential file}
        write_now,                     {amount of data to write}
        stat);
      sys_error_abort (stat, 'file', 'write_output_bin', nil, 0);
      write_left := write_left - write_now; {update amount left to write}
      node_p := node_p^.next_p;        {point to node for next memory block}
      end;                             {back to write next chunk of the file}
    if write_pos_ok then goto file_pos_done; {already at right file position ?}
    end;
{
*   Make sure we are positioned at the end of the mapped file if it is open
*   for write.  This makes sure the file is truncated properly when closed.
}
  if file_rw_write_k in data_p^.conn.rw_mode then begin {seq file open for write ?}
    file_pos_ofs (data_p^.conn, data_p^.len_map, stat);
    sys_error_abort (stat, '', '', nil, 0);
    end;
file_pos_done:                         {jump here if file position all set}

  file_close (data_p^.conn);           {close the sequential file}
  mem_p := data_p^.mem_p;              {save pointer to mem handle}
  util_mem_context_del (mem_p);        {deallocate all our dynamiclly allocated mem}
  conn_p^.data_p := nil;               {indicate nothing left to deallocate}
  end;
