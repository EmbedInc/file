{   Routines dealing with general USB issues.
}
module file_usb;
define file_usbid;
define file_usbdev_list_init;
define file_usbdev_list_start;
define file_usbdev_list_add;
define file_usbdev_list_del;
%include 'file2.ins.pas';
{
********************************************************************************
*
*   Function FILE_USBID (VID, PID)
*
*   Returns the single USB device ID value for the USB device with vendor ID VID
*   and product ID PID.
}
function file_usbid (                  {make USB device ID}
  in      vid, pid: sys_int_conv16_t)  {vendor ID (VID), product ID (PID)}
  :file_usbid_t;
  val_param;

begin
  file_usbid := lshft(vid & 16#FFFF, 16) ! (pid & 16#FFFF);
  end;
{
********************************************************************************
*
*   Subroutine FILE_USBDEV_LIST_INIT (LIST)
*
*   Initialize the fields in the USB devices list descriptor LIST to certain but
*   benign values.  The list will be empty with no system resources allocated to
*   it.
}
procedure file_usbdev_list_init (      {init USB devices list descriptor}
  out     list: file_usbdev_list_t);
  val_param;

begin
  list.mem_p := nil;
  list.n := 0;
  list.list_p := nil;
  list.last_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine FILE_USBDEV_LIST_START (LIST)
*
*   Start a new USB devices list in LIST.  The existing values in the LIST
*   structure are irrelevant.  However, no resources should be allocated to the
*   list since knowledge of them will be lost.  Resources will be allocated to
*   the list.
}
procedure file_usbdev_list_start (     {start a new USB devices list}
  in out  mem: util_mem_context_t;     {context new list context will be created in}
  out     list: file_usbdev_list_t);   {the list to start}
  val_param;

begin
  file_usbdev_list_init (list);        {init all the fields in list structure}
  util_mem_context_get (mem, list.mem_p); {create private mem context for the list}
  end;
{
********************************************************************************
*
*   Subroutine FILE_USBDEV_LIST_ADD (LIST)
*
*   Add one entry to the end of the USB devices list LIST.  The new entry will
*   be initialized to empty or benign values to the extent possible.
*
*   The list must have been previously started with FILE_USBDEV_LIST_START.
}
procedure file_usbdev_list_add (       {add entry to end of USB devices list}
  in out  list: file_usbdev_list_t);   {the list to add entry to}
  val_param;

var
  ent_p: file_usbdev_p_t;              {pointer to new entry}

begin
  if list.mem_p = nil then return;     {no memory context (shouldn't happen) ?}

  util_mem_grab (                      {allocate memory for the new list entry}
    sizeof(ent_p^),                    {amount of memory to allocate}
    list.mem_p^,                       {mem context to allocate new mem under}
    false,                             {won't need to individually deallocate}
    ent_p);                            {returned pointer to the new memory}

  ent_p^.next_p := nil;                {init the contents of the new entry}
  ent_p^.vidpid := 0;
  ent_p^.name.max := size_char(ent_p^.name.str);
  ent_p^.name.len := 0;
  ent_p^.path.max := size_char(ent_p^.path.str);
  ent_p^.path.len := 0;
  ent_p^.drtype := 0;

  if list.last_p = nil
    then begin                         {this is first entry in the list}
      list.list_p := ent_p;            {set the start of list pointer}
      list.n := 1;                     {set number of entries now in the list}
      end
    else begin                         {adding after existing entry}
      list.last_p^.next_p := ent_p;    {point previous entry to the new entry}
      list.n := list.n + 1;            {count one more entry in the list}
      end
    ;
  list.last_p := ent_p;                {update pointer to the last list entry}
  end;
{
********************************************************************************
*
*   Subroutine FILE_USBDEV_LIST_DEL (LIST)
*
*   Deallocate all dynamic resources allocated to the USB devices list LIST.
*   The list will be empty, and the list structure must be re-initialized before
*   reuse.
}
procedure file_usbdev_list_del (       {delete USB devices list, dealloc resources}
  in out  list: file_usbdev_list_t);
  val_param;

begin
  if list.mem_p <> nil then begin
    util_mem_context_del (list.mem_p); {deallocate dynamic mem, delete mem context}
    end;
  file_usbdev_list_init (list);
  end;
