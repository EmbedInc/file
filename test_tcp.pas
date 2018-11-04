{   Program TEST_TCP [options]
}
program test_tcp;
%include '(cog)lib/sys.ins.pas';
%include '(cog)lib/util.ins.pas';
%include '(cog)lib/string.ins.pas';
%include '(cog)lib/file.ins.pas';

const
  port_def_k = 2000;                   {default port}
  max_send_k = 48;                     {max bytes allowed to send in one packet}
  n_cmdnames_k = 2;                    {number of command names in the list}
  cmdname_maxchars_k = 6;              {max chars in any command name}
  max_msg_parms = 4;                   {max parameters we can pass to a message}
{
*   Derived constants.
}
  cmdname_len_k = cmdname_maxchars_k + 1; {number of chars to reserve per cmd name}
  last_send_k = max_send_k - 1;        {last valid output buffer index}

type
  cmdname_t =                          {one command name in the list}
    array[1..cmdname_len_k] of char;
  cmdnames_t =                         {list of all the command names}
    array[1..n_cmdnames_k] of cmdname_t;

var
  cmdnames: cmdnames_t := [            {list of all the command names}
    'HELP  ',                          {1}
    'QUIT  ',                          {2}
     ];

var
  serv_name:                           {server name}
    %include '(cog)lib/string132.ins.pas';
  i: sys_int_machine_t;                {scratch integer and loop counter}
  port: sys_inet_port_id_t;            {server port number on remote machine}
  serv: file_inet_port_serv_t;         {handle to our public server socket}
  conn: file_conn_t;                   {handle to TCP connection}
  wrlock: sys_sys_threadlock_t;        {lock for writing to standard output}
  thid_in: sys_sys_thread_id_t;        {ID of low level serial line input thread}
  prompt:                              {prompt string for entering command}
    %include '(cog)lib/string4.ins.pas';
  buf:                                 {one line command input buffer}
    %include '(cog)lib/string8192.ins.pas';
  p: string_index_t;                   {BUF parse index}
  obuf: array[0 .. last_send_k] of int8u_t; {single packet output buffer}
  obufn: sys_int_machine_t;            {number of bytes in the output buffer}
  quit: boolean;                       {TRUE when trying to exit the program}
  newline: boolean;                    {STDOUT stream is at start of new line}
  port_set: boolean;                   {port explicitly supplied on command line}
  client: boolean;                     {we are client end of TCP stream}
  server: boolean;                     {we are sever end of TCP stream}
  tcpopen: boolean;                    {TCP connection currently open on CONN}

  opt:                                 {upcased command line option}
    %include '(cog)lib/string_treename.ins.pas';
  parm:                                {command line option parameter}
    %include '(cog)lib/string_treename.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

label
  next_opt, err_parm, err_conflict, parm_bad, done_opts,
  loop_cmd, loop_ubyte, got_ubytes,
  done_cmd, err_extra, bad_cmd, err_cmparm, leave;
{
****************************************************************************
*
*   Subroutine LOCKOUT
*
*   Acquire exclusive lock for writing to standard output.
}
procedure lockout;

begin
  sys_thread_lock_enter (wrlock);
  if not newline then writeln;         {start on a new line}
  newline := true;                     {init to STDOUT will be at start of line}
  end;
{
****************************************************************************
*
*   Subroutine UNLOCKOUT
*
*   Release exclusive lock for writing to standard output.
}
procedure unlockout;

begin
  sys_thread_lock_leave (wrlock);
  end;
{
****************************************************************************
*
*   Subroutine OPEN_CLIENT
*
*   Wait for a client connection request and establish the TCP stream to the
*   client.  The stream is returned open on CONN.
*
*   This routine must only be called in server mode with CONN not open.
}
procedure open_client;

var
  cl_adr: sys_inet_adr_node_t;         {address of client machine}
  cl_port: sys_inet_port_id_t;         {client port number on client machine}
  tk: string_var32_t;                  {scratch token}
  stat: sys_err_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  file_open_inetstr_accept (serv, conn, stat); {wait for client, open stream}
  sys_error_abort (stat, '', '', nil, 0);
  tcpopen := true;                     {indicate TCP stream is now open}

  file_inetstr_info_remote (           {get info about remote end of connection}
    conn, cl_adr, cl_port, stat);
  sys_error_abort (stat, '', '', nil, 0);

  string_f_inetadr (tk, cl_adr);       {make dot notation client machine address}
  lockout;                             {lock output for our use}
  writeln;
  writeln ('Client on machine ', tk.str:tk.len, ' at port ', cl_port, '.');
  unlockout;                           {release output for use by other threads}
  end;
{
****************************************************************************
*
*   Subroutine STARTUP_SERVER
*
*   Startup in server mode, meaning this program will act as the server side
*   of the connection.  If PORT_SET is set, then PORT will be the server port
*   or the program will be aborted with error.  If PORT_SET is not set, then
*   the default port set by PORT_DEF_K will be used if possible, or the port
*   will be assigned by the system if not.  In any case PORT will be returned
*   the actual port number.  SERVER will be returned TRUE and CLIENT FALSE.
*
*   This routine only establishes the server and does not wait for a client
*   connection.
}
procedure startup_server;

