{   Subroutine FILE_WRITE_SIO_REC (BUF, CONN, STAT)
*
*   Write a record to the serial line indicated by the connection handle CONN.
*   BUF is the source of the data characters.  If enabled, the current end of
*   record string will be written after all the characters in BUF.  The output
*   end of record string is turned ON, and set to carriage return when the
*   serial line is opened.
}
module file_write_sio_rec;
define file_write_sio_rec;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_write_sio_rec (         {write record to serial line}
  in      buf: univ string_var_arg_t;  {record to send, not including end of record}
  in      conn: file_conn_t;           {handle to serial line connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  data_p: file_sio_data_p_t;           {pointer to our private data block}
  tlen: win_dword_t;                   {amount of data actually written}
  ok: win_bool_t;                      {WIN_BOOL_FALSE_K on system call failure}
  ovl: overlap_t;                      {state used during overlapped I/O}

label
  leave;

begin
  sys_error_none(stat);                {init to no error}
  data_p := conn.data_p;               {set pointer to out private data block}

  ovl.offset := 0;
  ovl.offset_high := 0;
  ovl.event_h := CreateEventA (        {create event for overalpped I/O}
    nil,                               {no security attributes supplied}
    win_bool_true_k,                   {no automatic event reset on successful wait}
    win_bool_false_k,                  {init event to not triggered}
    nil);                              {no name supplied}
  if ovl.event_h = handle_none_k then begin {error creating event ?}
    stat.sys := GetLastError;
    return;
    end;
{
*   Write the caller's string.
}
  if buf.len > 0 then begin            {caller supplied anything to write ?}
    ok := WriteFile (                  {write caller's string}
      conn.sys,                        {I/O connection handle}
      buf.str,                         {output buffer}
      buf.len,                         {amount of data to write}
      tlen,                            {returned amount of data actually written}
      addr(ovl));                      {pointer to overlapped I/O state}
    if ok = win_bool_false_k then begin {system call reporting error ?}
      if GetLastError <> err_io_pending_k then begin {hard error ?}
        stat.sys := GetLastError;
        goto leave;
        end;
      ok := GetOverlappedResult (      {wait for I/O to complete}
        conn.sys,                      {handle that I/O is pending on}
        ovl,                           {overlapped I/O state}
        tlen,                          {number of bytes written}
        win_bool_true_k);              {wait for I/O to complete}
      if ok = win_bool_false_k then begin
        stat.sys := GetLastError;
        goto leave;
        end;
      end;
    end;
{
*   Write the EOR string, if enabled.
}
  if data_p^.eor_out_on then begin     {EOR output enabled ?}
    ok := WriteFile (                  {write EOR string}
      conn.sys,                        {I/O connection handle}
      data_p^.eor_out.str,             {output buffer}
      data_p^.eor_out.len,             {output buffer length}
      tlen,                            {returned amount of data actually written}
      addr(ovl));                      {pointer to overlapped I/O state}
    if ok = win_bool_false_k then begin {system call reporting error ?}
      if GetLastError <> err_io_pending_k then begin {hard error ?}
        stat.sys := GetLastError;
        goto leave;
        end;
      ok := GetOverlappedResult (      {wait for I/O to complete}
        conn.sys,                      {handle that I/O is pending on}
        ovl,                           {overlapped I/O state}
        tlen,                          {number of bytes written}
        win_bool_true_k);              {wait for I/O to complete}
      if ok = win_bool_false_k then begin
        stat.sys := GetLastError;
        goto leave;
        end;
      end;
    end;

leave:                                 {common exit after event created}
  discard( CloseHandle(ovl.event_h) ); {deallocate I/O completion event}
  end;
