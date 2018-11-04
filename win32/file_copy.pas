{   Subroutine FILE_COPY (SRC, DEST, FLAGS, STAT)
*
*   Copy a file from one pathname to another.
*
*   SRC - Source file name.
*
*   DEST - Destination file name
*
*   FLAGS - Set of optional flags that modify routine behaviour.  Flags are:
*
*     FILE_COPY_REPLACE_K - Allow copying onto an existing file.  Without
*       this flag it is an error if the destination file already exists.
*
*   STAT - Returned completion status code.  The copy was performed only when
*     STAT is set to indicate no error.
}
module file_COPY;
define file_copy;
%include 'file2.ins.pas';
%include 'file_sys2.ins.pas';

procedure file_copy (                  {copy a file to another place}
  in      src: univ string_var_arg_t;  {source file name}
  in      dest: univ string_var_arg_t; {destination file name}
  in      flags: file_copy_t;          {set of modifier flags}
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  told, tnew: string_treename_t;       {old and new file treenames}
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on system call success}
  create_only: win_bool_t;             {don't overwrite old file when TRUE}

begin
  told.max := size_char(told.str);     {init local var strings}
  tnew.max := size_char(tnew.str);
  sys_error_none (stat);               {init to no error}

  string_treename (src, told);         {convert old name to system format}
  string_terminate_null (told);
  string_treename (dest, tnew);        {convert new name to system format}
  string_terminate_null (tnew);

  if file_copy_replace_k in flags
    then begin                         {OK to overwrite existing file}
      discard( DeleteFileA (tnew.str) );
      create_only := win_bool_false_k;
      end
    else begin                         {not allowed to overwrite existing file}
      create_only := win_bool_true_k;
      end
    ;

  ok := CopyFileA (told.str, tnew.str, create_only); {try to copy the file}
  if ok = win_bool_false_k then begin  {error ?}
    stat.sys := GetLastError;
    end;
  end;
