/*   Error messages related to status codes.
/*
msg err1
  lan english -def
    End of file.
msg err2                               /* name attempted to use as a directory.
  lan english -def
    "%p1s" is not a directory.
msg err4
  lan english -def
    File name was empty string on attempt to open file.
msg err5
  lan english -def
    SIO line input end of record not ON or set to null string.
msg err6
  lan english -def
    Improper serial line baud rate specifier.
msg err7                               /* object name
  lan english -def
    File not found.  File name was "%p1s" with suffix string "%p2s".
msg err8
  lan english -def
    No data was written with system call to write to a file, although
    system otherwise reported no errors.
msg err9
  lan english -def
    Wrong amount of data was written by system call to write to file "%p1s".
    Requested size of data was %p2i, but actual amount of data written was %p3i.
msg err10
  lan english -def
    Only part of the requested read operation was performed because the end
    of the file was encountered.  %p1i address units of data were requested,
    although only %p2i were available before the end of file.
msg err11
  lan english -def
    Neither read nor write access was requested on attempt to open
    file.  File name was "%p1s" with suffix string "%p2s".
msg err12
  lan english -def
    Unable to return all the information requested about a file.
    Check the FLAGS field to determine what was actually returned.
msg err13
  lan english -def
    Illegal file type or connection type for positioning the file to
    an absolute offset.  Only binary files opened for sequential access
    are allowed to be positioned in this way.  Attempt was to position
    file "%p1s" to offset %p2i.
msg err14
  lan english -def
    A new mapped region was requested that crosses boundaries between
    separately created regions of the mapped file.
msg err15
  lan english -def
    Unable to determine internet address from node name "%p1s".
msg err16
  lan english -def
    Not all the requested data was read because no additional data was immediately
    available, although no end of file was encountered.
msg err17
  lan english -def
    Unable to find network name of node at internet address "%p1s".
msg err18
  lan english -def
    The COGSERVE server on machine "%p1s" is at an incompatible version to
    this client software.  Client software version is %p2i.%p3i.
msg err19
  lan english -def
    Error occurred in communicating with COGSERVE server on machine "%p1s".
msg err20
  lan english -def
    Remote operation on machine "%p1s" failed.
msg err21
  lan english -def
    Unable to delete all requested objects.  %p1i object(s) not deleted.
msg err22
  lan english -def
    Attempt to copy onto existing file system object %p1s.
msg err23
  lan english -def
    Attempt to create a new object "%p1s", but the object already exists.
msg err24
  lan english -def
    Error on attempt to rename object from %p1s to %p2s.  The old and new file
    names are not in the same directory.
msg err25
  lan english -def
    Unable to open system serial (RS-232) port %p1i.
    The port is probably in use by another program, or you do not have
    the necessary priveledges to access the port.
msg err26
  lan english -def
    Unable to open system serial (RS-232) port %p1i because it does
    not exist.
msg err27
  lan english -def
    The resource %p1s is already in use and can not be accessed.
msg err28
  lan english -def
    Not all the requested data was written.
msg err29
  lan english -def
    USB device with VID %p1i and PID %p2i was not found.
msg err30
  lan english -def
    USB device with VID %p2i, PID %p3i, and name "%p1s" was not found.
msg err31
  lan english -def
    USB device with VID %p2i, PID %p3i, and name "%p1s" is in use.
msg err32
  lan english -def
    I/O operation timed out.
msg err33
  lan english -def
    The I/O connection is closed.
msg err34
  lan english -def
    Text write is not supported for this object type.  Object name "%p1s",
    object type ID %p2i.
/*
/*   Other messages that do not have status codes.
/*
msg attributes_get_err
  lan english -def
    Error occurred on attempt to get attributes for file "%p1s".
msg cogserve_close
  lan english -def
    Error occurred on attempt to remote COGSERVE server operation on machine "%p1s".
msg cogserve_connect
  lan english -def
    Error on attempt to connect to COGSERVE server on machine "%p1s".
msg cogserve_incompatible
  lan english -def
    COGSERVE server on machine "%p1s" is at version %p2i.%p3i, which is
    incompatible with the version of this program.
msg cogserve_readfrom
  lan english -def
    Error on attempt to read data from COGSERVE server.
msg cogserve_response_unexpected
  lan english -def
    Received unexpected response of ID %p1i from COGSERVE server.
msg cogserve_run_abort
  lan english -def
    The remote program was killed by another process.
msg cogserve_run_cmline
  lan english -def
    Error on sending RUN command to COGSERVE server.
    The command line was "%p1s".
msg cogserve_run_nogo
  lan english -def
    Remote server was unable to invoke the program.
    Check pathname and command search rules.
    The command line was "%p1s".
msg cogserve_run_nostop
  lan english -def
    Server was unable to stop the remote program.  Remote program still
    running.
msg cogserve_run_stat_bad
  lan english -def
    Unexpected stop code of %p1i returned by server.  Please notify a
    Cognivision representative of this error.
msg cogserve_run_stat_unknown
  lan english -def
    The server was unable to determine the exit status of the remote
    program.  ERROR assumed.
msg cogserve_run_sverr
  lan english -def
    Internal error occurred on remote server.  Program not invoked.
msg cogserve_run_svkill
  lan english -def
    Remote program was killed by the server due to a server error.
msg copy_err
  lan english -def
    Error on attempt to copy "%p1s" to "%p2s".
msg error_fnam_lnum
  lan english -def
    Error occurred on line %p1i of file "%p2s".
msg close
  lan english -def
    On system call to close a file.
msg close_dir
  lan english -def
    On system call to close directory.
msg close_inet_stream
  lan english -def
    On system call to close an internet stream connection.
msg close_map_object
  lan english -def
    On system call to close file mapping object.
msg create_server
  lan english -def
    Error on attempt to create network server port and socket.
msg delete                             /* file name
  lan english -def
    Error occurred on attempt to delete file "%p1s".
msg inet_adr_name
  lan english -def
    Error on trying to get official network name for node at address
    %p1i.%p2i.%p3i.%p4i.
msg inet_info_remote
  lan english -def
    Error on trying to get information about remote end of internet
    stream connection.
msg inet_name_adr
  lan english -def
    Error on trying to get internet address for node "%p1s".
msg inetstr_accept
  lan english -def
    Error on waiting for client to request internet stream connection.
msg info
  lan english -def
    Error on trying to get information about file "%p1s".
msg map_access
  lan english -def
    More read/write access was requested to a region of a mapped file than the
    file was opened with.
msg open_dir                           /* directory name
  lan english -def
    Error on trying to open directory "%p1s" for read.
msg open_inetstr_client
  lan english -def
    Error on trying to establish internet stream connection to port %p1i
    on network node "%p2s".
msg open_input_read_bin                /* file name
  lan english -def
    Error on trying to open input file "%p1s" for binary read.
msg open_input_read_text               /* file name
  lan english -def
    Error on trying to open input file "%p1s" for text read.
msg open_output_write_text             /* file name
  lan english -def
    Error on trying to open output file "%p1s" for text write.
msg open_stdin
  lan english -def
    Error on connecting to to standard input stream.
msg open_stdout
  lan english -def
    Error on connecting to to standard output stream.
msg open_errout
  lan english -def
    Error on connecting to to standard error output stream.
msg open_stream
  lan english -def
    Error on attempt to connect I/O to existing system stream.
    ID of system stream was %p1i.
msg open_sio                           /* serial line number
  lan english -def
    Error on trying to open connection to serial line number %p1i.
msg pos_bof
  lan english -def
    Error on trying to position to start of file.
msg pos_eof
  lan english -def
    Error on trying to position to end of file.
msg pos_get
  lan english -def
    Error on system call to get current position into file.
msg pos_set
  lan english -def
    Error on trying to re-position file from position handle.
msg read_dir
  lan english -def
    Error on trying to read next entry from directory.
msg read_inetstr_client
  lan english -def
    Error on trying to read data from internet stream to client.
msg read_inetstr_server
  lan english -def
    Error on trying to read data from internet stream to server.
msg read_input_bin
  lan english -def
    Error occurred on reading from binary input file.
msg read_input_text
  lan english -def
    Error on trying to read text line from input file.
msg read_sio
  lan english -def
    Error on trying to read from serial line.
msg read_stdin
  lan english -def
    Error on trying to read from standard input.
msg rename                             /* old file name, new file name
  lan english -def
    Error occurred on attempt to change file name from "%p1s" to "%p2s".
msg skip_input_text
  lan english -def
    Error on trying to skip over text lines in input file.
msg stdstream_id_bad
  lan english -def
    Illegal ID for standard system stream encountered.
msg too_many_ext
  lan english -def
    Too many file name extensions.  Only one is allowed when
    opening for write, or when opening a set of environment files.
msg truncate
  lan english -def
    On system call to truncate file.
msg unk_enttype
  lan english -def
    Unknown system object type on reading directory.
msg unmap
  lan english -def
    Error occurred on system call to unmap a region of a mapped file.
msg write_inetstr_client
  lan english -def
    Error on trying to write to internet stream connected to remote server.
msg write_inetstr_server
  lan english -def
    Error on trying to write to internet stream connected to remote client.
msg write_output_bin
  lan english -def
    Error on trying to write to binary output file.
msg write_output_text
  lan english -def
    Error on trying to write text line to output file.
msg write_sio
  lan english -def
    Error on trying to write to serial line.
msg write_stdout_text
  lan english -def
    Error on trying to write text to standard output.
msg write_errout_text
  lan english -def
    Error on trying to write text to standard error output.
/*
/*   Error messages related environment files.
/*
msg env_cmd_bad
  lan english -def
    Illegal environment file command "%p1s" encountered on line %p2i
    of file "%p3s".
msg env_open                           /* environment file set name
  lan english -def
    Error while trying to open environment file set "%p1s" for read.
msg env_parm_bad
  lan english -def
    Error occurred on parameter "%p1s" for command "%p2s" on line
    %p3i of file "%p4s".
msg env_read                           /* line number, file name
  lan english -def
    Error on reading from environment file.  Error occurred at line
    %p1i of file "%p2s".
msg env_too_many_tokens
  lan english -def
    Too many tokens encounterd in environment file.  First extraneous
    token was "%p1s".  Error occurred on line %p2i of file "%p3s".
/*
/*   Messages used by programs.
/*
msg copya_no_outfile
  lan english -def
    No output file name was supplied or could be inferred.
msg copya_tab_out_range
  lan english -def
    Tab number %p1i is out of range.
msg copya_tabs_not_ascending
  lan english -def
    COPYA command line error.  Tab column %p1i is not after column %p2s.
    Tab columns must be given in ascending order.
msg curr_dir_get
  lan english -def
    Error on attempt to get current working directory name.
msg curr_dir_set
  lan english -def
    Error on attempt to set current working directory to %p1s.
msg dir_create
  lan english -def
    Error on attempt to create the directory "%p1s".
msg l_lo_badflag
  lan english -def
    Illegal letter "%p1s" found in parameter to -LO command line option.
msg link_create
  lan english -def
    Error on attempt to create the link "%p1s".
msg link_del
  lan english -def
    Error on attempt to delete link "%p1s".
msg link_del_incompatible
  lan english -def
    The -DEL command line option is not allowed with one or more of the
    other command line options.
msg link_no_name
  lan english -def
    No link name was supplied.
msg link_resolve
  lan english -def
    Error on attempt to resolve the link "%p1s".
msg no_input_filename
  lan english -def
    No input file name specified.  An input file is required.
msg no_name
  lan english -def
    No name specified.  A name is required on the command line.
msg runon_cmline_empty
  lan english -def
    No remote command was specified.
msg test_client_auth_fail
  lan english -def
    Server authentication failed.  The remote server is therefore assumed
    to not be the type we were expecting.
msg test_client_cmd_bad
  lan english -def
    Command "%p1s" is not recognized.
msg test_client_tkextra
  lan english -def
    ERROR: Too many tokens encountered after command.
msg test_map_err_data
  lan english -def
    Different value read from file than expected at file offset
    %p1i.  Expected %p2i, found %p3i.
msg test_map_err_extend
  lan english -def
    Error on attempt to map region to extend the file length by %p1i,
    from %p2i to %p3i.
msg test_map_err_map
  lan english -def
    Error on attempt to map region from %p1i to %p2i, of length %p3i.
msg test_map_len
  lan english -def
    Unexpected file length found on re-open file.  Expected %p1i,
    found %p2i.
msg test_server_rem_name
  lan english -def
    Error on trying to get name of client machine from its address.
