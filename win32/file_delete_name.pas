{   subroutine FILE_DELETE_NAME (FNAM, STAT)
*
*   Delete the file whos name is in FNAM.  STAT is the returned completion status
*   code.
}
module file_delete_name;
define file_delete_name;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_delete_name (           {delete a file by name}
  in      fnam: univ string_var_arg_t; {name of file to delete}
  out     stat: sys_err_t);            {completion status code}

var
  tnam: string_treename_t;             {local treename of file}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

begin
  tnam.max := sizeof(tnam.str);        {init local var string}
  sys_error_none (stat);               {init to no error}

  string_treename (fnam, tnam);        {convert input name to system format}
  string_terminate_null (tnam);

  ok := DeleteFileA (tnam.str);        {try to delete the file}
  if ok = win_bool_false_k then begin  {error ?}
    stat.sys := GetLastError;
    end;
  end;
