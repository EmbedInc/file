{   Subroutine FILE_EOF_PARTIAL (STAT)
*
*   Return TRUE if STAT indicates that a partial record was read before the
*   end of the file was encountered.  If so, STAT will be reset to indicate
*   no error.
}
module file_EOF_PARTIAL;
define file_eof_partial;
%include 'file2.ins.pas';

function file_eof_partial (            {return TRUE if partial data read before EOF}
  in out  stat: sys_err_t):            {status code, reset to no err on return TRUE}
  boolean;
  val_param;

begin
  file_eof_partial :=
    sys_stat_match (file_subsys_k, file_stat_eof_partial_k, stat);
  end;
