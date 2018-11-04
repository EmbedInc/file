{   Subroutine FILE_OPEN_READ_BIN (NAME,EXT,CONN,STAT)
*
*   Open a binaru file for read.  NAME is the file name.  EXT is a list of possible
*   file name extensions separated by blanks.  It is permissible for NAME to
*   already have one of the extensions on it.  In that case it will be ignored
*   in making the the non-extended name.  CONN is returned as the file connection
*   handle.  STAT is returned as the status completion code.
}
module file_open_read_bin;
define file_open_read_bin;
%include 'file2.ins.pas';

procedure file_open_read_bin (         {open binary file for read}
  in      name: univ string_var_arg_t; {generic file name}
  in      ext: string;                 {file name extensions, separated by blanks}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

begin
  file_open_bin (name, ext, [file_rw_read_k], conn, stat);
  end;
