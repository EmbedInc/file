{   Program TEST_CLIENT <node name> [<port number on remote node>]
}
program test_client;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'test_server.ins.pas';

const
  max_msg_parms = 4;                   {max parameters we can pass to a message}

var
  node_name: string_var132_t;          {name of machine server is running on}
  node_adr: sys_inet_adr_node_t;       {internet address of server node}
  tk: string_var80_t;                  {scratch token}
  cmdnam: string_var16_t;              {current user command name}
  i: sys_int_machine_t;                {scratch integer and loop counter}
  port: sys_inet_port_id_t;            {server port number on remote machine}
  conn: file_conn_t;                   {handle to stream connection to server}
  ilin: string_var256_t;               {one input line from user}
  p: string_index_t;                   {ILIN parse index}
  cmd: tserv_cmd_t;                    {all the command packets in one overlay}
  rsp: tserv_rsp_t;                    {all the response packets in one overlay}
  rbuf_p: sys_size1_p_t;               {server response buffer pointer}
  olen: sys_int_adr_t;                 {amount of data actually transferred}
  pick: sys_int_machine_t;             {number of token picked from list}
  order: sys_byte_order_k_t;           {byte order for communicating with server}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {error status code}

label
  loop_cmd, auth_fail, tkextra;

begin
  node_name.max := size_char(node_name.str); {init local var strings}
  tk.max := size_char(tk.str);
  cmdnam.max := size_char(cmdnam.str);
  ilin.max := size_char(ilin.str);

  order := sys_byte_order_k;           {init server byte order to our own}
{
*   Handle command line.
}
  string_cmline_init;                  {init for command line processing}

  string_cmline_token (node_name, stat); {get server machine name string}
  string_cmline_req_check (stat);      {machine name argument is required}

  port := tserv_port_k;                {init to default port number on remote server}
  string_cmline_token_int (i, stat);   {try to read server port number argument}
  if sys_error(stat)
    then begin                         {error getting optional port number argument}
      if not string_eos(stat) then begin {other than argument not present ?}
        sys_msg_parm_int (msg_parm[1], 2);
        sys_error_abort (stat, 'string', 'cmline_arg_error', msg_parm, 1);
        end;
      end
    else begin                         {port number arg was successfully read}
      port := i;                       {set port number to value from argument}
      end
    ;

  string_cmline_end_abort;             {nothing more is allowed on command line}
{
*   Find internet address and official name of the node where the server is
*   running, then show the results.
}
  file_inet_name_adr (node_name, node_adr, stat); {try to get internet adr from name}
  sys_msg_parm_vstr (msg_parm[1], node_name);
  sys_error_abort (stat, 'file', 'inet_name_adr', msg_parm, 1);

  file_inet_adr_name (node_adr, node_name, stat); {get official name of remote node}
  discard( sys_stat_match(file_subsys_k, file_stat_inetname_dot_k, stat));
  sys_msg_parm_int (msg_parm[1], rshft(node_adr, 24) & 255);
  sys_msg_parm_int (msg_parm[2], rshft(node_adr, 16) & 255);
  sys_msg_parm_int (msg_parm[3], rshft(node_adr, 8) & 255);
  sys_msg_parm_int (msg_parm[4], node_adr & 255);
  sys_error_abort (stat, 'file', 'inet_adr_name', msg_parm, 4);

  string_f_inetadr (tk, node_adr);     {make server node address string}
  writeln (                            {show where we think the server is}
    'Server is on node "', node_name.str:node_name.len,
    '", ', tk.str:tk.len, ', at port ', port, '.');
{
*   Open internet stream to server.
}
  file_open_inetstr (                  {open stream connection to remote server}
    node_adr,                          {internet address of remote node}
    port,                              {port to connect to on remote node}
    conn,                              {returned connection handle}
    stat);
  sys_msg_parm_int (msg_parm[1], port);
  sys_msg_parm_vstr (msg_parm[2], node_name);
  sys_error_abort (stat, 'file', 'open_inetstr_client', msg_parm, 2);
{
*   Internet stream to server has been successfully established.
*
********************************
*
*   Back here each new user command.
}
loop_cmd:
  string_prompt (string_v('> '(0)));   {write user prompt}
  string_readin (ilin);                {read input line from user}
  p := 1;                              {init input line parse index}
  string_token (ilin, p, cmdnam, stat); {try to read command name from input line}
  if string_eos(stat) then goto loop_cmd; {ingore blank lines}
  sys_error_abort (stat, '', '', nil, 0);
  string_upcase (cmdnam);              {make upper case for keyword matching}
  string_tkpick80m (cmdnam,
    'SVINFO ADD QUIT',
    pick);                             {number of keyword picked from list}
  case pick of                         {which command did the user enter ?}
{
*   Command SVINFO t1 t2 t3 t4
}
1: begin
  cmd.svinfo.cmd := tserv_cmd_svinfo_k; {set command opcode}

  string_token_int (ilin, p, i, stat);
  sys_error_abort (stat, '', '', nil, 0);
  cmd.svinfo.t1 := i;

  string_token_int (ilin, p, i, stat);
  sys_error_abort (stat, '', '', nil, 0);
  cmd.svinfo.t2 := i;

  string_token_int (ilin, p, i, stat);
  sys_error_abort (stat, '', '', nil, 0);
  cmd.svinfo.t3 := i;

  string_token_int (ilin, p, i, stat);
  sys_error_abort (stat, '', '', nil, 0);
  cmd.svinfo.t4 := i;

  string_token (ilin, p, tk, stat);
  if not string_eos(stat) then goto tkextra;

  file_write_inetstr (                 {send command to server}
    cmd,                               {output buffer}
    conn,                              {handle to server stream connection}
    size_min(cmd.svinfo),              {amount of data to send}
    stat);
  sys_error_abort (stat, 'file', 'write_inetstr_client', nil, 0);
  end;
{
*   Command ADD i1 i2
}
2: begin
  cmd.add.cmd := tserv_cmd_add_k;      {set command opcode}

  string_token_int (ilin, p, i, stat);
  sys_error_abort (stat, '', '', nil, 0);
  cmd.add.i1 := i;

  string_token_int (ilin, p, i, stat);
  sys_error_abort (stat, '', '', nil, 0);
  cmd.add.i2 := i;

  string_token (ilin, p, tk, stat);
  if not string_eos(stat) then goto tkextra;

  if order <> sys_byte_order_k then begin {need to flip multi-byte fields ?}
    sys_order_flip (cmd.add.i1, sizeof(cmd.add.i1));
    sys_order_flip (cmd.add.i2, sizeof(cmd.add.i2));
    end;

  file_write_inetstr (                 {send command to server}
    cmd,                               {output buffer}
    conn,                              {handle to server stream connection}
    size_min(cmd.add),                 {amount of data to send}
    stat);
  sys_error_abort (stat, 'file', 'write_inetstr_client', nil, 0);
  end;
{
*   Command QUIT
}
3: begin
  file_close (conn);                   {close connection to server}
  sys_exit;
  end;
{
*   Unrecognized user command.
}
otherwise
    sys_msg_parm_vstr (msg_parm[1], cmdnam);
    sys_message_parms ('file', 'test_client_cmd_bad', msg_parm, 1);
    goto loop_cmd;                     {back for next command}
    end;                               {end of user command cases}
{
*   Done processing the current user command.  If we get to here, then
*   we are expecting a response from the server.  If a particular command
*   doesn't expect a server response, then it should not fall thru to here,
*   but jump to the appropriate place, probably LOOP_CMD.
*
********************************
*
*   Wait for and process the next server response.
}
  rbuf_p := univ_ptr(addr(rsp));       {init where to place next server input data}

  file_read_inetstr (                  {read response opcode from server}
    conn,                              {handle to server stream connection}
    size_min(rsp.none.rsp),            {amount of data to read}
    [],                                {optional modifier flags}
    rbuf_p^,                           {input buffer}
    olen,                              {amount of data actually read}
    stat);
  sys_error_abort (stat, 'file', 'read_inetstr_client', nil, 0);
  rbuf_p := univ_ptr(                  {update input pointer to after this data}
    sys_int_adr_t(rbuf_p) + olen);
  case rsp.none.rsp of                 {what is server response opcode ?}
{
*   Response SVINFO.
*
*   The SVINFO command data is assumed to still be in CMD.
}
tserv_rsp_svinfo_k: begin
  file_read_inetstr (                  {read response data from server stream}
    conn,                              {handle to server stream connection}
    tserv_szrsp_svinfo_k,              {amount of data to read}
    [],                                {optional modifier flags}
    rbuf_p^,                           {input buffer}
    olen,                              {amount of data actually read}
    stat);
  sys_error_abort (stat, 'file', 'read_inetstr_client', nil, 0);

  if rsp.svinfo.t1 <> cmd.svinfo.t1 then goto auth_fail;
  if rsp.svinfo.t2 <> cmd.svinfo.t2 then goto auth_fail;
  if rsp.svinfo.t3 <> cmd.svinfo.t3 then goto auth_fail;
  if rsp.svinfo.t4 <> cmd.svinfo.t4 then goto auth_fail;
  i := xor(cmd.svinfo.t1, cmd.svinfo.t2, cmd.svinfo.t3, cmd.svinfo.t4, 5);
  if i <> rsp.svinfo.r1 then goto auth_fail;
  i := xor(cmd.svinfo.t1 + cmd.svinfo.t2 + cmd.svinfo.t3 + cmd.svinfo.t4, 5);
  if (i & 255) <> rsp.svinfo.r2 then goto auth_fail;
  i := xor(rsp.svinfo.r1 + rsp.svinfo.r2, 5);
  if (i & 255) <> rsp.svinfo.r3 then goto auth_fail;

  case rsp.svinfo.order of
