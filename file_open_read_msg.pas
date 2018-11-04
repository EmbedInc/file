{   Subroutine FILE_OPEN_READ_MSG (GNAM,MSG,PARMS,N_PARMS,CONN,STAT)
*
*   Open a connection to a particular message in a .msg message file.
*
*   GNAM
*     Generic name of message file.
*
*   MSG
*     Name of message within message file.  Message files are environment files
*     and therefore will be searched for in the environment directories list.
*     The .msg files will be read in local to global order.  The first message
*     encountered that matches the requirements will be used.
*
*   PARMS
*     List of pointers to parameters.  These parameters are referenced
*     in the text of the message.  The parameter values will be inserted
*     into the final message text.
*
*   N_PARMS
*     Number of parameters referenced in PARMS.
*
*   CONN
*     Handle to this connection to this message.  Must be supplied to
*     all future calls that refer to the connection opened here.
*
*   STAT
*     Completion status code.  Set to NOT FOUND if message files or message
*     could not be found.
}
module file_OPEN_READ_MSG;
define file_open_read_msg;
%include 'file2.ins.pas';

var
  cmd_msg: string_var16_t :=           {name of .msg file MSG command}
    [str := 'MSG', len := 3, max := sizeof(cmd_msg.str)];
  cmd_msg_lan: string_var16_t :=       {name of LAN subcommand to MSG command}
    [str := 'LAN', len := 3, max := sizeof(cmd_msg_lan.str)];

