// FILE: EmbedUSB_Public.h

#pragma once

// This file contains definitions that are shared between the EmbedUSB
// driver and user applications.

//===================================================================
// VID and PID values for known devices

#define VID_EMBEDINC    0x16C0
#define PID_EMBEDPROGRAMMER  0x05C8
#define PID_EMBEDREADYBOARD2 0x05C9

//===================================================================
// Define interface GUID
// dfee9484-ff0e-40eb-a874-3f75c039f53b

DEFINE_GUID(GUID_DEVINTERFACE_EmbedUSB,
    0xdfee9484, 0xff0e, 0x40eb, 0xa8, 0x74, 0x3f, 0x75, 0xc0, 0x39, 0xf5, 0x3b);

//===================================================================
// Vendor control range:

// Range allowed for vendor commands.  Commands in the ranges
// 0x00..0x3F and 0xC0..0xFF are reserved for the driver. It
// uses 0x3F internally to report open and close operations to
// the device.
#define EMBEDUSB_VENDOR_REQUEST_MINIMUM    0x40
#define EMBEDUSB_VENDOR_REQUEST_MAXIMUM    0xBF

//===================================================================
// IOCTL valuesGET_

#define FILE_DEVICE_EMBEDUSB 43215     // 'random' device type code.
                 // any value between 32768 (0x8000)
                 // and 65535 (0xFFFF) is valid

#define IOCTL_FUNCTION0 0x800          // First code used for IOCTL functions
                 // These must be in the range 0x800
                 // through 0xFFF and must be unique
                 // per IOCTL

// Get the VID and PID of the device
// Returns a 4-byte buffer:
//   USHORT  vid
//   USHORT  pid

#define IOCTL_EMBEDUSB_GET_VID_PID CTL_CODE(  \
 FILE_DEVICE_EMBEDUSB,         \
    IOCTL_FUNCTION0,           \
    METHOD_BUFFERED,           \
    FILE_ANY_ACCESS              \
)

// Return the manufacturer string in UNICODE

#define IOCTL_EMBEDUSB_GET_MANUFACTURER CTL_CODE(  \
 FILE_DEVICE_EMBEDUSB,         \
    IOCTL_FUNCTION0+1,           \
    METHOD_BUFFERED,           \
    FILE_ANY_ACCESS              \
)

// Return the product name in UNICODE

#define IOCTL_EMBEDUSB_GET_PRODUCT CTL_CODE(  \
 FILE_DEVICE_EMBEDUSB,         \
    IOCTL_FUNCTION0+2,           \
    METHOD_BUFFERED,           \
    FILE_ANY_ACCESS              \
)

// Return the serial number string in UNICODE

#define IOCTL_EMBEDUSB_GET_SERIAL CTL_CODE( \
 FILE_DEVICE_EMBEDUSB,        \
 IOCTL_FUNCTION0+3,           \
 METHOD_BUFFERED,           \
 FILE_ANY_ACCESS                      \
)

// Return the user set name in UNICODE

#define IOCTL_EMBEDUSB_GET_NAME CTL_CODE(  \
 FILE_DEVICE_EMBEDUSB,         \
    IOCTL_FUNCTION0+4,           \
    METHOD_BUFFERED,           \
    FILE_ANY_ACCESS              \
)

// Perform a vendor control read operation
//
// Buffer sent to IOCTL:
//     BYTE    target, normally=0, device
//   BYTE  request code, in the range 0x40..0xBF
//     USHORT  value
//      USHORT  index
// Buffer received from IOCTL:
//   Data read length for the control transfer will
//   be set equal to the user-provided buffer
//   length, must not exceed 65535 (0xFFFF)

#define IOCTL_EMBEDUSB_VENDOR_CONTROL_READ CTL_CODE( \
 FILE_DEVICE_EMBEDUSB,         \
 IOCTL_FUNCTION0+5,            \
 METHOD_BUFFERED,            \
 FILE_READ_ACCESS            \
)

// Perform a vendor control write operation
//
// Buffer sent to IOCTL:
//   BYTE  target, normally=0, device
//   BYTE    request code, in the range 0x40..0xBF
//   USHORT  value
//   USHORT  index
//   BYTE[]  data to send with control operation
//  NOTE: The transfer length will be set to the length
//   of the buffer sent to the IOCTL minus 6 bytes
//   for the header data. This value must not
//   exceed 65535 (0xFFFF)
// Buffer returned by IOCTL to the application
//   None
//

#define IOCTL_EMBEDUSB_VENDOR_CONTROL_WRITE CTL_CODE( \
 FILE_DEVICE_EMBEDUSB,         \
 IOCTL_FUNCTION0+6,            \
 METHOD_BUFFERED,            \
 FILE_WRITE_ACCESS           \
)
