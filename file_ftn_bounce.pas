{
*  This module contains all the bounce routines used by FORTRAN for communicating
*  with the file library.
}
module file_ftn;
define file_ftn_close_;
define file_ftn_copy_;
define file_ftn_delete_name_;
define file_ftn_exists_;
define file_ftn_find_;
define file_ftn_info_len_;
define file_ftn_map_;
define file_ftn_map_truncate_;
define file_ftn_open_map_;
define file_ftn_open_read_text_;
define file_ftn_read_text_;

%include 'file2.ins.pas';
%include 'sys_ftn.ins.pas';

type
  file_ftn_conn_p_t =                  {pointer to file connection handle for fortran}
    ^file_ftn_conn_t;

  file_ftn_conn_t = record             {file connection handle for fortran}
    conn: file_conn_t;                 {connection handle to mapped file}
    mem_p: util_mem_context_p_t;       {pointer to context for file admin memory alloc}
    end;

procedure file_ftn_close_ (            {close file}
  in out conn_p: file_ftn_conn_p_t);   {pointer to file connection}
  extern;

procedure file_ftn_copy_ (             {copy a file - write over if already exists}
  in      src: univ sys_ftn_char_t;    {source file name}
  in      src_len: sys_ftn_integer_t;  {source file name length in characters}
  in      dest: univ sys_ftn_char_t;   {destination file name}
  in      dest_len: sys_ftn_integer_t); {destination file name length in characters}
  extern;

procedure file_ftn_delete_name_ (      {delete file by name}
  in      fnam: univ sys_ftn_char_t;   {name of file}
  in      flen: sys_ftn_integer_t);    {length of name}
  extern;

function file_ftn_exists_ (            {determine the existance of a file}
  in      fnam: univ sys_ftn_char_t;   {file name}
  in      fnam_len: sys_ftn_integer_t): {length of file name}
  sys_ftn_logical_t;                   {true means file exists}
  extern;

procedure file_ftn_find_ (             {sequentially find files with the given extension}
  in      ext: univ sys_ftn_char_t;    {extension on file names}
  in      ext_len: sys_ftn_integer_t;  {extension length in characters}
  in out  cnt: sys_ftn_integer_t;      {file count: init to 0 to start find}
  out     file_found: sys_ftn_logical_t; {true if file found}
  out     fnam: univ sys_ftn_char_t;   {file name}
  out     fnam_len: sys_ftn_integer_t; {file name length}
  in      fnam_max: sys_ftn_integer_t); {file name maximum length}
  extern;

procedure file_ftn_info_len_ (         {get length of file in machine address units}
  in      fnam: univ sys_ftn_char_t;   {name of file}
  in      flen: sys_ftn_integer_t;     {length of file name}
  out     len: sys_ftn_integer_adr_t); {length of file in machine address units}
  extern;

procedure file_ftn_map_ (              {map portion of file to virtual adr space}
  in      conn_p: file_ftn_conn_p_t;   {pointer to file connection handle}
  in      ofs: sys_ftn_integer_adr_t;  {mapped region offset from start of file}
  in      len: sys_ftn_integer_adr_t;  {length of region to make available}
  out     p: sys_ftn_integer_adr_t);   {pointer to start of mapped region}
  extern;

procedure file_ftn_map_truncate_ (     {truncate mapped file to specified length}
  in      conn_p: file_ftn_conn_p_t;   {pointer to file connection handle}
  in      len: sys_ftn_integer_adr_t); {length to truncate file to}
  extern;

procedure file_ftn_open_map_ (         {open system file for mapped access}
  in      fnam: univ sys_ftn_char_t;   {name of file}
  in      flen: sys_ftn_integer_t;     {length of name}
  out     conn_p: file_ftn_conn_p_t);  {pointer to file connection handle}
  extern;

procedure file_ftn_open_read_text_ (   {open system file for ascii read}
  in      fnam: univ sys_ftn_char_t;   {name of file}
  in      flen: sys_ftn_integer_t;     {length of name}
  out     conn_p: file_ftn_conn_p_t;   {pointer to file connection handle}
  out     ok: sys_ftn_logical_t);      {true if file opened ok}
  extern;

procedure file_ftn_read_text_ (        {read one line of text from file}
  in out  conn_p: file_ftn_conn_p_t;   {handle to this file connection}
  out     buf: univ sys_ftn_char_t;    {returned line of text}
  in      buf_max: sys_ftn_integer_t;  {dimensioned length of text line}
  out     buf_len: sys_ftn_integer_t;  {returned length of text line}
  out     eof: sys_ftn_logical_t);     {true if eof encountered}
  extern;

{****************************************************}

