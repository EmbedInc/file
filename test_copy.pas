{   Program TEST_COPY <source fnam> <dest fnam> [ options ]
*
*   Test the FILE_COPY routine.  Command line options are:
*
*   -R
*
*     OK to overwrite existing file.  By default it is an error if the destination
*     file exists previous to the copy.
}
program test_copy;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';

var
  src, dest:                           {source and destination file names}
    %include '(cog)lib/string_treename.ins.pas';
  flags: file_copy_t;                  {set of FILE_COPY routine options}

  opt:                                 {command line option name}
    %include '(cog)lib/string32.ins.pas';
  pick: sys_int_machine_t;             {number of option name in list}
  stat: sys_err_t;                     {error status code}

label
  next_parm, done_parms;

begin
  string_cmline_init;                  {init reading our command line}

  string_cmline_token (src, stat);     {get source file name}
  string_cmline_req_check (stat);

  string_cmline_token (dest, stat);    {get destination file name}
  string_cmline_req_check (stat);

  flags := [];                         {init to default values}

next_parm:                             {back here for each new command line parameter}
  string_cmline_token (opt, stat);     {get next command line option name}
  if string_eos(stat) then goto done_parms; {exhausted command line ?}
  string_upcase (opt);                 {make upper case for token matching}
  string_tkpick80 (opt,
    '-R',
    pick);
  case pick of
{
*   -R
}
1: begin
  flags := flags + [file_copy_replace_k];
  end;
{
*   Unrecognized command line option name.
}
otherwise
    string_cmline_opt_bad;
    end;                               {end of option name cases}
  goto next_parm;                      {back for next command line option}
done_parms:                            {jump here when all done with comline parms}

  file_copy (src, dest, flags, stat);  {do the copy}
  sys_error_abort (stat, '', '', nil, 0);
  end.
