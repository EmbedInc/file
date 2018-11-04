{   Subroutine FILE_READ_ENV (CONN,BUF,STAT)
*
*   Read the next line from a hierarchical set of environment files.
*   All the files have the same leafname, which was declared when CONN was
*   created with subroutine FILE_OPEN_READ_ENV.  The files are effectively chained
*   together so that the first line of one file directly follows the last line
*   of the previous file.  The files are read in order from most general to most
*   specific.  '/*' is the end of line comment delimiter in the files.  Blank
*   lines are also ignored.
*
*   CONN is the connection handle created with FILE_OPEN_READ_ENV.  BUF is the
*   returned string for the next line.  Comments and trailing blanks are stripped
*   off.  Blank lines are eliminated before being returned, so BUF will not
*   be empty.  STAT is the returned completion status code.  It is set to
*   indicate end of file on an attempt to read beyond the last available line.
*
*   The actual treename of the file used can be found in CONN.TNAM.  This will
*   also be the pathname of which file was being accessed when an error condition
*   occurred.  CONN.LNUM is updated to the last line number read.
}
module file_read_env;
define file_read_env;
%include 'file2.ins.pas';

var
  comment: string_var4_t               {device descriptor file comment delimeter}
    := [max := sizeof(comment.str), str := '/*', len := 2];

procedure file_read_env (              {read next line from environment files}
  in out  conn: file_conn_t;           {handle to this file connection}
  in out  buf: univ string_var_arg_t;  {text line, no comments or trailing blanks}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  data_p: file_env_data_p_t;           {points to our private data}
  ind: string_index_t;                 {string index for comment start}

label
  next_line;

begin
  data_p := conn.data_p;               {get pointer to our private data}
  with data_p^: d do begin             {D is abbrev for context block}

next_line:                             {back to read each new line from input file}
    if d.closed then begin             {need to open next file in sequence ?}
      if d.next_dir_p = nil then begin {no more directories in hierarchy ?}
        sys_stat_set (file_subsys_k, file_stat_eof_k, stat); {indicate end of file}
        return;
        end;
      string_copy (d.next_dir_p^.name, conn.tnam); {get new directory name}
      if d.forwards                    {update pointer to next directoy in path}
        then d.next_dir_p := d.next_dir_p^.next_p
        else d.next_dir_p := d.next_dir_p^.prev_p;
      string_append1 (conn.tnam, '/'); {separator before file name}
      string_append (conn.tnam, conn.fnam); {make full file name}
      file_open_read_text (conn.tnam, '', d.conn, stat); {try to open new file}
      if file_not_found(stat) then goto next_line; {back and try next direcotry}
      if sys_error(stat) then return;  {a real error ?}
      string_copy (d.conn.tnam, conn.tnam); {expose full treename to caller}
      d.closed := false;               {new file has been opened}
      end;                             {done opening new file}
{
*   A file is definately open on connection handle D.CONN.
}
    file_read_text (d.conn, buf, stat); {read next line from this file}
    conn.lnum := d.conn.lnum;          {update user-visible line number}
    if file_eof(stat) then begin       {hit end of this file ?}
      file_close (d.conn);             {close this file}
      d.closed := true;                {indicate no file currently open}
      goto next_line;                  {back and try again with next file}
      end;
    if sys_error(stat) then return;    {a real error ?}
    string_find (comment, buf, ind);   {look for comment start}
    if ind > 0 then begin              {found a comment ?}
      buf.len := ind - 1;              {truncate to just before comment start}
      end;
    string_unpad (buf);                {delete all trailing blanks}
    if buf.len <= 0 then goto next_line; {nothing left on this line ?}
    end;                               {done with D abbreviation}
  end;