procedure file_ftn_close_ (            {close file}
  in out  conn_p: file_ftn_conn_p_t);  {pointer to file connection handle}

begin
  file_close (conn_p^.conn);           {close file}
  util_mem_context_del (conn_p^.mem_p); {deallocate file admin memory}
  util_mem_ungrab (conn_p, util_top_mem_context); {deallocate memory for conn handle}
  end;

{****************************************************}

procedure file_ftn_copy_ (             {copy a file - write over if already exists}
  in      src: univ sys_ftn_char_t;    {source file name}
  in      src_len: sys_ftn_integer_t;  {source file name length in characters}
  in      dest: univ sys_ftn_char_t;   {destination file name}
  in      dest_len: sys_ftn_integer_t); {destination file name length in characters}

var
  source: string_treename_t;           {internal source file name}
  destin: string_treename_t;           {internal destination file name}
  i: string_index_t;                   {loop index for string}
  stat: sys_err_t;                     {completion status}

begin
  source.max := sizeof(source.str);    {set maximum length of source file}
  source.len := src_len;               {copy source file length}
  for i := 1 to src_len do
    source.str[i] := src[i];           {copy each character of source file name}
  destin.max := sizeof(destin.str);    {set maximum length of destination file}
  destin.len := dest_len;              {copy destination file length}
  for i := 1 to src_len do
    destin.str[i] := dest[i];          {copy each character of destination file name}
  file_copy (                          {copy routine}
    source,                            {source file name}
    destin,                            {destination file name}
    [file_copy_replace_k],             {ok to write over}
    stat);                             {return status}
  sys_error_abort (stat, '', '', nil, 0); {check completion status}
  end;

{****************************************************}

procedure file_ftn_delete_name_ (      {delete file by name}
  in      fnam: univ sys_ftn_char_t;   {name of file}
  in      flen: sys_ftn_integer_t);    {length of name}

var
  ifnam: string_treename_t;            {internal file name}
  stat: sys_err_t;                     {completion status}

begin
  ifnam.max := sizeof(ifnam.str);      {init internal file name}
  string_vstring (ifnam, fnam, flen);  {load name of file to delete}
  file_delete_name (ifnam, stat);      {delete file}
  sys_error_abort (stat, '', '', nil, 0); {check completion status}
  end;

{****************************************************}

function file_ftn_exists_ (            {determine the existance of a file}
  in      fnam: univ sys_ftn_char_t;   {file name}
  in      fnam_len: sys_ftn_integer_t): {length of file name}
  sys_ftn_logical_t;                   {true means file exists}

var
  int_fnam: string_treename_t;         {internal file name}
  i: string_index_t;                   {loop index for string}

begin
  int_fnam.max := sizeof(int_fnam.str); {set maximum length of int_fnam file}
  int_fnam.len := fnam_len;            {copy int_fnam file length}
  for i := 1 to fnam_len do
    int_fnam.str[i] := fnam[i];        {copy each character of int_fnam file name}
  file_ftn_exists_ := sys_pas_boolean_t_ftn_logical (file_exists (int_fnam));
  end;

{****************************************************}

procedure file_ftn_find_ (             {sequentially find files with the given extension}
  in      ext: univ sys_ftn_char_t;    {extension on file names}
  in      ext_len: sys_ftn_integer_t;  {extension length in characters}
  in out  cnt: sys_ftn_integer_t;      {file count: init to 0 to start find}
  out     file_found: sys_ftn_logical_t; {true if file found}
  out     fnam: univ sys_ftn_char_t;   {file name}
  out     fnam_len: sys_ftn_integer_t; {file name length}
  in      fnam_max: sys_ftn_integer_t); {file name maximum length}

var
  info: file_info_t;                   {unused}

label
  next_file_name;

var
  extension: static string_var80_t;    {extension on file names}
  name: static string_treename_t;      {internal string for name of file}
  name_with_ext: static string_treename_t; {internal string for name of file}
  dir_conn: static file_conn_t;        {connection to current directory}

  stat: sys_err_t;                     {completion status}
  i: string_index_t;                   {loop index for string}

begin
  if cnt = 0 then begin
{
*  We are looking for the first file matching the extension.
*  Need to open directory for reading.
}
    name.max := sizeof(name.str);      {init name string}
    name.len := 0;
    name_with_ext.max := sizeof(name.str); {init name with extension string}
    name_with_ext.len := 0;
    extension.max := sizeof(name.str); {init ext string}
    extension.len := 0;
    string_vstring (extension, ext, ext_len); {convert fortran string to var string}
    string_fill (extension);           {pad with spaces}
    file_open_read_dir (               {open the working directory for reading file names}
      string_v('.'),                   {current working directory}
      dir_conn,                        {handle to newly created connection}
      stat);                           {completion status code}
    sys_error_abort (stat, '', '', nil, 0);
    end;

  file_found := sys_ftn_logical_false_k; {init most file as not being found}

