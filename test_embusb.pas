{   TEST_EMBUSB
*
*   Quick hack program for testing the Embed portable USB device interface.
}
program test_embusb;
%include '(cog)lib/base.ins.pas';

const
  max_msg_args = 2;                    {max arguments we can pass to a message}

var
  vid: sys_int_machine_t;              {USB device vendor ID (VID)}
  pid: sys_int_machine_t;              {USB device product ID (PID)}
  list: file_usbdev_list_t;            {list of USB devices}
  dev_p: file_usbdev_p_t;              {pointer to current list entry}

  opt:                                 {upcased command line option}
    %include '(cog)lib/string_treename.ins.pas';
  parm:                                {command line option parameter}
    %include '(cog)lib/string_treename.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

label
  next_opt, err_parm, parm_bad, done_opts;
{
********************************************************************************
*
*   Start of main routine.
}
begin
{
*   Initialize before reading the command line.
}
  string_cmline_init;                  {init for reading the command line}
  vid := 0;                            {init to list all devices}
  pid := 0;
{
*   Back here each new command line option.
}
next_opt:
  string_cmline_token (opt, stat);     {get next command line option name}
  if string_eos(stat) then goto done_opts; {exhausted command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (opt,                {pick command line option name from list}
    '-VID -PID',
    pick);                             {number of keyword picked from list}
  case pick of                         {do routine for specific option}
{
*   -VID vid
}
1: begin
  string_cmline_token_int (vid, stat);
  end;
{
*   -VID pid
}
2: begin
  string_cmline_token_int (pid, stat);
  end;
{
*   Unrecognized command line option.
}
otherwise
    string_cmline_opt_bad;             {unrecognized command line option}
    end;                               {end of command line option case statement}

err_parm:                              {jump here on error with parameter}
  string_cmline_parm_check (stat, opt); {check for bad command line option parameter}
  goto next_opt;                       {back for next command line option}

parm_bad:                              {jump here on got illegal parameter}
  string_cmline_reuse;                 {re-read last command line token next time}
  string_cmline_token (parm, stat);    {re-read the token for the bad parameter}
  sys_msg_parm_vstr (msg_parm[1], parm);
  sys_msg_parm_vstr (msg_parm[2], opt);
  sys_message_bomb ('string', 'cmline_parm_bad', msg_parm, 2);
done_opts:                             {done with all the command line options}

  file_embusb_list_get (               {get list of Embed USB devices}
    file_usbid(vid, pid),              {ID of devices to list, 0 = all}
    util_top_mem_context,              {parent mem context for the list}
    list,                              {the returned list}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  writeln (list.n, ' Devices');

  dev_p := list.list_p;                {init pointer to first list entry}
  while dev_p <> nil do begin          {loop thru all the list entries}
    writeln;
    writeln ('Dev "', dev_p^.path.str:dev_p^.path.len, '"');
    writeln ('  VID ', rshft(dev_p^.vidpid, 16), ', PID ', dev_p^.vidpid & 16#FFFF);
    writeln ('  Name "', dev_p^.name.str:dev_p^.name.len, '"');
    writeln ('  DRTYPE ', dev_p^.drtype);
    dev_p := dev_p^.next_p;            {point to next list entry}
    end;

  file_usbdev_list_del (list);         {deallocate list resources}
  end.
