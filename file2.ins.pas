{   Private include file used to implement all the FILE_ routines.
*
*   This is the base internal include file for the file library.  It has no
*   branches, and contains no system-specific customizations.  Such
*   customizations must be put into FILE_SYS2.INS.PAS.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'file_map2.ins.pas';

const
  file_textr_bufsize = 8192;           {size of generic text read input buffer}
  file_textr_bufmax = file_textr_bufsize - 1; {max array index for text read buffer}

type
  file_map_data_p_t =                  {pointer to private data for mapped file}
    ^file_map_data_t;                  {data structure declared in FILE_MAP2.INS.PAS}

  file_textr_data_t = record           {private data used by generic text read rout}
    conn: file_conn_t;                 {handle to actual file open for binary read}
    nxchar: sys_int_machine_t;         {BUF index to next unread character}
    nbuf: sys_int_machine_t;           {total number of characters in buffer}
    ofs: sys_int_adr_t;                {file offset for first character in buffer}
    eof: boolean;                      {TRUE if end of buffer is end of file}
    buf: array[0..file_textr_bufmax] of char; {input buffer}
    end;
  file_textr_data_p_t = ^file_textr_data_t;

  file_env_data_t = record             {private data about set of environment files}
    closed: boolean;                   {TRUE if no file currently open}
    next_dir_p: sys_name_ent_p_t;      {points to entry for next directory to try}
    conn: file_conn_t;                 {connection handle for current open file}
    forwards: boolean;                 {TRUE if scanning directories in fwd order}
    end;
  file_env_data_p_t = ^file_env_data_t;

  file_msg_data_t = record             {private data about connection to a message}
    msg: string_var80_t;               {message name within subsystem}
    parms_p: sys_parm_msg_ar_p_t;      {points to list of parameter pointers}
    n_parms: sys_int_machine_t;        {number of parameter pointers in PARMS_P^}
    conn: file_conn_t;                 {connection handle to .msg file set}
    lang_p: sys_lang_p_t;              {pointer to current language descriptor}
    buf: string_var8192_t;             {pending message text not passed back yet}
    p: string_index_t;                 {BUF index to text not yet passed back}
    eof: boolean;                      {TRUE if hit end of input message}
    flow: boolean;                     {TRUE if text flow enabled}
    end;
  file_msg_data_p_t = ^file_msg_data_t;

  file_sio_data_t = record             {private data about SIO line connection}
    sio_n: sys_int_machine_t;          {serial line number}
    baud: file_baud_k_t;               {baud rate ID}
    config: file_sio_config_t;         {set of configuration flags}
    in_id: sys_sys_iounit_t;           {stream ID for reading SIO line}
    out_id: sys_sys_iounit_t;          {stream ID for writing to SIO line}
    eor_in: string_var16_t;            {end of record to recognize on input}
    eor_out: string_var16_t;           {end of record to send on output}
    eor_in_on: boolean;                {TRUE if input end of record enabled}
    eor_out_on: boolean;               {TRUE if output end of record enabled}
    end;
  file_sio_data_p_t = ^file_sio_data_t;

  file_name_handle_t = record          {handle for creating file names}
    ext: string_var80_t;               {list of suffixes separated by blanks}
    p: string_index_t;                 {parse index into EXT}
    name_p: string_var_p_t;            {points to caller's original name string}
    conn_p: file_conn_p_t;             {points to connection handle}
    end;

var (file2)                            {private common block for FILE library}
  file_map_ftn_inhibit: boolean := false; {FTN array access problem inhibit map files}
{
*   Private subroutines.
}
procedure file_close_embusb (          {close connection to Embed USB device}
  in      conn_p: file_conn_p_t);      {pointer to the connection to close}
  val_param; extern;

procedure file_close_env (             {close conn opened with FILE_OPEN_READ_ENV}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param; extern;

procedure file_close_map (             {close connection to mapped file}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param; extern;

procedure file_close_msg (             {close connection to message in .msg file}
  in      conn_p: file_conn_p_t);
  val_param; extern;

procedure file_close_sio (             {close connection to serial I/O line}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param; extern;

procedure file_close_stream (          {close connection to system stream}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param; extern;

procedure file_close_textr (           {close conn opened with FILE_OPEN_READ_TEXT}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param; extern;

procedure file_csrv_close_txw (        {close remote COGSERVE text write file}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param; extern;

procedure file_csrv_txw_open (         {open COGSERVE text write file}
  in out  conn: file_conn_t;           {user text file write connection handle}
  out     stat: sys_err_t);            {returned completion status code}
  val_param; extern;

procedure file_csrv_txw_write (        {write line to COGSERVE remote text file}
  in      buf: univ string_var_arg_t;  {string to write to line}
  in out  conn: file_conn_t;           {handle to this file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_name_init (             {init for creating file names from user args}
  in      name: univ string_var_arg_t; {file name}
  in      ext: string;                 {suffixes string}
  in      rw: file_rw_t;               {read/write modes}
  out     conn: file_conn_t;           {will be initialized}
  out     h: file_name_handle_t);      {handle for call to make successive names}
  val_param; extern;

function file_name_next (              {create next file name to try to open}
  in out  h: file_name_handle_t)       {handle from FILE_NAME_INIT}
  :boolean;                            {TRUE if did create a new name}
  val_param; extern;

procedure file_pos_end_textr (         {position to end of text read file}
  in out  conn: file_conn_t;           {handle to this file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_pos_get_textr (         {get curr position of text read file}
  in      conn: file_conn_t;           {handle to this file connection}
  out     pos: file_pos_t);            {handle to current file position}
  val_param; extern;

procedure file_pos_set_textr (         {set curr position of text read file}
  in out  pos: file_pos_t;             {position handle obtained with FILE_POS_GET}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_pos_start_textr (       {position to start of text read file}
  in out  conn: file_conn_t;           {handle to this file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure file_set_ftn_map_inhibit_;   {flags to not use mapped files for DS problem}
  extern;

procedure file_usbdev_list_add (       {add entry to end of USB devices list}
  in out  list: file_usbdev_list_t);   {the list to add entry to}
  val_param; extern;

procedure file_usbdev_list_init (      {init USB devices list descriptor}
  out     list: file_usbdev_list_t);
  val_param; extern;

procedure file_usbdev_list_start (     {start a new USB devices list, alloc resources}
  in out  mem: util_mem_context_t;     {context new list context will be created in}
  out     list: file_usbdev_list_t);   {the list to start}
  val_param; extern;

procedure file_embusb_sys_enum (       {adds all known Embed USB devices to list}
  in out  devs: file_usbdev_list_t);   {list to add to, must be previously started}
  val_param; extern;

function file_embusb_sys_open_data (   {open exclusive data-transfer conn to USB dev}
  in      path: univ string_var_arg_t; {base system pathname of the device}
  in      drtype: sys_int_machine_t;   {driver type ID, 1 old, 2 new}
  out     stat: sys_err_t)             {completion status}
  :sys_sys_file_conn_t;                {returned I/O connection handle}
  val_param; extern;

function file_embusb_sys_open_info (   {open non-exclusive info-only conn to USB dev}
  in      path: univ string_var_arg_t; {base system pathname of the device}
  in      drtype: sys_int_machine_t;   {driver type ID, 1 old, 2 new}
  out     stat: sys_err_t)             {completion status}
  :sys_sys_file_conn_t;                {returned I/O connection handle}
  val_param; extern;
