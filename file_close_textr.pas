{   Subroutine FILE_CLOSE_TEXTR (CONN_P)
*
*   Close connection to a file that was opened for reading text.
*
*   This version is the main line of decent, and works on any system where
*   text files are a stream of characters separated by NEW LINE characters.
}
module file_close_textr;
define file_close_textr;
%include 'file2.ins.pas';

procedure file_close_textr (           {close conn opened with FILE_OPEN_READ_TEXT}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param;

var
  data_p: file_textr_data_p_t;         {pointer to private data block}

begin
  data_p := conn_p^.data_p;            {get pointer to our private data block}
  file_close (data_p^.conn);           {close connection to binary file}
  end;
