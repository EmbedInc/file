{   Routines that impement the FILE library application calls for internet
*   stream I/O.  This module is system-specific, and may be customized for
*   different operating systems.  Module FILE_INET2.PAS contains additional
*   routines that may require a higher level of customization between
*   target systems.  For example, the generic version of FILE_INET.PAS
*   assumes the "standard" BSD Unix socket calls.  This version is the same
*   accross Unix systems and Domain/OS.  FILE_INET2.PAS contains routines
*   that are not constant accross all the unix platforms.
*
*   This version uses the Windows Socket calls.
}
module file_inet;
define file_create_inetstr_serv;
define file_inet_name_adr;
define file_inetstr_info_local;
define file_inetstr_info_remote;
define file_open_inetstr;
define file_open_inetstr_accept;
define file_inetstr_tout_rd;
define file_inetstr_tout_wr;
define file_read_inetstr;
define file_write_inetstr;
define file_close_inet;
define file_open_dgram_client;
define file_write_dgram;

%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';
%include 'file_inet.ins.pas';

type
  file_inetstr_dat_p_t = ^file_inetstr_dat_t;
  file_inetstr_dat_t = record          {private CONN data for internet stream}
    toutrd: real;                      {seconds timeout for read, 0 = none}
    toutwr: real;                      {seconds timeout for write, 0 = none}
    end;

  file_conndat_udp_p_t = ^file_conndat_udp_t;
  file_conndat_udp_t = record          {private CONN data for UDP socket}
    sockaddr: sockaddr_t;              {system info about the socket}
    end;
{
********************************************************************************
}
procedure file_close_inet (            {close connection to an internet stream}
  in      conn_p: file_conn_p_t);      {pointer to user file connection handle}
  val_param;

var
  err: sys_int_machine_t;              {error flag from system routine}

begin
  err := closesocket (conn_p^.sys);
  if err <> 0 then begin
    sys_sys_error_bomb ('file', 'close_inet_stream', nil, 0);
    end;
  conn_p^.sys := handle_none_k;
  end;
{
********************************************************************************
*
*   Local subroutine INETSTR_CONN (CONN)
*
*   Initialize the I/O connection descriptor CONN for a internet stream.
}
procedure inetstr_conn (               {init CONN for internet stream}
  out     conn: file_conn_t);          {connection descriptor to initialize}
  val_param; internal;

var
  dat_p: file_inetstr_dat_p_t;         {pointer to private conn data}

