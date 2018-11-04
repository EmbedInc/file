{   Function FILE_INUSE (STAT)
*
*   Return TRUE if STAT indicates a file or system object is in use.  If
*   so, STAT will be reset to indicate no error.
}
module file_inuse;
define file_inuse;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

function file_inuse (                  {return TRUE if STAT means file is in use}
  in out  stat: sys_err_t)             {status code, reset to no err on in use}
  :boolean;                            {TRUE on file in use condition}
  val_param;

label
  inuse;

begin
  file_inuse := false;                 {init to STAT not indicate file in use}
{
*   Check for system error codes that indicate in use.
}
  if not stat.err then begin           {system error code, not Embed error code ?}
    if stat.sys = err_none_k then return; {no error at all ?}
    case stat.sys of
err_inuse_k: goto inuse;
      end;
    return;                            {some other system error}
    end;
{
*   STAT indicates a Embed error code.
}
  if stat.subsys = file_subsys_k then begin {FILE subsystem status ?}
    case stat.code of
file_stat_sio_inuse_k,
file_stat_inuse_k: goto inuse;
      end;
    return;                            {some other FILE error}
    end;

inuse:                                 {STAT does indicate file in use}
  file_inuse := true;                  {return in use condition}
  sys_error_none (stat);               {reset STAT to no error}
  end;
