{   Subroutine FILE_RENAME (OLD_NAME, NEW_NAME, STAT)
*
*   Change the name of a file.
}
module file_rename;
define file_rename;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_rename (                {change name of a file}
  in      old_name: univ string_var_arg_t; {old file name}
  in      new_name: univ string_var_arg_t; {new file name}
  out     stat: sys_err_t);            {completion status code}

var
  told, tnew: string_treename_t;       {file names in system format}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}

begin
  told.max := size_char(told.str);     {init local var strings}
  tnew.max := size_char(tnew.str);
  sys_error_none (stat);               {init to no error}

  string_treename (old_name, told);    {convert old name to system format}
  string_terminate_null (told);
  string_treename (new_name, tnew);    {convert new name to system format}
  string_terminate_null (tnew);


  ok := MoveFileA (told.str, tnew.str); {try to rename the file}
  if ok = win_bool_false_k then begin  {error ?}
    stat.sys := GetLastError;
    end;
  end;
