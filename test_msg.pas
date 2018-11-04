{   Program TEST_MSG <subsystem name> <message name> [ <options> ]
*
*   Print text of message.  Options are:
*
*   -VSTR <string>
*
*   -STR <string>
*
*   -INT <integer>
*
*   -REAL <floating point number>
*
*   -FP1 <floating point number>
*
*   -FP2 <floating point number>
}
program test_msg;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';

const
  max_msg_parms = 10;                  {max parameters we can pass to a message}

var
  subsys_name,                         {subsystem name from command line}
  message_name,                        {message name within subsystem from com line}
  val_str:                             {temp holding area for a string value}
    %include '(cog)lib/string80.ins.pas';
  n_parms: sys_int_machine_t;          {number of message parameters given}
  opt:                                 {command line option name}
    %include '(cog)lib/string80.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  val_str_p: string_var_p_t;           {pointers to message parameter values}
  val_int_p: sys_int_machine_p_t;
  val_real_p: ^real;
  val_fp1_p: ^single;
  val_fp2_p: ^double;
  val_fp: double;
  stat: sys_err_t;
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

label
  next_arg, done_args;

begin
  string_cmline_init;                  {init for parsing command line}

  string_cmline_token (subsys_name, stat); {get subsystem name}
  string_cmline_req_check (stat);
  string_fill (subsys_name);

  string_cmline_token (message_name, stat); {get message name within subsystem}
  string_cmline_req_check (stat);
  string_fill (message_name);

  n_parms := 0;                        {init number of optional parameters given}
{
*   Loop back here for each optional argument on command line.
}
next_arg:
  string_cmline_token (opt, stat);     {get next command line option name}
  if string_eos(stat) then goto done_args; {nothing more on command line?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  n_parms := n_parms + 1;              {count this command line parameter}
  if n_parms > max_msg_parms then begin
    writeln ('Too many message arguments.');
    sys_bomb;
    end;
  string_upcase (opt);                 {make upper case for token matching}
  string_tkpick80 (opt,
    '-VSTR -STR -INT -REAL -FP1 -FP2',
    pick);
  case pick of
{
*   -VSTR <string>
}
1: begin
  string_cmline_token (val_str, stat);
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  string_alloc (val_str.len, util_top_mem_context, false, val_str_p);
  string_copy (val_str, val_str_p^);
  sys_msg_parm_vstr (msg_parm[n_parms], val_str_p^);
  end;
{
*   -STR <string>
}
2: begin
  string_cmline_token (val_str, stat);
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  string_alloc (sizeof(string), util_top_mem_context, false, val_str_p);
  string_copy (val_str, val_str_p^);
  string_fill (val_str_p^);
  sys_msg_parm_str (msg_parm[n_parms], val_str_p^.str);
  end;
{
*   -INT <integer>
}
3: begin
  sys_mem_alloc (sizeof(val_int_p^), val_int_p);
  string_cmline_token_int (val_int_p^, stat);
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  sys_msg_parm_int (msg_parm[n_parms], val_int_p^);
  end;
{
*   -REAL <floating point number>
}
4: begin
  sys_mem_alloc (sizeof(val_real_p^), val_real_p);
  string_cmline_token_fp2 (val_fp, stat);
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  val_real_p^ := val_fp;
  sys_msg_parm_real (msg_parm[n_parms], val_real_p^);
  end;
{
*   -FP1 <floating point number>
}
5: begin
  sys_mem_alloc (sizeof(val_fp1_p^), val_fp1_p);
  string_cmline_token_fp1 (val_fp1_p^, stat);
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  sys_msg_parm_fp1 (msg_parm[n_parms], val_fp1_p^);
  end;
{
*   -FP2 <floating point number>
}
6: begin
  sys_mem_alloc (sizeof(val_fp2_p^), val_fp2_p);
  string_cmline_token_fp2 (val_fp2_p^, stat);
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  sys_msg_parm_fp2 (msg_parm[n_parms], val_fp2_p^);
  end;
{
*   Unrecognized command line option.
}
otherwise
    sys_msg_parm_vstr (msg_parm[1], opt);
    sys_message_bomb ('string', 'cmline_opt_bad', msg_parm, 1);
    end;                               {end of command line option cases}
  goto next_arg;                       {back and process next command line argument}

done_args:                             {done reading parms from command line}
{
*   All data has been collected.  Now call routine we are trying to test.
}
  sys_message_parms (
    subsys_name.str,                   {subsystem name}
    message_name.str,                  {message name}
    msg_parm,                          {array of parameters for message}
    n_parms);                          {number of parameters in PARMS}
  end.
