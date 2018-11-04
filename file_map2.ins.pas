{   This file is really part of FILE2.INS.PAS, and is used to declare data
*   structures related to mapped file I/O.
*
*   This version is for any operating system that does not have mapped
*   file I/O capability.  The routines that implement this version are the
*   main line of decent, and are layered on other Cognivision utilities.
}
const
  file_map_split_bits_k = 4;           {number of bits resolved each address split}

  file_map_split_n_k =                 {number of choices in one address split}
    2 ** file_map_split_bits_k;
  file_map_split_ar_max_k =            {max index to address split array in a node}
    file_map_split_n_k - 1;
  file_map_adr_bits_k =                {number of bits in a system address}
    sys_bits_adr_k * sizeof(sys_int_adr_t);
  file_map_bits_left_first_k =         {bit remaining in address after first split}
    file_map_adr_bits_k - file_map_split_bits_k;
  file_map_mask_first_k =              {mask for address bits of first split}
    lshft(~lshft(~0, file_map_split_bits_k), file_map_bits_left_first_k);

type
  file_map_ofs_node_p_t =              {pointer to node in file offset lookup tree}
    ^file_map_ofs_node_t;

  file_map_node_k_t = (                {used to identify the type of ofs lookup node}
    file_map_node_split_k,             {not a leaf node, offsets are split further}
    file_map_node_leaf_k,              {all offsets for this node map to same block}
    file_map_node_unused_k);           {this node unused, may be re-used later}

  file_map_ofs_node_t = record         {one node in file offset lookup tree}
    node_type: file_map_node_k_t;      {identifies what type of node this is}
    case file_map_node_k_t of
file_map_node_split_k: (               {offset is split further}
      split:                           {separate pointer for each possible value}
        array[0..file_map_split_ar_max_k]
        of file_map_ofs_node_p_t;      {NIL means no memory allocated for these ofs}
      );
file_map_node_leaf_k: (                {no more splits, all offsets in same block}
      ofs: sys_int_adr_t;              {file offset for start of block}
      adr: sys_int_adr_t;              {memory addres of start of block}
      len: sys_int_adr_t;              {length of this block}
      next_p: file_map_ofs_node_p_t;   {points to leaf node for next block}
      );
file_map_node_unused_k: (              {this node is not used now, may be used later}
      unused_next_p: file_map_ofs_node_p_t; {pointer to next node in unused chain}
      );
    end;

  file_map_data_t = record             {private data for mapped file I/O routines}
    mem_p: util_mem_context_p_t;       {points to parent context for our dyn memory}
    mem_data_p: util_mem_context_p_t;  {points to mem handle for the data memory}
    len_file: sys_int_adr_t;           {length of the sequential file}
    len_map: sys_int_adr_t;            {apparent length of mapped file}
    len_read: sys_int_adr_t;           {how much has been read from sequential file}
    len_mem: sys_int_adr_t;            {length of virtual memory allocated}
    map_p: univ_ptr;                   {pnt to whole file mapped, if at all}
    node_top: file_map_ofs_node_t;     {file offset tree node for first split}
    node_unused_p: file_map_ofs_node_p_t; {points to first unused ofs node in chain}
    first_p: file_map_ofs_node_p_t;    {points to leaf name for first block}
    last_p: file_map_ofs_node_p_t;     {points to leaf node entry for last block}
    conn: file_conn_t;                 {handle to sequential read/write file}
    written: boolean;                  {TRUE if any part of file written}
    end;

procedure file_map_add_block (         {add another mem block to end of list}
  in out  data: file_map_data_t;       {private data for mapped file connection}
  in      size: sys_int_adr_t);        {size of new block to add}
  val_param; extern;
