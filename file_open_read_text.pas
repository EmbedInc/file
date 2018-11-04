{   Subroutine FILE_OPEN_READ_TEXT (NAME, EXT, CONN, STAT)
*
*   Open a text file for read.  NAME is the file name.  EXT is a list of possible
*   file name extensions separated by blanks.  It is permissible for NAME to
*   already have one of the extensions on it.  In that case it will be ignored
*   in making the the non-extended name.  CONN is returned as the file connection
*   handle.  STAT is returned as the status completion code.
*
*   This version is the main line of decent, and works on any system where
*   text files are a stream of characters separated by NEW LINE characters.
}
module file_open_read_text;
define file_open_read_text;
%include 'file2.ins.pas';

procedure file_open_read_text (        {open text file for read}
  in      name: univ string_var_arg_t; {generic file name}
  in      ext: string;                 {file name extensions, separated by blanks}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}

var
  data_p: file_textr_data_p_t;         {pointer to our private data block}

begin
  sys_mem_alloc (sizeof(data_p^), data_p); {allocate memory for private data block}
  sys_mem_error (data_p, '', '', nil, 0);

  file_open_read_bin (name, ext, data_p^.conn, stat); {open as binary file}
  if sys_error(stat) then begin        {error opening file ?}
    sys_mem_dealloc (data_p);          {deallocate private data block}
    return;                            {return with error}
    end;
{
*   The text file has been successfully opened for binary read.
*
*   Fill in user-visible handle for reading this text file.
}
  conn := data_p^.conn;                {init user handle with handle to bin file}
  conn.fmt := file_fmt_text_k;         {this is really a text file}
  conn.lnum := 0;                      {init line number counter}
  conn.data_p := data_p;               {save pointer to our private data}
  conn.close_p := addr(file_close_textr); {set routine to call for close operation}
  conn.sys := data_p^.conn.sys;        {set system file connection handle}
{
*   Fill in the rest of our private data block.
}
  data_p^.nxchar := 0;
  data_p^.nbuf := 0;
  data_p^.ofs := 0;
  data_p^.eof := false;
  end;
