{   Subroutine FILE_SET_FTN_MAP_INHIBIT
*
*   This subroutine sets a flag that indicates to NOT use direct OS mapped
*   file I/O due to the problem that Fortran can't seem to generate the correct
*   array references.  The default is that mapped file I/O is allowed.
*   This is only called from old code that uses DS, which is the only place
*   that a fixed Fortran array is used to try to access mapped file data.
}
module file_set_ftn_map_inhibit;
define file_set_ftn_map_inhibit_;
%include 'file2.ins.pas';

procedure file_set_ftn_map_inhibit_;   {flags to not use mapped files for DS problem}

begin
  file_map_ftn_inhibit := true;        {set the inhibit flag}
  end;
