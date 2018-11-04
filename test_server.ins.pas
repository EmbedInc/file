{   Include file to define data structures for the test server.  The programs
*   TEST_SERVER and TEST_CLIENT are used to test network client/server
*   communication.
}
const
  tserv_port_k = 631;                  {"well known port" of the server}
  tserv_id_k = 1;                      {ID of this server}

type
  tserv_cmd_k_t = int8u_t (            {IDs for all commands (client to server)}
    tserv_cmd_none_k,                  {no command specified}
    tserv_cmd_svinfo_k,                {inquire general server information}
    tserv_cmd_add_k);                  {add two numbers and return string result}

  tserv_rsp_k_t = int8u_t (            {IDs for all responses (server to client)}
    tserv_rsp_none_k,                  {no response specified}
    tserv_rsp_svinfo_k,                {response to SVINFO command}
    tserv_rsp_add_k);                  {response to ADD command}

  tserv_string80_t = array [1..80] of char; {80 character text string}

  tserv_cmd_none_t = record
    cmd: tserv_cmd_k_t;
    end;

  tserv_rsp_none_t = record
    rsp: tserv_rsp_k_t;
    end;
{
*   SVINFO command.
}
  tserv_cmd_svinfo_t = record          {data for SVINFO command}
    cmd: tserv_cmd_k_t;                {command ID}
    t1, t2, t3, t4: int8u_t;           {test bytes to confirm right kind of server}
    end;

  tserv_order_k_t = int8u_t (          {machine byte order flag}
    tserv_order_fwd_k,                 {forwards, most significant byte is first}
    tserv_order_bkw_k);                {backwards, least significant byte is first}

  tserv_rsp_svinfo_t = record          {data for SVINFO response}
    rsp: tserv_rsp_k_t;                {response ID}
    t3, t2, t4, t1: int8u_t;           {test bytes returned in different order}
    r1: int8u_t;                       {T1 xor T2 xor T3 xor T4 xor 5}
    r2: int8u_t;                       {(T1 + T2 + T3 + T4) xor 5}
    r3: int8u_t;                       {(R1 + R2) xor 5}
    order: tserv_order_k_t;            {server byte order}
    id: int32u_t;                      {ID of this server}
    ver_maj: int16u_t;                 {server major version number}
    ver_min: int16u_t;                 {server minor version number}
    ver_seq: int16u_t;                 {server private build sequence number}
    name: tserv_string80_t;            {server name, blank padded or null terminated}
    end;
{
*   ADD command.
}
  tserv_cmd_add_t = record             {data for ADD command}
    cmd: tserv_cmd_k_t;                {command ID}
    i1, i2: integer32;                 {two numbers to add together}
    end;

  tserv_rsp_add_t = record             {data for ADD response}
    rsp: tserv_rsp_k_t;                {response ID}
    len: int8u_t;                      {number of characters in STR, always <= 80}
    str: tserv_string80_t;             {returned character string}
    end;
{
*   Constants related to the various command and response data type sizes.
}
const
  tserv_szcmd_svinfo_k =
    size_min(tserv_cmd_svinfo_t) - size_min(tserv_cmd_k_t);
  tserv_szcmd_add_k =
    size_min(tserv_cmd_add_t) - size_min(tserv_cmd_k_t);

  tserv_szrsp_svinfo_k =
    size_min(tserv_rsp_svinfo_t) - size_min(tserv_rsp_k_t);
  tserv_szrsp_add_k =
    size_min(tserv_rsp_add_t) - size_min(tserv_rsp_k_t);

type
{
*   General data types not specific to particular commands or repsonses.
}
  tserv_cmd_t = record                 {all commands in one overlay}
    case tserv_cmd_k_t of              {different data for each command}
tserv_cmd_none_k: (none: tserv_cmd_none_t);
tserv_cmd_svinfo_k: (svinfo: tserv_cmd_svinfo_t);
tserv_cmd_add_k: (add: tserv_cmd_add_t);
    end;

  tserv_rsp_t = record                 {all responses in one overlay}
    case tserv_rsp_k_t of              {different data for each response}
tserv_rsp_none_k: (none: tserv_rsp_none_t);
tserv_rsp_svinfo_k: (svinfo: tserv_rsp_svinfo_t);
tserv_rsp_add_k: (add: tserv_rsp_add_t);
    end;
