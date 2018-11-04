{   Subroutine FILE_OPEN_WRITE_BIN (NAME,EXT,CONN,STAT)
*
*   Open a binary file for write.  NAME is the file name.  EXT is an optional
*   file name extension when not set to all-blank.  It is permissible for NAME to
*   already have the extensions on it.  In that case it will be ignored
*   in making the the non-extended name.  CONN is returned as the file connection
*   handle.  STAT is returned as the status completion code.
}
module file_open_write_bin;
define file_open_write_bin;
%include 'file2.ins.pas';

procedure file_open_write_bin (        {open binary file for write}
  in      name: univ string_var_arg_t; {generic file name}
  in      ext: string;                 {file name extension, blank if not used}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

begin
  file_open_bin (name, ext, [file_rw_write_k], conn, stat);
  end;