procedure file_open_read_msg (         {init for reading a message from .msg files}
  in      gnam: univ string_var_arg_t; {generic name of message file}
  in      msg: univ string_var_arg_t;  {message name withing subsystem file}
  in      parms: univ sys_parm_msg_ar_t; {array of parameter descriptors}
  in      n_parms: sys_int_machine_t;  {number of parameters in PARMS}
  out     conn: file_conn_t;           {handle to connection to this message}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  data_p: file_msg_data_p_t;           {pointer to our private data}
  pick: sys_int_machine_t;             {number of token picked from list}
  token: string_var80_t;               {token parsed from .msg file}
  lang_name: string_var80_t;           {name of language actually used}
  in_msg: boolean;                     {TRUE if reading our message}
  in_lang: boolean;                    {TRUE if in our language in our message}

label
  msg_loop, msg_lan_next, msg_lan_done, abort1, abort2;
{
*************************************************************
*
*   Local subroutine SYN_ERROR
*
*   A syntax error was detected while parsing a .msg file line.
*   Print message identifying the line and bomb.
}
procedure syn_error;

var
  buf: string_var132_t;                {message output buffer}
  token: string_var8192_t;             {scratch token for integer conversion}

begin
  buf.max := sizeof(buf.str);          {init var strings}
  token.max := sizeof(token.str);

  buf.len := 0;
  string_appends (buf, 'Syntax error occurred on line');
  string_append1 (buf, ' ');
  string_f_int (token, data_p^.conn.lnum);
  string_append (buf, token);
  string_appends (buf, ' of file');
  string_append1 (buf, ' ');
  string_append (buf, data_p^.conn.tnam);
  writeln (buf.str:buf.len);
  sys_bomb;
  end;
{
*************************************************************
*
*   Start of main routine.
}
begin
  token.max := sizeof(token.str);      {init var strings}
  lang_name.max := sizeof(lang_name.str);
  conn.fnam.max := sizeof(conn.fnam.str);
  conn.gnam.max := sizeof(conn.gnam.str);
  conn.tnam.max := sizeof(conn.tnam.str);
  sys_error_none (stat);               {init to no error}

  sys_mem_alloc (sizeof(data_p^), data_p); {grab memory for our private data}
  sys_mem_error (data_p, '', '', nil, 0);

  with data_p^: d do begin
{
*   D is abbreviation for our private data block for this connection.
}
  file_open_read_env (                 {open .msg environment file set for read}
    gnam,                              {generic environment file name}
    '.msg',                            {environment file name extension}
    false,                             {read files in local to global order}
    d.conn,                            {returned connection handle}
    stat);
  if sys_error(stat) then goto abort2;
{
*   Message file set opened successfully.
*
*   Fill in static fields in user-visible connection handle.
}
  conn.rw_mode := [file_rw_read_k];
  conn.obty := file_obty_msg_k;
  conn.fmt := file_fmt_text_k;
  conn.ext_num := 0;
  conn.data_p := data_p;
  conn.close_p := addr(file_close_msg);
{
*   Init our private data for this connection.
}
  d.msg.max := sizeof(d.msg.str);      {init var strings}
  d.buf.max := sizeof(d.buf.str);

  string_copy (msg, d.msg);            {message name within message file}
  string_upcase (d.msg);               {message names are case-insensitive}
  d.parms_p := addr(parms);            {pointer to parameter pointers array}
  d.n_parms := n_parms;                {number of parameters}
  sys_langp_curr_get (d.lang_p);       {get pointer to current language}
  d.eof := false;                      {init to end of message not found yet}
  d.flow := true;                      {init text flow ON}

  in_msg := false;                     {init to not within our message}
  in_lang := false;                    {not within our language in our message}
{
*   Loop back here for each new line from message files until we get to the
*   text for our message in our language.
}
msg_loop:                              {back here each new line until message start}
  file_read_env (                      {read next line from message file set}
    d.conn,                            {connection handle to .msg file set}
    d.buf,                             {returned line of text}
    stat);
  if file_eof(stat) then begin         {end of message file set ?}
    sys_stat_set (file_subsys_k, file_stat_not_found_k, stat);
    sys_stat_parm_vstr (gnam, stat);
    string_vstring (token, '.msg', 4);
    sys_stat_parm_vstr (token, stat);
    goto abort1;
    end;
  if sys_error(stat) then goto abort1;
  d.p := 1;                            {init parse index into BUF}
  while d.buf.str[d.p] = ' ' do begin  {find column where first token starts}
    d.p := d.p + 1;
    end;
  case d.p of                          {what column does first token start in ?}
{
*   BUF contains a top level .msg file command.
}
1: begin
  in_msg := false;                     {init to not in our message}
  string_token (d.buf, d.p, token, stat); {extract command name}
  if sys_error(stat) then syn_error;
  string_upcase (token);               {make upper case for token matching}
  if not string_equal(token, cmd_msg)  {unknown top level command ?}
    then goto msg_loop;
  string_token (d.buf, d.p, token, stat); {extract message name}
  if string_eos(stat) then begin
    writeln ('Missing message name after MSG command.');
    syn_error;
    end;
  if sys_error(stat) then syn_error;
  string_upcase (token);               {make upper case for comparison}
  in_msg := string_equal(token, d.msg); {set flag if this is our message}
  end;                                 {done with top level command case}
{
*   BUF contains a subcommand within the current top level command.
}
3: begin
  if not in_msg then goto msg_loop;    {not within our message ?}
  string_token (d.buf, d.p, token, stat); {extract subcommand name}
  if sys_error(stat) then syn_error;
  string_upcase (token);               {make upper case for token matching}
  if not string_equal(token, cmd_msg_lan) {unknown subcommand ?}
    then goto msg_loop;
  string_token (d.buf, d.p, lang_name, stat); {extract language name}
  if string_eos(stat) then begin
    writeln ('Missing language name after LAN sub-command');
    syn_error;
    end;
  if sys_error(stat) then syn_error;
  string_upcase (lang_name);           {make upper case for comparison}
  in_lang := string_equal(lang_name, d.lang_p^.name); {TRUE if explicitly our language}

msg_lan_next:                          {back here next LAN subcommand option}
  string_token (d.buf, d.p, token, stat); {get next token on LAN command line}
  if string_eos(stat) then goto msg_lan_done; {done processing all LAN options ?}
  if sys_error(stat) then syn_error;
  string_upcase (token);               {make upper case for token matching}
  string_tkpick80 (token,              {pick option name from list}
    '-DEF',
    pick);                             {number of token picked from list}

  case pick of
1:  begin                              {-DEF}
      in_lang := true;                 {definately in our language now}
      end;
otherwise
    writeln ('Unrecognized LAN command option "', token.str:token.len, '".');
    syn_error;
    end;                               {end of LAN command option cases}

  goto msg_lan_next;                   {back to process next LAN command option}
msg_lan_done:                          {jump here after processing all options}
  end;                                 {done with .msg file subcommand case}
{
*   First token on .msg file line started at an illegal column.
}
2, 4: begin
  writeln ('Illegal starting column for text.');
  syn_error;
  end;
{
*   This line contains message text, but not for our message and language.
}
otherwise
    goto msg_loop;                     {ignore line}
    end;                               {done with .msg file line type cases}
{
*   The input line contained information we parsed and understood.
}
  string_token (d.buf, d.p, token, stat); {check for dangling token on line}
  if not string_eos(stat) then begin   {there was another token ?}
    writeln ('Too many tokens.  First excess token is "', token.str:token.len, '".');
    syn_error;
    end;
  if sys_error(stat) then goto abort1;
  if not in_lang then goto msg_loop;   {not start of our message text ?}
{
*   We are positioned so that the next line from the message files is the
*   first line of the message text we will actually use.
}
  string_copy (d.conn.fnam, conn.fnam); {copy current state to user connection handle}
  string_copy (d.conn.gnam, conn.gnam);
  string_copy (d.conn.tnam, conn.tnam);
  conn.lnum := d.conn.lnum;

  sys_langp_get (lang_name, d.lang_p); {pnt to data about language of this message}
  d.buf.len := 0;                      {init to no pending unused message text}
  d.p := 1;
  return;                              {normal return}

abort1:                                {close msg files, deallocate mem, and leave}
  file_close (d.conn);                 {close msg files}

abort2:                                {deallocate mem and leave}
  sys_mem_dealloc (data_p);            {deallocate our private data block}
  end;                                 {done with D abbreviation}
  end;
