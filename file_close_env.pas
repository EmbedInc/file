{   Subroutine FILE_CLOSE_ENV (CONN_P)
*
*   Special close routine to close connection opened with FILE_OPEN_READ_ENV.
}
module file_close_env;
define file_close_env;
%include 'file2.ins.pas';

procedure file_close_env (             {close connection opened with FILE_OPEN_ENV}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param;

var
  data_p: file_env_data_p_t;           {points to our private data}

begin
  data_p := conn_p^.data_p;            {get pointer to our private data}

  with data_p^: d do begin             {D is abbrev for context block}
    if not d.closed then begin         {one of the files is still open ?}
      file_close (d.conn);             {close file}
      end;
    end;                               {done with D abbreviation}
  end;
