{   Function FILE_NOT_FOUND (STAT)
*
*   Return TRUE if STAT indicates a "FILE NOT FOUND" condition.  In that case,
*   STAT will be reset to indicate no error.
}
module file_not_found;
define file_not_found;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

function file_not_found (              {return TRUE if STAT means "NOT FOUND"}
  in out  stat: sys_err_t):            {status code, reset to no err on not found}
  boolean;                             {TRUE on not found status}

var
  yes: boolean;                        {TRUE if condition was found}

begin
  if stat.err
    then begin                         {Cognivision error code}
      yes :=
        (stat.subsys = file_subsys_k) and
        (stat.code = file_stat_not_found_k);
      end
    else begin                         {system error code}
      yes :=
        (stat.sys = err_file_not_found_k) or
        (stat.sys = err_path_not_found_k);
      end
    ;

  if yes
    then begin                         {condition WAS found}
      file_not_found := true;
      sys_error_none (stat);           {reset to indicate no error}
      end
    else begin                         {condition was NOT found}
      file_not_found := false;
      end
    ;
  end;
