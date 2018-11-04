{   Subroutine FILE_READ_TEXT (CONN, BUF, STAT)
*
*   Read the next line of text from the file indicated by CONN.  The line of
*   text will be returned in BUF, truncated to the maximum length of BUF.  The
*   truncated characters, if any, will be lost.  STAT is returned as the
*   error completion code.
*
*   This version is the main line of decent, and works on any system where
*   text files are a stream of characters separated by NEW LINE characters.
*   The new line character value is defined by the constant END_OF_LINE.
*   This is usually declared in SYS_SYS2.INS.PAS.
}
module file_read_text;
define file_read_text;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_read_text (             {read one line of text from file}
  in out  conn: file_conn_t;           {handle to this file connection}
  in out  buf: univ string_var_arg_t;  {returned line of text}
  out     stat: sys_err_t);            {completion status code}

var
  n: sys_int_machine_t;                {number of characters to transfer this chunk}
  data_p: file_textr_data_p_t;         {pointer to our private data}
  c: char;                             {scratch character}
  i: sys_int_machine_t;                {scratch integer and loop counter}

label
  chunk_read, skip_to_eol, end_of_file, leave;
{
***************************************************
*
*   Local subroutine READ_BUFFER
*
*   Re-fill the buffer with the next data from the file.
}
procedure read_buffer;

var
  n: sys_int_adr_t;                    {amount of data actually read}

begin
  with data_p^: d do begin             {D is abbreviation for our private data block}
  d.ofs := d.ofs + (d.nbuf * sizeof(char)); {update file offset for start of buffer}

  file_read_bin (                      {read next buffer full from binary file}
    d.conn,                            {connextion handle to binary file}
    sizeof(d.buf),                     {amount of data to read}
    d.buf,                             {where to put the data}
    n,                                 {amount of data actually read}
    stat);                             {completion status code}
  d.nbuf := n div sizeof(char);        {number of characters now in buffer}
  d.nxchar := 0;                       {init index to next character to read}

  discard (file_eof_partial(stat));    {ignore EOF until at start of new line}
  d.eof := file_eof(stat);             {TRUE if exhausted input file}
  end;                                 {done with D abbreviation}
  end;
{
***************************************************
*
*   Start of main routine.
}
begin
  sys_error_none (stat);               {init to no error}
  data_p := conn.data_p;               {get pointer to our private data}
  buf.len := 0;                        {init to no characters returned}
  with data_p^: d do begin             {D is abbreviation for our private data block}

chunk_read:                            {back here to read next chunk of characters}
  n := min(                            {max characters we can copy without checking}
    buf.max - buf.len,                 {room left in returned string}
    d.nbuf - d.nxchar);                {number of unread chars left in buffer}

  for i := 1 to n do begin             {once for each character to transfer}
    c := d.buf[d.nxchar];              {fetch this character from buffer}
    d.nxchar := d.nxchar + 1;          {update index to next character in buffer}
    if ord(c) = end_of_line then goto leave; {hit end of this text line ?}
    buf.len := buf.len + 1;            {count one more character in returned line}
    buf.str[buf.len] := c;             {stuff this character into returned line}
    end;                               {back to transfer next character from buffer}
{
*   Done processing the chunk of characters.  Either the returned line is
*   full, or the input buffer has been exhausted.
}
  if buf.len >= buf.max                {the returned text string is full ?}
    then goto skip_to_eol;             {skip to the end of the input line}
  if d.eof then goto end_of_file;      {end of file acts like an end of line}
  read_buffer;                         {re-fill buffer from input file}
  if sys_error(stat) then return;      {error reading new buffer ?}
  goto chunk_read;                     {continue reading this text line}
{
*   The returned text string has been filled before the end of line was
*   reached.  Now just skip ahead until the end of line.
}
skip_to_eol:
  for i := d.nxchar to d.nbuf-1 do begin {scan remaining characters in buffer}
    c := d.buf[d.nxchar];              {fetch this character from buffer}
    d.nxchar := d.nxchar + 1;          {update index to next character in buffer}
    if ord(c) = end_of_line then goto leave; {found end of line ?}
    end;
  if d.eof then goto end_of_file;      {end of file acts like an end of line}
  read_buffer;                         {re-fill buffer from input file}
  if sys_error(stat) then return;      {error reading new buffer ?}
  goto skip_to_eol;                    {continue looking for end of line}

end_of_file:                           {jump here when encountered end of file}
  sys_stat_set (file_subsys_k, file_stat_eof_k, stat);
  if buf.len <= 0 then return;

leave:                                 {common exit point when no errors occurred}
  if conn.lnum >= 0 then begin         {current line numbers are known ?}
    conn.lnum := conn.lnum + 1;        {increment the line number}
    end;
  end;                                 {done with D abbreviation}

  if (buf.len > 0) and (buf.str[buf.len] = chr(13)) then begin {ends in CR ?}
    buf.len := buf.len - 1;            {truncate trailing CR}
    end;
  end;