begin
  file_conn_init (conn);               {initialize CONN generally}

  conn.rw_mode := [file_rw_read_k, file_rw_write_k];
  conn.obty := file_obty_inetstr_k;
  conn.fmt := file_fmt_bin_k;
  conn.lnum := file_lnum_nil_k;
  conn.close_p := addr(file_close_inet); {point to our private close routine}

  sys_mem_alloc (sizeof(dat_p^), dat_p); {allocate private inet stream data}
  conn.data_p := dat_p;                {set pointer to the private data}
  dat_p^.toutrd := 0.0;                {init to no read timeout}
  dat_p^.toutwr := 0.0;                {init to no write timeout}
  end;
{
********************************************************************************
}
procedure file_inetstr_info_local (    {get local end info of internet stream conn}
  in      conn: file_conn_t;           {handle to internet stream connection}
  out     adr: sys_inet_adr_node_t;    {internet node address}
  out     port: sys_inet_port_id_t;    {port on node ADR}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  err: sys_int_machine_t;              {error flag from system routine}
  sockaddr: sockaddr_t;                {network socket full address}
  sz: sys_int_adr_t;

begin
  sys_error_none (stat);               {init to no error encountered}

  sz := sizeof(sockaddr);
  err := getsockname (                 {get info about socket at our end of stream}
    conn.sys,                          {ID of socket on our end}
    sockaddr,                          {returned full network address}
    sz);
  if err <> 0 then begin               {system error ?}
    stat.sys := WSAGetLastError;
    return;
    end;

  if sys_byte_order_k <> sys_byte_order_fwd_k then begin {flip from network order ?}
    sys_order_flip (sockaddr.inet_adr, sizeof(sockaddr.inet_adr));
    sys_order_flip (sockaddr.inet_port, sizeof(sockaddr.inet_port));
    end;

  adr := sockaddr.inet_adr;            {pass back internet address info}
  port := sockaddr.inet_port;
  end;
{
********************************************************************************
}
procedure file_inetstr_info_remote (   {get remote end info of internet stream conn}
  in      conn: file_conn_t;           {handle to internet stream connection}
  out     adr: sys_inet_adr_node_t;    {internet node address}
  out     port: sys_inet_port_id_t;    {port on node ADR}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  err: sys_int_machine_t;              {error flag from system routine}
  sockaddr: sockaddr_t;                {network socket full address}
  sz: sys_int_adr_t;

begin
  sys_error_none (stat);               {init to no error encountered}

  sz := sizeof(sockaddr);
  err := getpeername (                 {get info about socket at other end of stream}
    conn.sys,                          {ID of socket on our end}
    sockaddr,                          {returned full network address}
    sz);
  if err <> 0 then begin               {system error ?}
    stat.sys := WSAGetLastError;
    return;
    end;

  if sys_byte_order_k <> sys_byte_order_fwd_k then begin {flip from network order ?}
    sys_order_flip (sockaddr.inet_adr, sizeof(sockaddr.inet_adr));
    sys_order_flip (sockaddr.inet_port, sizeof(sockaddr.inet_port));
    end;

  adr := sockaddr.inet_adr;            {pass back internet address info}
  port := sockaddr.inet_port;
  end;
{
********************************************************************************
*
*   Subroutine FILE_INET_NAME_ADR (NAME, ADR, STAT)
*
*   Find the internet address of a node, given its name.  NAME must be either
*   the name of a known node, or a dot notation internet address string.
}
procedure file_inet_name_adr (         {convert machine name to internet address}
  in      name: univ string_var_arg_t; {node name, may have domains, etc.}
  out     adr: sys_inet_adr_node_t;    {internet addres by which to reach machine}
  out     stat: sys_err_t);            {error status code}
  val_param;

var
  host_p: hostent_p_t;                 {pointer to info about node}
  cname: array[1..1024] of char;       {null terminated host name in C format}
  clen: sys_int_machine_t;             {number of characters in CNAME}
  i: sys_int_machine_t;                {scratch integer and loop counter}

begin
  string_t_inetadr (                   {try converting from "dot notation" name}
    name,                              {input name}
    adr,                               {returned binary internet address}
    stat);
  if not sys_error(stat) then return;  {was dot notation, all done ?}

  sys_error_none (stat);               {clear error code}
{
*   The node name is not a dot notation internet address.  We now have to
*   ask the system to translate the name to an address.
}
  sys_sys_netstart;                    {initialize network DLL, if not already}

  clen := min(size_char(cname) - 1, name.len); {number of characters to copy}
  for i := 1 to clen  do begin         {copy name into C format}
    cname[i] := name.str[i];
    end;
  cname[clen + 1] := chr(0);           {write null string terminator}

  host_p := gethostbyname (cname);     {get pointer to info about this node}

  if host_p = nil then begin           {system couldn't find entry for node name ?}
    stat.sys := WSAGetLastError;       {save the system error ID}
    if stat.sys <> err_host_unknown_k then return; {not error we recognize ?}
    end;

  if                                   {no internet address returned ?}
      (host_p = nil) or else
      (host_p^.adr_list_p = nil) or else
      (host_p^.adr_list_p^[1] = nil)
      then begin
    sys_stat_set (file_subsys_k, file_stat_inet_name_adr_k, stat);
    sys_stat_parm_vstr (name, stat);
    return;                            {return with error}
    end;

  adr := host_p^.adr_list_p^[1]^;      {fetch internet address of remote machine}
  if sys_byte_order_k <> sys_byte_order_fwd_k then begin {flip from network order ?}
    sys_order_flip (adr, sizeof(adr));
    end;
  end;
{
********************************************************************************
}
procedure file_create_inetstr_serv (   {create internet stream server port}
  in      node: sys_inet_adr_node_t;   {inet adr or FILE_INET_NODE_ANY_K}
  in      port: sys_inet_port_id_t;    {requested port on this machine or unspec}
  out     serv: file_inet_port_serv_t; {returned handle to new server port}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  sockaddr: sockaddr_t;                {socket address descriptor}
  err: sys_int_machine_t;              {error flag from system routine}
  sz: sys_int_adr_t;                   {memory size}

label
  abort;

begin
  sys_error_none (stat);               {init to no errors encountered}
  sys_sys_netstart;                    {initialize network DLL, if not already}
{
*   Create socket that clients will reference in connection requests.
}
  serv.socket_id := socket (           {create our server socket}
    adrfam_inet_k,                     {use internet address family}
    socktype_stream_k,                 {socket will be for stream-type connection}
    protfam_unspec_k);
  if serv.socket_id = socket_invalid_k then begin {error creating socket ?}
    stat.sys := WSAGetLastError;       {return system error code}
    return;
    end;
{
*   Bind socket to a specific internet port on this machine.
}
  file_inet_sockaddr_init (sockaddr);  {init internet socket address descriptor}
  sockaddr.inet_port := port;          {set requested port ID}
  sockaddr.inet_adr := node;           {set node address to respond to}
  if sys_byte_order_k <> sys_byte_order_fwd_k then begin {flip to network order ?}
    sys_order_flip (sockaddr.inet_adr, sizeof(sockaddr.inet_adr));
    sys_order_flip (sockaddr.inet_port, sizeof(sockaddr.inet_port));
    end;
  err := bind (                        {bind socket to requested network port}
    serv.socket_id,                    {ID of socket to bind}
    sockaddr,                          {requested network address of socket}
    sockaddr_len_inet_k);              {size of used data in SOCKADDR}
  if err <> 0 then begin               {error binding socket to address ?}
abort:                                 {abort on error after socket created}
    stat.sys := WSAGetLastError;       {return system error code}
    discard( closesocket (serv.socket_id) ); {get rid of our newly created socket}
    return;                            {return with error}
    end;

  sz := sizeof(sockaddr);
  err := getsockname (                 {find out what we ended up with}
    serv.socket_id,                    {ID of socket inquiring about}
    sockaddr,                          {returned full network socket address}
    sz);                               {max size in, size written on out}
  if err <> 0 then goto abort;         {error on GETSOCKNAME call ?}
  if sys_byte_order_k <> sys_byte_order_fwd_k then begin {flip from network order ?}
    sys_order_flip (sockaddr.inet_adr, sizeof(sockaddr.inet_adr));
    sys_order_flip (sockaddr.inet_port, sizeof(sockaddr.inet_port));
    end;
  serv.port := sockaddr.inet_port;     {return port number actually picked}
{
*   Enable socket to handle client connection requests.
}
  err := listen (                      {set up socket to handle connect requests}
    serv.socket_id,                    {ID of socket}
    8);                                {max connect requests allowed to queue}
  if err <> 0 then goto abort;         {error on LISTEN call ?}
  end;
{
********************************************************************************
}
procedure file_open_inetstr_accept (   {open internet stream when client requests}
  in      port_serv: file_inet_port_serv_t; {handle to internet server port}
  out     conn: file_conn_t;           {connection handle to new internet stream}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  sock: socketid_t;                    {ID of new socket for connection to client}
  sockaddr: sockaddr_t;                {address of new socket}
  sz: sys_int_adr_t;                   {memory size}

begin
  sys_error_none(stat);                {init to no error occurred}

  sz := sizeof(sockaddr);
  sock := accept (                     {wait for client to request connection}
    port_serv.socket_id,               {socket waiting for client connection request}
    sockaddr,                          {returned address of new socket}
    sz);                               {max ADR size in, actual size used out}
  if sock = socket_invalid_k then begin {error ?}
    stat.sys := WSAGetLastError;       {pass back system error code}
    return;
    end;
{
*   Connection has been established.  Fill in connection handle.
}
  inetstr_conn (conn);                 {initialize CONN for inet stream}
  conn.sys := sock;                    {save system handle to stream}
  end;
{
********************************************************************************
}
procedure file_open_inetstr (          {open internet stream to existing port}
  in      node: sys_inet_adr_node_t;   {internet address of node}
  in      port: sys_inet_port_id_t;    {internet port within node}
  out     conn: file_conn_t;           {connection handle to new internet stream}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  sock: socketid_t;                    {ID of socket for our end of connection}
  sockaddr: sockaddr_t;                {complete socket address descriptor}
  err: sys_int_machine_t;              {error flag from system routine}

begin
  sys_error_none(stat);                {init to no errors encountered}
  sys_sys_netstart;                    {initialize network DLL, if not already}

  sock := socket (                     {create socket we can use to make connection}
    adrfam_inet_k,                     {use internet address family}
    socktype_stream_k,                 {socket will be for stream-type connection}
    protfam_unspec_k);
  if sock = socket_invalid_k then begin {error creating socket ?}
    stat.sys := WSAGetLastError;       {return system error code}
    return;
    end;

  file_inet_sockaddr_init (sockaddr);  {init internet socket address descriptor}
  sockaddr.inet_adr := node;           {set address of remote node}
  sockaddr.inet_port := port;          {set port number within remote node}
  if sys_byte_order_k <> sys_byte_order_fwd_k then begin {flip to network order ?}
    sys_order_flip (sockaddr.inet_adr, sizeof(sockaddr.inet_adr));
    sys_order_flip (sockaddr.inet_port, sizeof(sockaddr.inet_port));
    end;

  err := connect (                     {try to connect to remote port}
    sock,                              {socket to use for our connection end}
    sockaddr,                          {address of remote port to connect to}
    sockaddr_len_inet_k);              {length of ADR actually used}
  if err <> 0 then begin               {error on connect attempt ?}
    stat.sys := WSAGetLastError;       {return system error code}
    return;
    end;
{
*   Connection has been established.  Fill in connection handle.
}
  inetstr_conn (conn);                 {initialize CONN for inet stream}
  conn.sys := sock;                    {save system handle to stream}
  end;
{
********************************************************************************
}
procedure file_inetstr_tout_rd (       {set internet stream read timeout}
  in out  conn: file_conn_t;           {connection to the internet strea}
  in      tout: real);                 {timeout in seconds, 0 = none}
  val_param;

var
  dat_p: file_inetstr_dat_p_t;         {pointer to private connection data}

begin
  dat_p := conn.data_p;                {get pointer to private data}
  if dat_p = nil then return;          {no private data (shouldn't happen) ?}

  dat_p^.toutrd := tout;               {save the new timeout value}
  end;
{
********************************************************************************
}
procedure file_inetstr_tout_wr (       {set internet stream write timeout}
  in out  conn: file_conn_t;           {connection to the internet strea}
  in      tout: real);                 {timeout in seconds, 0 = none}
  val_param;

var
  dat_p: file_inetstr_dat_p_t;         {pointer to private connection data}

begin
  dat_p := conn.data_p;                {get pointer to private data}
  if dat_p = nil then return;          {no private data (shouldn't happen) ?}

  dat_p^.toutwr := tout;               {save the new timeout value}
  end;
{
********************************************************************************
*
*   Subroutine FILE_READ_INETSTR (CONN, ILEN, FLAGS, BUF, OLEN, STAT)
*
*   Read the next ILEN bytes from the internet stream open on CONN.
*   The data will be read into BUF, and OLEN will be returned the amount
*   of data written into BUF.  OLEN is guaranteed to never exceed ILEN.
*   FLAGS is a set of flags that modify the routine operation:
*
*     FILE_RDSTREAM_1CHUNK_K  -  Return with whatever data is available,
*       but wait for at least some data to be available.  OLEN will be
*       returned indicating the amount of data actually read, which may
*       be less than ILEN but at least one except on an error.  STAT
*       will not indicate an error if less than ILEN data is being
*       returned.
}
procedure file_read_inetstr (          {read from an internet stream}
  in out  conn: file_conn_t;           {handle to this internet stream connection}
  in      ilen: sys_int_adr_t;         {number of machine adr increments to read}
  in      flags: file_rdstream_t;      {set of modifier flags}
  out     buf: univ sys_size1_t;       {buffer to read data into}
  out     olen: sys_int_adr_t;         {amount of data actually read}
  out     stat: sys_err_t);            {completion status code}
  val_param;

const
  show_err_codes = false;              {debug switch to show low level error codes}

var
  dat_p: file_inetstr_dat_p_t;         {pointer to private connection data}
  n_left: sys_int_adr_t;               {number of bytes left to stuff into BUF}
  n_chunk: win_dword_t;                {number of bytes read in this chunk}
  put_p: sys_size1_p_t;                {points to next byte to write into BUF}
  overlap: overlap_t;                  {overalpped I/O control block}
  err: sys_sys_err_t;                  {system error code}
  ok: win_bool_t;                      {not zero on system call success}
  donewait: donewait_k_t;              {reason wait completed}
  tout: win_dword_t;                   {timeout value in system format}

label
  leave;

begin
  sys_error_none(stat);                {init to no error occurred}

  dat_p := conn.data_p;                {get pointer to private data for this connection}

  n_left := ilen;                      {init number of bytes left to return}
  put_p := addr(buf);                  {init pointer to next byte to write}
  olen := 0;                           {init amount of data actually read}
  overlap.offset := 0;                 {file offsets not used on streams}
  overlap.offset_high := 0;
  overlap.event_h := CreateEventA (    {create event for overalpped I/O}
    nil,                               {no security attributes supplied}
    win_bool_true_k,                   {no automatic event reset on successful wait}
    win_bool_false_k,                  {init event to not triggered}
    nil);                              {no name supplied}

  while n_left > 0 do begin            {keep looping until got everything}
    ok := ReadFile (                   {try to read requested info from stream}
      conn.sys,                        {system I/O connection handle}
      put_p^,                          {input buffer}
      n_left,                          {number of bytes to try to read}
      n_chunk,                         {number of bytes actually read}
      addr(overlap));                  {pointer to overlapped I/O control block}
    if ok = win_bool_false_k then begin {error on ReadFile}
      err := GetLastError;             {get reason ReadFile failed}
      if err <> err_io_pending_k then begin {not just overlapped I/O ?}
        stat.sys := err;               {pass back error code}
        if show_err_codes then begin
          writeln ('FILE_READ_INETSTR: error ', stat.sys, ' from ReadFile');
          end;
        goto leave;                    {return with hard error}
        end;
      {
      *   The I/O operation was started, but ReadFile returned before it
      *   completed.  The event in the overlap structure will be signalled when
      *   the I/O operation does complete.
      }
      tout := timeout_infinite_k;      {init to no timeout, wait indefinitely}
      if (dat_p <> nil) and then (dat_p^.toutrd > 0.0) then begin {timeout supplied ?}
        tout := round(max(1.0, dat_p^.toutrd * 1000.0)); {convert to integer milliseconds}
        end;
      donewait := WaitForSingleObject ( {wait for I/O completed or timeout}
        overlap.event_h,               {event to wait on}
        tout);                         {maximum time to wait}
      case donewait of
donewait_failed_k: begin               {hard error ?}
          stat.sys := GetLastError;
          goto leave;
          end;
donewait_timeout_k: begin              {timed out, I/O didn't complete ?}
          sys_stat_set (file_subsys_k, file_stat_timeout_k, stat);
          goto leave;
          end;
        end;
      {
      *   The I/O operation completed.
      }
      ok := GetOverlappedResult (      {get info about the I/O operation}
        conn.sys,                      {handle I/O operation is in progress on}
        overlap,                       {overlap control block for this operation}
        n_chunk,                       {number of bytes actually read}
        win_bool_true_k);              {wait for I/O to complete}
      if ok = win_bool_false_k then begin {system call failed ?}
        stat.sys := GetLastError;
        if show_err_codes then begin
          writeln ('FILE_READ_INETSTR: error ', stat.sys, ' from GetOverlappedResult');
          end;
        goto leave;
        end;
      end;
    olen := olen + n_chunk;            {update amount of data actually read}
    if
        (olen > 0) and                 {have some data ?}
        (file_rdstream_1chunk_k in flags) then begin {return when anything received ?}
      goto leave;
      end;
    if n_chunk = 0 then begin          {connection got closed ?}
      if show_err_codes then begin
        writeln ('FILE_READ_INETSTR: 0 bytes returned by ReadFile');
        end;
      if olen = 0
        then begin                     {we encountered end of file immediately}
          sys_stat_set (file_subsys_k, file_stat_eof_k, stat);
          end
        else begin                     {some data was read before end of file}
          sys_stat_set (file_subsys_k, file_stat_eof_partial_k, stat);
          sys_stat_parm_int (ilen, stat);
          sys_stat_parm_int (olen, stat);
          end
        ;
      goto leave;
      end;

    n_left := n_left - n_chunk;        {update number of bytes left to read}
    put_p := univ_ptr(                 {update pointer to where to read next byte}
      sys_int_adr_t(put_p) + n_chunk);
    end;                               {try again if more left to read}

leave:
  discard( CloseHandle(overlap.event_h) ); {deallocate I/O completion event}
  if                                   {check for errors that should be reported as EOF}
      (stat.sys = err_net_gone_k) or
      (stat.sys = 64)
      then begin
    sys_stat_set (file_subsys_k, file_stat_eof_k, stat);
    end;
  end;
{
********************************************************************************
}
procedure file_write_inetstr (         {write to an internet stream}
  in      buf: univ sys_size1_t;       {data to write}
  in out  conn: file_conn_t;           {handle to this stream connection}
  in      len: sys_int_adr_t;          {number of machine adr increments to write}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  dat_p: file_inetstr_dat_p_t;         {pointer to private connection data}
  olen: win_dword_t;                   {number of bytes actually written}
  overlap: overlap_t;                  {overalpped I/O control block}
  err: sys_sys_err_t;                  {system error code}
  ok: win_bool_t;                      {not zero on system call success}
  donewait: donewait_k_t;              {reason wait completed}
  tout: win_dword_t;                   {timeout value in system format}

label
  leave;

begin
  sys_error_none (stat);               {init to no errors encountered}
  if len = 0 then return;              {nothing to write ?}

  dat_p := conn.data_p;                {get pointer to private data for this connection}

  overlap.offset := 0;                 {file offsets not used on streams}
  overlap.offset_high := 0;
  overlap.event_h := CreateEventA (    {create event for overalpped I/O}
    nil,                               {no security attributes supplied}
    win_bool_true_k,                   {no automatic event reset on successful wait}
    win_bool_false_k,                  {init event to not triggered}
    nil);                              {no name supplied}

  ok := WriteFile (                    {try to write data to the stream}
    conn.sys,                          {system I/O connection handle}
    buf,                               {output buffer}
    len,                               {number of bytes to write}
    olen,                              {number of bytes actually written}
    addr(overlap));                    {pointer to overlapped I/O control block}
  if ok = win_bool_false_k then begin  {error on WriteFile}
    err := GetLastError;               {get reason ReadFile failed}
    if err <> err_io_pending_k then begin {not just overlapped I/O ?}
      stat.sys := err;                 {pass back error code}
      goto leave;                      {return with hard error}
      end;
    {
    *   The I/O operation was started, but WriteFile returned before it
    *   completed.  The event in the overlap structure will be signalled when
    *   the I/O operation does complete.
    }
    tout := timeout_infinite_k;        {init to no timeout, wait indefinitely}
    if (dat_p <> nil) and then (dat_p^.toutwr > 0.0) then begin {timeout supplied ?}
      tout := round(max(1.0, dat_p^.toutwr * 1000.0)); {convert to integer milliseconds}
      end;
    donewait := WaitForSingleObject (  {wait for I/O completed or timeout}
      overlap.event_h,                 {event to wait on}
      tout);                           {maximum time to wait}
    case donewait of
donewait_failed_k: begin               {hard error ?}
        stat.sys := GetLastError;
        goto leave;
        end;
donewait_timeout_k: begin              {timed out, I/O didn't complete ?}
        sys_stat_set (file_subsys_k, file_stat_timeout_k, stat);
        goto leave;
        end;
      end;
    {
    *   The I/O operation completed.
    }
    ok := GetOverlappedResult (        {get info about the I/O operation}
      conn.sys,                        {handle I/O operation in progress on}
      overlap,                         {overlap control block for this operation}
      olen,                            {number of bytes actually read}
      win_bool_true_k);                {wait for I/O to complete}
    if ok = win_bool_false_k then begin {system call failed ?}
      stat.sys := GetLastError;
      goto leave;
      end;
    end;

  if olen <> len then begin            {didn't write all the requested info ?}
    sys_stat_set (file_subsys_k, file_stat_write_size_k, stat);
    sys_stat_parm_vstr (conn.tnam, stat);
    sys_stat_parm_int (len, stat);
    sys_stat_parm_int (olen, stat);
    end;

leave:
  discard( CloseHandle(overlap.event_h) ); {deallocate I/O completion event}
  end;
{
********************************************************************************
}
procedure file_open_dgram_client (     {set up for sending datagrams to remote server}
  in      node: sys_inet_adr_node_t;   {internet address of node}
  in      port: sys_inet_port_id_t;    {internet port within node}
  out     conn: file_conn_t;           {connection handle to new internet stream}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  sock: socketid_t;                    {ID of new socket for connection to client}
  dat_p: file_conndat_udp_p_t;         {pointer to private connection data}

begin
  sys_error_none (stat);               {init to no errors encountered}
  sys_sys_netstart;                    {initialize network DLL, if not already}
{
*   Create socket that will be used to send and receive data.
}
  sock := socket (                     {create our socket}
    adrfam_inet_k,                     {use internet address family}
    socktype_dgram_k,                  {socket will be for datagrams}
    protfam_unspec_k);
  if sock = socket_invalid_k then begin {error creating socket ?}
    stat.sys := WSAGetLastError;       {return system error code}
    return;
    end;
{
*   Fill in the CONN structure.
}
  sys_mem_alloc (sizeof(dat_p^), dat_p); {allocate private data descriptor}
  dat_p^.sockaddr.adrfam := ord(adrfam_inet_k); {fill in the private data}
  dat_p^.sockaddr.inet_port := port;   {save port number on remote system}
  dat_p^.sockaddr.inet_adr := node;    {address of the remote node}
  if sys_byte_order_k <> sys_byte_order_fwd_k then begin {flip to network byte order ?}
    sys_order_flip (dat_p^.sockaddr.inet_adr, sizeof(dat_p^.sockaddr.inet_adr));
    sys_order_flip (dat_p^.sockaddr.inet_port, sizeof(dat_p^.sockaddr.inet_port));
    end;

  conn.rw_mode := [file_rw_read_k, file_rw_write_k];
  conn.obty := file_obty_dgram_k;
  conn.fmt := file_fmt_bin_k;
  conn.fnam.max := sizeof(conn.fnam.str);
  conn.fnam.len := 0;
  conn.gnam.max := sizeof(conn.gnam.str);
  conn.gnam.len := 0;
  conn.tnam.max := sizeof(conn.tnam.str);
  conn.tnam.len := 0;
  conn.ext_num := 0;
  conn.lnum := file_lnum_nil_k;
  conn.data_p := dat_p;
  conn.close_p := addr(file_close_inet); {point to our private close routine}
  conn.sys := sock;
  end;
{
********************************************************************************
}
procedure file_write_dgram (           {send network datagram}
  in      buf: univ sys_size1_t;       {data to write}
  in out  conn: file_conn_t;           {handle to this connection to UDP server}
  in      len: sys_int_adr_t;          {number of machine adr increments to write}
  out     olen: sys_int_adr_t;         {number of bytes actually sent}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  dat_p: file_conndat_udp_p_t;         {pointer to private connection data}
  err: sys_int_machine_t;              {error status returned by system routine}

begin
  sys_error_none (stat);               {init to no error encountered}
  dat_p := conn.data_p;                {get pointer to private connection state}

  err := sendto (                      {send the datagram}
    conn.sys,                          {socket ID}
    buf,                               {data buffer}
    len,                               {number of data bytes to send}
    [],                                {no special options}
    dat_p^.sockaddr,                   {full network address to send to}
    sizeof(dat_p^.sockaddr));
  if err < 0 then begin                {hard error ?}
    olen := 0;
    stat.sys := WSAGetLastError;
    return;
    end;
  olen := err;                         {return number of bytes actually written}
  if err = len then begin              {full success}
    return;
    end;
{
*   Only some of the data was sent.
}
  sys_stat_set (file_subsys_k, file_stat_write_partial_k, stat);
  end;
