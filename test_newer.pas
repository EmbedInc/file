{   Program TEST_NEWER <file name 1> <file name 2>
*
*   The program test ability to compare modified date/times of two files.
*   The name of the newer file is printed.  Both names are printed if the
*   files have identical modified date/time stamps.
}
program test_newer;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  fnam1, fnam2:                        {names of the two files to test}
    %include '(cog)lib/string_treename.ins.pas';
  info1, info2: file_info_t;           {info for each file}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;

begin
  string_cmline_init;                  {init for reading the command line}
  string_cmline_token (fnam1, stat);
  string_cmline_req_check (stat);
  string_cmline_token (fnam2, stat);
  string_cmline_req_check (stat);
  string_cmline_end_abort;

  file_info (                          {get modified date/time for file 1}
    fnam1,                             {file name}
    [file_iflag_dtm_k],                {request modified date/time}
    info1,                             {returned info about this file}
    stat);
  sys_msg_parm_vstr (msg_parm[1], fnam1);
  sys_error_abort (stat, 'file', 'info', msg_parm, 1);

  file_info (                          {get modified date/time for file 2}
    fnam2,                             {file name}
    [file_iflag_dtm_k],                {request modified date/time}
    info2,                             {returned info about this file}
    stat);
  sys_msg_parm_vstr (msg_parm[1], fnam2);
  sys_error_abort (stat, 'file', 'info', msg_parm, 1);

  case sys_clock_compare(info1.modified, info2.modified) of
sys_compare_lt_k:                      {second file is newer}
    writeln (fnam2.str:fnam2.len);
sys_compare_eq_k:                      {both files have same modified date}
    writeln (fnam1.str:fnam1.len, ' ', fnam2.str:fnam2.len);
sys_compare_gt_k:                      {first file is newer}
    writeln (fnam1.str:fnam1.len);
    end;
  end.
