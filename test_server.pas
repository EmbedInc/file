{   Program TEST_SERVER
}
program test_server;
%include 'base.ins.pas';
%include 'test_server.ins.pas';

const
  version_major_k = 1;
  version_minor_k = 0;
  version_sequence_k = 1;
  server_name_k = 'Cognivision internet stream test server.';

var
  serv: file_inet_port_serv_t;         {handle to our public server socket}
  conn: file_conn_t;                   {connection handle to client stream}
  rem_adr: sys_inet_adr_node_t;        {internet address of client node}
  rem_name: string_var132_t;           {name of client node}
  rem_port: sys_inet_port_id_t;        {port number of client on remote node}
  cmd: tserv_cmd_t;                    {buffer for command from client}
  rsp: tserv_rsp_t;                    {buffer for response to client}
  olen: sys_int_adr_t;                 {amount of data actually transferred}
  ibuf_p: sys_size1_p_t;               {input buffer read pointer}
  s80: string_var80_t;                 {arbitrary response string}
  token: string_var16_t;               {individual token for building string}
  stat: sys_err_t;

label
  next_client, done_show_client, next_cmd, client_end;

begin
  rem_name.max := size_char(rem_name.str); {init local var strings}
  s80.max := size_char(s80.str);
  token.max := size_char(token.str);

  file_create_inetstr_serv (           {create server socket waiting for clients}
    sys_sys_inetnode_any_k,            {respond to any addresses this node has}
    tserv_port_k,                      {our "well known" port number}
    serv,                              {returned handle to our server socket}
    stat);
  if sys_error(stat) then begin        {requesting fixed port number didn't work ?}
    file_create_inetstr_serv (         {create server socket waiting for clients}
      sys_sys_inetnode_any_k,          {respond to any addresses this node has}
      sys_sys_inetport_unspec_k,       {let system pick port number}
      serv,                            {returned handle to our server socket}
      stat);
    end;
  sys_error_abort (stat, 'file', 'create_server', nil, 0);

  writeln ('Server established at internet port ', serv.port, '.');
{
*   Network server port has been established.
*
*   Back here to wait for each new client connection.
}
next_client:
  writeln;
  writeln ('Waiting for client to request connection.');
  file_open_inetstr_accept (serv, conn, stat); {wait for client connection request}
  if sys_error_check (stat, 'file', 'inetstr_accept', nil, 0) then begin
    goto next_client;                  {back and try again with next client}
    end;

  file_inetstr_info_remote (           {get info about client end of connection}
    conn,                              {handle to internet stream connection}
    rem_adr,                           {returned address of client node}
    rem_port,                          {returned client port number or remote node}
    stat);
  if sys_error_check(stat, 'file', 'inet_info_remote', nil, 0) {error getting info ?}
    then goto done_show_client;

  file_inet_adr_name (rem_adr, rem_name, stat); {find name of client node}
  sys_error_print (stat, 'file', 'test_server_rem_name', nil, 0);
  discard(                             {reset STAT if just returned dot fmt address}
    sys_stat_match(file_subsys_k, file_stat_inetname_dot_k, stat));
  if sys_error(stat) then goto done_show_client; {other than dot fmt address error ?}

  string_f_inetadr (s80, rem_adr);
  writeln ('Connected to client on "', rem_name.str:rem_name.len,
    '", ', s80.str:s80.len, ', at port ', rem_port, '.');

done_show_client:                      {done showing info about client}
{
*   CONN is handle to new client connection.
}
next_cmd:                              {back here each new command from client}
  ibuf_p := univ_ptr(addr(cmd));       {init input buffer pointer}
  file_read_inetstr (                  {read command ID from client}
    conn,                              {client stream connection handle}
    sizeof(cmd.none.cmd),              {amount of data to read}
    [],                                {no modifier flags specified}
    ibuf_p^,                           {data input buffer}
    olen,                              {returned amount of data actually transferred}
    stat);
  if file_eof(stat) then begin         {client closed connection ?}
    writeln ('Connection closed by client.');
    goto client_end;
    end;
  if sys_error_check (stat, 'file', 'read_inetstr_server', nil, 0)
    then goto client_end;
  ibuf_p := univ_ptr(                  {update to point to next unread location}
    sys_int_adr_t(ibuf_p) + olen);

  case cmd.none.cmd of                 {which command is this ?}
{
*   Command SVINFO.
}
tserv_cmd_svinfo_k: begin
  writeln ('Received command SVINFO.');

  file_read_inetstr (                  {read data for this command}
    conn,                              {client stream connection handle}
    tserv_szcmd_svinfo_k,              {amount of remaining data in this command}
    [],
    ibuf_p^,                           {input buffer}
    olen,
    stat);
  if sys_error_check (stat, 'file', 'read_inetstr_server', nil, 0)
    then goto client_end;

  rsp.svinfo.rsp := tserv_rsp_svinfo_k; {fill in response packet}
  rsp.svinfo.t1 := cmd.svinfo.t1;
  rsp.svinfo.t2 := cmd.svinfo.t2;
  rsp.svinfo.t3 := cmd.svinfo.t3;
  rsp.svinfo.t4 := cmd.svinfo.t4;
  rsp.svinfo.r1 :=
    xor(cmd.svinfo.t1, cmd.svinfo.t2, cmd.svinfo.t3, cmd.svinfo.t4, 5);
  rsp.svinfo.r2 :=
    xor(cmd.svinfo.t1 + cmd.svinfo.t2 + cmd.svinfo.t3 + cmd.svinfo.t4, 5);
  rsp.svinfo.r3 :=
    xor(rsp.svinfo.r1 + rsp.svinfo.r2, 5);
  case sys_byte_order_k of
sys_byte_order_fwd_k: rsp.svinfo.order := tserv_order_fwd_k;
sys_byte_order_bkw_k: rsp.svinfo.order := tserv_order_bkw_k;
    end;
  rsp.svinfo.id := tserv_id_k;
  rsp.svinfo.ver_maj := version_major_k;
  rsp.svinfo.ver_min := version_minor_k;
  rsp.svinfo.ver_seq := version_sequence_k;
  rsp.svinfo.name := server_name_k;

  file_write_inetstr (                 {send response packet back to client}
    rsp,                               {data to send}
    conn,                              {client stream connection handle}
    size_min(tserv_rsp_svinfo_t),      {amount of data to send}
    stat);
  if sys_error_check (stat, 'file', 'write_inetstr_server', nil, 0)
    then goto client_end;
  end;                                 {end of SVINFO command case}
{
*   Command ADD.
}
tserv_cmd_add_k: begin
  writeln ('Received command ADD.');

  file_read_inetstr (                  {read data for this command}
    conn,                              {client stream connection handle}
    tserv_szcmd_add_k,                 {amount of remaining data in this command}
    [],
    ibuf_p^,                           {input buffer}
    olen,
    stat);
  if sys_error_check (stat, 'file', 'read_inetstr_server', nil, 0)
    then goto client_end;

  rsp.add.rsp := tserv_rsp_add_k;      {set response ID}

  string_f_int (s80, cmd.add.i1);      {build response string}
  string_appends (s80, ' + '(0));
  string_f_int (token, cmd.add.i2);
  string_append (s80, token);
  string_appends (s80, ' = '(0));
  string_f_int (token, cmd.add.i1 + cmd.add.i2);
  string_append (s80, token);
  string_fill (s80);                   {fill unused space with blanks}

  rsp.add.len := s80.len;              {set response string and length}
  rsp.add.str := s80.str;

  file_write_inetstr (                 {send response packet back to client}
    rsp,                               {data to send}
    conn,                              {client stream connection handle}
    size_min(tserv_rsp_add_t),         {amount of data to send}
    stat);
  if sys_error_check (stat, 'file', 'write_inetstr_server', nil, 0)
    then goto client_end;
  end;                                 {end of ADD command case}
{
*   Unsupported command ID encountered.
}
otherwise
    writeln ('Received unrecognized command ', ord(cmd.none.cmd), ' from client.');
    goto client_end;
    end;                               {end of client command type cases}
  goto next_cmd;                       {back for next command from this client}
{
*   Jump here to close client connection and wait for next client.
}
client_end:                            {one way or another done with this client}
  writeln ('Closing connection to client.');
  file_close (conn);                   {close connection to client}
  goto next_client;                    {back to wait for next client connect request}
  end.
