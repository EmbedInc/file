{   Routines for performing I/O to Embed USB devices.
}
module file_embusb;
define file_embusb_list_get;
%include 'file2.ins.pas';
{
********************************************************************************
*
*   Subroutine FILE_EMBUSB_LIST_GET (USBID, MEM, LIST, STAT)
*
*   Returns the list of Embed USB devices currently connected to the system and
*   that have the VID/PID combination identified in USBID.  MEM is the parent
*   memory context under which the memory context for the list will be created.
*   LIST is returned the list of devices.  System resources may be allocated to
*   the list, which should be deallocated with FILE_USBDEV_LIST_DEL when done
*   with the list.
*
*   LIST may be comletely uninitialized on entry.  However, it must not be a
*   active list with resources allocated to it.
}
procedure file_embusb_list_get (       {make list of Embed USB devices of a VID/PID}
  in      usbid: file_usbid_t;         {USB VID/PID of the devices to list, 0 for all}
  in out  mem: util_mem_context_t;     {mem context to create list context within}
  out     list: file_usbdev_list_t;    {the returned list}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  llist: file_usbdev_list_t;           {local list of all Embed USB devices}
  dev_p: file_usbdev_p_t;              {points to entry in caller's list}

label
  next_dev;

begin
  sys_error_none (stat);               {init to no error encountered}

  file_usbdev_list_start (mem, llist); {init local list of all devices}
  file_embusb_sys_enum (llist);        {get list of all Embed USB devices}
{
*   Loop thru the list of all Embed USB devices and copy the appropriate ones
*   to the caller's list.
}
  file_usbdev_list_start (mem, list);  {initialize the returned list}
  dev_p := llist.list_p;               {init pointer to first dev in local list}

  while dev_p <> nil do begin          {once for each device in the local list}
    if (usbid <> 0) and (dev_p^.vidpid <> usbid) {skip this device ?}
      then goto next_dev;
    file_usbdev_list_add (list);       {add new entry to end of caller's list}
    list.last_p^ := dev_p^;            {copy this device to caller's list}
    list.last_p^.next_p := nil;        {make sure link is NIL at end of list}
next_dev:                              {jump here to proceed to the next device}
    dev_p := dev_p^.next_p;            {point to next dev in the local list}
    end;

  file_usbdev_list_del (llist);        {deallocate resources of the local list}
  end;
