{   Module of routines that are used to implement standard FILE library
*   functions by communicating with a remote COGSERVE server.
}
module file_csrv;
define file_csrv_close_txw;
define file_csrv_txw_open;
define file_csrv_txw_write;
%include 'file2.ins.pas';
%include 'cogserve.ins.pas';

type
  file_textw_rem_data_t = record       {private data for remote text write file}
    conn: file_conn_t;                 {handle to COGSERVE stream connection}
    machine: string_var256_t;          {name of machine remote server is on}
    flip: boolean;                     {TRUE if server byte order flipped from ours}
    end;
  file_textw_rem_data_p_t = ^file_textw_rem_data_t;
{
************************************************************************
*
*   Local subroutine PATH_MACHINE (TNAM, MACHINE, PATH)
*
*   Split a full treename into the machine it points to and the path within
*   that machine.  TNAM *must* already be in Cognivision pathname naming
*   format (//<machine>/<path on machine).  Results are not defined otherwise.
}
procedure path_machine (               {Cog tnam into machine and path on machine}
  in      tnam: univ string_var_arg_t; {input treename in Cognivision format}
  in out  machine: univ string_var_arg_t; {machine name}
  in out  path: univ string_var_arg_t); {path within machine}

var
  i: sys_int_machine_t;                {scratch integer}

begin
  machine.len := 0;                    {init extracted machine name to empty}
  i := 1;                              {init parse index}
  while (i <= tnam.len) and then (tnam.str[i] = '/') {skip leading "/" chars}
    do i := i + 1;
  while                                {loop until first "/" after tnam name}
      (i <= tnam.len) and then (tnam.str[i] <> '/')
      do begin
    if machine.len >= machine.max then exit; {no room for additional chars ?}
    machine.len := machine.len + 1;    {append this char to end of MACHINE}
    machine.str[machine.len] := tnam.str[i];
    i := i + 1;                        {advance to next TNAM character}
    end;                               {back for next char from TNAM}

  path.len := 0;                       {init extracted path on machine}
  while i <= tnam.len do begin         {loop over the characters after machine name}
    if path.len >= path.max then exit; {no room for additional chars ?}
    path.len := path.len + 1;          {append this char to end of PATH}
    path.str[path.len] := tnam.str[i];
    i := i + 1;                        {advance to next TNAM character}
    end;                               {back for next char from TNAM}

  if path.len > 0 then return;         {treename wasn't just //<machine name> ?}
  if path.max <= 0 then return;        {can't fit any characters into PATH anyway ?}
  path.len := 1;                       {pass back '/' indicating machine root}
  path.str[1] := '/';
  end;
{
************************************************************************
*
*   Subroutine FILE_CSRV_TXW_OPEN (CONN, STAT)
*
*   Open text file for write.  All the static fields, plus FNAM, GNAM,
*   TNAM, and EXT_NUM in CONN have been set.  CONN.TNAM *MUST* already be
*   translated to the full treename as best as possible.  The resulting
*   CONN and STAT are passed directly back to the caller of
*   FILE_OPEN_WRITE_TEXT.
}
procedure file_csrv_txw_open (         {open COGSERVE text write file}
  in out  conn: file_conn_t;           {user text file write connection handle}
  out     stat: sys_err_t);            {returned completion status code}
  val_param;

var
  data_p: file_textw_rem_data_p_t;     {pointer to our private connection data}
  i: sys_int_machine_t;                {scratch integer and loop counter}
  len: sys_int_machine_t;              {string length}
  svinfo: csrv_server_info_t;          {info about remote COGSERVE server}
  cmd: csrv_cmd_t;                     {buffer for one command to COGSERVE server}
  err: csrv_err_t;                     {server error status code}
  machine: string_var256_t;            {remote machine name}
  path: string_var8192_t;              {pathname within remote machine}

label
  err_remote_fail, err_comm, abort1, abort2;

begin
  machine.max := size_char(machine.str); {init local var strings}
  path.max := size_char(path.str);

  sys_mem_alloc (sizeof(data_p^), data_p); {alloc our private connection data block}
{
*   Establish connection with remote server.
}
  path_machine (conn.tnam, machine, path); {find machine and pathname on machine}
  csrv_connect (                       {try to connect to remote COGSERVE server}
    machine,                           {name of remote machine}
    data_p^.conn,                      {returned handle to server stream connection}
    svinfo,                            {returned info about remote server}
    stat);                             {returned completion status code}
  if sys_error(stat) then goto abort1;
{
*   Check the server version for compatibility.
}
  if                                   {incompatible server version ?}
      (svinfo.ver_maj <> csrv_ver_maj_k) or {not same major version number}
      (svinfo.ver_min < csrv_ver_min_k) {server has older minor version ?}
      then begin
    sys_stat_set (file_subsys_k, file_stat_csrv_version_k, stat); {set error status}
    sys_stat_parm_vstr (machine, stat); {machine name}
    sys_stat_parm_int (csrv_ver_maj_k, stat); {our major version number}
    sys_stat_parm_int (csrv_ver_min_k, stat); {our minor version number}
    goto abort2;
    end;

  data_p^.flip := svinfo.flip;         {save whether we need to flip server bytes}
{
*   Send the TXWRITE command to server.
}
  cmd.cmd := csrv_cmd_txwrite_k;       {set command opcode}
  len :=                               {set length of pathname in TXWRITE command}
    min(csrv_maxchars_k, path.len);
  for i := 1 to len do begin           {copy the pathname into the command buffer}
    cmd.txwrite.name[i] := path.str[i];
    end;
  cmd.txwrite.len := len;

  if data_p^.flip then begin           {must flip to server byte order ?}
    sys_order_flip (cmd.cmd, sizeof(cmd.cmd));
    sys_order_flip (cmd.txwrite.len, sizeof(cmd.txwrite.len));
    end;

  file_write_inetstr (                 {send TXWRITE command to server}
    cmd,                               {output buffer}
    data_p^.conn,                      {server connection handle}
    offset(cmd.txwrite.name) + sizeof(cmd.txwrite.name[1])*len, {length}
    stat);
  if sys_error(stat) then goto abort2;
{
*   Get and process the STAT response to the TXWRITE command.
}
  csrv_stat_get (                      {read STAT response from server}
    data_p^.conn,                      {server connection handle}
    data_p^.flip,                      {flip byte order flag}
    err,                               {returned server error status}
    stat);
  if sys_error(stat) then goto err_comm;

  if err <> csrv_err_none_k            {TXWRITE failed ?}
    then goto err_remote_fail;
{
*   Fill in remaining CONN fields and return.
}
  conn.rw_mode := [file_rw_write_k];
  conn.obty := file_obty_remote_k;
  conn.fmt := file_fmt_text_k;
  conn.lnum := 0;
  conn.data_p := data_p;
  conn.close_p := addr(file_csrv_close_txw);
  conn.sys := data_p^.conn.sys;

  data_p^.machine.max := size_char(data_p^.machine.str); {save remote machine name}
  string_copy (machine, data_p^.machine);
  return;                              {normal return point}
{
*   Operation on remote machine failed.
}
err_remote_fail:
  sys_stat_set (file_subsys_k, file_stat_remote_fail_k, stat);
  sys_stat_parm_vstr (machine, stat);
  goto abort2;
{
*   Server communication error.  STAT will be filled in.
}
err_comm:
  sys_stat_set (file_subsys_k, file_stat_csrv_comm_k, stat);
  sys_stat_parm_vstr (machine, stat);
{
*   Error exits.  STAT must already be set to indicate the error.
}
abort2:                                {error with server connection open}
  file_close (data_p^.conn);
abort1:                                {error with private memory allocated}
  sys_mem_dealloc (data_p);
  end;
{
************************************************************************
*
*   Subroutine FILE_CSRV_TXW_WRITE (BUF, CONN, STAT)
*
*   Write one line of text to a remote text file.
}
procedure file_csrv_txw_write (        {write line to COGSERVE remote text file}
  in      buf: univ string_var_arg_t;  {string to write to line}
  in out  conn: file_conn_t;           {handle to this file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  i: sys_int_machine_t;                {scratch integer and loop counter}
  len: sys_int_machine_t;              {string length}
  cmd: csrv_cmd_t;                     {buffer for one command to COGSERVE server}
  data_p: file_textw_rem_data_p_t;     {pointer to our private connection data}

begin
  data_p := conn.data_p;               {get pointer to our private data block}

  cmd.cmd := csrv_cmd_txw_data_k;      {set TXW_DATA command opcode}
  len :=                               {set number of characters in this line}
    min(csrv_maxchars_k, buf.len);
  for i := 1 to len do begin           {copy the text line into the command buf}
    cmd.txw_data.line[i] := buf.str[i];
    end;
  cmd.txw_data.len := len;

  if data_p^.flip then begin           {must flip to server byte order ?}
    sys_order_flip (cmd.cmd, sizeof(cmd.cmd));
    sys_order_flip (cmd.txw_data.len, sizeof(cmd.txw_data.len));
    end;

  file_write_inetstr (                 {send TXW_DATA command to server}
    cmd,                               {output buffer}
    data_p^.conn,                      {server connection handle}
    offset(cmd.txw_data.line) + sizeof(cmd.txw_data.line[1])*len, {len}
    stat);
  end;
{
************************************************************************
*
*   Subroutine FILE_CSRV_CLOSE_TXW (CONN_P)
*
*   Close text write connection to remote COGSERVE server.
}
procedure file_csrv_close_txw (        {close remote COGSERVE text write file}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  data_p: file_textw_rem_data_p_t;     {pointer to our private connection data}
  cmd: csrv_cmd_t;                     {buffer for one command to COGSERVE server}
  err: csrv_err_t;                     {server error status code}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;

begin
  data_p := conn_p^.data_p;            {get pointer to our private data block}

  cmd.cmd := csrv_cmd_txw_end_k;       {set TXW_END command opcode}
  if data_p^.flip then begin           {must flip to server byte order ?}
    sys_order_flip (cmd.cmd, sizeof(cmd.cmd));
    end;

  file_write_inetstr (                 {send TXW_END command to server}
    cmd,                               {output buffer}
    data_p^.conn,                      {server connection handle}
    sizeof(cmd.cmd),                   {amount of data to write}
    stat);
  sys_msg_parm_vstr (msg_parm[1], data_p^.machine);
  sys_error_abort (stat, 'file', 'cogserve_close', msg_parm, 1);

  csrv_stat_get (                      {read STAT response from server}
    data_p^.conn,                      {server connection handle}
    data_p^.flip,                      {flip byte order flag}
    err,                               {returned server error status}
    stat);
  if sys_error(stat) then begin
    sys_stat_set (file_subsys_k, file_stat_csrv_comm_k, stat);
    sys_stat_parm_vstr (data_p^.machine, stat);
    sys_error_abort (stat, '', '', nil, 0); {bomb with error}
    end;

  if err <> csrv_err_none_k then begin {overall textfile write operation failed ?}
    sys_stat_set (file_subsys_k, file_stat_remote_fail_k, stat);
    sys_stat_parm_vstr (data_p^.machine, stat);
    sys_error_abort (stat, '', '', nil, 0); {bomb with error}
    end;

  file_close (data_p^.conn);           {close connection to server}
  end;
