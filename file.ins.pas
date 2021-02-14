{   Public include file for the FILE library.
*
*   This library attempts to present a system-independent interface to common
*   file manipulation operations.
}
const
  file_subsys_k = -3;                  {subsystem ID number for FILE library}
{
*   Mnemonics for status values unique to the FILE subsystem.
}
  file_stat_eof_k = 1;                 {end of file has been encountered}
  file_stat_not_dir_k = 2;             {not a directory}
  file_stat_no_fnam_open_k = 4;        {missing file name in FILE_OPEN_xxx call}
  file_stat_no_in_eor_k = 5;           {no SIO input end of record ON or exists}
  file_stat_bad_baud_k = 6;            {illegal or unavailable baud rate}
  file_stat_not_found_k = 7;           {object not found}
  file_stat_write_0_k = 8;             {wrote nothing on attempt to write to file}
  file_stat_write_size_k = 9;          {didn't write right amount of data to file}
  file_stat_eof_partial_k = 10;        {some but not all data read, EOF encountered}
  file_stat_rw_none_open_k = 11;       {no read or write access requested on open}
  file_stat_info_partial_k = 12;       {not get all file info req, check FLAGS field}
  file_stat_posofs_ftype_k = 13;       {illegal file or connection type for POS_OFS}
  file_stat_map_cross_k = 14;          {mapped region crosses block boundaries}
  file_stat_inet_name_adr_k = 15;      {err convert node name to internet address}
  file_stat_read_partial_k = 16;       {not all requested data read, check OLEN}
  file_stat_inetname_dot_k = 17;       {not get node name, returning dot format adr}
  file_stat_csrv_version_k = 18;       {remote COGSERVE server version incompatible}
  file_stat_csrv_comm_k = 19;          {error communicating with COGSERVE server}
  file_stat_remote_fail_k = 20;        {remote operation failed}
  file_stat_ndel_k = 21;               {N file system objects not deleted}
  file_stat_copy_exists_k = 22;        {illegal attempt to copy onto existing object}
  file_stat_crea_exists_k = 23;        {illegal attempt to create over existing obj}
  file_stat_rename_move_k = 24;        {trying to move file on rename}
  file_stat_sio_inuse_k = 25;          {SIO port is already in use}
  file_stat_sio_nexist_k = 26;         {SIO port does not exist}
  file_stat_inuse_k = 27;              {can't access resource, already in use}
  file_stat_write_partial_k = 28;      {not all requested data was written}
  file_stat_usbid_nfound_k = 29;       {USB device with VID/PID not found}
  file_stat_usbidn_nfound_k = 30;      {USB device with VID/PID and name not found}
  file_stat_usbdev_busy_k = 31;        {USB device with VID/PID and name is busy}
  file_stat_timeout_k = 32;            {timeout reached before I/O completed}
  file_stat_closed_k = 33;             {the I/O connection is closed}
  file_stat_wtxt_badobj_k = 34;        {text write not supported for this object type}
  file_stat_not_callobj_k = 35;        {not a CALL object type}
  file_stat_not_fmttext_k = 36;        {not TEXT format type}
{
*   Mnemonics for special flags for the line number (LNUM) field in a connection
*   handle (FILE_CONN_T).
}
  file_lnum_unk_k = -1;                {line number is unknown}
  file_lnum_nil_k = -2;                {line numbers don't apply to this I/O type}

type
  file_rw_k_t = (                      {mnemonics for read/write modes}
    file_rw_read_k,                    {connection is open for read}
    file_rw_write_k                    {connection is open for write}
    );
  file_rw_t = set of file_rw_k_t;      {read/write flags in one word}

  file_obty_k_t = (                    {system obj types and things that can be open}
    file_obty_file_k,                  {system file}
    file_obty_dir_k,                   {system directory}
    file_obty_env_k,                   {environment file}
    file_obty_sio_k,                   {serial line}
    file_obty_msg_k,                   {message within a .msg file}
    file_obty_map_k,                   {system file mapped to user address space}
    file_obty_stream_k,                {previously established system stream}
    file_obty_inetstr_k,               {reliable stream via internet}
    file_obty_remote_k,                {remote file on another machine}
    file_obty_embusb_k,                {Embed USB device, bi-directional byte stream}
    file_obty_dgram_k,                 {network datagrams}
    file_obty_call_k,                  {I/O causes calls to callback routines}
    file_obty_dev_k);                  {arbitrary special device}

  file_type_k_t = (                    {system file types we understand}
    file_type_other_k,                 {not a file type we specifically know about}
    file_type_data_k,                  {regular data file}
    file_type_dir_k,                   {directory of nested files}
    file_type_link_k);                 {symbolic link}
  file_type_t = set of file_type_k_t;

  file_fmt_k_t = (                     {mnemonics for file data formats}
    file_fmt_bin_k,                    {binary, arbitrary data}
    file_fmt_text_k);                  {text, can only read/write whole lines}

  file_perm_k_t = (                    {file permission flags}
    file_perm_read_k,                  {permission to read file or directory}
    file_perm_write_k,                 {permission to write to file}
    file_perm_exec_k,                  {permission to execute the file directly}
    file_perm_perm_k,                  {permission to change permissions}
    file_perm_del_k,                   {permission to delete}
    file_perm_crea_k);                 {permission to create new files in directory}
  file_perm_t = set of file_perm_k_t;  {all the permission flags in one set}

  file_crea_k_t = (                    {file creation option flags}
    file_crea_overwrite_k,             {overwrite existing file, if present}
    file_crea_keep_k);                 {keep old object if same type as new}

  file_crea_t = set of file_crea_k_t;

  file_iflag_k_t = (                   {one flag for each bit of info from FILE_INFO}
    file_iflag_dtm_k,                  {date/time of last modification}
    file_iflag_len_k,                  {length of file in machine address units}
    file_iflag_perm_k,                 {our current permissions regarding file}
    file_iflag_type_k);                {what kind of file system object is this}
  file_iflags_t =                      {all the file info flags in one set}
    set of file_iflag_k_t;

  file_sio_k_t = (                     {mnemonics for serial line config options}
    file_sio_xonoff_send_k,            {send XON/XOFF on buffer empty/full}
    file_sio_xonoff_obey_k,            {obey incoming XON/XOFF signals}
    file_sio_rtscts_k,                 {use RTS/CTS flow control}
    file_sio_par_odd_k,                {additional parity bit, odd parity}
    file_sio_par_even_k);              {additional parity bit, even parity}
  file_sio_config_t =                  {SIO config mnemonics in one set}
    set of file_sio_k_t;

  file_baud_k_t = (                    {mnemonics for serial line baud rates}
    file_baud_300_k,
    file_baud_1200_k,
    file_baud_2400_k,
    file_baud_4800_k,
    file_baud_9600_k,
    file_baud_19200_k,
    file_baud_38400_k,
    file_baud_57600_k,
    file_baud_115200_k,
    file_baud_153600_k);

  file_copy_k_t = (                    {flags that control file copying}
    file_copy_replace_k,               {OK to copy onto previously existing file}
    file_copy_list_k);                 {list activity to standard output}
  file_copy_t = set of file_copy_k_t;

  file_rdstream_k_t = (                {options flags for reading streams}
    file_rdstream_nowait_k,            {return immediately with whatever is avail}
    file_rdstream_1chunk_k);           {return as soon as something is read}
  file_rdstream_t =                    {all the flags in one set}
    set of file_rdstream_k_t;

  file_del_k_t = (                     {delete option flags}
    file_del_errgo_k,                  {continue on error, error still flagged}
    file_del_list_k);                  {list activity to standard output}
  file_del_t = set of file_del_k_t;

  file_conn_p_t = ^file_conn_t;
  file_conn_t = record                 {handle to an open file}
    rw_mode: file_rw_t;                {read/write mode}
    obty: file_obty_k_t;               {what kind of object connected to}
    fmt: file_fmt_k_t;                 {data format}
    fnam: string_treename_t;           {file name with extension as used}
    gnam: string_leafname_t;           {generic leafname (no extension or dir)}
    tnam: string_treename_t;           {full tree name of file}
    ext_num: sys_int_machine_t;        {# of extension used, 0 = none}
    lnum: sys_int_machine_t;           {line number of last transfer, text I/O only}
    data_p: univ_ptr;                  {pointer to internal data, may be NIL}
    close_p: ^procedure (              {procedure to call to do a close, none if NIL}
      in  conn_p: file_conn_p_t);      {pointer to this connection handle}
      val_param;
    sys: sys_sys_file_conn_t;          {system handle to file connection, if any}
    end;

  file_pos_p_t = ^file_pos_t;
  file_pos_t = record                  {handle to a particular file position}
    conn_p: file_conn_p_t;             {points to connection handle pos valid for}
    sys: sys_sys_stream_pos_t;         {system handle to file position}
    end;

  file_names_ar_t =                    {array of arbitrary file names}
    array[1..1] of string_treename_t;

  file_info_p_t = ^file_info_t;
  file_info_t = record                 {all the data returned by FILE_INFO routine}
    flags: file_iflags_t;              {indicates which fields are valid}
    ftype: file_type_k_t;              {file system object type}
    perm_us: file_perm_t;              {what we currently have permission to do}
    len: sys_int_adr_t;                {length of file in machine address units}
    modified: sys_clock_t;             {time file last modified}
    end;

  file_inet_port_serv_t = record       {info about internet port we are serving}
    port: sys_inet_port_id_t;          {ID of inet port we are serving on this mach}
    socket_id: sys_sys_inetsock_id_t;  {ID of socket bound to port}
    end;

  file_usbid_t = sys_int_conv32_t;     {VID in high 16 bits, PID in low 16 bits}

  file_usbdev_p_t = ^file_usbdev_t;
  file_usbdev_t = record               {info about one USB device}
    next_p: file_usbdev_p_t;           {pointer to next list entry}
    vidpid: file_usbid_t;              {VID and PID of the device, 0 = not known}
    name: string_var80_t;              {user-settable name string}
    path: string_treename_t;           {system device pathname}
    drtype: sys_int_machine_t;         {private to FILE library}
    end;

  file_usbdev_list_t = record          {list of Embed USB devices}
    mem_p: util_mem_context_p_t;       {pointer to memory context for all list memory}
    n: sys_int_machine_t;              {number of devices in the list}
    list_p: file_usbdev_p_t;           {pointer to first list entry}
    last_p: file_usbdev_p_t;           {pointer to last list entry}
    end;

  file_call_close_p_t = ^procedure (   {callback routine for closing CALL object type}
    in out conn: file_conn_t);         {CALL type I/O connection being closed}
    val_param;

  file_call_wtxt_p_t = ^procedure (    {callback routine for writing line of text}
    in    buf: univ string_var_arg_t;  {string to write as text line}
    in out conn: file_conn_t;          {handle to this I/O connection, CALL object type}
    out   stat: sys_err_t);            {completion status code, initialized to no err}
    val_param;
{
*   Define FILE_MAP_HANDLE_T.  The internals of this data structure depend on
*   the underlying operating system.  The definition is in a separate file so
*   that it can be customized per target operating system.  The rest of the FILE
*   library considers FILE_MAP_HANDLE_T an opaque object.
}
  file_map_handle_p_t = ^file_map_handle_t; {pointer to memory-mapped file handle}

%include '(cog)lib/file_map.ins.pas';  {define FILE_MAP_HANDLE_T, customizable by OS}
{
*   Entry point definitions.
}
procedure file_call_set_close (        {set close object callback routine}
  in out  conn: file_conn_t;           {I/O connection to set callback for}
  in      call_p: file_call_close_p_t; {pointer to routine to call on closing}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_call_set_wtxt (         {set text write callback routine}
  in out  conn: file_conn_t;           {I/O connection to set callback for}
  in      call_p: file_call_wtxt_p_t;  {pointer to routine to call on text write}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_close (                 {close a connection, truncate when appropriate}
  in out  conn: file_conn_t);          {handle to file connection}
  val_param; extern;

procedure file_close_sysconn (         {close system I/O connection handle}
  in      sysconn: sys_sys_file_conn_t); {system I/O handle to close}
  val_param; extern;

procedure file_copy (                  {copy a file to another place}
  in      src: univ string_var_arg_t;  {source file name}
  in      dest: univ string_var_arg_t; {destination file name}
  in      flags: file_copy_t;          {set of modifier flags}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_copy_tree (             {copy a whole directory tree}
  in      src: univ string_var_arg_t;  {source tree name}
  in      dest: univ string_var_arg_t; {destination tree name}
  in      opts: file_copy_t;           {set of option flags}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_create_dir (            {create a new directory}
  in      name: univ string_var_arg_t; {name of directory to create}
  in      flags: file_crea_t;          {set of creation option flags}
  out     stat: sys_err_t);            {returned completion status code}
  val_param; extern;

procedure file_create_inetstr_serv (   {create internet stream server port}
  in      node: sys_inet_adr_node_t;   {inet adr or SYS_SYS_INETNODE_ANY_K}
  in      port: sys_inet_port_id_t;    {requested port on this machine or unspec}
  out     serv: file_inet_port_serv_t; {returned handle to new server port}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_currdir_get (           {get current directory name}
  in out  dnam: univ string_var_arg_t; {returned directory name}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_currdir_set (           {set current directory}
  in      dnam: univ string_var_arg_t; {name of directory to set as current}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_delete_name (           {delete a file by name}
  in      fnam: univ string_var_arg_t; {name of file to delete}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_delete_tree (           {delete a whole directory tree}
  in      name: univ string_var_arg_t; {name of tree to delete}
  in      opts: file_del_t;            {additional option flags}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_embusb_list_get (       {make list of Embed USB devices of a VID/PID}
  in      usbid: file_usbid_t;         {USB VID/PID of the devices to list, 0 for all}
  in out  mem: util_mem_context_t;     {mem context to create list context within}
  out     list: file_usbdev_list_t;    {the returned list}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

function file_eof (                    {return TRUE if STAT means "END OF FILE"}
  in out  stat: sys_err_t)             {status code, reset to no err on EOF}
  :boolean;                            {TRUE on end of file status}
  val_param; extern;

function file_eof_partial (            {return TRUE if partial data read before EOF}
  in out  stat: sys_err_t)             {status code, reset to no err on return TRUE}
  :boolean;
  val_param; extern;

function file_exists (                 {return TRUE if file exists}
  in      fnam: univ string_var_arg_t) {arbitrary file name}
  :boolean;                            {TRUE on existance of file}
  val_param; extern;

procedure file_link_create (           {create a symbolic link}
  in      name: univ string_var_arg_t; {name of link to create}
  in      val: univ string_var_arg_t;  {link value (file name link resolves to)}
  in      flags: file_crea_t;          {set of creation option flags}
  out     stat: sys_err_t);            {returned completion status code}
  val_param; extern;

procedure file_link_del (              {delete a symbolic link}
  in      name: univ string_var_arg_t; {name of link to delete}
  out     stat: sys_err_t);            {returned completion status code}
  val_param; extern;

procedure file_link_resolve (          {get symbolic link expansion}
  in      name: univ string_var_arg_t; {name of link to delete}
  in out  val: univ string_var_arg_t;  {returned link value}
  out     stat: sys_err_t);            {returned completion status code}
  val_param; extern;

procedure file_inet_adr_name (         {get node name from internet address}
  in      adr: sys_inet_adr_node_t;    {input internet node address}
  in out  name: univ string_var_arg_t; {node name or "dot notation" address}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_inet_name_adr (         {convert machine name to internet address}
  in      name: univ string_var_arg_t; {node name, may have domains, etc.}
  out     adr: sys_inet_adr_node_t;    {internet address by which to reach machine}
  out     stat: sys_err_t);            {error status code}
  val_param; extern;

procedure file_inetstr_info_local (    {get local end info of internet stream conn}
  in      conn: file_conn_t;           {handle to internet stream connection}
  out     adr: sys_inet_adr_node_t;    {internet node address}
  out     port: sys_inet_port_id_t;    {port on node ADR}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_inetstr_info_remote (   {get remote end info of internet stream conn}
  in      conn: file_conn_t;           {handle to internet stream connection}
  out     adr: sys_inet_adr_node_t;    {internet node address}
  out     port: sys_inet_port_id_t;    {port on node ADR}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_inetstr_tout_rd (       {set internet stream read timeout}
  in out  conn: file_conn_t;           {connection to the internet strea}
  in      tout: real);                 {timeout in seconds, 0 = none}
  val_param; extern;

procedure file_inetstr_tout_wr (       {set internet stream write timeout}
  in out  conn: file_conn_t;           {connection to the internet strea}
  in      tout: real);                 {timeout in seconds, 0 = none}
  val_param; extern;

procedure file_info (                  {get information about a file}
  in      name: univ string_var_arg_t; {name of file to get information about}
  in      request: file_iflags_t;      {indicates which information is requested}
  out     info: file_info_t;           {returned information}
  out     stat: sys_err_t);            {error status, got all info if no error}
  val_param; extern;

function file_inuse (                  {return TRUE if STAT means file is in use}
  in out  stat: sys_err_t)             {status code, reset to no err on in use}
  :boolean;                            {TRUE on file in use condition}
  val_param; extern;

procedure file_map (                   {map portion of file to virtual adr space}
  in out  conn: file_conn_t;           {handle to file, from FILE_OPEN_MAP}
  in      ofs: sys_int_adr_t;          {mapped region offset from start of file}
  in      len: sys_int_adr_t;          {length of region to make available}
  in      access: file_rw_t;           {read/write access needed to this region}
  out     p: univ_ptr;                 {pointer to start of mapped region}
  out     len_mapped: sys_int_adr_t;   {actual length mapped, = LEN if no error}
  out     handle: file_map_handle_t;   {handle to this mapped region}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_map_done (              {indicate done with mapped region of file}
  in out  handle: file_map_handle_t);  {handle from FILE_MAP, returned invalid}
  val_param; extern;

function file_map_length (             {return length of a file open for mapping}
  in      conn: file_conn_t)           {handle to file, from FILE_OPEN_MAP}
  :sys_int_adr_t;                      {current length of file in machine adr units}
  val_param; extern;

procedure file_map_truncate (          {truncate mapped file to specified length}
  in out  conn: file_conn_t;           {handle to file, from FILE_OPEN_MAP}
  in      len: sys_int_adr_t);         {desired length of file}
  val_param; extern;

function file_not_found (              {return TRUE if STAT means "NOT FOUND"}
  in out  stat: sys_err_t)             {status code, reset to no err on not found}
  :boolean;                            {TRUE on not found status}
  val_param; extern;

procedure file_open_bin (              {open binary file for read and/or write}
  in      name: univ string_var_arg_t; {generic file name}
  in      ext: string;                 {file name extensions, separated by blanks}
  in      rw_mode: file_rw_t;          {intended read/write access}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_call_wtxt (        {open callback object for writing text lines}
  in      name: univ string_var_arg_t; {name to set callback objec to}
  out     conn: file_conn_t;           {handle to newly created I/O connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_embusb (           {open bi-directional stream to Embed USB device}
  in      usbid: file_usbid_t;         {VID/PID of the device to open}
  in      name: univ string_var_arg_t; {name of device, empty string means any}
  out     conn: file_conn_t;           {returned connection to the USB device}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_inetstr (          {open internet stream to existing port}
  in      node: sys_inet_adr_node_t;   {internet address of node}
  in      port: sys_inet_port_id_t;    {internet port within node}
  out     conn: file_conn_t;           {connection handle to new internet stream}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_inetstr_accept (   {open internet stream when client requests}
  in      port_serv: file_inet_port_serv_t; {handle to internet server port}
  out     conn: file_conn_t;           {connection handle to new internet stream}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_map (              {open system file for mapped access}
  in      name: univ string_var_arg_t; {generic file name}
  in      ext: string;                 {file name extensions, separated by blanks}
  in      rw_mode: file_rw_t;          {intended read/write access}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_read_bin (         {open binary file for read}
  in      name: univ string_var_arg_t; {generic file name}
  in      ext: string;                 {file name extensions, separated by blanks}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_read_dir (         {open directory for reading file names}
  in      name: univ string_var_arg_t; {generic directory name}
  out     conn: file_conn_t;           {handle to newly created connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_read_env (         {init for reading set of environment files}
  in      env_name: univ string_var_arg_t; {generic environment file name}
  in      ext: string;                 {file name extension}
  in      global_first: boolean;       {TRUE if read in global to local order}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_read_msg (         {init for reading a message from .msg files}
  in      gnam: univ string_var_arg_t; {generic name of message file}
  in      msg: univ string_var_arg_t;  {message name withing subsystem file}
  in      parms: univ sys_parm_msg_ar_t; {array of parameter descriptors}
  in      n_parms: sys_int_machine_t;  {number of parameters in PARMS}
  out     conn: file_conn_t;           {handle to connection to this message}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_read_text (        {open text file for read}
  in      name: univ string_var_arg_t; {generic file name}
  in      ext: string;                 {file name extensions, separated by blanks}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_sio (              {open connection to a serial line}
  in      n: sys_int_machine_t;        {system serial line number}
  in      baud: file_baud_k_t;         {baud rate ID}
  in      config: file_sio_config_t;   {set of configuration flags}
  out     conn: file_conn_t;           {handle to new serial line connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_stream_bin (       {create binary connection to system stream}
  in      stream_id: sys_sys_iounit_t; {system stream ID to connect to}
  in      rw_mode: file_rw_t;          {intended read/write access}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_stream_text (      {create text connection to system stream}
  in      stream_id: sys_sys_iounit_t; {system stream ID to connect to}
  in      rw_mode: file_rw_t;          {intended read/write access}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_sysconn_bin (      {create binary connection to system I/O conn}
  in      sysconn: sys_sys_file_conn_t; {system I/O ID to connect to}
  in      rw_mode: file_rw_t;          {intended read/write access}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_sysconn_text (     {create text connection to system I/O conn}
  in      sysconn: sys_sys_file_conn_t; {system I/O ID to connect to}
  in      rw_mode: file_rw_t;          {intended read/write access}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_dgram_client (     {set up for sending datagrams to remote server}
  in      node: sys_inet_adr_node_t;   {internet address of node}
  in      port: sys_inet_port_id_t;    {internet port within node}
  out     conn: file_conn_t;           {connection handle to new internet stream}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_write_bin (        {open binary file for write}
  in      name: univ string_var_arg_t; {generic file name}
  in      ext: string;                 {file name extension, blank if not used}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_open_write_text (       {open text file for write}
  in      name: univ string_var_arg_t; {generic file name}
  in      ext: string;                 {file name extension, blank if not used}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_pos_end (               {set current file position to end of file}
  in out  conn: file_conn_t;           {handle to this file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_pos_get (               {return current position within file}
  in      conn: file_conn_t;           {handle to this file connection}
  out     pos: file_pos_t);            {handle to current file position}
  val_param; extern;

procedure file_pos_ofs (               {position binary file to fixed file offset}
  in out  conn: file_conn_t;           {handle to this file connection}
  in      ofs: sys_int_adr_t;          {offset from file start in machine adr units}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_pos_set (               {set file to fixed position}
  in out  pos: file_pos_t;             {position handle obtained with FILE_POS_GET}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_pos_start (             {set current file position to start of file}
  in out  conn: file_conn_t;           {handle to this file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_read_bin (              {read data from binary file}
  in      conn: file_conn_t;           {handle to this file connection}
  in      ilen: sys_int_adr_t;         {number of machine adr increments to read}
  out     buf: univ char;              {returned data}
  out     olen: sys_int_adr_t;         {number of machine adresses actually read}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_read_embusb (           {read chunk of data from Embed USB device}
  in out  conn: file_conn_t;           {connection to the USB device}
  in      ilen: sys_int_adr_t;         {maximum number of bytes to read}
  out     buf: univ char;              {returned data}
  out     olen: sys_int_adr_t;         {number of bytes actually read}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure file_read_dir (              {read next directory entry name}
  in      conn: file_conn_t;           {handle to connection to directory}
  in      info_req: file_iflags_t;     {flags for requesting additional info in INFO}
  out     name: univ string_var_arg_t; {name from directory entry}
  out     info: file_info_t;           {returned information requested about file}
  out     stat: sys_err_t);            {error status, got all info if no error}
  val_param; extern;

procedure file_read_env (              {read next line from environment files}
  in out  conn: file_conn_t;           {handle to this file connection}
  in out  buf: univ string_var_arg_t;  {text line, no comments or trailing blanks}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_read_inetstr (          {read from an internet stream}
  in out  conn: file_conn_t;           {handle to this internet stream connection}
  in      ilen: sys_int_adr_t;         {number of machine adr increments to read}
  in      flags: file_rdstream_t;      {set of modifier flags}
  out     buf: univ sys_size1_t;       {buffer to read data into}
  out     olen: sys_int_adr_t;         {amount of data actually read}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_read_msg (              {read next line of a message from .msg file}
  in out  conn: file_conn_t;           {handle to connection to this message}
  in      width: sys_int_machine_t;    {max width to text-flow into}
  in out  buf: univ string_var_arg_t;  {returned line of message text}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_read_sio_rec (          {read next record from serial line}
  in      conn: file_conn_t;           {handle to serial line connection}
  in out  buf: univ string_var_arg_t;  {characters not including end of record}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_read_text (             {read one line of text from file}
  in out  conn: file_conn_t;           {handle to this file connection}
  in out  buf: univ string_var_arg_t;  {returned line of text}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_rename (                {change name of a file}
  in      old_name: univ string_var_arg_t; {old file name}
  in      new_name: univ string_var_arg_t; {new file name}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_set_env_bkwds (         {read ENV files in backwards order}
  in out  conn: file_conn_t);          {connection handle to env files}
  val_param; extern;

procedure file_sio_set_eor_read (      {set "end of record" to use for reading SIO}
  in out  conn: file_conn_t;           {handle to serial line connection}
  in      str: string;                 {the characters to look for}
  in      len: sys_int_machine_t);     {number of characters in STR}
  val_param; extern;

procedure file_sio_set_eor_write (     {set "end of record" to use for writing SIO}
  in out  conn: file_conn_t;           {handle to serial line connection}
  in      str: string;                 {the characters to add at end of record}
  in      len: sys_int_machine_t);     {number of characters in STR}
  val_param; extern;

procedure file_skip_text (             {skip over next N lines in text file}
  in out  conn: file_conn_t;           {file connection, must be open for read}
  in      n: sys_int_machine_t;        {number of text lines to skip}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_usbdev_list_del (       {delete USB devices list, dealloc resources}
  in out  list: file_usbdev_list_t);
  val_param; extern;

function file_usbid (                  {make USB device ID}
  in      vid, pid: sys_int_conv16_t)  {vendor ID (VID), product ID (PID)}
  :file_usbid_t;
  val_param; extern;

procedure file_write_bin (             {write data to binary file}
  in      buf: univ char;              {data to write}
  in      conn: file_conn_t;           {handle to this file connection}
  in      len: sys_int_adr_t;          {number of machine adr increments to write}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_write_embusb (          {write data to a Embed USB device}
  in      buf: univ char;              {data to write}
  in      conn: file_conn_t;           {connection to the USB device}
  in      len: sys_int_adr_t;          {number of machine adr increments to write}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure file_write_inetstr (         {write to an internet stream}
  in      buf: univ sys_size1_t;       {data to write}
  in out  conn: file_conn_t;           {handle to this stream connection}
  in      len: sys_int_adr_t;          {number of machine adr increments to write}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_write_sio_rec (         {write record to serial line}
  in      buf: univ string_var_arg_t;  {record to send, not including end of record}
  in      conn: file_conn_t;           {handle to serial line connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_write_text (            {write string as one line of text}
  in      buf: univ string_var_arg_t;  {string to write as text line}
  in out  conn: file_conn_t;           {handle to this I/O connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_write_dgram (           {send network datagram}
  in      buf: univ sys_size1_t;       {data to write}
  in out  conn: file_conn_t;           {handle to this connection to UDP server}
  in      len: sys_int_adr_t;          {number of machine adr increments to write}
  out     olen: sys_int_adr_t;         {number of bytes actually sent}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;