next_file_name:                        {come here to read next file name}
  file_read_dir (                      {read file name}
    dir_conn,                          {handle to connection to directory}
    [],                                {no additional info is being requested}
    name,                              {name of file}
    info,                              {unused}
    stat);                             {completion status}
  if file_eof(stat)
    then begin                         {another file in directory exists}
      file_close (dir_conn);           {close the working directory}
      end
    else begin                         {another file in directory exists}
      sys_error_abort (stat, '', '', nil, 0); {check for errors}
      string_fnam_extend (             {extend filename with extension}
        name,                          {name to extend}
        extension.str,                 {extension to use}
        name_with_ext);                {name with extension}
      if name.len = name_with_ext.len
        then begin                     {found file with extension}
          fnam_len := min(fnam_max, name.len); {set file name length}
          for i := 1 to min(fnam_max, name.len) do begin
            fnam[i] := name.str[i];    {copy name}
            end;
          file_found := sys_ftn_logical_true_k; {indicate file was found}
          cnt := cnt + 1;              {increment file count}
          end
        else begin                     {name did not have right extension}
          goto next_file_name;         {read next file name}
          end
        ;
      end
    ;
  end;

{****************************************************}

procedure file_ftn_info_len_ (         {get length of file in machine address units}
  in      fnam: univ sys_ftn_char_t;   {name of file}
  in      flen: sys_ftn_integer_t;     {length of name}
  out     len: sys_ftn_integer_adr_t); {length of file in machine address units}

var
  ifnam: string_treename_t;            {internal file name}
  info: file_info_t;                   {file information}
  stat: sys_err_t;                     {completion status}

begin
  ifnam.max := sizeof(ifnam.str);      {init internal file name}
  string_vstring (ifnam, fnam, flen);  {load name of file to delete}
  file_info (                          {get information about file}
    ifnam,                             {name of file get information about}
    [file_iflag_len_k],                {get length of file}
    info,                              {information about file}
    stat);                             {completion status}
  sys_error_abort (stat, '', '', nil, 0); {check completion status}
  len := info.len;                     {copy length of file}
  end;

{****************************************************}

procedure file_ftn_map_ (              {map portion of file to virtual adr space}
  in      conn_p: file_ftn_conn_p_t;   {pointer to file connection handle}
  in      ofs: sys_ftn_integer_adr_t;  {mapped region offset from start of file}
  in      len: sys_ftn_integer_adr_t;  {length of region to make available}
  out     p: sys_ftn_integer_adr_t);   {pointer to start of mapped region}

var
  len_mapped: sys_int_adr_t;           {length actually mapped}
  handle_p: file_map_handle_p_t;       {pointer to handle of mapped region}
  ip: univ_ptr;                        {intenal pointer}
  old_len: sys_int_adr_t;              {file length before new mapping}
  new_len: sys_int_adr_t;              {file length after new mapping}
  fint_p: ^sys_ftn_integer_t;          {used for clearing newly created part of file}
  i: sys_int_machine_t;                {scratch integer and loop counter}
  nint: sys_int_machine_t;             {number of FTN integers to clear}
  stat: sys_err_t;                     {completion status}

