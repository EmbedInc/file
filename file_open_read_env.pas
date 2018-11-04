{   Subroutine FILE_OPEN_READ_ENV (ENV_NAME,EXT,CONN,STAT)
*
*   Init for reading a set of Cognivision environment files.  ENV_NAME is the
*   generic name of all the files in the set, and EXT is the file name extension
*   of all the files.  CONN is the returned connection handle to use with the
*   actual read routine.  STAT is the returned completion status code.
*
*   For each generic environment file name, there may be a set of actual files,
*   up to one in each directory in a search hierarchy.  It is not required for
*   an environment file of a particualr name to exist in any of the directories.
*   The files are later read as if they were all one file, with the appearance
*   that they are concatenated sequentially.  This is intended to allow specific
*   environment files per site, node, user, and directory.
}
module file_open_read_env;
define file_open_read_env;
%include 'file2.ins.pas';

procedure file_open_read_env (         {init for reading set of environment files}
  in      env_name: univ string_var_arg_t; {generic environment file name}
  in      ext: string;                 {file name extension}
  in      global_first: boolean;       {TRUE if read in global to local order}
  out     conn: file_conn_t;           {handle to newly created file connection}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  data_p: file_env_data_p_t;           {points to our private data}
  extv: string_var80_t;                {extensions in a var string}
  ex: string_var80_t;                  {one extension parsed from EXTV}
  p: string_index_t;                   {EXTV parse index}

begin
  extv.max := sizeof(extv.str);        {init var strings}
  ex.max := sizeof(ex.str);
  conn.fnam.max := sizeof(conn.fnam.str);
  conn.gnam.max := sizeof(conn.gnam.str);
  conn.tnam.max := sizeof(conn.tnam.str);

  if env_name.len <= 0 then begin      {file name string empty ?}
    sys_stat_set (file_subsys_k, file_stat_no_fnam_open_k, stat);
    return;                            {return with error}
    end;

  sys_mem_alloc (sizeof(data_p^), data_p); {grab memory for our private data}
  if data_p = nil then begin
    sys_message ('sys', 'no_mem');     {complain about no memory}
    sys_bomb;
    end;

  string_vstring (extv, ext, sizeof(ext)); {make extension name var string}
  p := 1;                              {init EXTV parse index}
  string_token (extv, p, ex, stat);    {extract first extension name into EX}
  if ex.len > 0
    then begin                         {at least one extension name was given}
      string_fill (ex);                {fill unused chars with blanks}
      string_fnam_extend (env_name, ex.str, conn.fnam); {make extended file name}
      string_copy (conn.fnam, conn.gnam); {init generic name}
      conn.gnam.len := conn.gnam.len - ex.len; {remove extension name}
      string_token (extv, p, ex, stat); {try to get another extension name}
      if ex.len <> 0 then begin        {a second extension name was found ?}
        sys_mem_dealloc (data_p);      {deallocate our private conn data}
        sys_message ('file', 'too_many_ext');
        sys_bomb;
        end;
      conn.ext_num := 1;               {indicate extension was used}
      end
    else begin                         {no extension name was given}
      string_copy (env_name, conn.fnam); {save complete file name}
      string_copy (env_name, conn.gnam); {save generic name}
      conn.ext_num := 0;               {indicate no extension used}
      end
    ;

  with data_p^: d do begin             {D is private context record}
    d.closed := true;                  {indicate no file currently open}
    sys_env_path_get (d.next_dir_p);   {get pointer to list of directory names}
    if global_first
      then begin                       {read global to local order}
        d.forwards := true;
        end
      else begin                       {read local to global order}
        while d.next_dir_p^.next_p <> nil {find end of directories chain}
          do d.next_dir_p := d.next_dir_p^.next_p;
        d.forwards := false;
        end
      ;
    end;                               {done with D abbreviation}

  conn.rw_mode := [file_rw_read_k];    {fill in rest of connection handle}
  conn.obty := file_obty_env_k;
  conn.fmt := file_fmt_text_k;
  conn.lnum := 0;
  conn.data_p := data_p;               {link our memory into connection handle}
  conn.close_p := addr(file_close_env); {indicate to call our routine for close}
  sys_error_none (stat);               {indicate no error}
  end;