var
  stat: sys_err_t;

begin
  if not port_set then port := port_def_k; {get default port value if none specified}

  file_create_inetstr_serv (           {create server socket waiting for clients}
    sys_sys_inetnode_any_k,            {respond to any addresses this node has}
    port,                              {fixed port number to use}
    serv,                              {returned handle to our server socket}
    stat);

  if sys_error(stat) then begin        {requesting fixed port number didn't work ?}
    if not port_set then begin         {OK to let system pick port ?}
      file_create_inetstr_serv (       {create server socket waiting for clients}
        sys_sys_inetnode_any_k,        {respond to any addresses this node has}
        sys_sys_inetport_unspec_k,     {let system pick port number}
        serv,                          {returned handle to our server socket}
        stat);
      end;
    sys_error_abort (stat, 'file', 'create_server', nil, 0);
    end;

  port := serv.port;                   {indicate port number}
  lockout;                             {lock output for our use}
  writeln ('Server established at port ', port, '.');
  unlockout;                           {release output for use by other threads}
  client := false;                     {indicate we are acting as the server}
  server := true;
  end;
{
****************************************************************************
*
*   Subroutine STARTUP_CLIENT
*
*   Startup in client mode, meaning this program will act as the client side
*   of the connection.  SERV_NAME must be set to the server machine name or
*   server IP address string in dot notation format.  PORT must be the server
*   port on that machine.  On return, the TCP stream will be open on CONN.
*   CLIENT will be set to TRUE and SEVER to FALSE.
}
procedure startup_client;

var
  sadr: sys_inet_adr_node_t;           {address of server machine}
  stat: sys_err_t;

begin
  file_inet_name_adr (                 {get server address from its name}
    serv_name, sadr, stat);
  sys_error_abort (stat, '', '', nil, 0);
  if not port_set then port := port_def_k; {use default port ?}

  file_open_inetstr (                  {open TCP stream to the client}
    sadr, port, conn, stat);
  sys_error_abort (stat, '', '', nil, 0);
  tcpopen := true;                     {indicate TCP stream is now open}
  end;
{
****************************************************************************
*
*   Subroutine THREAD_IN (ARG)
*
*   This routine is run in a separate thread.  It processes the incoming byte
*   stream.
}
procedure thread_in (                  {get data bytes from serial line}
  in      arg: sys_int_adr_t);         {unused argument}
  val_param; internal;

const
  bufsize_k = 1500;                    {max bytes to read in one chunk}
  maxbuf_k = bufsize_k - 1;            {max BUF array index}

var
  b: sys_int_machine_t;                {data byte value}
  buf: array[0 .. maxbuf_k] of int8u_t; {one chunk input buffer}
  bufn: sys_int_machine_t;             {number of unread bytes in BUF}
  bufi: sys_int_machine_t;             {0-N BUF index to read next byte from}
  tk, tk2: string_var32_t;             {scratch tokens}
  stat: sys_err_t;                     {completion status}

label
  loop;
{
******************************
*
*   Local function IBYTE
*
*   Return the next input byte.
}
function ibyte                         {return next byte from remote system}
  :sys_int_machine_t;                  {0-255 byte value}

var
  olen: sys_int_adr_t;                 {number of bytes actually read}
  stat: sys_err_t;                     {completion status}

label
  get_byte, loop_read;

begin
get_byte:                              {back here to try to get byte from buffer}
  if bufn > 0 then begin               {a byte is available in the buffer ?}
    bufn := bufn - 1;                  {buffer will have one less byte}
    ibyte := buf[bufi];                {get the next byte from the buffer}
    bufi := bufi + 1;                  {update index where to get next byte from}
    return;
    end;

loop_read:                             {back here to try reading from stream}
  if not tcpopen then begin            {not connected to a client ?}
    open_client;                       {wait for client to connect}
    end;
  file_read_inetstr (                  {read from the TCP stream}
    conn,                              {connection to the stream}
    bufsize_k,                         {maximum number of bytes to read}
    [file_rdstream_1chunk_k],          {return as soon as anything is received}
    buf,                               {buffer to read the data into}
    olen,                              {returned number of bytes actually read}
    stat);
  ibyte := 0;                          {keep compiler from complaining}
  if quit then return;
  if sys_error_check (stat, '', '', nil, 0) then begin {hard error on read ?}
    file_close (conn);                 {close the connection to the remote server or client}
    tcpopen := false;                  {indicate no TCP is currently open}
    if server
      then begin                       {this program is acting as the server}
        goto loop_read;                {back to wait for next client}
        end
      else begin                       {this program is acting as the client}
        sys_bomb;                      {abort program with error status}
        end
      ;
    end;

  bufn := olen;                        {set number of bytes now in the buffer}
  bufi := 0;                           {init index to next buffer byte to read}
  goto get_byte;                       {back to read next byte from the buffer}
  end;
{
******************************
*
*   Executable code for subroutine THREAD_IN.
}
begin
  tk.max := size_char(tk.str);         {init local var strings}
  tk2.max := size_char(tk2.str);

loop:                                  {back here each new input byte}
  b := ibyte;                          {get the next input byte into B}
  if quit then return;
  string_f_int_max_base (              {make HEX byte value}
    tk,                                {output string}
    b,                                 {input integer}
    16,                                {radix}
    2,                                 {fixed field width}
    [ string_fi_leadz_k,               {pad on left with leading zeros}
      string_fi_unsig_k],              {input number is unsigned}
    stat);
  string_f_int_max_base (              {make decimal byte value}
    tk2,                               {output string}
    b,                                 {input integer}
    10,                                {radix}
    3,                                 {fixed field width}
    [string_fi_unsig_k],               {input number is unsigned}
    stat);

  lockout;                             {lock access to standard output}
  write ('< ', tk.str:tk.len, 'h ', tk2.str:tk2.len);
  if b >= 32 then begin                {not a control character ?}
    write (' "', chr(b), '"');
    end;
  writeln;
  unlockout;                           {release lock on standard output}
  goto loop;
  end;
{
***************************************************************************
*
*   Subroutine NEXT_KEYW (TK, STAT)
*
*   Parse the next token from BUF as a keyword and return it in TK.
}
procedure next_keyw (
  in out  tk: univ string_var_arg_t;   {returned token}
  out     stat: sys_err_t);
  val_param;

begin
  string_token (buf, p, tk, stat);
  string_upcase (tk);
  end;
{
***************************************************************************
*
*   Function NEXT_INT (MN, MX, STAT)
*
*   Parse the next token from BUF and return its value as an integer.
*   MN and MX are the min/max valid range of the integer value.
}
function next_int (                    {get next token as integer value}
  in      mn, mx: sys_int_machine_t;   {valid min/max range}
  out     stat: sys_err_t)             {completion status code}
  :sys_int_machine_t;
  val_param;

var
  i: sys_int_machine_t;

begin
  string_token_int (buf, p, i, stat);  {get token value in I}
  next_int := i;                       {pass back value}
  if sys_error(stat) then return;

  if (i < mn) or (i > mx) then begin   {out of range}
    lockout;
    writeln ('Value ', i, ' is out of range.');
    unlockout;
    sys_stat_set (sys_subsys_k, sys_stat_failed_k, stat);
    end;
  end;
{
***************************************************************************
*
*   Function NOT_EOS
*
*   Returns TRUE if the input buffer BUF was is not exhausted.  This is
*   used to check for additional tokens at the end of a command.
}
function not_eos                       {check for more tokens left}
  :boolean;                            {TRUE if more tokens left in BUF}

var
  psave: string_index_t;               {saved copy of BUF parse index}
  tk: string_var4_t;                   {token parsed from BUF}
  stat: sys_err_t;                     {completion status code}

begin
  tk.max := size_char(tk.str);         {init local var string}

  not_eos := false;                    {init to BUF has been exhausted}
  psave := p;                          {save current BUF parse index}
  string_token (buf, p, tk, stat);     {try to get another token}
  if sys_error(stat) then return;      {assume normal end of line encountered ?}
  not_eos := true;                     {indicate a token was found}
  p := psave;                          {reset parse index to get this token again}
  end;
{
****************************************************************************
*
*   Start of main routine.
}
begin
  port_set := false;                   {init to no port specified}
{
*   Handle command line.
}
  string_cmline_init;                  {init for command line processing}

next_opt:
  string_cmline_token (opt, stat);     {get next command line option name}
  if string_eos(stat) then goto done_opts; {exhausted command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  if (opt.len >= 1) and (opt.str[1] <> '-') then begin {implicit server name token ?}
    string_copy (opt, serv_name);
    goto next_opt;
    end;
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (opt,                {pick command line option name from list}
    '-PORT',
    pick);                             {number of keyword picked from list}
  case pick of                         {do routine for specific option}
{
*   -PORT p
}
1: begin
  string_cmline_token_int (i, stat);
  port := i;
  port_set := true;
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

err_conflict:                          {this option conflicts with a previous opt}
  sys_msg_parm_vstr (msg_parm[1], opt);
  sys_message_bomb ('string', 'cmline_opt_conflict', msg_parm, 1);

parm_bad:                              {jump here on got illegal parameter}
  string_cmline_reuse;                 {re-read last command line token next time}
  string_cmline_token (parm, stat);    {re-read the token for the bad parameter}
  sys_msg_parm_vstr (msg_parm[1], parm);
  sys_msg_parm_vstr (msg_parm[2], opt);
  sys_message_bomb ('string', 'cmline_parm_bad', msg_parm, 2);
{
*   All done reading the command line.
}
done_opts:                             {done with all the command line options}
  tcpopen := false;                    {init to no TCP stream currently open}
  sys_thread_lock_create (wrlock, stat); {create interlock for writing to STDOUT}
  sys_error_abort (stat, '', '', nil, 0);

  if serv_name.len > 0
    then begin                         {have server name, act as client}
      startup_client;
      end
    else begin                         {no server name, become the server}
      startup_server;
      end
    ;
{
*   The TCP connection has been established, and CONN is the connection descriptor.
*   The stream to/from the remote program gets handles the same whether we are a
*   server or a client.  CLIENT and SERVER have been set according to this program's
*   role.
}
  sys_thread_create (                  {start thread for reading input stream}
    addr(thread_in),                   {address of thread root routine}
    0,                                 {argument passed to thread (unused)}
    thid_in,                           {returned thread ID}
    stat);
  sys_error_abort (stat, '', '', nil, 0);
  string_vstring (prompt, ': '(0), -1); {set command prompt string}

loop_cmd:
  sys_wait (0.25);
  lockout;
  string_prompt (prompt);              {prompt the user for a command}
  newline := false;                    {indicate STDOUT not at start of new line}
  unlockout;

  string_readin (buf);                 {get command from the user}
  newline := true;                     {STDOUT now at start of line}
  if buf.len <= 0 then goto loop_cmd;  {ignore blank lines}
  p := 1;                              {init BUF parse index}
  next_keyw (opt, stat);               {extract command name into OPT}
  if sys_error_check (stat, '', '', nil, 0) then begin
    goto loop_cmd;
    end;
  string_tkpick_s (                    {pick command name from list}
    opt, cmdnames, sizeof(cmdnames), pick);
  case pick of                         {which command is it}
{
**********
*
*   HELP
}
1: begin
  if not_eos then goto err_extra;

  lockout;                             {acquire lock for writing to output}
  writeln ('val ... val  -  Send bytes with the indicated values to remote');
  writeln ('QUIT      - Exit the program');
  unlockout;                           {release lock for writing to output}
  end;
{
**********
*
*   QUIT
}
2: begin
  if not_eos then goto err_extra;

  goto leave;
  end;
{
**********
*
*   Unrecognized command, try to interpret as integer values.
}
otherwise
    obufn := 0;                        {make sure output buffer is empty}
    p := 1;                            {reset parse index to get first token again}
loop_ubyte:                            {back here to get each new byte from the user}
    i := next_int (-128, 255, stat);
    if string_eos(stat) then goto got_ubytes;
    if sys_error(stat) then goto err_cmparm;
    if obufn >= last_send_k then begin {buffer already full}
      writeln ('Too many bytes, max allowed is ', last_send_k, '.');
      goto loop_cmd;
      end;
    obuf[obufn] := i;                  {stuff the byte into the buffer}
    obufn := obufn + 1;                {count one more byte in the buffer}
    goto loop_ubyte;                   {back to get the next byte}

got_ubytes:                            {all bytes from command are in the output buffer}
    if obufn <= 0 then goto loop_cmd;  {nothing to send ?}
    if not tcpopen then begin          {no current TCP connection ?}
      lockout;
      writeln ('No TCP stream is open, data not sent.');
      unlockout;
      goto done_cmd;
      end;
    file_write_inetstr (obuf, conn, obufn, stat);
    end;                               {end of command cases}

done_cmd:                              {done processing this command}
  if sys_error(stat) then goto err_cmparm;

  if not_eos then begin                {extraneous token after command ?}
err_extra:
    lockout;
    writeln ('Too many parameters for this command.');
    unlockout;
    end;
  goto loop_cmd;                       {back to process next command}

bad_cmd:                               {unrecognized or illegal command}
  lockout;
  writeln ('Huh?');
  unlockout;
  goto loop_cmd;

err_cmparm:                            {parameter error, STAT set accordingly}
  lockout;
  sys_error_print (stat, '', '', nil, 0);
  unlockout;
  goto loop_cmd;

leave:
  quit := true;                        {tell all threads to shut down}
  if tcpopen then begin
    file_close (conn);                 {close connection to the serial line}
    end;
  end.
