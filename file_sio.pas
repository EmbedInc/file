{   Collection of portable routines that deal with serial lines.
}
module file_sio;
define file_sio_set_eor_read;
define file_sio_set_eor_write;
%include 'file2.ins.pas';
{
***********************************************************
*
*   Subroutine FILE_SIO_SET_EOR_READ (CONN, STR, LEN)
*
*   Set the string that will be used to recognize an "end of record".
*   Setting STR to null length disables the end of record feature.
}
procedure file_sio_set_eor_read (      {set "end of record" to use for reading SIO}
  in out  conn: file_conn_t;           {handle to serial line connection}
  in      str: string;                 {the characters to look for}
  in      len: sys_int_machine_t);     {number of characters in STR}
  val_param;

var
  d_p: file_sio_data_p_t;              {pointer to our private data block}
  i: sys_int_machine_t;                {scratch integer and loop counter}

begin
  d_p := conn.data_p;                  {get pointer to our private data block}

  if len <= 0 then begin               {end of record feature is being disabled ?}
    d_p^.eor_in_on := false;           {turn off the feature}
    d_p^.eor_in.len := 0;
    return;
    end;

  d_p^.eor_in.len := min(len, d_p^.eor_in.max); {number of characters to save}
  for i := 1 to d_p^.eor_in.len do begin {once for each character to copy}
    d_p^.eor_in.str[i] := str[i];      {copy this character to save area}
    end;                               {back to save next EOR string character}
  d_p^.eor_in_on := true;              {enable the EOR feature}
  end;
{
***********************************************************
*
*   Subroutine FILE_SIO_SET_EOR_WRITE (CONN, STR, LEN)
*
*   Set the string to automatically send after every call to
*   FILE_WRITE_SIO_REC.  This is intended to be the "end of line" protocol
*   for the particular serial line and/or device.
}
procedure file_sio_set_eor_write (     {set "end of record" to use for writing SIO}
  in out  conn: file_conn_t;           {handle to serial line connection}
  in      str: string;                 {the characters to add at end of record}
  in      len: sys_int_machine_t);     {number of characters in STR}
  val_param;

var
  d_p: file_sio_data_p_t;              {pointer to our private data block}
  i: sys_int_machine_t;                {scratch integer and loop counter}

begin
  d_p := conn.data_p;                  {get pointer to our private data block}

  if len <= 0 then begin               {end of record feature is being disabled ?}
    d_p^.eor_out_on := false;          {turn off the feature}
    d_p^.eor_out.len := 0;
    return;
    end;

  d_p^.eor_out.len := min(len, d_p^.eor_out.max); {number of characters to save}
  for i := 1 to d_p^.eor_out.len do begin {once for each character to copy}
    d_p^.eor_out.str[i] := str[i];     {copy this character to save area}
    end;                               {back to save next EOR string character}
  d_p^.eor_out_on := true;             {enable the EOR feature}
  end;
