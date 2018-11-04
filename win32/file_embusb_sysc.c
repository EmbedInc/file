//   C-language system dependent routines for Embed USB devices.
//
//   This version is for Windows 2000 and later.  It assumes the Microsoft
//   visual C++ compiler version 6 using the C (not C++) language.
//
#include <wtypes.h>
#include <winbase.h>
#include <stdio.h>
#include <io.h>
#include <setupapi.h>
#include <initguid.h>
#include <winioctl.h>

#include "sys.h"
#include "util.h"
#include "string.h"
#include "file.h"
#include "embusb_driver.h"

//****************************
//
//   GUIDs for all the instances of the old driver.  A new driver was created
//   for each VID/PID, although the code was the same for all drivers except
//   for some name changes and a different GUID.  All these drivers function the
//   same once opened, but a separate GUID is required per VID/PID to find each
//   of them.  The separate VID/PID the old driver was ever created for is a
//   finite and known list.
//

DEFINE_GUID(usbprog_guid,
0x873fdf, 0x61a8, 0x11d1, 0xaa, 0x5e, 0x0, 0xc0, 0x4f, 0xb1, 0x72, 0x8b);

DEFINE_GUID(u1ex_guid,
0x268a329b, 0xdfca, 0x438b, 0x8d, 0x4e, 0x96, 0xc7, 0x81, 0x53, 0x92, 0x4b);

DEFINE_GUID(irlog_guid,
0x6a515db2, 0x4c61, 0x4e8e, 0xb4, 0x70, 0x5, 0xcf, 0x46, 0x7b, 0x34, 0xd9);

DEFINE_GUID(ushos_guid,
0xf50e9d16, 0xad37, 0x4090, 0xb3, 0x3a, 0xc, 0xf8, 0x13, 0x23, 0xd3, 0x80);

DEFINE_GUID(prba_guid,
0xbf13c445, 0xe6df, 0x4407, 0xae, 0x3d, 0x13, 0x10, 0x82, 0xb6, 0x4, 0xb1);

DEFINE_GUID(usbcan_guid,
0x6310356f, 0x28be, 0x4678, 0xab, 0x3a, 0xe6, 0x42, 0xb0, 0x17, 0xe4, 0xa);

DEFINE_GUID(touchtag_guid,
0xaf361899, 0x937d, 0x46a5, 0xb0, 0x44, 0xc0, 0xaa, 0xe5, 0x6a, 0x30, 0xb2);

DEFINE_GUID(ebox_guid,
0x5191eff2, 0x9d2b, 0x4304, 0xb5, 0x90, 0x55, 0x02, 0x71, 0xa5, 0xd9, 0x73);

DEFINE_GUID(dsnif_guid,
0x892f36ac, 0x48b4, 0x4011, 0xbb, 0x19, 0x58, 0xea, 0xef, 0x19, 0x2a, 0x15);

DEFINE_GUID(dev10_guid,
0xcde1630, 0x37c9, 0x4c45, 0x9b, 0x5b, 0x4b, 0x34, 0x28, 0xb6, 0x5b, 0x2a);

DEFINE_GUID(jowa_guid,
0xd21c11ae, 0x23e5, 0x4de9, 0x9f, 0xeb, 0x34, 0x79, 0x6b, 0x34, 0xf5, 0x30);

#define U1EX_IOCTL_INDEX 0x0000

// IOCTL to get the firmware ID string
// returns unterminated string in output buffer
#define IOCTL_U1EX_GET_FWID CTL_CODE( \
  FILE_DEVICE_UNKNOWN, \
  U1EX_IOCTL_INDEX + 1, \
  METHOD_BUFFERED, \
  FILE_ANY_ACCESS)

#define FWID_STRING_SIZE (80)          // maximum length of the firmware ID string

