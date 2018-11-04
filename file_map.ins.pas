{   This file is really part of FILE.INS.PAS, and is used to declare data
*   structures related to mapped file I/O.
*
*   This version is for any operating system that does not have mapped
*   file I/O capability.  The routines that implement this version are the
*   main line of decent, and are layered on other Cognivision utilities.
}
type
  file_map_handle_t = record           {user handle to a mapped region of a file}
    unused: char;
    end;
