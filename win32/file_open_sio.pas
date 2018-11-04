{   Subroutine FILE_OPEN_SIO (N, BAUD, CONFIG, CONN, STAT)
*
*   Open a connection to a serial line.  N is the serial line number.  BAUD
*   is the baud rate identifier.  CONFIG is a set of configuration flags.
*   Possible flags are:
*
*   FILE_SIO_XONOFF_SEND_K
*
*     Automatically send XOFF when the input buffer gets full, and XON when the
*     input buffer is sufficiently drained.  The default is to not automatically
*     produce XON/XOFF characters.
*
*   FILE_SIO_XONOFF_OBEY_K
*
*     Obey incoming XON/XOFF characters.  Transmission will automatically suspend
*     when an XOFF is received, and resume when an XON is received.  The XON and
*     XOFF characters will NOT be passed back to the caller in the data buffer.
*
*   FILE_SIO_RTSCTS_K
*
*     Use RTS/CTS flow control.
*
*   FILE_SIO_PAR_ODD_K
*
*     Use additional parity bit.  Odd parity.
*
*   FILE_SIO_PAR_EVEN_K
*
*     Use additional parity bit.  Even parity.
*
*   CONN is the connection handle that must be referenced in all further
*   interactions with this serial line until the connection is closed.
*   STAT is the completion status code.
}
module file_open_sio;
define file_open_sio;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

const
  envvar_dbg = 'SIO_DBG';              {name of envvar, value "ON" causes debug}
  ibufsize_k = 2048;                   {desired size of input buffer}
  obufsize_k = 2048;                   {desired size of output buffer}
  gnam = 'COM';                        {generic SIO device name}
  eor_char = chr(13);                  {default input and output end of record char}