//******************************************************************************
//
//   Function FILE_EMBUSB_SYS_OPEN_INFO (PATH, DRTYPE, STAT)
//
//   Open a info-only connection to the Embed USB device with the base system
//   pathname of PATH.  DRTYPE is the driver type with the following valid
//   values:
//
//     1 - Old Embed driver.
//
//     2 - New unified driver for all Embed USB devices.
//
//   The function value is the system handle to the newly opened connections.
//   This value is undefined unless STAT indicates no error.
//
HANDLE file_embusb_sys_open_info (     //open info-only connection to device
  string_treename_t *path,             //base system pathname of the device
  sys_int_machine_t drtype,            //driver type, 1 = old, 2 = new
  sys_err_t *stat) {                   //completion status

string_treename_t tnam;                //scratch pathname
HANDLE h;                              //temp handle
//
//   Executable code for subroutine FILE_EMBUSB_SYS_OPEN_INFO.
//
  tnam.max = sizeof(tnam.str);         //init local var string
  sys_error_none (stat);               //init all fields in STAT to no error

switch (drtype) {                      //which driver is being used ?
//
//   Old driver.  This driver presents a second device pathname with "\INFO" at
//   the end.  This second device can be opened at any time to get the
//   user-settable name string, whether the real device is in use or not.
//
case 1:
  string_copy (path, &tnam);           //make "\INFO" pathname
  string_appendn (&tnam, "\\INFO", 5); //make device pathname for getting the name
  string_terminate_null (&tnam);       //make sure STR field contains terminating NULL

  h = CreateFile (                     //try to open this device
    tnam.str,                          //pathname of object to open
    GENERIC_READ | GENERIC_WRITE,      //required for opening "info" device
    FILE_SHARE_READ | FILE_SHARE_WRITE, //required for opening "info" device
    NULL,                              //no security attributes specified
    OPEN_EXISTING,                     //device must already exist
    0,                                 //no special attributes
    NULL);                             //no template attributes file supplied
  if (h == INVALID_HANDLE_VALUE) {     //attempt to open "\info" device failed ?
    stat->sys = GetLastError();
    }
  return h;
  break;
//
//   New driver.
//
case 2:
  string_copy (path, &tnam);           //make null-terminated device pathname
  string_terminate_null (&tnam);

  h = CreateFile (                     //try to open device in info-only mode
    tnam.str,                          //pathname of device object
    0,                                 //neither read no write access requested
    FILE_SHARE_READ | FILE_SHARE_WRITE, //allow others read/write access
    NULL,                              //no security attributes specified
    OPEN_EXISTING,                     //device must already exist
    0,                                 //no special attributes
    NULL);                             //no template attributes file supplied
  if (h == INVALID_HANDLE_VALUE) {     //open attempt failed ?
    stat->sys = GetLastError();
    }
  return h;
  break;
//
//   Unimplemented or invalid driver type.
//
default:
    sys_stat_set (sys_subsys_k, sys_stat_not_impl_k, stat);
    return 0;
    };                                 //end of driver type cases
  }                                    //end of FILE_EMBUSB_SYS_OPEN_INFO

//******************************************************************************
//
//   Function FILE_EMBUSB_SYS_OPEN_DATA (PATH, DRTYPE, STAT)
//
//   Open a exclusive data transfer connection to the Embed USB device with the
//   base system pathname of PATH.  DRTYPE is the driver type with the following
//   valid values:
//
//     1 - Old Embed driver.
//
//     2 - New unified driver for all Embed USB devices.
//
//   The function value is the system handle to the newly opened connections.
//   This value is undefined unless STAT indicates no error.
//
HANDLE file_embusb_sys_open_data (     //open exclusive data transfer connection
  string_treename_t *path,             //base system pathname of the device
  sys_int_machine_t drtype,            //driver type, 1 = old, 2 = new
  sys_err_t *stat) {                   //completion status

string_treename_t tnam;                //scratch pathname
HANDLE h;                              //temp handle
//
//   Executable code for subroutine FILE_EMBUSB_SYS_OPEN_DATA.
//
  tnam.max = sizeof(tnam.str);         //init local var string
  sys_error_none (stat);               //init all fields in STAT to no error

switch (drtype) {                      //which driver is being used ?
//
//   Old driver.
//
case 1:
  string_copy (path, &tnam);           //make null-terminated device pathname
  string_terminate_null (&tnam);

  h = CreateFile (                     //try to open this device
    tnam.str,                          //pathname of object to open
    GENERIC_READ | GENERIC_WRITE,      //will read and write to the device
    0,                                 //open for exclusive access to the device
    NULL,                              //no security attributes specified
    OPEN_EXISTING,                     //device must already exist
    FILE_FLAG_OVERLAPPED,              //we will be using overlapped I/O
    NULL);                             //no template attributes file supplied
  if (h == INVALID_HANDLE_VALUE) {     //unable to open the device ?
    stat->sys = GetLastError ();
    }
  return h;
  break;
//
//   New driver.
//
case 2:
  string_copy (path, &tnam);           //make null-terminated device pathname
  string_terminate_null (&tnam);

  h = CreateFile (                     //try to open this device
    tnam.str,                          //pathname of object to open
    GENERIC_READ | GENERIC_WRITE,      //will read and write to the device
    0,                                 //open for exclusive access to the device
    NULL,                              //no security attributes specified
    OPEN_EXISTING,                     //device must already exist
    FILE_FLAG_OVERLAPPED,              //we will be using overlapped I/O
    NULL);                             //no template attributes file supplied
  if (h == INVALID_HANDLE_VALUE) {     //unable to open the device ?
    stat->sys = GetLastError ();
    }
  return h;
  break;
//
//   Unimplemented or invalid driver type.
//
default:
    sys_stat_set (sys_subsys_k, sys_stat_not_impl_k, stat);
    return 0;
    };                                 //end of driver type cases
  }                                    //end of FILE_EMBUSB_SYS_OPEN_DATA

