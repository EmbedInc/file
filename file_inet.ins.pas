{   Private include file used by the routines that implement the FILE library
*   internet streams interface.
*
*   The version is the main line of decent, and is used for all versions
*   of Unix and Domain/OS.
}
procedure file_inet_sockaddr_init (    {init socket network address descriptor}
  out     adr: sockaddr_t);            {data structure to initialize}
  extern;
