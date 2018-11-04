{   Program TEST_DEL <file name>
*
*   Delete the named file.
}
program test_del;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';

var
  fnam:                                {file name from command line}
    %include '(cog)lib/string_treename.ins.pas';
  fullnam:
    %include '(cog)lib/string_treename.ins.pas';
  stat: sys_err_t;                     {error status code}
  msg_parms:                           {parameters to messages}
    array[1..1] of sys_parm_msg_t;

begin
  string_cmline_init;
  string_cmline_token (fnam, stat);    {get name of file to delete}
  string_cmline_req_check (stat);
  string_cmline_end_abort;

  writeln ('Deleting "', fnam.str:fnam.len, '".');
  string_treename(fnam, fullnam);
  file_delete_name (fullnam, stat);
  sys_msg_parm_vstr (msg_parms[1], fnam);
  sys_error_abort (stat, 'file', 'delete', msg_parms, 1);
  end.