//******************************************************************************
//
//   Subroutine FILE_EMBUSB_SYS_ENUM (DEVS)
//
//   Add all the Embed USB devices currently connected to the system to the list
//   of devices in DEVS.  The list must have been previously "started" with
//   FILE_USBDEV_LIST_START.  New entries will be added after all previously
//   existing list entries, if any.
//
void file_embusb_sys_enum (            //add Embed USB devices to list
  file_usbdev_list_t *devs) {          //devices list to add to

typedef struct vpid_t {                //VID/PID as passed back by new driver
  USHORT vid;
  USHORT pid;
  } vpid_t;

LPGUID guid_p;                         //pointer to GUID of driver
INT guidn;                             //0-N sequential index for GUID curr trying
sys_int_conv32_t vidpid;               //VID/PID of curr device, 0 if not known
sys_int_machine_t drtype;              //driver type ID
HDEVINFO devlist;                      //handle to list of devices with our GUID
BOOL devlist_alloc;                    //data allocated to DEVLIST
INT devn;                              //current 0-N DEVLIST entry number
SP_DEVICE_INTERFACE_DATA devinfo;      //info about one USB device
BOOL succ;                             //success flag returned by some functions
DWORD sz;                              //memory size
PSP_DEVICE_INTERFACE_DETAIL_DATA devpath_p; //points to descriptor containing device path
BOOL devpath_alloc;                    //device pathname descriptor allocated
SP_DEVINFO_DATA devnode;               //descriptor containing dev-node info
string_treename_t tnam;                //scratch pathname
HANDLE h;                              //temp handle
sys_int_machine_t ii, jj;              //scratch integer
vpid_t vpid;                           //VID/PID from the new driver
sys_err_t stat;                        //completion status
//
//   Executable code for subroutine U1EX_SYS_ENUM.
//
  tnam.max = sizeof(tnam.str);         //init local var string
  devlist_alloc = FALSE;               //indicate devs list handle has no data allocated
  devpath_alloc = FALSE;               //device pathname descriptor not allocated
  guidn = 0;                           //init number of next GUID to try

loop_guid:                             //back here each new driver GUID to try
  switch (guidn) {                     //which GUID to use this time ?
    case 0:
      guid_p = (LPGUID) &usbprog_guid;
      drtype = 1;                      //old driver
      vidpid = 0x16C005C8;             //VID/PID of these devices
      break;
    case 1:
      guid_p = (LPGUID) &u1ex_guid;
      drtype = 1;                      //old driver
      vidpid = 0x16C005C9;             //VID/PID of these devices
      break;
    case 2:
      guid_p = (LPGUID) &irlog_guid;
      drtype = 1;                      //old driver
      vidpid = 0x16C005CA;             //VID/PID of these devices
      break;
    case 3:
      guid_p = (LPGUID) &ushos_guid;
      drtype = 1;                      //old driver
      vidpid = 0x16C005CB;             //VID/PID of these devices
      break;
    case 4:
      guid_p = (LPGUID) &prba_guid;
      drtype = 1;                      //old driver
      vidpid = 0x16C005CC;             //VID/PID of these devices
      break;
    case 5:
      guid_p = (LPGUID) &usbcan_guid;
      drtype = 1;                      //old driver
      vidpid = 0x16C005CD;             //VID/PID of these devices
      break;
    case 6:
      guid_p = (LPGUID) &touchtag_guid;
      drtype = 1;                      //old driver
      vidpid = 0x16C005CE;             //VID/PID of these devices
      break;
    case 7:
      guid_p = (LPGUID) &ebox_guid;
      drtype = 1;                      //old driver
      vidpid = 0x16C005CF;             //VID/PID of these devices
      break;
    case 8:
      guid_p = (LPGUID) &dsnif_guid;
      drtype = 1;                      //old driver
      vidpid = 0x16C005D0;             //VID/PID of these devices
      break;
    case 9:
      guid_p = (LPGUID) &dev10_guid;
      drtype = 1;                      //old driver
      vidpid = 0x16C005D1;             //VID/PID of these devices
      break;
    case 10:
      guid_p = (LPGUID) &jowa_guid;
      drtype = 1;                      //old driver
      vidpid = 0x16C00A32;             //VID/PID of these devices
      break;
    case 11:                           //try new unified Embed USB driver
      guid_p = (LPGUID) &GUID_DEVINTERFACE_EmbedUSB;
      drtype = 2;                      //new driver
      vidpid = 0;                      //indicate VID/PID not known up front
      break;
    default:                           //done trying all the known drivers
      return;
    };

  devlist = SetupDiGetClassDevs (      //get handle to list of devices with our GUID
    guid_p,                            //pointer to our GUID
    NULL,                              //no special pattern to match
    NULL,                              //handle to top level GUI window, not used
    ( DIGCF_PRESENT |                  //only devices currently present
      DIGCF_DEVICEINTERFACE) );        //GUID specifies an interface class, not setup class
  if (devlist == INVALID_HANDLE_VALUE) goto done_list;
  devlist_alloc = TRUE;                //indicate devices list handle has data allocated
//
//   Loop thru all devices of our type that are currently connected.
//
  devn = -1;                           //init to before first list entry
  devinfo.cbSize = sizeof(SP_DEVICE_INTERFACE_DATA); //set size of this structure

next_listent:                          //back here to try next list entry
  devn++;                              //make 0-N list entry number for this pass
  if (devpath_alloc) {
    free (devpath_p);                  //deallocate any previous device pathname descriptor
    devpath_alloc = FALSE;
    }

  succ = SetupDiEnumDeviceInterfaces ( //get info on one device in the list
    devlist,                           //handle to the list of devices
    NULL,                              //no extra info to constrain the search
    guid_p,                            //pointer to GUID of our device
    devn,                              //0-N number of device to get info about
    &devinfo);                         //returned device info
  if (!succ) goto done_list;           //didn't get info about this device number ?
//
//   Get the Win32 pathname for this device.  The function
//   SetupDiGetDeviceInterfaceDetail is called twice.  The first time to find
//   the size of the buffer needed to hold all the return information, and the
//   second time to get the return information.
//
  succ = SetupDiGetDeviceInterfaceDetail ( //find size of buffer to hold all the data
    devlist,                           //handle to list of our USB devices
    &devinfo,                          //info about the selected device
    NULL,                              //no detailed information output buffer supplied
    0,                                 //output buffer size
    &sz,                               //required buffer size
    NULL);                             //no dev-node info buffer supplied
  if (!succ) {
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) goto done_listent;
    }
  //
  //   SZ is the size of the buffer required to hold all the returned info.
  //
  devpath_p = malloc (sz);             //allocate the device pathname descriptor
  devpath_alloc = TRUE;                //indicate device pathname descriptor allocated
  devpath_p->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA);
  devnode.cbSize = sizeof(SP_DEVINFO_DATA);

  succ = SetupDiGetDeviceInterfaceDetail ( //get detail information on this device
    devlist,                           //handle to list of our USB devices
    &devinfo,                          //info about the selected device
    devpath_p,                         //returned device pathname descriptor
    sz,                                //output buffer size
    NULL,                              //no required size return variable supplied
    &devnode);                         //returned dev-node info (not used)
  if (!succ) goto done_listent;
