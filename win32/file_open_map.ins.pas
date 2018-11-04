{   Local subroutine INIT_MAPPING
*
*   This routine is really part of the main line of decent of FILE_OPEN_MAP.
*   It is in a separate file to allow customization to OS without requiring
*   any customizations of the rest of FILE_OPEN_MAP.
*
*   Everything has already been initialized, except the initial mapping for the
*   whole file has not been done yet.  The private data block has been
*   initialized to assume no direct OS file mapping at all.
*
*   This is the Microsoft Win32 API version.
*   The entire existing file is mapped in one region if any read access was
*   requested.  If the file is lengthened, the new portion is dealt with
*   in the same way as when no OS file mapping capabilities are assumed.
}
var
  moaccess: moaccess_k_t;              {mapped object access}
  maccess: maccess_k_t;                {mapped view access}

label
  error;

begin
  if not (file_rw_read_k in rw_mode) then return; {not trying to read file ?}
  if data_p^.len_file <= 0 then return; {no existing file to map ?}

  if file_rw_write_k in rw_mode
    then begin                         {caller wants write access}
      moaccess := moaccess_readwrite_k;
      maccess := maccess_readwrite_k;
      end
    else begin                         {caller wants read access}
      moaccess := moaccess_read_k;
      maccess := maccess_read_k;
      end
    ;

  conn.sys := CreateFileMappingA (     {create file mapping object}
    data_p^.conn.sys,                  {handle to regular file connection}
    nil,                               {no security info supplied}
    moaccess,                          {read/write access required}
    0, 0,                              {max size if current file size}
    nil);                              {no name for sharing supplied}
  if conn.sys = 0 then begin           {system call failed ?}
error:                                 {common code for system error encountered}
    stat.sys := GetLastError;
    return;
    end;

  data_p^.map_p := MapViewOfFile (     {map the whole file into our address space}
    conn.sys,                          {handle to file mapping object}
    maccess,                           {read/write access required}
    0, 0,                              {starting file offset}
    data_p^.len_file);                 {length of region to map}
  if data_p^.map_p = nil then goto error; {system call failed ?}

  data_p^.len_read := data_p^.len_file; {indicate whole file already "read"}
  end;
