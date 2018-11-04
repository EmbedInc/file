{   Subroutine FILE_MAP_ADD_BLOCK (DATA, SIZE)
*
*   Add a new block to the end of the dynamically allocated data memory for
*   this file.  DATA is the private data block for the connection to this
*   mapped file.  SIZE is the size to make the new data block.  If the
*   memory for the new data block happens to start immediately after the
*   memory for the previous data block, then the previous data block is
*   increased.
*
*   The address tree is updated to take the new memory into account.
}
module file_map_add_block;
define file_map_add_block;
%include 'file2.ins.pas';

procedure file_map_add_block (         {add another mem block to end of list}
  in out  data: file_map_data_t;       {private data for mapped file connection}
  in      size: sys_int_adr_t);        {size of new block to add}
  val_param;

var
  ofs_first, ofs_last: sys_int_adr_t;  {first/last file offsets for new block}
  start_p: univ_ptr;                   {pointer to newly allocated memory}
  old_last_p: file_map_ofs_node_p_t;   {pointer to previous last block descriptor}
{
**************************************
*
*   Local subroutine NODE_ALLOC (NODE_P)
*
*   Allocate a new node descriptor.  If possible, and old unused node descriptor
*   will be re-used.  NODE_P is returned pointing to the new node descriptor.
}
procedure node_alloc (
  out     node_p: file_map_ofs_node_p_t); {returned pointing to new node}
  val_param;

begin
  if data.node_unused_p <> nil then begin {an unused node is available ?}
    node_p := data.node_unused_p;      {return pointer to the node}
    data.node_unused_p := node_p^.unused_next_p; {remove this node from unused list}
    return;
    end;

  util_mem_grab (                      {allocate a new node descriptor}
    sizeof(node_p^),                   {amount of memory to allocate}
    data.mem_p^,                       {parent memory context}
    false,                             {we won't individually deallocate this}
    node_p);                           {returned pointer to start of new memory}
  end;
{
**************************************
*
*   Local subroutine NODE_DEALLOC (NODE_P)
*
*   Recursively deallocate all branch nodes pointed to by NODE_P.  Any
*   deallocated nodes are put onto the unused list to possible re-use later.
}
procedure node_dealloc (
  in      node_p: file_map_ofs_node_p_t); {pointer to top node to deallocate}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}

begin
  if node_p = nil then return;         {nothing to deallocate ?}

  if node_p^.node_type <> file_map_node_split_k {not the right kind of node ?}
    then return;

  for i := 0 to file_map_split_ar_max_k do begin {once for each pointer in this node}
    node_dealloc (node_p^.split[i]);   {deallocate this sub-node}
    end;

  node_p^.node_type := file_map_node_unused_k; {indicate this node is unused}
  node_p^.unused_next_p := data.node_unused_p; {link node to start of unused chain}
  data.node_unused_p := node_p;
  end;
{
**************************************
*
*   Local subroutine NODE_UPDATE (NODE, SHFT, OFS_NODE)
*
*   Update the file offset lookup tree node to take into account the new
*   mapped region.  The file offsets for the effected block are from
*   OFS_FIRST to OFS_LAST.  SHFT is the number of bits remaining below
*   this level.  This is the value the masked bits must be shifted right
*   to make the split index.  OFS_NODE is the first offset handled by this node.
}
procedure node_update (
  in out  node: file_map_ofs_node_t;   {the node to update}
  in      shft: sys_int_adr_t;         {amount to shift bits right to make index}
  in      ofs_node: sys_int_adr_t);    {first address handled by this node}
  val_param;

var
  ofs: sys_int_adr_t;                  {starting offset for current split}
  len: sys_int_adr_t;                  {length of each split}
  split: sys_int_machine_t;            {0..n number of current split}
  split2: sys_int_machine_t;           {split loop counter in subordinate node}
  node_p: file_map_ofs_node_p_t;       {pointer to newly created split node}
  shift_new: sys_int_machine_t;        {SHFT argument in recursive calls}

label
  next_split;

