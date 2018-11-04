{   Module of routines that implement the FILE_POS_xxx calls for
*   text files that are open for read.
}
module file_pos_text;
define file_pos_end_textr;
define file_pos_get_textr;
define file_pos_set_textr;
define file_pos_start_textr;
%include 'file2.ins.pas';
{
****************************************************************
*
*   Subroutine FILE_POS_START_TEXTR (CONN, STAT)
}
procedure file_pos_start_textr (       {position to start of text read file}
  in out  conn: file_conn_t;           {handle to this file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  data_p: file_textr_data_p_t;         {pointer to our private data}

begin
  sys_error_none (stat);               {init to no errors}
  data_p := conn.data_p;               {get pointer to our private data block}
  with data_p^: d do begin             {D is abbreviation for our private data block}

  file_pos_start (d.conn, stat);       {position actual file to start}

  d.nxchar := 0;                       {reset values in private data block}
  d.nbuf := 0;
  d.ofs := 0;
  d.eof := false;

  conn.lnum := 0;                      {reset current line number}
  end;                                 {done with D abbreviation}
  end;
{
****************************************************************
*
*   Subroutine FILE_POS_END_TEXTR (CONN, STAT)
}
procedure file_pos_end_textr (         {position to end of text read file}
  in out  conn: file_conn_t;           {handle to this file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  data_p: file_textr_data_p_t;         {pointer to our private data}

begin
  sys_error_none (stat);               {init to no errors}
  data_p := conn.data_p;               {get pointer to our private data block}
  with data_p^: d do begin             {D is abbreviation for our private data block}

  d.nxchar := 0;                       {set values to always return end of file}
  d.nbuf := 0;
  d.ofs := 0;
  d.eof := true;

  conn.lnum := file_lnum_unk_k;        {current line number is now unknown}
  end;                                 {done with D abbreviation}
  end;
{
****************************************************************
*
*   Subroutine FILE_POS_GET_TEXTR (CONN, POS)
}
procedure file_pos_get_textr (         {get curr position of text read file}
  in      conn: file_conn_t;           {handle to this file connection}
  out     pos: file_pos_t);            {handle to current file position}
  val_param;

var
  data_p: file_textr_data_p_t;         {pointer to our private data}

begin
  data_p := conn.data_p;               {get pointer to our private data block}
  with data_p^: d do begin             {D is abbreviation for our private data block}

  pos.conn_p := addr(conn);            {save pointer to connection handle}
  pos.sys := d.ofs + d.nxchar;         {save file position as offset from start}

  end;                                 {done with D abbreviation}
  end;
{
****************************************************************
*
*   Subroutine FILE_POS_SET_TEXTR (POS, STAT)
}
procedure file_pos_set_textr (         {set curr position of text read file}
  in out  pos: file_pos_t;             {position handle obtained with FILE_POS_GET}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  data_p: file_textr_data_p_t;         {pointer to our private data}

begin
  sys_error_none (stat);               {init to no errors}
  data_p := pos.conn_p^.data_p;        {get pointer to our private data block}
  with data_p^: d do begin             {D is abbreviation for our private data block}

  if
      (pos.sys >= d.ofs) and
      (pos.sys <= (d.ofs + d.nbuf))
    then begin                         {the new position is within the curr buffer}
      d.nxchar := pos.sys - d.ofs;     {adjust position within this buffer}
      end
    else begin                         {new position is not within current buffer}
      file_pos_ofs (d.conn, pos.sys, stat); {set file to new position}
      d.nxchar := 0;                   {reset buffer to empty}
      d.nbuf := 0;
      d.ofs := pos.sys;
      d.eof := false;
      end
    ;

  pos.conn_p^.lnum := file_lnum_unk_k; {current line number is now unknown}
  end;                                 {done with D abbreviation}
  end;
