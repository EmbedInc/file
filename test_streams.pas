{   Program TEST_STREAMS
*
*   Program to test FILE library system stream I/O.  This program will
*   write its command line arguments and standard input stream to
*   standard output with annotation.  The same output is also written
*   to file /tmp/test_streams.
}
program test_streams;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  conn_in: file_conn_t;                {standard input connection handle}
  conn_out: file_conn_t;               {standard output connection handle}
  conn_log: file_conn_t;               {connection handle to log file}
  fnam_log: string_var32_t :=          {log file name}
    [str := '/tmp/test_streams', len := 17, max := sizeof(fnam_log.str)];
  ibuf, obuf:                          {input and output buffers}
    %include '(cog)lib/string132.ins.pas';
  token:                               {scratch token for number conversion}
    %include '(cog)lib/string32.ins.pas';
  n: sys_int_machine_t;                {args/lines counter}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

label
  loop_arg, done_args, loop_line, done_lines;
{
******************************************
*
*   Local subroutine WRIT
*
*   Write the contents of OBUF to standard output and the log file.
*   OBUF is reset to empty.
}
procedure writ;

var
  stat: sys_err_t;

begin
  file_write_text (obuf, conn_out, stat); {write line to standard output}
  sys_error_abort (stat, 'file', 'write_stdout_text', nil, 0);
  file_write_text (obuf, conn_log, stat); {write line to log file}
  sys_error_abort (stat, 'file', 'write_output_text', nil, 0);
  obuf.len := 0;
  end;
{
******************************************
*
*   Start of main routine.
}
begin
  file_open_stream_text (              {connect to standard input}
    sys_sys_iounit_stdin_k,            {stream ID to connect to}
    [file_rw_read_k],                  {read/write mode}
    conn_in,                           {returned connection handle}
    stat);
  sys_error_abort (stat, 'file', 'open_stdin', nil, 0);

  file_open_stream_text (              {connect to standard output}
    sys_sys_iounit_stdout_k,           {stream ID to connect to}
    [file_rw_write_k],                 {read/write mode}
    conn_out,                          {returned connection handle}
    stat);
  sys_error_abort (stat, 'file', 'open_stdout', nil, 0);

  file_open_write_text (               {open log output file}
    fnam_log, '',                      {file name and suffix}
    conn_log,                          {returned connection handle}
    stat);
  sys_msg_parm_vstr (msg_parm[1], fnam_log);
  sys_error_abort (stat, 'file', 'open_output_write_text', msg_parm, 1);
{
*   Done opening connections to standard input, standard output, and
*   the log file.
}
  string_cmline_init;                  {init for command line processing}
  n := 0;                              {init number of command line arguments}
  string_vstring (obuf, 'Command line arguments:'(0), -1);
  writ;

loop_arg:                              {back here each new command line argument}
  string_cmline_token (ibuf, stat);    {get next command line argument}
  if string_eos(stat) then goto done_args; {hit end of command line arguments list ?}
  n := n + 1;                          {make number of this command line argument}
  sys_msg_parm_int (msg_parm[1], n);
  sys_error_abort (stat, 'string', 'cmline_arg_error', msg_parm, 1);
  string_f_intrj (token, n, 4, stat);  {make argument number string}
  sys_error_abort (stat, '', '', nil, 0);
  string_append (obuf, token);         {assemble output line}
  string_appendn (obuf, ': "', 3);
  string_append (obuf, ibuf);
  string_append1 (obuf, '"');
  writ;                                {write output line}
  goto loop_arg;                       {back for next command line argument}
done_args:                             {done with all the command line arguments}

  n := 0;                              {init number of lines from standard input}
  string_vstring (obuf, 'Standard input:'(0), -1);
  writ;

loop_line:                             {back here for each new line from stdin}
  file_read_text (conn_in, ibuf, stat); {read next line from standard input}
  if file_eof(stat) then goto done_lines; {hit end of standard input stream ?}
  n := n + 1;                          {make number of this input line}
  sys_error_abort (stat, 'file', 'read_stdin', nil, 0);
  string_f_intrj (token, n, 4, stat);  {make line number string}
  sys_error_abort (stat, '', '', nil, 0);
  string_append (obuf, token);         {assemble output line}
  string_appendn (obuf, ': "', 3);
  string_append (obuf, ibuf);
  string_append1 (obuf, '"');
  writ;                                {write output line}
  goto loop_line;
done_lines:                            {all done handling standard input lines}

  file_close (conn_in);
  file_close (conn_out);
  file_close (conn_log);
  end.
