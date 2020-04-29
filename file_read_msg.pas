{   Subroutine FILE_READ_MSG (CONN, WIDTH, BUF, STAT)
*
*   Read the next line from the message indicated by CONN.  WIDTH is the line
*   width for text-flow, if enabled.  The message text will be returned in BUF.
}
module file_READ_MSG;
define file_read_msg;
%include 'file2.ins.pas';

procedure file_read_msg (              {read next line of a message from .msg file}
  in out  conn: file_conn_t;           {handle to connection to this message}
  in      width: sys_int_machine_t;    {max width to text-flow into}
  in out  buf: univ string_var_arg_t;  {returned line of message text}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  data_p: file_msg_data_p_t;           {pointer to private data for this connection}
  olen: sys_int_machine_t;             {output buffer length}
  cn: sys_int_machine_t;               {size of current chunk}
  i: sys_int_machine_t;                {loop counter}
  padn: string_index_t;                {size of blank pad between chunks}
  end_msg: boolean;                    {TRUE if hit end of input mesage}
  oldflow: boolean;                    {local copy of previous FLOW flag}

  conn_p: file_conn_p_t;               {pointer to arg for compiler bug}

label
  chunk_loop, leave;
{
**************************************************************
*
*   Local subroutine SYN_ERROR
*
*   A syntax error was found.  Print the file name and line number where it
*   occurred.
}
procedure syn_error;
  internal;

var
  token: string_var32_t;               {token for int/string conversion}
  msg: string_treename_t;              {output message buffer}

begin
  token.max := sizeof(token.str);      {init var strings}
  msg.max := sizeof(msg.str);

  msg.len := 0;
  string_appends (msg, 'Error on line');
  string_append1 (msg, ' ');
  string_f_int (token, data_p^.conn.lnum);
  string_append (msg, token);
  string_appends (msg, ' of file');
  writeln (msg.str:msg.len);
  writeln (data_p^.conn.tnam.str:data_p^.conn.tnam.len);
  end;
{
**************************************************************
*
*   Local subroutine TRANSLATE (IBUF, OBUF)
*
*   Translate the raw .msg file line in IBUF to the printable output in OBUF.
*   If a syntax error is encountered, a message will be printed and the
*   remainder of the line aborted.
}
procedure translate (
  in      ibuf: univ string_var_arg_t; {raw input string}
  in out  obuf: univ string_var_arg_t); {translated output string}
  internal;

var
  ibuf_p: string_var_p_t;              {point to call arg for compiler bug}
  p: string_index_t;                   {parse index for IBUF}
  p_start: string_index_t;             {start index of last token for error message}
  ecmd: sys_msg_ecmd_k_t;              {ID of this escape command}
  ecmd_parm: sys_msg_parm_k_t;         {ID of PARM escape subcommand}
  pnum: sys_int_machine_t;             {user's parameter number}
  ival: sys_int_max_t;                 {value of integer parameter}
  i: sys_int_machine_t;                {scratch machine integer}
  token: string_var80_t;               {string expansion of parm value}
  fw: string_index_t;                  {max allowed field width}
  nd: sys_int_machine_t;               {max allowed digits right of decimal point}
  rval: sys_fp_max_t;                  {value of floating point parameter}

label
  next_char, parm_mismatch;
{
********************************
*
*   Local subroutine SYN_ERROR_COLUMN
*
*   Print message about syntax error.  The syntax error occurred at column
*   P_START in string IBUF.
}
procedure syn_error_column;
  internal;

var
  nb: sys_int_machine_t;               {number of blanks before pointer char}

begin
  syn_error;                           {print file name and line number}
  writeln (ibuf_p^.str:ibuf_p^.len);   {print contents of line with error}
  nb := p_start - 1;                   {number of blanks before pointer}
  writeln (' ':nb, '^');               {point to offending character}
  end;
{
********************************
*
*   Local function STR_HERE(BUF, P, STR)
*   This function is local to subroutine TRANSLATE.
*
*   Return TRUE if the string in BUF starting at P is the same as STR.  If
*   so, update P to the next character after the escape sequence.  The characters
*   from BUF will be converted to upper case for sake of the comparison.
}
function str_here (
  in      buf: univ string_var_arg_t;  {input buffer}
  in out  p: string_index_t;           {parse index into BUF}
  in      str: univ string_var_arg_t): {string to compare}
  boolean;                             {TRUE if at string matches sequence}
  val_param; internal;

var
  p2: string_index_t;                  {temp BUF parse index}
  c: string_var4_t;                    {for upcasing characters}

begin
  c.max := sizeof(c.str);              {init var string}
  c.len := 1;

  str_here := false;                   {init to string not here}
  if (buf.len - p + 1) < str.len       {not enough room for string ?}
    then return;
  p2 := p;                             {init temp BUF parse index}
  for i := 1 to str.len do begin       {once for each STR char}
    c.str[1] := buf.str[p2];           {fetch this BUF character}
    string_upcase (c);                 {make upper case for comparison}
    if c.str[1] <> str.str[i]          {not match STR ?}
      then return;
    p2 := p2 + 1;                      {advance BUF index}
    end;                               {back and test next char for esc}
  str_here := true;                    {DID match escape string}
  p := p2;                             {update to first char after ESC sequence}
  end;
{
********************************
*
*   Local subroutine INT_HERE (ABERR, BUF, P, IVAL, STAT)
*   This subroutine is local to TRANSLATE.
*
*   Extract the integer value at the current character position in BUF.  The
*   integer value is returned in IVAL.  P, the BUF parse index, is updated
*   to the first character after the integer.
}
procedure int_here (
  in      aberr: boolean;              {abort on error when TRUE}
  in      buf: univ string_var_arg_t;  {input buffer}
  in out  p: string_index_t;           {parse index into BUF}
  out     ival: sys_int_machine_t;     {returned integer value}
  out     stat: sys_err_t);            {completion status code}
  val_param; internal;

var
  token: string_var32_t;               {scratch token for int/str conversion}

begin
  token.max := sizeof(token.str);      {init var string}
  token.len := 0;                      {init accumulated digits string}

  p_start := p;                        {save starting BUF index for error message}
  while                                {extract all the available 0-9 digits}
      (p <= buf.len) and (buf.str[p] >= '0') and (buf.str[p] <= '9') do begin
    string_append1 (token, buf.str[p]); {append digit onto number string}
    p := p + 1;                        {update parse index to next char}
    end;                               {back and check next BUF character}

  string_t_int (token, ival, stat);    {try convert digits string to integer}
  if sys_error(stat) then begin        {not a legal integer string ?}
    if aberr
      then begin                       {complain about error}
        writeln ('Bad integer "', token.str:token.len, '".');
        syn_error_column;
        end
      else begin                       {pass error to caller silently}
        p := p_start;                  {reset parse index as if nothing read here}
        end
      ;
    end;
  end;
{
********************************
*
*   Start of subroutine TRANSLATE
}
begin
  token.max := sizeof(token.str);      {init var string}
  with data_p^: d do begin             {D is our private data block}

  ibuf_p := addr(ibuf);                {save adr of call arg for compiler bug}
  p := 5;                              {init IBUF parse index}
  d.buf.len := 0;                      {reset output buffer to empty}

next_char:                             {back here to process next IBUF characters}
  if p > ibuf.len then return;         {exhausted input buffer ?}
  if not str_here(ibuf, p, d.lang_p^.msg_esc) then begin {not an escape sequence ?}
    string_append1 (obuf, ibuf.str[p]); {copy this char from input to output}
    p := p + 1;                        {advance input parse index}
    goto next_char;                    {back and to process rest of IBUF}
    end;                               {done handling normal character}
{
*   We just read escape sequence in IBUF.
}
  if str_here(ibuf, p, d.lang_p^.msg_esc) then begin {two escapes in a row ?}
    string_append (obuf, d.lang_p^.msg_esc); {translate to one esc}
    goto next_char;                    {back and to process rest of IBUF}
    end;                               {done handling double escape}

  p_start := p;                        {save char pos for error message}
  for ecmd := firstof(ecmd) to lastof(ecmd) do begin {scan escape commands}
    if not str_here(ibuf, p, d.lang_p^.msg_ecmd[ecmd]) then next;
    case ecmd of
{
*   Escape command PARM.
}
sys_msg_ecmd_parm_k: begin
  int_here (true, ibuf, p, pnum, stat); {get parameter number}
  if sys_error(stat) then goto next_char; {abort command on error}
  if (pnum < 1) or (pnum > d.n_parms) then begin {parameter value out of range}
    writeln ('Parameter number out of range.');
    syn_error_column;
    goto next_char;                    {abort command}
    end;
  p_start := p;                        {save char pos for error message}
  for ecmd_parm := firstof(ecmd_parm) to lastof(ecmd_parm) do begin {subcommands}
    if not str_here(ibuf, p, d.lang_p^.msg_ecmd_parm[ecmd_parm]) then next;
    case ecmd_parm of
{
*   Escape command PARM, subcommand STR.
}
sys_msg_parm_str_k: begin
  case d.parms_p^[pnum].dtype of       {what data type is parameter ?}

sys_msg_dtype_vstr_k: begin            {parm data is a var string}
      string_append (obuf, d.parms_p^[pnum].vstr_p^);
      end;

sys_msg_dtype_str_k: begin             {parm data is a raw string}
      string_appendn (
        obuf,                          {buffer to append to}
        d.parms_p^[pnum].str_p^,       {string to append}
        d.parms_p^[pnum].str_len);     {number of characters in string}
      end;

otherwise                              {incompatible data type}
    goto parm_mismatch;
    end;                               {end of parm data type cases}
  end;                                 {end of PARM STR command}
{
*   Escape command PARM, subcommand INT.
}
sys_msg_parm_int_k: begin
  int_here (false, ibuf, p, i, stat);  {get optional field width value}
  if sys_error(stat)
    then begin                         {no field width string present}
      fw := 0;                         {set to free format}
      end
    else begin                         {we successfully got field width specifier}
      fw := i;
      end
    ;

  case d.parms_p^[pnum].dtype of       {what data type is parameter ?}
sys_msg_dtype_int_k: begin             {parm data is a machine integer}
      ival := d.parms_p^[pnum].int_p^; {fetch integer value}
      end;
otherwise                              {incompatible data type}
    goto parm_mismatch;
    end;                               {end of parm data type cases}

  string_f_int_max_base (              {make string from integer value}
    token,                             {output string}
    ival,                              {input integer}
    10,                                {number base}
    fw,                                {field width}
    [],                                {signed, no leading zeros or plus}
    stat);
  sys_error_none (stat);               {ignore any errors}
  string_append (obuf, token);         {write integer value to output buffer}
  end;                                 {end of PARM INT command}
{
*   Escape command PARM, subcommand FLOAT.
}
sys_msg_parm_float_k: begin
  int_here (true, ibuf, p, i, stat);   {get field width value}
  if sys_error(stat) then goto next_char; {abort command on error}
  fw := i;                             {set field width}

  if  (p > ibuf.len) or else           {end of input buffer ?}
      (ibuf.str[p] <> d.lang_p^.decimal) {not right separator character ?}
      then begin
    p_start := p;                      {set column of syntax error}
    syn_error_column;                  {print info about syntax error position}
    goto next_char;                    {abort this command}
    end;
  p := p + 1;                          {skip over decimal char}

  int_here (true, ibuf, p, i, stat);   {get number of digits right of point}
  if sys_error(stat) then goto next_char; {abort command on error}
  nd := i;                             {set number of digits to right of point}
  case d.parms_p^[pnum].dtype of       {what data type is parameter ?}

sys_msg_dtype_fp1_k: begin             {parm data type is SINGLE}
      rval := d.parms_p^[pnum].fp1_p^; {fetch value}
      end;

sys_msg_dtype_fp2_k: begin             {parm data type is DOUBLE}
      rval := d.parms_p^[pnum].fp2_p^; {fetch value}
      end;

otherwise                              {incompatible data type}
    goto parm_mismatch;
    end;                               {end of parm data type cases}

  string_f_fp (                        {convert floating point value to string}
    token,                             {output string}
    rval,                              {input floating point number}
    fw,                                {total field width}
    0,                                 {no fixed field width for exponent}
    0,                                 {minimum required significant digits}
    fw,                                {max digits allowed left of point}
    nd,                                {min digits required right of point}
    nd,                                {max allowed digits right of point}
    [ string_ffp_exp_eng_k,            {use engineering notation if need exponent}
      string_ffp_group_k],             {group the digits (commas in English)}
    stat);
  sys_error_none (stat);               {we don't care if string conversion failed}
  string_append (obuf, token);         {write floating point value to output buffer}
  end;                                 {end of PARM FLOAT command}
{
*   Escape command PARM, unimplemented subcommand.
}
otherwise
      writeln ('Unimplemented subcommand.');
      syn_error_column;
      end;                             {done with PARM subcommand cases}
    goto next_char;                    {done processing PARM command}
    end;                               {back and test for next PARM subcommand}

  writeln ('Unrecognized subcommand.');
  syn_error_column;
  goto next_char;
  end;                                 {done with PARM escape command case}
{
*   Unimplemented escape command.
}
otherwise
      writeln ('Unimplemented escape command.');
      syn_error_column;
      end;                             {done with escape command cases}
    goto next_char;                    {done processing escape command}
    end;                               {back and test for next escape command}

  writeln ('Unrecognized escape command.');
  syn_error_column;
  goto next_char;

parm_mismatch:                         {jump here if parm data types don't match}
  writeln ('Data type expected in message doesn''t match parameter.');
  syn_error_column;
  goto next_char;
  end;                                 {done with D abbreviation}
  end;
{
**************************************************************
*
*   Local subroutine NEXT_LINE (END_MSG, STAT)
*
*   Read the next message text line from the .msg file set, do any tranlation
*   required, and put the result in DATA_P^.BUF.  END_MSG is set to TRUE
*   if there is no more input message text.
}
procedure next_line (
  out     end_msg: boolean;            {TRUE if hit end of message}
  out     stat: sys_err_t);
  internal;

var
  buf: string_var132_t;                {raw input line buffer}
  p: string_index_t;                   {parse index for BUF}
  i: sys_int_machine_t;                {loop counter}
  cmd: string_var32_t;                 {formatting command name}
  pick: sys_int_machine_t;             {number of token picked from list}
  retnow: boolean;                     {return with current DATA_P^.BUF contents}

label
  read_loop, eof;

begin
  buf.max := sizeof(buf.str);          {init var strings}
  cmd.max := sizeof(cmd.str);
  sys_error_none (stat);               {init to no error}

  with data_p^: d do begin             {D is our private data block}
  if d.eof then goto eof;              {previously hit end of message ?}

  end_msg := false;                    {init to not hit end of message text}
  retnow := false;                     {don't return now with D.BUF contents}

read_loop:                             {back here to read new input line}
  file_read_env (d.conn, buf, stat);   {read next line from .msg file}
  string_copy (d.conn.tnam, conn_p^.tnam); {update user-visible state}
  conn_p^.lnum := d.conn.lnum;
  if file_eof(stat) then goto eof;     {hit end of .msg file set ?}
  if sys_error(stat) then return;      {a real error ?}
  if buf.len < 5 then goto eof;        {can't possibly be message text ?}
  for i := 1 to 4 do begin             {once for each left margin char}
    if buf.str[i] <> ' ' then goto eof; {this is a command line ?}
    end;
{
*   The next raw message text line is sitting in BUF.  Process for commands
*   or translate into DATA_P^.BUF.
}
  if buf.str[5] <> '.' then begin      {just text, no command}
    translate (buf, d.buf);            {translate into output buffer}
    d.p := 1;                          {reset parse index to start of returned buf}
    return;
    end;

  p := 6;                              {set parse index to command name start}
  string_token (buf, p, cmd, stat);    {get command name}
  if sys_error(stat) then begin
    writeln ('Missing command name.');
    syn_error;
    goto read_loop;
    end;
  string_upcase (cmd);                 {make upper case for token matching}
  string_tkpick80 (cmd,
    'FILL NFILL BLANK',
    pick);
  case pick of
{
*   FILL
}
1: begin
  d.flow := true;
  end;
{
*   NFILL
}
2: begin
  if d.flow then begin                 {mode is getting changed ?}
    d.buf.len := 0;                    {don't return chars with mode change}
    retnow := true;                    {return with current D.BUF}
    end;
  d.flow := false;
  end;
{
*   BLANK
*
*   Acts as if a blank input line were read.  Only valid in NFILL mode.
*   Note that input lines can never be blank because these are stripped away
*   by environment file reading layer.
}
3: begin
  d.buf.len := 0;                      {set returned line to empty}
  retnow := true;                      {return with current D.BUF}
  end;
{
*   Unrecognized command.
}
otherwise
    writeln ('Unrecognized command "', cmd.str:cmd.len, '".');
    syn_error;
    goto read_loop;                    {back and process next message text line}
    end;                               {end of command name cases}

  string_token (buf, p, cmd, stat);    {check for dangling token}
  if not string_eos(stat) then begin   {found dangling token ?}
    writeln ('Too many cmds.  First excess cmd is "', cmd.str:cmd.len, '".');
    syn_error;
    end;
  if retnow then begin                 {return with current D.BUF contents ?}
    d.p := 1;                          {reset parse index to start of new string}
    return;
    end;
  goto read_loop;                      {back and process next message text line}

eof:
  end_msg := true;
  d.eof := true;                       {remember we hit end of message}
  end;                                 {done with D abbreviation}
  end;
{
**************************************************************
*
*   Local subroutine NEXT_CHUNK (CN, END_MSG, STAT)
*
*   Return size of next chunk in CN.  END_MSG is set true if the end of message
*   was reached.  The chunk text starts at data_p^.p.
}
procedure next_chunk (
  out     cn: sys_int_machine_t;       {size of next chunk in characters}
  out     end_msg: boolean;            {TRUE if got to end of message}
  out     stat: sys_err_t);
  internal;

var
  p: sys_int_machine_t;                {used to find end of chunk}

label
  find_chunk_start;

begin
  sys_error_none (stat);               {init to no error}
  with data_p^: d do begin             {D is our private data block}

find_chunk_start:                      {back here after read new buffer}
  if d.flow then begin                 {OK to eat blanks ?}
    while (d.p <= d.buf.len) and (d.buf.str[d.p] = ' ') {skip over blanks}
      do d.p := d.p + 1;
    end;

  if d.p > d.buf.len then begin        {exhausted current buffer ?}
    next_line (end_msg, stat);         {get next input line of message text}
    if end_msg or sys_error(stat) then return;
    if d.flow then goto find_chunk_start; {back and find chunk start in new buffer ?}
    end;
{
*   D.P is character index into D.BUF of first character of this chunk.
}
  if d.flow
    then begin                         {text flow is ON}
      p := d.p + 1;                    {init index to search for chunk end}
      while (p <= d.buf.len) and (d.buf.str[p] <> ' ') {scan for end of chunk break}
        do p := p + 1;
      end
    else begin                         {text flow is OFF}
      p := d.buf.len + 1;              {chunk is whole buffer}
      end
    ;
{
*   P is index of one character after end of this chunk.
}
  cn := p - d.p;                       {number of characters in chunk}
  end_msg := false;                    {not hit end of message yet}
  end;                                 {done with D abbreviation}
  end;
{
**************************************************************
*
*   Start of main routine.
}
begin
  data_p := conn.data_p;               {set pointer to our private data block}
  with data_p^: d do begin             {D is our private data block}

  sys_error_none (stat);               {init to no error}
  olen := 0;                           {init number of output chars}
  buf.len := 0;                        {init number of chars passed back}

  conn_p := addr(conn);                {store adr of call arg for copiler bug}

chunk_loop:                            {back here to get each new input chunk}
  oldflow := d.flow;                   {save FLOW flag before getting chunk}
  next_chunk (cn, end_msg, stat);      {find next input chunk of characters}
  if end_msg or sys_error(stat) then goto leave;

  if (oldflow and (not d.flow)) then begin {just transitioned to fixed format ?}
    if olen > 0 then goto leave;       {previous free format string to return ?}
    if cn = 0 then goto chunk_loop;    {no real chunk received, just processed cmd ?}
    end;

  if d.flow and (buf.len > 0) then begin {check for chunk not fit ?}
    case buf.str[buf.len] of           {what char is at current end of line ?}
'.', '?', '!': begin                   {end of sentence punctuation ?}
        padn := 2;                     {pad with two spaces after a sentence}
        end;
otherwise                              {not adding new chunk to end of sentence}
      padn := 1;
      end;
    if (olen + padn + cn) > width then goto leave; {new chunk won't fit ?}
    string_appendn (buf, '  ', padn);  {add padding before new chunk}
    olen := olen + padn;               {account for padding characters}
    end;
{
*   Append this chunk to output buffer.
}
  for i := 1 to cn do begin            {once for each character to copy}
    if buf.len < buf.max then begin    {character will fit in output buffer ?}
      buf.len := buf.len + 1;          {make index of new destination char}
      buf.str[buf.len] := d.buf.str[d.p]; {copy this character}
      end;
    d.p := d.p + 1;                    {advance source char index}
    end;                               {back and copy next character}
  olen := olen + cn;                   {add this chunk size to output size}
  if d.flow then goto chunk_loop;      {try for another chunk if text flow ON}

leave:                                 {common exit point}
  if  end_msg and                      {true user-visible end of message ?}
      (olen = 0) and
      (not sys_error(stat))
    then sys_stat_set (file_subsys_k, file_stat_eof_k, stat);
  end;                                 {done with D abbreviation}
  end;
