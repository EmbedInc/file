module file_write_text;
define file_write_text;
%include 'file2.ins.pas';
{
********************************************************************************
*
*   Subroutine FILE_WRITE_TEXT (BUF, CONN, STAT)
*
*   Write one line to the text file indicated by CONN.  The string in BUF will
*   become the line of text.  STAT is returned as the completion code.
*
*   Writing lines of text is supported for several different object types.  This
*   is the generic version of the text writing routine.  It checks the object
*   type of CONN and calls the specific routine for the object type.  Those
*   routines can be customized per underlying operating system.
}
procedure file_write_text (            {write one line to text file}
  in      buf: univ string_var_arg_t;  {string to write to line}
  in out  conn: file_conn_t;           {handle to this file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

begin
  sys_error_none (stat);               {init to no error encountered}
  case conn.obty of                    {what object type is being written to ?}

file_obty_file_k: begin                {ordinary file}
      file_wtxt_file (buf, conn, stat);
      end;

file_obty_remote_k: begin              {remote file on another machine}
      file_csrv_txw_write (buf, conn, stat);
      end;

file_obty_call_k: begin                {callback routines, no actual I/O}
      file_call_wtxt (buf, conn, stat);
      end;

otherwise
    sys_stat_set (file_subsys_k, file_stat_wtxt_badobj_k, stat);
    sys_stat_parm_vstr (conn.tnam, stat);
    sys_stat_parm_int (ord(conn.obty), stat);
    end;
  end;
