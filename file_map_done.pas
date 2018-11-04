{   Subroutine FILE_MAP_DONE (HANDLE)
*
*   Release a mapped region of a file.  HANDLE is the handle for the mapped
*   region returned by FILE_MAP when the region was mapped.
}
module file_MAP_DONE;
define file_map_done;
%include 'file2.ins.pas';

procedure file_map_done (              {indicate done with mapped region of file}
  in out  handle: file_map_handle_t);  {handle from FILE_MAP, returned invalid}
  val_param;

begin
  end;