begin
  old_len := file_map_length (conn_p^.conn); {save file length before new mapping}

  util_mem_grab (                      {alloc memory for handle}
    sizeof(handle_p^),                 {size of memory to grab}
    conn_p^.mem_p^,                    {context under which to allocate memory}
    false,                             {won't need to deallocate individually}
    handle_p);                         {pointer to handle of mapped portion of file}
  file_map (                           {map portion of file to virtual adr space}
    conn_p^.conn,                      {handle to file}
    ofs,                               {mapped region offset from start of file}
    len,                               {length of region to make available}
    [file_rw_read_k, file_rw_write_k], {allow read and writing to portion}
    ip,                                {pointer to start of mapped region}
    len_mapped,                        {actual length mapped}
    handle_p^,                         {handle to this mapped region}
    stat);                             {completion status}
  sys_error_abort (stat, '', '', nil, 0); {check completion status}
  p := sys_ftn_integer_adr_t(ip);      {convert data type}

  new_len := file_map_length (conn_p^.conn); {get new file length after mapping}

  if new_len > old_len then begin      {this mapping extended file size ?}
    fint_p := univ_ptr(                {make pointer to first newly created address}
      sys_int_adr_t(ip) + len_mapped - (new_len - old_len));
    nint := (new_len - old_len) div sizeof(fint_p^); {number of words to clear}
    for i := 1 to nint do begin        {once for each FTN integer to clear}
      fint_p^ := 0;
      fint_p := univ_ptr(sys_int_adr_t(fint_p) + sizeof(fint_p^)); {advance pointer}
      end;                             {back for next word to clear}
    end;                               {done handling newly created part of file}
  end;

{****************************************************}

procedure file_ftn_map_truncate_ (     {truncate mapped file to specified length}
  in      conn_p: file_ftn_conn_p_t;   {pointer to file connection handle}
  in      len: sys_ftn_integer_adr_t); {length to truncate file to}

begin
  file_map_truncate (                  {truncate mapped file to specified length}
    conn_p^.conn,                      {file connection handle}
    len);                              {len to truncate file to}
  end;

{****************************************************}

procedure file_ftn_open_map_ (         {open system file for mapped access}
  in      fnam: univ sys_ftn_char_t;   {name of file}
  in      flen: sys_ftn_integer_t;     {length of name}
  out     conn_p: file_ftn_conn_p_t);  {pointer to file connection handle}

var
  ifnam: string_treename_t;            {internal file name}
  stat: sys_err_t;                     {completion status}

begin
  ifnam.max := sizeof(ifnam.str);      {init internal file name}
  string_vstring (ifnam, fnam, flen);  {load name of file to delete}
  util_mem_grab (                      {grab memory for file connection handle}
    sizeof(conn_p^),                   {size required}
    util_top_mem_context,              {context underwhich to grab memory}
    true,                              {need to be able to deallocate individually}
    conn_p);                           {pointer to file connection handle}
  util_mem_context_get (               {get context for mapped file memory admin}
    util_top_mem_context,              {parent context to create new context under}
    conn_p^.mem_p);                    {pointer to memory context}
  file_open_map (                      {open system file for mapped access}
    ifnam,                             {file name}
    '',                                {no file name extensions}
    [file_rw_read_k, file_rw_write_k], {intended read/write access}
    conn_p^.conn,                      {newly created file connection}
    stat);                             {completion status code}
  sys_error_abort (stat, '', '', nil, 0); {check completion status}
  end;

{****************************************************}

procedure file_ftn_open_read_text_ (   {open system file for ascii read}
  in      fnam: univ sys_ftn_char_t;   {name of file}
  in      flen: sys_ftn_integer_t;     {length of name}
  out     conn_p: file_ftn_conn_p_t;   {pointer to file connection handle}
  out     ok: sys_ftn_logical_t);      {true if file opened ok}

var
  ifnam: string_treename_t;            {internal file name}
  stat: sys_err_t;                     {completion status}

begin
  ifnam.max := sizeof(ifnam.str);      {init internal file name}
  string_vstring (ifnam, fnam, flen);  {load name of file to delete}
  util_mem_grab (                      {grab memory for file connection handle}
    sizeof(conn_p^),                   {size required}
    util_top_mem_context,              {context underwhich to grab memory}
    true,                              {need to be able to deallocate individually}
    conn_p);                           {pointer to file connection handle}
  util_mem_context_get (               {get context for mapped file memory admin}
    util_top_mem_context,              {parent context to create new context under}
    conn_p^.mem_p);                    {pointer to memory context}
  file_open_read_text (                {open system file for mapped access}
    ifnam,                             {file name}
    '',                                {no file name extensions}
    conn_p^.conn,                      {newly created file connection}
    stat);                             {completion status code}
  if sys_error(stat)
    then ok := sys_ftn_logical_false_k {file was not opened}
    else ok := sys_ftn_logical_true_k; {file was opened}
  end;

{****************************************************}

procedure file_ftn_read_text_ (        {read one line of text from file}
  in out  conn_p: file_ftn_conn_p_t;   {handle to this file connection}
  out     buf: univ sys_ftn_char_t;    {returned line of text}
  in      buf_max: sys_ftn_integer_t;  {dimensioned length of text line}
  out     buf_len: sys_ftn_integer_t;  {returned length of text line}
  out     eof: sys_ftn_logical_t);     {true if eof encountered}

var
  ibuf: string_var8192_t;
  stat: sys_err_t;
  i: sys_int_machine_t;

begin
  ibuf.max := sizeof(ibuf.str);
  file_read_text (conn_p^.conn, ibuf, stat);
  if file_eof(stat)
    then eof := sys_ftn_logical_true_k
    else eof := sys_ftn_logical_false_k;
  sys_error_abort (stat, 'file', 'read_input_text', nil, 0);
  buf_len := min(buf_max, ibuf.len);
  for i := 1 to buf_len do begin
    buf[i] := ibuf.str[i];
    end;
  end;
