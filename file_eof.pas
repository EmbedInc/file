{   Function FILE_EOF (STAT)
*
*   Return TRUE if STAT indicates an end of file condition.  In that case,
*   STAT will be reset to indicate no error.
}
module file_eof;
define file_eof;
%include 'file2.ins.pas';

function file_eof (                    {return TRUE if STAT means "END OF FILE"}
  in out  stat: sys_err_t):            {status code, reset to no err on EOF}
  boolean;                             {TRUE on end of file status}

begin
  if
      stat.err and
      (stat.subsys = file_subsys_k) and
      (stat.code = file_stat_eof_k)
    then begin                         {IS end of file status}
      file_eof := true;
      sys_error_none (stat);           {reset to indicate no error}
      end
    else begin                         {is NOT end of file status}
      file_eof := false;
      end
    ;
  end;
