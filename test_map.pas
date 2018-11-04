{   Program TEST_MAP
*
*   Test mapped file access routines.
}
program test_map;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';

const
  file_name = 'X';                     {name of file used for testing}
  max_size = 17382;                    {max mapped file size}
  max_handles = 5;                     {number of simultaneous handles to retain}
  max_msg_parms = 3;                   {max parameters we can pass to a message}

  max_ind = max_size - 1;              {max DATA array index}

type
  data_ar_t = array[0..sys_arr_size_index_k] of char; {template for mapped data}
  data_ar_p_t = ^data_ar_t;            {pointer to mapped data}

var
  conn: file_conn_t;                   {connection handle to mapped file}
  data:                                {our local copy of file data values}
    array[0..max_ind] of char;
  di: sys_int_machine_t;               {index into DATA array}
  len_file_orig: sys_int_adr_t;        {original file length when opened}
  len_file: sys_int_adr_t;             {current file length}
  rw_file: file_rw_t;                  {access mode file opened with}
  map_p: data_ar_p_t;                  {pointer to start of current mapped region}
  ofs: sys_int_adr_t;                  {offset of this mapped region}
  len_map: sys_int_adr_t;              {length of this mapped region}
  rw: file_rw_t;                       {read/write access to current mapped region}
  n_handles: sys_int_machine_t;        {number of handles currently retained}
  h: sys_int_machine_t;                {HANDLE index for current handle}
  handle:                              {most recently used mapped region handles}
    array[1..max_handles] of file_map_handle_t;
  i: sys_int_machine_t;                {scratch integer}
  j: sys_int_adr_t;                    {scratch address or offset}
  count_map: sys_int_machine_t;        {count of mapping operations verified}
  fnam:
    %include '(cog)lib/string_treename.ins.pas';
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;

label
  loop;
{
*******************************************************
*
*   Local function RAND(MINVAL,MAXVAL)
*
*   Return a pseudo-random integer value.  The value will be >= MINVAL
*   and <= MAXVAL.
}
function rand (
  in      minval: sys_int_machine_t;   {minimum value for the random number}
  in      maxval: sys_int_machine_t)   {maximum value for the random number}
  :sys_int_machine_t;                  {returned random number}
  val_param;

const
  n_rand = 7;                          {number of random numbers in table}
  rand_max = n_rand - 1;               {max RAND_AR array index}