procedure file_open_sio (              {open connection to a serial line}
  in      n: sys_int_machine_t;        {system serial line number}
  in      baud: file_baud_k_t;         {baud rate ID}
  in      config: file_sio_config_t;   {set of configuration flags}
  out     conn: file_conn_t;           {handle to new serial line connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  data_p: file_sio_data_p_t;           {pointer to our private data}
  dcb: win_dcb_t;                      {SIO line control state}
  commprop: commprop_t;                {comm port configuration properties}
  timeout: commtimeout_t;              {timeout info descriptor}
  token, tk: string_var16_t;           {scratch token for number conversion}
  isize, osize: sys_int_adr_t;         {desired input and output buffer sizes}
  err: sys_sys_err_t;                  {system error code}
  ok: win_bool_t;                      {WIN_BOOL_FALSE_K on system call failure}
  debug: boolean;                      {TRUE if in debug mode}
  parbit: boolean;                     {extra parity bit enabled}

label
  abort0, abort1;

begin
  token.max := size_char(token.str);   {init local var strings}
  tk.max := size_char(tk.str);

  sys_error_none (stat);               {init to no error occurred}
{
*   Set the DEBUG flag depending on whether debug mode is enabled.
}
  debug := false;                      {init to not in debug mode}

  string_vstring (token, envvar_dbg, size_char(envvar_dbg)); {make envvar name}
  sys_envvar_get (token, tk, stat);    {try to get environment variable value}
  if not sys_error(stat) then begin    {got environment variable value ?}
    string_upcase (tk);                {make value upper case for keyword matching}
    debug := string_equal(tk, string_v('ON'(0))); {set debug mode if keyword matches}
    end;
  sys_error_none (stat);               {reset to no error}

  parbit :=                            {TRUE if additional parity bit required}
    (file_sio_par_odd_k in config) or
    (file_sio_par_even_k in config);
{
*   Init CONN.
}
  conn.rw_mode := [file_rw_read_k, file_rw_write_k];
  conn.obty := file_obty_sio_k;
  conn.fmt := file_fmt_bin_k;
  conn.fnam.max := size_char(conn.fnam.str);
  conn.gnam.max := size_char(conn.gnam.str);
  conn.tnam.max := size_char(conn.tnam.str);
  conn.ext_num := 0;
  conn.lnum := 0;
  conn.data_p := nil;
  conn.close_p := nil;
  conn.sys := handle_none_k;
{
*   Open the SIO port.
}
  string_vstring (conn.gnam, gnam, size_char(gnam)); {init with fixed device name}
  string_f_int (token, n);             {make SIO line 1-N number string}
  string_append (conn.gnam, token);    {make device name with line number}
  string_vstring (conn.fnam, '\\.\', 4); {start with special "Win32 device" prefix}
  string_append (conn.fnam, conn.gnam); {make full name to open device with}
  string_terminate_null (conn.fnam);   {NULL terminate for system call}

  conn.sys := CreateFileA (            {open connection to SIO line}
    conn.fnam.str,                     {name of file to open}
    [faccess_read_k, faccess_write_k], {SIO line is bi-directional}
    [],                                {we won't share access with anyone else}
    nil,                               {no security attributes supplied}
    fcreate_existing_k,                {the device must already exist}
    [fattr_overlap_k],                 {allow overlapped I/O operations}
    handle_none_k);                    {no attributes template file supplied}
  if conn.sys = handle_invalid_k then begin {failed to open SIO line ?}
    err := GetLastError;               {get the system error code}
    stat.sys := err;
    if err = err_access_denied_k then begin {COM port in use ?}
      sys_stat_set (file_subsys_k, file_stat_sio_inuse_k, stat);
      sys_stat_parm_int (n, stat);
      end;
    if err = err_file_not_found_k then begin {no such COM port}
      sys_stat_set (file_subsys_k, file_stat_sio_nexist_k, stat);
      sys_stat_parm_int (n, stat);
      end;
    goto abort0;
    end;
{
*   Show some port configuration and default values if debug enabled.
}
  commprop.packet_len := size_min(commprop); {pass size of properties structure}
  commprop.prov_spec1 := commprop_init_k; {indicate PACKET_LEN already set}
  ok := GetCommProperties (            {get configuration and properties of port}
    conn.sys,                          {handle to communications port}
    commprop);                         {returned properties of the port}
  if ok = win_bool_false_k then begin
    stat.sys := GetLastError;
    goto abort1;
    end;

  if debug then begin
    write ('SIO ', n, ' max input buffer size = ');
    if commprop.max_rx_queue = 0
      then writeln ('- no limit -')
      else writeln (commprop.max_rx_queue);
    write ('SIO ', n, ' default input buffer size = ');
    if commprop.rx_queue = 0
      then writeln ('- unknown -')
      else writeln (commprop.rx_queue);
    write ('SIO ', n, ' max output buffer size = ');
    if commprop.max_tx_queue = 0
      then writeln ('- no limit -')
      else writeln (commprop.max_tx_queue);
    write ('SIO ', n, ' default output buffer size = ');
    if commprop.tx_queue = 0
      then writeln ('- unknown -')
      else writeln (commprop.tx_queue);
    end;
{
*   Try to set I/O buffer sizes.
}
  isize := ibufsize_k;                 {init input buffer size request}
  if commprop.max_rx_queue <> 0 then begin {max input buffer size is limited ?}
    isize := min(isize, commprop.max_rx_queue);
    end;
  osize := obufsize_k;                 {init output buffer size request}
  if commprop.max_rx_queue <> 0 then begin {max output buffer size is limited ?}
    osize := min(osize, commprop.max_tx_queue);
    end;

  ok := SetupComm (                    {request specific buffer sizes}
    conn.sys,                          {handle to communications port}
    isize,                             {desired size of input buffer}
    osize);                            {desired size of output buffer}
  if ok = win_bool_false_k then begin
    stat.sys := GetLastError;
    goto abort1;
    end;
{
*   Set the SIO line control state and intialize the SIO line.
}
  ok := GetCommState (conn.sys, dcb);  {get current control state in DCB}
  if ok = win_bool_false_k then begin
    stat.sys := GetLastError;
    goto abort1;
    end;

  case baud of                         {what baud rate was selected ?}
file_baud_300_k: dcb.baud := winbaud_300_k;
file_baud_1200_k: dcb.baud := winbaud_1200_k;
file_baud_2400_k: dcb.baud := winbaud_2400_k;
file_baud_4800_k: dcb.baud := winbaud_4800_k;
file_baud_9600_k: dcb.baud := winbaud_9600_k;
file_baud_19200_k: dcb.baud := winbaud_19200_k;
file_baud_38400_k: dcb.baud := winbaud_38400_k;
file_baud_57600_k: dcb.baud := winbaud_57600_k;
file_baud_115200_k: dcb.baud := winbaud_115200_k;
file_baud_153600_k: dcb.baud := winbaud_153600_k;
otherwise
    sys_stat_set (file_subsys_k, file_stat_bad_baud_k, stat);
    goto abort1;
    end;
  dcb.bin := true;                     {binary mode, no EOF check}
  dcb.parity_check := parbit;          {enable parity check if using parity bit}
  dcb.cts_obey := file_sio_rtscts_k in config; {obey incoming CTS flow control line}
  dcb.dsr_obey := false;               {ignore incoming DSR line}
  dcb.dtrdrv := dtrdrv_on_k;           {always assert DTR}
  dcb.dsrrcv := false;                 {receive characters regardless of DSR}
  dcb.xoff_send_go := true;            {sending XOFF doesn't effect other sending}
  dcb.x_obey := file_sio_xonoff_obey_k in config; {obey incoming XON/XOFF}
  dcb.x_send := file_sio_xonoff_send_k in config; {generate outgoing XON/XOFF}
  dcb.parity_char_replace := false;    {don't replace char on parity errors}
  dcb.null_discard := false;           {don't discard NULL characters}
  dcb.rtsdrv := rtsdrv_handshake_k;    {always do flow RTS flow control out}
  dcb.err_abort := false;              {don't abort I/O operations on any error}
  dcb.char_size := 8;                  {data bits per character}
  dcb.parity := parity_none_k;         {init to no parity bit}
  if file_sio_par_even_k in config then begin {using even parity ?}
    dcb.parity := parity_even_k;
    end;
  if file_sio_par_odd_k in config then begin {using odd parity ?}
    dcb.parity := parity_odd_k;
    end;
  dcb.stopbits := stopbits_1_k;        {use one stop bit}
  dcb.xon_char := 17;                  {XON is CTRL-Q}
  dcb.xoff_char := 19;                 {XOFF is CTRL-S}
  dcb.parity_char := 0;                {parity error replacement character, unused}
  dcb.eod_char := 0;                   {end of data char, unused}
  dcb.event_char := 0;                 {special event char, not used initially}

  ok := SetCommState (conn.sys, dcb);  {set new SIO line control state}
  if ok = win_bool_false_k then begin
    stat.sys := GetLastError;
    goto abort1;
    end;

  ok := PurgeComm (                    {clean up any junk in the buffers}
    conn.sys,                          {handle to I/O connection}
    [ commpurge_txabort_k,             {terminate outstanding write requests}
      commpurge_rxabort_k,             {terminate outstanding read requests}
      commpurge_txclear_k,             {discard output buffer contents}
      commpurge_rxclear_k]);           {discard input buffer contents}
  if ok = win_bool_false_k then begin
    stat.sys := GetLastError;
    goto abort1;
    end;

  timeout.read_interval := commtimeout_max_k; {wait on at least one char for read}
  timeout.read_per_char := commtimeout_max_k;
  timeout.read_fixed := rshft(commtimeout_max_k, 2);
  timeout.write_per_char := 0;         {disable write timeouts}
  timeout.write_fixed := 0;

  ok := SetCommTimeouts (              {set SIO port timeout strategy and values}
    conn.sys,                          {handle to I/O connection}
    timeout);                          {timeout info descriptor}
  if ok = win_bool_false_k then begin
    stat.sys := GetLastError;
    goto abort1;
    end;
{
*   Show final port configuration if debug enabled.
}
  if debug then begin
    ok := GetCommProperties (          {get configuration and properties of port}
      conn.sys,                        {handle to communications port}
      commprop);                       {returned properties of the port}
    if ok = win_bool_false_k then begin
      stat.sys := GetLastError;
      goto abort1;
      end;

    write ('SIO ', n, ' final input buffer size = ');
    if commprop.rx_queue = 0
      then writeln ('- unknown -')
      else writeln (commprop.rx_queue);
    write ('SIO ', n, ' final output buffer size = ');
    if commprop.tx_queue = 0
      then writeln ('- unknown -')
      else writeln (commprop.tx_queue);
    end;
{
*   Allocate and fill in our private state for this connection.
}
  sys_mem_alloc (sizeof(data_p^), data_p); {allocate private state block}
  sys_mem_error (data_p, '', '', nil, 0);

  data_p^.sio_n := n;                  {save system serial line number}
  data_p^.baud := baud;                {save our baud rate ID}
  data_p^.config := config;            {save caller's configuration flags}
  data_p^.in_id := conn.sys;           {handle for reading SIO line}
  data_p^.out_id := conn.sys;          {handle for writing to SIO line}
  data_p^.eor_in.max := size_char(data_p^.eor_in.str);
  data_p^.eor_in.str[1] := eor_char;
  data_p^.eor_in.len := 1;
  data_p^.eor_out.max := size_char(data_p^.eor_out.str);
  data_p^.eor_out.str[1] := eor_char;
  data_p^.eor_out.len := 1;
  data_p^.eor_in_on := true;           {enable input EOR recognition}
  data_p^.eor_out_on := true;          {enable output EOR generation}
{
*   Fix up any remaining fields in CONN.
}
  string_copy (conn.fnam, conn.tnam);  {just copy name used to open device}
  conn.data_p := data_p;               {save pointer to our private state block}
  conn.close_p := addr(file_close_sio); {set pointer to our specific CLOSE routine}
  return;                              {normal return, no error}
{
*   Error exits.  STAT must already be set.  The choice of ABORTn label
*   depends on what resources have already been allocated.
}
abort1:                                {SIO line open}
  discard( CloseHandle (conn.sys) );   {try to close SIO line connection}
abort0:                                {no resources allocated yet}
  end;
