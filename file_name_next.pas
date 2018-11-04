{   Subroutine FILE_NAME_NEXT (H)
*
*   Generate the next name to try given the original user file name arguments
*   that were passed to FILE_NAME_INIT.  H is the handle from FILE_NAME_INIT.
*
*   The file connection handle will be completely set up for this new file
*   name, if FILE_NAME_EXT returns TRUE.  Otherwise, all possible names have
*   been exhausted.
}
module file_NAME_NEXT;
define file_name_next;
%include 'file2.ins.pas';

function file_name_next (              {create next file name to try to open}
  in out  h: file_name_handle_t)       {handle from FILE_NAME_INIT}
  :boolean;                            {TRUE if did create a new name}
  val_param;

var
  ex: string_var80_t;                  {suffix to use this time}
  stat: sys_err_t;

label
  no_name;

begin
  ex.max := sizeof(ex.str);            {init local var string}
  if h.p < 0 then goto no_name;        {all possible names have been tried ?}

  if h.ext.len <= 0
    then begin                         {no extensions were supplied, use raw name}
      string_copy (h.name_p^, h.conn_p^.fnam);
      ex.len := 0;                     {set extension used (none)}
      h.conn_p^.ext_num := 0;          {indicate no extension used}
      h.p := -1;                       {definately no more names after this one}
      end
    else begin                         {extensions exist, use next extension}
      string_token (h.ext, h.p, ex, stat); {extract next file name suffix}
      if sys_error(stat) then goto no_name; {exhausted all possible suffixes ?}
      string_fill (ex);                {make sure unused chars are blank padding}
      string_fnam_extend (h.name_p^, ex.str, h.conn_p^.fnam); {make extended name}
      h.conn_p^.ext_num :=             {make number of extension for this time}
        h.conn_p^.ext_num + 1;
      end
    ;
  if ex.len < ex.max then begin        {room for string terminator character ?}
    ex.str[ex.len + 1] := chr(0);      {put string terminator after suffix}
    end;
{
*   H.CONN_P^.FNAM is all set.  EX is set to the extension used.  It is either
*   completely filled, or a null terminating character immediately follows the
*   extension name.
}
  string_treename (h.conn_p^.fnam, h.conn_p^.tnam); {make full treename}
  string_generic_fnam (h.conn_p^.fnam, ex.str, h.conn_p^.gnam); {make generic name}
  file_name_next := true;              {a new file name was created}
  return;                              {return with file name}

no_name:                               {jump here if no new name left}
  file_name_next := false;
  end;