var
  rand_ar:
    static array[0..rand_max] of sys_int_machine_t := [
      16#F5C80F9B, 16#0D20F8E2, 16#1FD5A102, 16#A5593E2A,
      16#FC729FFC, 16#DC6BB1A4, 16#BBF7A406];
  r: sys_int_machine_t;                {random number accumulator}
  i: sys_int_machine_t;                {scratch integer and loop counter}

begin
  if maxval <= minval then begin
    rand := minval;
    return;
    end;
  r := rand_ar[rand_max];
  for i := rand_max downto 1 do begin  {add up and shift numbers in random array}
    r := r + rand_ar[i-1];
    rand_ar[i] := r;
    end;
  rand_ar[0] := rand_ar[0] + rshft(r, 8);
  r := r & lastof(r);                  {make sure R is positive}
  rand :=                              {make final value within requested range}
    minval + (r mod (maxval - minval + 1));
  end;
{
*******************************************************
*
*   Local subroutine PROCESS_MAP_COUNT
}
procedure process_map_count;

begin
  if count_map = 0 then return;
  writeln (count_map:4, ' mapped.');
  count_map := 0;
  end;
{
*******************************************************
*
*   Start of main routine.
}
begin
  string_vstring (fnam, file_name, sizeof(file_name)); {put file name in FNAM}
  file_delete_name (fnam, stat);       {delete file, if exists}

  len_file_orig := 0;                  {init original file length}
  len_file := 0;                       {init current file length}
  rw_file := [file_rw_read_k, file_rw_write_k]; {read/write mode for first time}
  file_open_map (                      {open mapped file for the first time}
    fnam, '',                          {file name and suffix}
    rw_file,                           {access needed}
    conn,                              {returned connection handle}
    stat);
  sys_error_abort (stat, '', '', nil, 0);
  n_handles := 0;                      {init number of active mapped region handles}
  h := 1;                              {init HANDLE index to current handle}
  count_map := 0;                      {init count of regions mapped}

loop:                                  {back here for each new random operation}
  i := rand(0, 99);                    {get random number to decide what to do}
  if len_file <= 0 then i := 0;        {always extend file when it is empty}
  case i of                            {decide what operation to perform}
{
*********************************
*
*   Make the file longer.
}
0: begin
  if not (file_rw_write_k in rw_file)  {no write access to file ?}
    then goto loop;
  process_map_count;
  h := h + 1;                          {make HANDLE index to next handle to use}
  if h > max_handles
    then h := 1;
  if n_handles >= max_handles then begin {all handles currently in use ?}
    file_map_done (handle[h]);         {close old use of this handle}
    n_handles := n_handles - 1;        {one less active handle}
    end;
  len_map := rand(1, max_size - len_file); {amount to increase file size by}

  if len_file < len_file_orig then begin {mapping starts within old file ?}
    len_map :=                         {truncate mapping to stay within old file}
      min(len_map, len_file_orig - len_file);
    end;

  writeln ('Extend to length ', len_file + len_map);

  file_map (                           {create mapped region at end of file}
    conn,                              {connection handle}
    len_file,                          {start region right after end of file}
    len_map,                           {length of new region to map}
    [file_rw_write_k],                 {read/write acces to mapped region}
    map_p,                             {returned pointer to start of region}
    j,                                 {actual length of mapped region}
    handle[h],                         {handle to this mapped region}
    stat);
  if sys_error(stat) then begin        {FILE_MAP failed ?}
    j := len_file + len_map;           {new desired file length}
    sys_msg_parm_int (msg_parm[1], len_map);
    sys_msg_parm_int (msg_parm[2], len_file);
    sys_msg_parm_int (msg_parm[3], j);
    sys_error_abort (stat, 'file', 'test_map_err_extend', msg_parm, 3);
    end;

  di := len_file;                      {DATA array index for copy of region start}
  n_handles := n_handles + 1;          {one more handle is now in use}
  len_file := len_file + len_map;      {update our record of file length}

  for i := 0 to len_map-1 do begin     {once for each address to write to}
    data[di] := chr(rand(0, 255));     {get value and save in our data array}
    map_p^[i] := data[di];             {write value to file}
    di := di + 1;                      {update index to our data array}
    end;                               {back to do next location in file}
  end;
{
*********************************
*
*   Make the file smaller.
}
1: begin
  if not (file_rw_write_k in rw_file)  {no write access to file ?}
    then goto loop;
  process_map_count;

  len_file := rand(0, len_file);       {pick a new file length}

  writeln ('Truncate to length ', len_file);

  file_map_truncate (conn, len_file);  {truncate file to this new length}
  end;
{
*********************************
*
*   Close file and re-open it.
}
2: begin
  process_map_count;
  file_close (conn);                   {close the file}
  case rand(0, 2) of                   {pick a random read/write access}
0: rw_file := [file_rw_read_k];
1: rw_file := [file_rw_write_k];
2: rw_file := [file_rw_read_k, file_rw_write_k];
    end;
  if len_file < 10 then begin          {always allow writing when file is very short}
    rw_file := rw_file + [file_rw_write_k];
    end;

  writeln;
  write ('Re-open, access =');
  if file_rw_read_k in rw_file
    then write (' READ');
  if file_rw_write_k in rw_file
    then write (' WRITE');
  writeln;

  file_open_map (fnam, '', rw_file, conn, stat);
  sys_error_abort (stat, '', '', nil, 0);
  n_handles := 0;
  len_file_orig := file_map_length(conn); {get length of file}
  if len_file_orig <> len_file then begin
    sys_msg_parm_int (msg_parm[1], len_file);
    sys_msg_parm_int (msg_parm[2], j);
    sys_message_bomb ('file', 'test_map_len', msg_parm, 2);
    end;
  end;
{
*********************************
*
*   Map a region of the file and access it.
}
otherwise
  count_map := count_map + 1;          {count one more mapped region accessed}
  rw := rw_file;                       {init access mode from file access mode}
  if rw_file >= [file_rw_read_k, file_rw_write_k] then begin {both modes allowed ?}
    case rand(0, 2) of                 {pick a random read/write access}
0:    rw := [file_rw_read_k];
1:    rw := [file_rw_write_k];
2:    rw := [file_rw_read_k, file_rw_write_k];
      end;
    end;                               {RW is set to read/write mode for this region}

  ofs := rand(0, len_file - 1);        {pick where region is to start}
  len_map := rand(1, len_file - ofs);  {pick size of region}
  if                                   {this region would cross old file length ?}
      (ofs < len_file_orig) and        {region starts within old file ?}
      ((ofs + len_map) > len_file_orig) {region ends after old file ?}
      then begin
    len_map := len_file_orig - ofs;    {truncate region to fit within old file}
    end;

  h := h + 1;                          {make HANDLE index to next handle to use}
  if h > max_handles
    then h := 1;
  if n_handles >= max_handles then begin {all handles currently in use ?}
    file_map_done (handle[h]);         {close old use of this handle}
    n_handles := n_handles - 1;        {one less active handle}
    end;

  file_map (                           {map the region}
    conn,                              {connection handle}
    ofs, len_map,                      {start and length of region}
    rw,                                {read/write access required}
    map_p,                             {returned pointer to start of region}
    j,                                 {length actually mapped}
    handle[h],                         {handle to this mapping}
    stat);
  if sys_error(stat) then begin        {FILE_MAP failed ?}
    sys_msg_parm_int (msg_parm[1], ofs);
    j := ofs + len_map - 1;            {last address of attempted mapping}
    sys_msg_parm_int (msg_parm[2], j);
    sys_msg_parm_int (msg_parm[3], len_map);
    sys_error_abort (stat, 'file', 'test_map_err_map', msg_parm, 3);
    end;

  n_handles := n_handles + 1;          {one more mapping handle is in use}

  if file_rw_read_k in rw then begin   {are we allowed to read the mapped region ?}
    di := ofs;                         {init DATA array index}
    for i := 0 to len_map-1 do begin   {loop over data in mapped region}
      if map_p^[i] <> data[di] then begin {file contents doesn't agree with array ?}
        sys_msg_parm_int (msg_parm[1], di);
        sys_msg_parm_int (msg_parm[2], ord(data[di]));
        sys_msg_parm_int (msg_parm[3], ord(map_p^[i]));
        sys_message_bomb ('file', 'test_map_err_data', msg_parm, 3);
        end;
      di := di + 1;                    {advance index into data array}
      end;                             {back and check next value}
    end;                               {done reading mapped region}

  if file_rw_write_k in rw then begin  {are we allowed to write mapped region ?}
    di := ofs;                         {init DATA array index}
    for i := 0 to len_map-1 do begin   {loop over data in mapped region}
      data[di] := chr(rand(0, 255));   {get random value for this location}
      map_p^[i] := data[di];           {write value to file}
      di := di + 1;                    {advance index into data array}
      end;                             {back and write next value}
    end;                               {done writing to mapped region}

    end;                               {end of randomly chosen operation cases}
  goto loop;                           {back for another random operation}
  end.