begin
  if node.node_type <> file_map_node_split_k {this is not a branching node ?}
    then return;                       {nothing to do here}

  ofs := ofs_node;                     {init starting offset for current split}
  len := lshft(1, shft);               {offset increment for each split}
  shift_new := max(shft - file_map_split_bits_k, 0); {SHFT arg for recursive calls}

  for split := 0 to file_map_split_ar_max_k do begin {once for each split}
    if (ofs + len) <= ofs_first        {this split is before block ?}
      then goto next_split;
    if ofs > ofs_last                  {this split past end of block ?}
      then exit;                       {no need to process any further}
    if                                 {this split completely within block ?}
        (ofs >= ofs_first) and
        ((ofs + len - 1) <= ofs_last)
        then begin
      node_dealloc (node.split[split]); {deallocate any nodes currently here}
      node.split[split] := data.last_p; {point directly to leaf node descriptor}
      goto next_split;                 {all done with this split entry}
      end;
{
*   The offset range for the current split straddles one or both of the
*   block's ends.  This means that this split entry will point to another
*   level of split node.
}
    node_p := node.split[split];       {get pointer to subordinate node}
    if                                 {not already pointing to another split node ?}
        (node_p = nil) or else
        (node_p^.node_type <> file_map_node_split_k)
        then begin
      node_alloc (node_p);             {allocate space for a new split node}
      node_p^.node_type := file_map_node_split_k; {new node is a split node}
      for split2 := 0 to file_map_split_ar_max_k do begin {per entry in new node}
        node_p^.split[split2] := node.split[split]; {init to value in parent node}
        end;
      node.split[split] := node_p;     {point this entry to the new node}
      end;                             {entry now definately points to a split node}

    node_update (node_p^, shift_new, ofs); {process nested node recursively}

next_split:                            {advance to next split array entry}
    ofs := ofs + len;                  {update offset for start of new entry}
    end;                               {back and process this new split array entry}
  end;
{
**************************************
*
*   Start of main routine.
}
begin
  if size <= 0 then return;            {nothing to do ?}

  if data.last_p = nil
    then begin                         {no previous blocks exist ?}
      ofs_first := 0;
      end
    else begin                         {the new block is not the first}
      ofs_first := data.last_p^.ofs +
        data.last_p^.len;
      end
    ;                                  {OFS_FIRST is first file offset in new block}
  ofs_last := ofs_first + size - 1;    {last file offset in new block}

  if                                   {check for this is initial mapped file mem}
      (ofs_first = 0) and              {block starts at beginning of file ?}
      (data.map_p <> nil)              {file is mapped ?}
    then begin                         {this is for region already mapped to file}
      start_p := data.map_p;           {get pointer to start of mapped file}
      end
    else begin                         {this is for new memory not mapped to file}
      util_mem_grab_align (size, 1, data.mem_data_p^, false, start_p); {alloc new mem}
      end
    ;                                  {START_P is pointer to start of mem area}

  if
      (data.last_p <> nil) and then
      (sys_int_adr_t(start_p) =
        (data.last_p^.adr + data.last_p^.len))
    then begin                         {new block is directly after old block}
      data.last_p^.len :=              {update length of previous block}
        data.last_p^.len + size;
      end
    else begin                         {new block is disjoint from previous block}
      old_last_p := data.last_p;       {save pointer to current last block}
      util_mem_grab (                  {allocate memory for new block descriptor}
        sizeof(data.last_p^), data.mem_p^, false, data.last_p);
      data.last_p^.node_type := file_map_node_leaf_k; {fill in new descriptor}
      data.last_p^.ofs := ofs_first;
      data.last_p^.adr := sys_int_adr_t(start_p);
      data.last_p^.len := size;
      data.last_p^.next_p := nil;
      if data.first_p = nil
        then begin                     {this new block is the first block}
          data.first_p := data.last_p;
          end
        else begin                     {this is not the first block}
          old_last_p^.next_p := data.last_p; {add new block to end of chain}
          end
        ;
      end
    ;

  data.len_mem := data.len_mem + size; {update length of allocated virtual memory}
{
*   The new data memory has been allocated, and the block descriptors updated.
*   OFS_FIRST and OFS_LAST are the first and last file offset within the
*   new block.  Now update the file offset lookup tree for that range of
*   offsets.  The leaf node for the block containing the entire range is
*   pointed to by DATA.LAST_P.
}
  ofs_first := data.last_p^.ofs;       {update to first offset in whole block}
  node_update (                        {update all the offset lookup nodes}
    data.node_top,                     {top node to update}
    file_map_bits_left_first_k,        {shift bits for this node}
    0);                                {offset that corresponds to start of node}
  end;
