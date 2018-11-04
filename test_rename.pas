{   Program TEST_RENAME <old name> <new name>
}
program test_rename;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';

var
  old_fnam,                            {old file name}
  new_fnam:                            {new file name}
    %include '(cog)lib/string_treename.ins.pas';
  stat: sys_err_t;                     {error status code}
  msg_parms:                           {parameters to messages}
    array[1..2] of sys_parm_msg_t;

begin
  string_cmline_init;                  {init command line handling}
  string_cmline_token (old_fnam, stat); {get old file name}
  string_cmline_req_check (stat);
  string_cmline_token (new_fnam, stat); {get new file name}
  string_cmline_req_check (stat);
  string_cmline_end_abort;

  file_rename (old_fnam, new_fnam, stat);
  sys_msg_parm_vstr (msg_parms[1], old_fnam);
  sys_msg_parm_vstr (msg_parms[2], new_fnam);
  sys_error_abort (stat, 'file', 'rename', msg_parms, 2);
  end.
