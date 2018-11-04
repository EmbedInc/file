{   Routines for performing I/O to Embed USB devices.
}
module file_embusb_sys;
define file_open_embusb;
define file_close_embusb;
define file_read_embusb;
define file_write_embusb;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

type
  file_embusb_data_p_t = ^file_embusb_data_t;
  file_embusb_data_t = record          {private data for Embed USB data connection}
    ovl_out: overlap_t;                {overlapped I/O descriptor for output}
    ovl_in: overlap_t;                 {overlapped I/O descriptor for input}
    name: string_var80_t;              {user name of the device}
    end;
{
********************************************************************************
*
*   Subroutine FILE_OPEN_EMBUSB (USBID, NAME, CONN, STAT)
*
*   Open a exclusive data-transfer connection to a Embed USB device.  USBID
*   identifies the device type, and NAME optionally specifies the internal name
*   of the device.  If NAME is the empty string, then one of the matching
*   devices that is not already in use will be arbitrarily picked.
}
procedure file_open_embusb (           {open bi-directional stream to Embed USB device}
  in      usbid: file_usbid_t;         {VID/PID of the device to open}
  in      name: univ string_var_arg_t; {name of device, empty string means any}
  out     conn: file_conn_t;           {returned connection to the USB device}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  vid, pid: sys_int_machine_t;         {USB device vendor and product IDs}
  list: file_usbdev_list_t;            {list of devices with this ID}
  dev_p: file_usbdev_p_t;              {pointer to current devices list entry}
  dat_p: file_embusb_data_p_t;         {pointer to private connection data}
  listop: boolean;                     {the devices list is open, resources allocated}
  busy: boolean;                       {matching device was found, but it was busy}

label
  next_dev, opened, abort2, abort1, not_found, err_vidpid, leave_err;

begin
  dat_p := nil;                        {init to private data not allocated}
  listop := false;                     {init to devices list is not open}
  vid := rshft(usbid, 16) & 16#FFFF;   {extract VID}
  pid := usbid & 16#FFFF;              {extract PID}
  if (vid = 0) and (pid = 0) then goto not_found; {invalid VID/PID ?}

  file_embusb_list_get (               {make list of devices with this VID/PID}
    usbid, util_top_mem_context, list, stat);
  if sys_error(stat) then goto leave_err;
  listop := true;                      {indicate devices list is open}

  busy := false;                       {init to no matching device found at all}
  dev_p := list.list_p;                {init to first list entry}
  while dev_p <> nil do begin          {back here to check each new list entry}
    if                                 {this device doesn't match ?}
        (name.len > 0) and then        {caller specified a particular name ?}
        not string_equal (dev_p^.name, name) {but doesn't match this name ?}
      then goto next_dev;              {ignore this device, on to next}
    conn.sys := file_embusb_sys_open_data ( {open data connection to the device}
      dev_p^.path,                     {system pathname of the device}
      dev_p^.drtype,                   {driver type ID}
      stat);
    if not sys_error(stat) then goto opened; {opened successfully ?}
    busy := true;                      {indicate matching device found, but was busy}
next_dev:                              {advance to the next device in the list}
    dev_p := dev_p^.next_p;
    end;
{
*   No device was opened.
}
  if busy then begin                   {suitable device found but was busy ?}
    sys_stat_set (file_subsys_k, file_stat_usbdev_busy_k, stat);
    sys_stat_parm_vstr (name, stat);
    goto err_vidpid;
    end;

  goto not_found;                      {no suitable device was found at all}
{
*   A matching device was found and a exclusive data connection to it has been
*   opened.
}
opened:
  sys_mem_alloc (sizeof(dat_p^), dat_p); {allocate private data area for this conn}
{
*   Create the overlapped I/O events that will be used for reading and writing
*   later.
}
  dat_p^.ovl_out.event_h := CreateEventA ( {create event for output overlapped I/O}
    nil,                               {no security attributes supplied}
    win_bool_true_k,                   {no automatic event reset on successful wait}
    win_bool_false_k,                  {init event to not triggered}
    nil);                              {no name supplied}
  if dat_p^.ovl_out.event_h = handle_none_k then begin {error creating event ?}
    stat.sys := GetLastError;
    goto abort1;                       {abort with I/O connection open}
    end;
  dat_p^.ovl_out.offset := 0;
  dat_p^.ovl_out.offset_high := 0;

  dat_p^.ovl_in.event_h := CreateEventA ( {create event for input overlapped I/O}
    nil,                               {no security attributes supplied}
    win_bool_true_k,                   {no automatic event reset on successful wait}
    win_bool_false_k,                  {init event to not triggered}
    nil);                              {no name supplied}
  if dat_p^.ovl_in.event_h = handle_none_k then begin {error creating event ?}
    stat.sys := GetLastError;
    goto abort2;                       {abort with output overlap event created}
    end;
  dat_p^.ovl_in.offset := 0;
  dat_p^.ovl_in.offset_high := 0;
{
*   Everything has been opened and allocated as needed.  Fill in the remaining
*   parts of the private and public connection descriptors.
}
  dat_p^.name.max := size_char(dat_p^.name.str);
  string_copy (name, dat_p^.name);     {save user-settable device name}

  conn.rw_mode := [file_rw_read_k, file_rw_write_k]; {open for read and write}
  conn.obty := file_obty_embusb_k;     {bi-directional byte stream to Embed USB device}
  conn.fmt := file_fmt_bin_k;          {data format is binary}
  conn.fnam.max := size_char(conn.fnam.str);
  string_copy (dev_p^.path, conn.fnam); {file name}
  conn.gnam.max := size_char(conn.gnam.str);
  string_copy (dev_p^.path, conn.gnam); {generic pathname}
  conn.tnam.max := size_char(conn.tnam.str);
  string_copy (dev_p^.path, conn.tnam); {full treename}
  conn.ext_num := 0;                   {no file suffix used}
  conn.lnum := 0;                      {init line number, not used}
  conn.data_p := dat_p;                {save pointer to our private data}
  conn.close_p := addr(file_close_embusb); {install our private close routine}

  file_usbdev_list_del (list);         {deallocate our temporary devices list}
  return;                              {return with success}

abort2:                                {abort with output overlapped I/O event created}
  discard( CloseHandle(dat_p^.ovl_out.event_h) ); {try to delete output overlapped event}

abort1:                                {abort with I/O connection open, STAT set}
  discard( CloseHandle(conn.sys) );    {try to close I/O handle}
  goto leave_err;

not_found:                             {the specified device was not found}
  if name.len = 0
    then begin                         {no specific name given}
      sys_stat_set (file_subsys_k, file_stat_usbid_nfound_k, stat);
      end
    else begin                         {a specific name was given}
      sys_stat_set (file_subsys_k, file_stat_usbidn_nfound_k, stat);
      sys_stat_parm_vstr (name, stat);
      end
    ;

err_vidpid:                            {add VID/PID to STAT, then exit with error}
  sys_stat_parm_int (vid, stat);       {fill in VID/PID error message parameters}
  sys_stat_parm_int (pid, stat);

leave_err:                             {common exit point to return with error}
  if listop then begin                 {deallocate devices list resources}
    file_usbdev_list_del (list);
    end;
  if dat_p <> nil then begin           {deallocate private data if created}
    sys_mem_dealloc (dat_p);
    end;
  end;
{
********************************************************************************
*
*   Subroutine FILE_CLOSE_EMBUSB (CONN_P)
*
*   Close a connection opened with FILE_OPEN_EMBUSB.  This is a standard FILE
*   library close routine.
}
procedure file_close_embusb (          {close connection to Embed USB device}
  in      conn_p: file_conn_p_t);      {pointer to the connection to close}
  val_param;

var
  dat_p: file_embusb_data_p_t;         {pointer to private connection data}

begin
  dat_p := conn_p^.data_p;             {get pointer to our private conn data}

  discard( CloseHandle(conn_p^.sys) ); {close the I/O connection}

  discard( SetEvent(dat_p^.ovl_out.event_h) ); {release threads waiting on I/O completion}
  discard( SetEvent(dat_p^.ovl_in.event_h) );
  Sleep (0);                           {give waiting threads a chance to see closed}
  discard( CloseHandle(dat_p^.ovl_out.event_h) ); {close output overlapped event}
  discard( CloseHandle(dat_p^.ovl_in.event_h) ); {close input overlapped event}
  end;
{
********************************************************************************
*
*   Subroutine FILE_READ_EMBUSB (CONN, ILEN, BUF, OLEN, STAT)
*
*   Read from the stream from a Embed USB device.  CONN is the connection to the
*   device.  ILEN is the maximum number of bytes to return.  OLEN is returned
*   the number of bytes actually read.  This routine blocks indefinitely until
*   at least one byte is available, which means OLEN will be from 1 to ILEN on
*   no error.
}
procedure file_read_embusb (           {read chunk of data from Embed USB device}
  in out  conn: file_conn_t;           {connection to the USB device}
  in      ilen: sys_int_adr_t;         {maximum number of bytes to read}
  out     buf: univ char;              {returned data}
  out     olen: sys_int_adr_t;         {number of bytes actually read}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  dat_p: file_embusb_data_p_t;         {pointer to private connection data}
  succ: win_bool_t;                    {system call succeeded}
  ol: win_dword_t;                     {amount of data returned by ReadFile}

label
  retry;

begin
  sys_error_none (stat);               {init to no error}
  dat_p := conn.data_p;                {get pointer to our private data}

retry:                                 {back here if not read any bytes}
  succ := ReadFile (                   {try to read a chunk from the device}
    conn.sys,                          {handle to the I/O connection}
    buf,                               {buffer to return the data in}
    min(ilen, 64),                     {max bytes to read, never more then 64}
    ol,                                {returned number of bytes actually read}
    addr(dat_p^.ovl_in));              {pointer to overlapped I/O descriptor}
  if succ = win_bool_false_k then begin {hard error ?}
    if GetLastError <> err_io_pending_k then begin {hard error ?}
      stat.sys := GetLastError;
      return;
      end;
    succ := GetOverlappedResult (      {wait for I/O to complete}
      conn.sys,                        {handle that I/O is pending on}
      dat_p^.ovl_in,                   {overlapped I/O descriptor}
      ol,                              {returned number of bytes actually read}
      win_bool_true_k);                {wait for I/O completion}
    if succ = win_bool_false_k then begin
      stat.sys := GetLastError;
      return;
      end;
    end;
  if ol = 0 then goto retry;           {didn't ready anything, back and try again ?}

  olen := ol;                          {pass back number of bytes actually read}
  end;
{
********************************************************************************
*
*   Subroutine FILE_WRITE_EMBUSB (BUF, CONN, LEN, STAT)
*
*   Write to the stream to a Embed USB device.  BUF is the array of bytes to
*   write.  CONN is the connection to the device.  LEN is the number of bytes to
*   write.
}
procedure file_write_embusb (          {write data to a Embed USB device}
  in      buf: univ char;              {data to write}
  in      conn: file_conn_t;           {connection to the USB device}
  in      len: sys_int_adr_t;          {number of machine adr increments to write}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  dat_p: file_embusb_data_p_t;         {pointer to private connection data}
  succ: win_bool_t;                    {system call succeeded}
  buf_p: ^intu8_t;                     {pointer to next byte to write}
  nleft: sys_int_adr_t;                {number of bytes left to write}
  olen: win_dword_t;                   {number of bytes actually written}

begin
  sys_error_none (stat);               {init to no error}
  dat_p := conn.data_p;                {get pointer to our private data}
  buf_p := univ_ptr(addr(buf));        {init pointer to next byte to write}
  nleft := len;                        {init number of bytes left to write}

  while nleft > 0 do begin             {back here until all data is written}
    succ := WriteFile (                {write a chunk of data}
      conn.sys,                        {handle to I/O connection}
      buf_p^,                          {the data to write}
      min(nleft, 64),                  {bytes in this chunk, never more than 64}
      olen,                            {returned number of bytes actually written}
      addr(dat_p^.ovl_out));           {pointer to overlapped I/O structure}
    if succ = win_bool_false_k then begin {hard error ?}
      if GetLastError <> err_io_pending_k then begin {hard error ?}
        stat.sys := GetLastError;
        return;
        end;
      succ := GetOverlappedResult (    {wait for I/O to complete}
        conn.sys,                      {handle that I/O is pending on}
        dat_p^.ovl_out,                {overlapped I/O descriptor}
        olen,                          {returned number of bytes actually written}
        win_bool_true_k);              {wait for I/O completion}
      if succ = win_bool_false_k then begin
        stat.sys := GetLastError;
        return;
        end;
      end;

    nleft := nleft - olen;             {update number of bytes left to write}
    buf_p :=                           {update pointer to next byte to write}
      univ_ptr(sys_int_adr_t(buf_p) + olen);
    end;                               {back for another chunk if data still left}
  end;