//
//   A new device has been found.  The system pathname to this device is in
//   devpath_p->DevicePath.  Create a new list entry and fill it in with what we
//   know so far.
//
  file_usbdev_list_add (devs);         //add new entry to end of devices list
  devs->last_p->vidpid = vidpid;       //set VID/PID if known
  string_vstring (&devs->last_p->path, &devpath_p->DevicePath, -1); //set system pathname
  devs->last_p->drtype = drtype;       //save driver type ID
//
//   Get additional info about the device from the driver using the INFO
//   connection.
//
  h = file_embusb_sys_open_info (      //get handle for info-only access
    &devs->last_p->path,               //base device pathname
    devs->last_p->drtype,              //driver type ID
    &stat);                            //returned completion status
  if (sys_error(&stat)) goto done_drinfo;

switch (drtype) {                      //which driver is being used ?
  //
  //   Old driver.
  //
case 1:
    succ = DeviceIoControl (           //get the user-settable name of this device
      h,                               //handle to the I/O connection
      IOCTL_U1EX_GET_FWID,             //control code for getting name
      NULL, 0,                         //no data passed to device
      tnam.str,                        //buffer to return data into
      tnam.max,                        //max size data allowed to return
      &sz,                             //number of bytes actually returned
      NULL);                           //no overlapped I/O structure supplied
    if (!succ) goto done_drtype;
    tnam.len = sz;                     //set received name string length
    string_copy (&tnam, &devs->last_p->name); //set user name in new list entry
    break;
  //
  //   New unified driver for all Embed USB devices.
  //
case 2:
    succ = DeviceIoControl (           //get the user-settable name of this device
      h,                               //handle to the I/O connection
      IOCTL_EMBEDUSB_GET_NAME,         //control code for getting name
      NULL, 0,                         //no data passed to device
      tnam.str,                        //buffer to return unicode string into
      tnam.max,                        //max size data allowed to return
      &sz,                             //number of bytes actually returned
      NULL);                           //no overlapped I/O structure supplied
    if (!succ) goto done_drtype;
    devs->last_p->name.len = 0;        //init the name string to empty
    jj = sz / 2;                       //make of number real chars in the string
    for (ii = 0; ii < jj; ii += 1) {   //pick out the ASCII characters from the unicode
      string_append1 (&devs->last_p->name, tnam.str[ii*2]);
      };

    succ = DeviceIoControl (           //get dev descriptor to determine VID/PID
      h,                               //handle to the I/O connection
      IOCTL_EMBEDUSB_GET_VID_PID,      //control code
      NULL, 0,                         //no data passed to device
      &vpid,                           //buffer to return data into
      sizeof(vpid),                    //max size data allowed to return
      &sz,                             //number of bytes actually returned
      NULL);                           //no overlapped I/O structure supplied
    if (!succ) goto done_drtype;
    if (sz < 4) goto done_drtype;      //data doesn't include VID and PID ?
    ii = vpid.vid;                     //assemble VID/PID into single word in our format
    devs->last_p->vidpid = ii << 16;
    ii = vpid.pid;
    devs->last_p->vidpid |= ii;
    break;
//
//   Unimplemented or invalid driver type.
//
default: ;
    };                                 //end of driver type cases
done_drtype:                           //done with specific code for driver type
    CloseHandle (h);                   //close the info connection to the driver
done_drinfo:                           //done getting extra device info from driver

done_listent:                          //done with this list entry from system
  goto next_listent;                   //back to check out next list entry
//
//   Done scanning the devices list.
//
done_list:
  if (devpath_alloc) {
    free (devpath_p);                  //deallocate device pathname descriptor
    devpath_alloc = FALSE;
    }
  if (devlist_alloc) {
    SetupDiDestroyDeviceInfoList (devlist); //try to deallocate devices list
    devlist_alloc = FALSE;
    }
  guidn++;                             //advance to next driver GUID to try
  goto loop_guid;                      //back to try with next driver GUID
  }
