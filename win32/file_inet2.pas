{   Additional FILE library routines that handle internet issues.  This
*   file is intended for routines that may need to be customized per OS
*   more often than those in FILE_INET.COG.  See header comments in
*   FILE_INET.COG.
*
*   This version is for most of the Unix systems that were derived from BSD.
}
module file_inet2;
define file_inet_adr_name;
define file_inet_sockaddr_init;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';
%include 'file_inet.ins.pas';
{
*************************************************************************
*
*   Subroutine FILE_INET_ADR_NAME (ADR, NAME, STAT)
*
*   Try to find the official internet name of the node with address ADR.
*   If no name can be found for ADR, then NAME is returned the dot format
*   internet address string, and STAT is set to FILE_STAT_INETNAME_DOT_K.
}
procedure file_inet_adr_name (         {get node name from internet address}
  in      adr: sys_inet_adr_node_t;    {input internet node address}
  in out  name: univ string_var_arg_t; {node name or "dot notation" address}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  host_p: hostent_p_t;                 {pointer to internet host info}
  ladr: sys_inet_adr_node_t;           {local copy of internet address}
  sadr: string_var32_t;                {internet address in "dot format"}

begin
  sadr.max := sizeof(sadr.str);        {init local var string}
  sys_error_none (stat);               {init to no error encountered}
  sys_sys_netstart;                    {initialize network DLL, if not already}

  ladr := adr;                         {make local copy of internet address}
  if sys_byte_order_k <> sys_byte_order_fwd_k then begin {flip to network order ?}
    sys_order_flip (ladr, sizeof(ladr));
    end;

  host_p :=                            {try to get node info given its address}
    gethostbyaddr (adr, sizeof(adr), adrfam_inet_k);
  if (host_p <> nil) and then (host_p^.name_p <> nil)
    then begin                         {we have pointer to node name}
      string_vstring (                 {extract node name}
        name, host_p^.name_p^, string_len_nullterm_k);
      end
    else begin                         {no name found, use dot format address}
      string_f_inetadr (sadr, adr);    {make internet adr in "dot format"}
      string_copy (sadr, name);        {return dot address instead of name}
      sys_stat_set (file_subsys_k, file_stat_inetname_dot_k, stat);
      sys_stat_parm_vstr (sadr, stat); {pass dot format address string as parm}
      end
    ;
  end;
{
*************************************************************************
}
procedure file_inet_sockaddr_init (    {init socket network address descriptor}
  out     adr: sockaddr_t);            {data structure to initialize}

var
  byte_p: ^int8u_t;
  i: sys_int_adr_t;

begin
  byte_p := univ_ptr(addr(adr));       {clear address descriptor to all zeros}
  for i := 1 to sizeof(adr) do begin
    byte_p^ := 0;
    byte_p := succ(byte_p);
    end;

  adr.adrfam := ord(adrfam_inet_k);    {set address family to INTERNET}
  end;
