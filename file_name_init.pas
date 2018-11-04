{   Subroutine FILE_NAME_INIT (NAME, EXT, RW, CONN, H)
*
*   Initialize for creating file names from the standard user file name input
*   parameters.  NAME is the raw file name.  EXT contains a list of possible
*   suffixes.  RW is the file access mode.  CONN is the file connection handle
*   that will have all var strings initialized.  H is a returned handle to
*   be used with subroutine FILE_NAME_NEXT to create the possible file names.
}
module file_NAME_INIT;
define file_name_init;
%include 'file2.ins.pas';

procedure file_name_init (             {init for creating file names from user args}
  in      name: univ string_var_arg_t; {file name}
  in      ext: string;                 {suffixes string}
  in      rw: file_rw_t;               {read/write modes}
  out     conn: file_conn_t;           {will be initialized}
  out     h: file_name_handle_t);      {handle for call to make successive names}
  val_param;

begin
  h.ext.max := sizeof(h.ext.str);      {save EXT argument as var string in handle}
  string_vstring (h.ext, ext, sizeof(ext));
  h.p := 1;                            {init parse index into H.EXT}
  h.name_p := addr(name);              {save pointer to user's original name}
  h.conn_p := addr(conn);              {save pointer to connection handle}

  conn.rw_mode := rw;                  {do standard initialization of CONN}
  conn.fnam.max := sizeof(conn.fnam.str);
  conn.gnam.max := sizeof(conn.gnam.str);
  conn.tnam.max := sizeof(conn.tnam.str);
  conn.ext_num := 0;
  end;
