{   Subroutine FILE_SET_ENV_BKWDS (CONN)
*
*   Indicate that the environment files are to read in reverse order.  The default
*   is to read enviroment files from the most general to the most specific.
*   This call reverses that order.  If used, this subroutine must be called before
*   any data is read from the environment files.
}
module file_set_env_bkwds;
define file_set_env_bkwds;
%include 'file2.ins.pas';

procedure file_set_env_bkwds (         {read ENV files in backwards order}
  in out  conn: file_conn_t);          {connection handle to env files}
  val_param;

var
  data_p: file_env_data_p_t;           {points to our private data}

begin
  data_p := conn.data_p;               {get pointer to our private data}
  with data_p^: d do begin             {D is abbrev for context block}

    d.forwards := false;               {set search path order}
    if d.next_dir_p = nil then return; {search list is empty anyways ?}

    while d.next_dir_p^.next_p <> nil do begin
      d.next_dir_p := d.next_dir_p^.next_p;
      end;
    end;                               {done with D abbreviation}

  end;
