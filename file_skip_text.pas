{   Subroutine FILE_SKIP_TEXT (CONN,N,STAT)
*
*   Skip over the next N lines in the text file indicated by CONN.  STAT is returned
*   as the completion code.
*
*   This version is the main line of decent, and works on any system where
*   text files are a stream of characters separated by NEW LINE characters.
}
module file_skip_text;
define file_skip_text;
%include 'file2.ins.pas';

procedure file_skip_text (             {skip over next N lines in text file}
  in out  conn: file_conn_t;           {file connection, must be open for read}
  in      n: sys_int_machine_t;        {number of text lines to skip}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  s: string_var4_t;                    {shortest possible var string}
  i: sys_int_machine_t;                {loop counter}

begin
  s.max := 0;                          {prevent wasting time actually copying chars}

  for i := 1 to n do begin             {once for each line to skip}
    file_read_text (conn, s, stat);    {skip over the next line}
    if sys_error(stat) then return;    {error reading this last line ?}
    end;                               {back to skip over next line in file}
  end;
