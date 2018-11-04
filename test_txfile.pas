{   TEST_TXFILE <input file name>
*
*   Test text file I/O capability.
*
*   This program reads in a text file, and echos some of the information
*   to standard output and to a different text file.  If the input file
*   name ends in ".pas", ".ftn", or ".sml", then the output file name will
*   be <generic name>_<suffix> ("." replaced by "_").  If the input file
*   name has none of these suffixes, then the output file name will be
*   <input file name>.text.
*
*   The input file will be listed to standard output with line numbers
*   preceeding every line.  Only 5 sequential lines are shown, then 5
*   are skipped.  This pattern is repeated to the end of the file.
*   All input text past column 43 is ignored and not listed.
*
*   The save information as listed to standard output is also written to
*   the output file.  Some additional lines are added to the end of the
*   output file that are not show to standard output.  After the end of the
*   input file is reached, the input file is positioned back to the start.
*   The first line read after position to start of file is written to the
*   output file.  The file is then positioned to a position saved before
*   line 3 was read earlier.  The next line read is then written to the
*   output file.  The input file is then positioned to its end and a check
*   is made that EOF status is returned on the next read.
}
program test_txfile;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';

const
  n_write = 5;                         {number of consecutive lines to write}
  n_skip = 5;                          {number of consecutive lines to skip}
  in_width = 43;                       {max input line characters to read}
  pos_line = 3;                        {line number to position back to}
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  in_fnam,                             {raw input file name}
  out_fnam:                            {output file name}
    %include '(cog)lib/string_treename.ins.pas';
  in_conn: file_conn_t;                {input file connection handle}
  out_conn: file_conn_t;               {output file connection handle}
  token:                               {scratch token for number conversion}
    %include '(cog)lib/string16.ins.pas';
  in_lnum: sys_int_machine_t;          {input file line number}
  ibuf, obuf:                          {input and output line buffers}
    %include '(cog)lib/string80.ins.pas';
  ext: string;                         {output file name extension string}
  write_cnt: sys_int_machine_t;        {number of consecutive lines written}
  pos: file_pos_t;                     {position handle for line number POS_LINE}
  stat: sys_err_t;                     {error status code}
  msg_parms:                           {parameters to messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

label
  next_read, eof;

begin
  string_cmline_init;                  {init for command line processing}
  string_cmline_token (in_fnam, stat); {get input file name from command line}
  string_cmline_req_check (stat);      {this command line argument is mandatory}
  string_cmline_end_abort;             {no more tokens are allowed on command line}

  file_open_read_text (in_fnam, '.pas .ftn .sml ""', in_conn, stat);
  sys_msg_parm_vstr (msg_parms[1], in_fnam);
  sys_error_abort (stat, 'file', 'open_input_read_text', msg_parms, 1);
  string_copy (in_conn.gnam, out_fnam); {init output file name}

  case in_conn.ext_num of              {which file name extension got used ?}
1:  begin                              {.pas}
      string_appends (out_fnam, '_pas');
      ext := '';
      end;
2:  begin                              {.ftn}
      string_appends (out_fnam, '_ftn');
      ext := '';
      end;
3:  begin                              {.sml}
      string_appends (out_fnam, '_sml');
      ext := '';
      end;
4:  begin
      ext := '.text';
      end;
otherwise
    writeln ('Bad IN_CONN.EXT_NUM value of ', in_conn.ext_num);
    sys_bomb;
    end;

  file_open_write_text (out_fnam, ext, out_conn, stat);
  sys_msg_parm_vstr (msg_parms[1], out_fnam);
  sys_error_abort (stat, 'file', 'open_output_write_text', msg_parms, 1);
{
*   Input and output files are open.
}
  in_lnum := 0;                        {number of last line read from input file}
  ibuf.max := min(ibuf.max, in_width);
  write_cnt := 0;                      {init number of lines written in block}

next_read:                             {back here to read next input line}
  in_lnum := in_lnum + 1;              {make number of line about to read}
  if in_lnum = pos_line then begin     {remember how to get back to this line ?}
    file_pos_get (in_conn, pos);       {get position handle for this line}
    end;
  file_read_text (in_conn, ibuf, stat);
  if file_eof(stat) then goto eof;     {hit end of input file ?}
  sys_error_abort (stat, 'file', 'read_input_text', nil, 0);
  string_f_int (token, in_lnum);
  obuf.len := 0;                       {init output buffer to empty}
  string_appendn (obuf, '     ', 5-token.len);
  string_append (obuf, token);
  string_appendn (obuf, '  ', 2);
  string_append (obuf, ibuf);
  writeln (obuf.str:obuf.len);         {write output line to user}
  file_write_text (obuf, out_conn, stat);
  sys_error_abort (stat, 'file', 'write_output_text', nil, 0);

  write_cnt := write_cnt + 1;          {one more consecutive line written}
  if write_cnt >= n_write then begin   {need to skip some lines ?}
    file_skip_text (in_conn, n_skip, stat); {skip over input lines}
    if file_eof(stat) then goto eof;   {hit end of input file ?}
    sys_error_abort (stat, 'file', 'skip_input_text', nil, 0);
    in_lnum := in_lnum + n_skip;       {keep input line counter up to date}
    write_cnt := 0;                    {reset number of consecutive lines written}
    end;                               {done skipping over input lines}
  goto next_read;                      {back and read next input line}
{
*   End of input file has been encountered.
}
eof:
  file_pos_start (in_conn, stat);
  sys_error_abort (stat, 'file', 'pos_bof', nil, 0);
  file_read_text (in_conn, obuf, stat);
  if sys_error_check(stat, 'file', 'read_input_text', nil, 0) then begin
    writeln ('Trying to re-read first line of input file.');
    sys_bomb;
    end;
  file_write_text (obuf, out_conn, stat);
  if sys_error_check(stat, 'file', 'write_output_text', nil, 0) then begin
    writeln ('Trying to re-write first input line to output file.');
    sys_bomb;
    end;
  file_pos_set (pos, stat);
  sys_error_abort (stat, 'file', 'pos_set', nil, 0);
  file_read_text (in_conn, obuf, stat);
  if sys_error_check(stat, 'file', 'read_input_text', nil, 0) then begin
    writeln ('Trying to re-read special line from input file.');
    sys_bomb;
    end;
  file_write_text (obuf, out_conn, stat);
  if sys_error_check(stat, 'file', 'write_output_text', nil, 0) then begin
    writeln ('Trying to re-write special input line to output file.');
    sys_bomb;
    end;
  file_pos_end (in_conn, stat);
  sys_error_abort (stat, 'file', 'pos_eof', nil, 0);
  file_read_text (in_conn, ibuf, stat);
  if not file_eof(stat) then begin
    writeln ('EOF not encountered after position to EOF.');
    end;

  file_close (in_conn);                {close input file}
  file_close (out_conn);               {truncate and close output file}
  end.
