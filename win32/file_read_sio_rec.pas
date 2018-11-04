{   Subroutine FILE_READ_SIO_REC (CONN, BUF, STAT)
*
*   Read the next record from the serial line.  CONN is the connection handle
*   returned by FILE_OPEN_SIO.  The bytes from the serial line will be placed
*   in BUF, up to, but not including the end of record string.  If end of
*   record recognition is disabled, then this call returns the raw incoming
*   characters.  It will fill BUF when that many characters are available,
*   but otherwise waits for at least one character to be available.
}
module file_read_sio_rec;
define file_read_sio_rec;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_read_sio_rec (          {read next record from serial line}
  in      conn: file_conn_t;           {handle to serial line connection}
  in out  buf: univ string_var_arg_t;  {characters not including end of record}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  data_p: file_sio_data_p_t;           {pointer to our private data block}
  tlen: win_dword_t;                   {data size actually transferred}
  c: char;                             {single input character}
  eori: sys_int_machine_t;             {curr index into EOR string}
  i: sys_int_machine_t;                {scratch character index}
  ok: win_bool_t;                      {WIN_BOOL_FALSE_K on system call failure}
  ovl: overlap_t;                      {state used during overlapped I/O}

label
  retest_eor, leave;

begin
  sys_error_none (stat);               {init to no error}
  data_p := conn.data_p;               {get pointer to our private connection state}

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
*   Handle case of EOR recognition disabled.
}
  if not data_p^.eor_in_on then begin  {EOR interpretation disabled ?}
    if buf.max <= 0 then goto leave;   {no place to put incoming characters ?}
    ok := ReadFile (                   {read characters from device}
      conn.sys,                        {handle to I/O connection}
      buf.str,                         {input buffer}
      buf.max,                         {max amount of data to read}
      tlen,                            {returned amount of data actually transferred}
      addr(ovl));                      {pointer to overlapped I/O state}
    if ok = win_bool_false_k then begin {system call reporting error ?}
      if GetLastError <> err_io_pending_k then begin {hard error ?}
        stat.sys := GetLastError;
        goto leave;
        end;
      ok := GetOverlappedResult (      {wait for I/O to complete}
        conn.sys,                      {handle that I/O is pending on}
        ovl,                           {overlapped I/O state}
        tlen,                          {number of bytes transferred}
        win_bool_true_k);              {wait for I/O to complete}
      if ok = win_bool_false_k then begin
        stat.sys := GetLastError;
        goto leave;
        end;
      end;
    buf.len := tlen;                   {indicate how many characters actually read}
    goto leave;
    end;
{
*   End of record recognition is enabled.
}
  eori := 0;                           {init to no part of EOR string detected}
  buf.len := 0;                        {init size of string passed back}

  repeat                               {loop until read whole EOR string}
    ok := ReadFile (                   {read next input character}
      conn.sys,                        {handle to I/O connection}
      c,                               {input buffer}
      1,                               {amount of data to read}
      tlen,                            {amount of data actually read}
      addr(ovl));                      {pointer to overlapped I/O state}
    if ok = win_bool_false_k then begin {system call reporting error ?}
      if GetLastError <> err_io_pending_k then begin {hard error ?}
        stat.sys := GetLastError;
        goto leave;
        end;
      ok := GetOverlappedResult (      {wait for I/O to complete}
        conn.sys,                      {handle that I/O is pending on}
        ovl,                           {overlapped I/O state}
        tlen,                          {number of bytes transferred}
        win_bool_true_k);              {wait for I/O to complete}
      if ok = win_bool_false_k then begin
        stat.sys := GetLastError;
        goto leave;
        end;
      end;
retest_eor:                            {back to try again at start of EOR sequence}
    if c = data_p^.eor_in.str[eori + 1]
      then begin                       {this is the next EOR char in sequence}
        eori := eori + 1;              {one char further into EOR sequence}
        end
      else begin                       {this char is not part of eor sequence}
        if eori <> 0 then begin        {we are part way thru aborted EOR sequence ?}
          for i := 1 to eori do begin  {copy EOR sequence so far to output string}
            string_append1 (buf, data_p^.eor_in.str[i]); {copy this EOR character}
            end;                       {back to copy next EOR character}
          eori := 0;                   {reset to not currently in EOR sequence}
          goto retest_eor;             {back to check for match with start of EOR}
          end;
        string_append1 (buf, c);       {stuff this char at end of output string}
        end
      ;
    until eori >= data_p^.eor_in.len;  {back until recognized whole EOR sequence}

leave:                                 {common exit one event created}
  discard( CloseHandle(ovl.event_h) ); {deallocate I/O completion event}
  end;
