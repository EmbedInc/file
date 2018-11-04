{   Subroutine FILE_MAP (CONN, OFS, LEN, ACCESS, P, LEN_MAPPED, HANDLE, STAT)
*
*   Make a portion of a file available for direct read/write access by mapping
*   it into the process' address space.  Arguments are:
*
*   CONN
*
*     Handle to this connection to the file.  The handle must have been created
*     with a call to FILE_OPEN_MAP.
*
*   OFS
*
*     Identifies the location within the file of the region to map.  OFS is
*     the offset from the start of the file in machine address units.
*     The constant SYS_INT_ADR_K is the number of bits in a machine address
*     unit (8 on most workstations).
*
*   LEN
*
*     The length of the region to map in machine address units.
*
*   ACCESS
*
*     Indicates what combination of read/write access will be required of the
*     mapped region.  This is a set whose members can be FILE_RW_READ_K
*     and FILE_RW_WRITE_K.  It is an error to request more access to the
*     mapped region than was originally requested for the whole file when
*     it was opened.
*
*   P
*
*     Returned pointer to where the start of the region got mapped in the
*     process' address space.
*
*   LEN_MAPPED
*
*     The size of the region actually mapped.  This is always the same as
*     LEN when STAT is indicating no error.  It may be less than LEN when
*     only read access is requested, and the mapped region
*     would otherwise have extended past the end of the file.  In this
*     case STAT is returned indicating FILE_STAT_EOF_PARTIAL_K status.
*     This can easily be checked with function FILE_EOF_PARTIAL.
*     The file length is automatically extended when write access is requested
*     and the end of the region extends past the old end of the file.
*
*   HANDLE
*
*     Returned handle for this mapped region.  This handle is needed to
*     release the mapped region.  All mapped regions are automatically
*     released when the file is closed.
*
*   STAT
*
*     Returned completion status code.  FILE_STAT_EOF_K is returned when
*     only read access is requested and the end of file is exactly where
*     the mapped region would start (OFS equals file length).
*     FILE_STAT_EOF_PARTIAL_K is returned when only read access is
*     requested, the start of the requested region is within the file,
*     but the end of the file is reached before the end of the region.
*     LEN_MAPPED can be used to determine how much actually did get mapped.
*     STAT may also be returned signalling other errors.
}
module file_map;
define file_map;
%include 'file2.ins.pas';

procedure file_map (                   {map portion of file to virtual adr space}
  in out  conn: file_conn_t;           {handle to file, from FILE_OPEN_MAP}
  in      ofs: sys_int_adr_t;          {mapped region offset from start of file}
  in      len: sys_int_adr_t;          {length of region to make available}
  in      access: file_rw_t;           {read/write access needed to this region}
  out     p: univ_ptr;                 {pointer to start of mapped region}
  out     len_mapped: sys_int_adr_t;   {actual length mapped, = LEN if no error}
  out     handle: file_map_handle_t;   {handle to this mapped region}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  data_p: file_map_data_p_t;           {points to private data for this connection}
  n_read: sys_int_adr_t;               {amount to read from file}
  buf_p: ^char;                        {points to where to read data into}
  node_p: file_map_ofs_node_p_t;       {points to current node in ofs tree}
  mask: sys_int_adr_t;                 {for masking in ofs bits to make split}
  shft: sys_int_machine_t;             {bits to shift right for split index}
  i: sys_int_machine_t;                {scratch integer}
  unused: sys_int_adr_t;

begin
  if
      (file_rw_write_k in access) and
      (not (file_rw_write_k in conn.rw_mode))
      then begin
    sys_message_bomb ('file', 'map_access', nil, 0);
    end;
  sys_error_none (stat);               {init to no error}
  data_p := conn.data_p;               {get pointer to our private data}
  data_p^.written :=                   {update flag to indicate anything written}
    data_p^.written or (file_rw_write_k in access);
{
*   Read more of the sequential file, if necessary.
}
  n_read :=                            {make offset need to have mapped up to}
    min(data_p^.len_file, ofs + len);

  if data_p^.len_read < n_read then begin {need to read more from file ?}
    n_read := n_read - data_p^.len_read; {additional amount we need to read}
    buf_p := univ_ptr(                 {first address to read data into}
      data_p^.last_p^.adr + data_p^.len_read);
    file_read_bin (                    {read more data from the sequential file}
      data_p^.conn,                    {connection handle to the file}
      n_read,                          {amount to read}
      buf_p^,                          {buffer to read data into}
      unused,                          {amount actually read}
      stat);
    if sys_error(stat) then return;
    data_p^.len_read := data_p^.len_read + n_read; {update amount read from file}
    end;
{
*   Extend the mapped file, if neccessary.
}
  if                                   {need to extend the mapped file ?}
      (file_rw_write_k in access) and  {trying to write to this region ?}
      ((ofs + len) > data_p^.len_map)  {end of region is past end of mapped file ?}
      then begin
    data_p^.len_map := ofs + len;      {make the mapped file longer}
    if data_p^.len_map > data_p^.len_mem then begin {need to allocate more space ?}
      file_map_add_block (             {add another block to end of mapped file}
        data_p^,                       {our private data for mapped file connection}
        data_p^.len_map - data_p^.len_mem); {size of block to add}
      end;
    end;
{
*   Check for trying to read after the end of the file.
}
  if ofs >= data_p^.len_map then begin
    sys_stat_set (file_subsys_k, file_stat_eof_k, stat);
    return;                            {return indicating END OF FILE}
    end;
{
*   Find the block containing the start of the requested mapped region.
*   NODE_P will be left pointing to the leaf node describing the block.
*   P and LEN_MAPPED will also be set.  LEN_MAPPED will be clipped to the
*   end of the block where the mapped region starts.
}
  node_p := addr(data_p^.node_top);    {init current node to top node}
  mask := file_map_mask_first_k;       {init mask to that for top node}
  shft := file_map_bits_left_first_k;  {init shift value for top node}
  while node_p^.node_type = file_map_node_split_k do begin {loop until hit leaf node}
    i := rshft(ofs & mask, shft);      {make split array index}
    node_p := node_p^.split[i];        {go to next node down the tree}
    mask := rshft(mask, file_map_split_bits_k); {make mask for this new level}
    shft := max(0, shft - file_map_split_bits_k); {make shift value for new level}
    end;                               {back and process this new level}
  p := univ_ptr(                       {pass back virtual address of block start}
    node_p^.adr + ofs - node_p^.ofs);
  len_mapped := min(len,               {clip mapped length to end of block}
    node_p^.ofs + node_p^.len - ofs);
{
*   Check for requested mapped region extends past the end of this block.
*   This either results in a partial end of file status, or an error to
*   indicate that the mapped region crosses block boundaries.
}
  if len_mapped < len then begin       {caller didn't get whole mapped region ?}
    if                                 {partial end of file condition ?}
        (not (file_rw_write_k in access)) and {only trying to read this region ?}
        ((ofs + len_mapped) = data_p^.len_map) {ends exactly at end of file ?}
      then begin
        sys_stat_set (file_subsys_k, file_stat_eof_partial_k, stat);
        sys_stat_parm_int (len, stat);
        sys_stat_parm_int (len_mapped, stat);
        end
      else begin
        sys_stat_set (file_subsys_k, file_stat_map_cross_k, stat);
        end
      ;
    end;
  end;
