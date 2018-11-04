{   Subroutine FILE_OPEN_MAP (NAME, EXT, RW_MODE, CONN, STAT)
*
*   Open a connection to a mapped file.
}
module file_OPEN_MAP;
define file_open_map;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_open_map (              {open system file for mapped access}
  in      name: univ string_var_arg_t; {generic file name}
  in      ext: string;                 {file name extensions, separated by blanks}
  in      rw_mode: file_rw_t;          {intended read/write access}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

const
  pool_size_k = 2**20;                 {size of pool for file mapping memory}
  pool_max_chunk_k = pool_size_k div 8; {max size of block to allocate from pool}

var
  mem_p: util_mem_context_p_t;         {points to context for all our dynamic memory}
  data_p: file_map_data_p_t;           {points to our private data for connection}
  info: file_info_t;                   {extra information about this file}
  i: sys_int_machine_t;                {scratch integer and loop counter}
  rw: file_rw_t;                       {read/write mode for sequential file}

label
  abort2, abort;
{
***************************************************
*
*   Local subroutine INIT_MAPPING
*
*   Do more initialization that is dependent on the underlying mechanism.
*   The body of this routine is in an include file so that it can be
*   customized per OS without the rest of FILE_OPEN_MAP needing to be
*   customized.  STAT is already assumed to indicate no error.
*
*   The main line of decent assumes no OS ability to do any file mapping,
*   and just returns.
}
procedure init_mapping;

%include 'file_open_map.ins.pas';
{
***************************************************
*
*   Start of main routine.
}
begin
  util_mem_context_get (util_top_mem_context, mem_p); {create our memory context}
  util_mem_grab (                      {allocate memory for private data block}
    sizeof(data_p^),                   {amount of memory to allocate}
    mem_p^,                            {parent memory context}
    false,                             {we will not individually deallocate this}
    data_p);                           {returned pointer to start of new memory}

  rw := rw_mode + [file_rw_read_k];    {we always need read access}
  file_open_bin (name, ext, rw, data_p^.conn, stat);
  if sys_error(stat) then goto abort;
{
*   The file was opened successfully.  Now fill in the connection handle.
}
  conn.rw_mode := rw_mode;
  conn.obty := file_obty_map_k;
  conn.fmt := file_fmt_bin_k;
  conn.fnam.max := sizeof(conn.fnam.str);
  string_copy (data_p^.conn.fnam, conn.fnam);
  conn.gnam.max := sizeof(conn.gnam.str);
  string_copy (data_p^.conn.gnam, conn.gnam);
  conn.tnam.max := sizeof(conn.tnam.str);
  string_copy (data_p^.conn.tnam, conn.tnam);
  conn.ext_num := data_p^.conn.ext_num;
  conn.lnum := file_lnum_nil_k;
  conn.data_p := data_p;
  conn.close_p := addr(file_close_map);
  conn.sys := data_p^.conn.sys;
{
*   Fill in remainder of our private data block.
}
  file_info (                          {get more information about this file}
    conn.tnam,                         {file name}
    [file_iflag_len_k],                {identifies the information we want}
    info,                              {returned information}
    stat);
  if sys_error(stat) then goto abort2;

  data_p^.mem_p := mem_p;              {save pointer to our dynamic memory handle}

  util_mem_context_get (mem_p^, data_p^.mem_data_p); {get context for data memory}
  data_p^.mem_data_p^.pool_size := pool_size_k; {set parameters for data mem context}
  data_p^.mem_data_p^.max_pool_chunk := pool_max_chunk_k;
  data_p^.len_file := info.len;        {save length of the sequential file}
  data_p^.len_map := info.len;         {init length of file as mapped}
  data_p^.len_read := 0;               {init amount already read from file}
  data_p^.len_mem := 0;                {init length of virtual adr space allocated}
  data_p^.map_p := nil;                {init to file is not mapped at all}
  data_p^.node_top.node_type := file_map_node_split_k;
  for i := 0 to file_map_split_ar_max_k do begin
    data_p^.node_top.split[i] := nil;
    end;
  data_p^.node_unused_p := nil;        {no unused address tree nodes exist yet}
  data_p^.first_p := nil;              {no memory blocks have been allocated yet}
  data_p^.last_p := nil;
  data_p^.written := false;            {file has not been written to yet}

  if not file_map_ftn_inhibit then begin {OK to use direct OS mapped file I/O ?}
    init_mapping;                      {do OS dependent initialization}
    end;
  if sys_error(stat) then goto abort2; {error in INIT_MAPPING ?}

  file_map_add_block (                 {allocate mem for whole file}
    data_p^, data_p^.len_file);
  return;
{
*   An error was detected after our top memory context was created.
*   Deallocate the memory and return with the error.  STAT is already set
*   to indicate the error condition.
}
abort2:                                {abort to here when file open}
  file_close (data_p^.conn);           {close file}

abort:                                 {abort to here when just mem alloc, no file}
  util_mem_context_del (mem_p);        {deallocate all our dynamic memory}
  end;                                 {return with the error}