tserv_order_fwd_k: order := sys_byte_order_fwd_k;
tserv_order_bkw_k: order := sys_byte_order_bkw_k;
    end;

  write ('Server byte order is ');
  case order of
sys_byte_order_fwd_k: writeln ('FORWARDS.');
sys_byte_order_bkw_k: writeln ('BACKWARDS.');
    end;

  if order <> sys_byte_order_k then begin {need to flip multi-byte fields ?}
    sys_order_flip (rsp.svinfo.id, sizeof(rsp.svinfo.id));
    sys_order_flip (rsp.svinfo.ver_maj, sizeof(rsp.svinfo.ver_maj));
    sys_order_flip (rsp.svinfo.ver_min, sizeof(rsp.svinfo.ver_min));
    sys_order_flip (rsp.svinfo.ver_seq, sizeof(rsp.svinfo.ver_seq));
    end;

  writeln ('Server ID is ', rsp.svinfo.id, '.');
  if rsp.svinfo.id <> tserv_id_k then goto auth_fail;

  writeln ('Server info:');
  writeln ('    Major version:   ', rsp.svinfo.ver_maj);
  writeln ('    Minor version:   ', rsp.svinfo.ver_maj);
  writeln ('    Sequence number: ', rsp.svinfo.ver_maj);
  string_vstring (tk, rsp.svinfo.name, size_char(rsp.svinfo.name));
  writeln ('    Name:            "', tk.str:tk.len, '"');
  end;                                 {end of response SVINFO case}
{
*   Response ADD.
}
tserv_rsp_add_k: begin
  file_read_inetstr (                  {read response data from server stream}
    conn,                              {handle to server stream connection}
    tserv_szrsp_add_k,                 {amount of data to read}
    [],                                {optional modifier flags}
    rbuf_p^,                           {input buffer}
    olen,                              {amount of data actually read}
    stat);
  sys_error_abort (stat, 'file', 'read_inetstr_client', nil, 0);

  string_vstring (tk, rsp.add.str, rsp.add.len);
  writeln ('ADD: "', tk.str:tk.len, '"');
  end;
{
*   Unrecognized server response.
}
otherwise
    writeln ('Unexpected server response opcode ', ord(rsp.none.rsp), ' received.');
    sys_bomb;
    end;
  goto loop_cmd;                       {back to process next user command}
{
*   Error exits.
}
auth_fail:                             {server authentication failed}
  sys_message_bomb ('file', 'test_client_auth_fail', nil, 0);

tkextra:                               {extra token found at end of command}
  sys_message ('file', 'test_client_tkextra');
  goto loop_cmd;
  end.
