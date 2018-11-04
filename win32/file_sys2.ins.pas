{   System-dependent include file for implementing FILE library routines.
*
*   This version is for the Microsoft Win32 API.
}
%include 'sys_sys2.ins.pas';

type
  file_rdir_data_t = record            {private data used for reading directory}
    fdata: fdata_find_t;               {data returned from system call}
    valid: boolean;                    {TRUE when FDATA info not yet passed back}
    eof: boolean;                      {TRUE when no more info available from system}
    end;
  file_rdir_data_p_t = ^file_rdir_data_t;

procedure file_close_dir (             {close conn opened with FILE_OPEN_READ_DIR}
  in      conn_p: file_conn_p_t);      {pointer to our connection handle}
  val_param; extern;

procedure file_info2 (                 {extract file info from system structure}
  in      fdata: fdata_find_t;         {info about file from FindNextFileW}
  in      info_req: file_iflags_t;     {info requested to return}
  out     info: file_info_t;           {returned file info}
  in out  name: univ string_var_arg_t; {returned apparent file name}
  out     stat: sys_err_t);
  val_param; extern;
