(* Copyright (C) 2014, Thanassis Tsiodras *)

open Unix
open Utils
open Common
open System

type 'a osResult = Result of 'a | Error of string

module RealSystem = System.RealSystem(Unix);;
let systemUnix = new RealSystem.real_system

let errorCatcher f =
  try
    let result = f () in
    Result result
  with
  | Unix.Unix_error (code, fun_name, arg) ->
    Error(String.concat ":" [(Unix.error_message code); fun_name; arg])
  | Common.Safe_exception (msg, _) ->
    Error(msg)

let fallback default = function
  | Result s -> s
  | Error _ -> default

let fallbackStr ?addSuffix:(addSuffix=false) default = function
  | Result s -> s
  | Error msg -> match addSuffix with
    | true -> default ^ msg
    | false -> default

module Time = struct
  let sleep = Unix.sleep
end;;

module Os = struct

  module Path = struct
    let abspath x = errorCatcher (fun () -> Utils.abspath systemUnix x)
    let abspath_unsafe = Utils.abspath systemUnix

    let basename_unsafe = Filename.basename
    let basename x = errorCatcher (fun () -> basename_unsafe x)

    let dirname_unsafe = Filename.dirname
    let dirname x = errorCatcher (fun () -> dirname_unsafe x)

    let exists_unsafe x =
      Sys.file_exists x
      || try
        Sys.is_directory x
      with Sys_error (_) ->
        false
    let exists x = errorCatcher (fun () -> exists_unsafe x)

    let isdir_unsafe = Sys.is_directory
    let isdir x = errorCatcher (fun () -> isdir_unsafe x)

    let isrealfile x = errorCatcher (fun () ->
      let s = Unix.lstat x in
      s.st_kind = Unix.S_REG)

    let isfile_unsafe x =
      let s1 = Unix.lstat x in
      match s1.st_kind with
      | Unix.S_REG -> true
      | Unix.S_DIR | Unix.S_SOCK | Unix.S_BLK | Unix.S_CHR | Unix.S_FIFO -> false
      | Unix.S_LNK -> 
        let f = isrealfile x in
        match f with
        | Result true -> true
        | _ -> false
    let isfile x = errorCatcher (fun () -> isfile_unsafe x)

    let islink_unsafe x =
      let s = Unix.lstat x in
      s.st_kind = Unix.S_LNK
    let islink x = errorCatcher (fun () -> islink_unsafe x)

    let realpath_unsafe = Utils.realpath systemUnix
    let realpath x = errorCatcher (fun () -> Utils.realpath systemUnix x)

    (*let splitext*)

    (*let f="/home/ttsiod/.xinitrc.lxde";;*)
    (*let r=Str.regexp "^\\(.*?\\)\\(\\.[^\\.]*\\)$";;*)
    (*let a=Str.string_match r f 0 in if a then Str.matched_group 2 f else "";;*)
    (*- : string = ".lxde"     *)

  end;;

  let chdir_unsafe = Unix.chdir
  let chdir folder = errorCatcher (fun () -> chdir_unsafe folder)

  let getcwd_unsafe = Unix.getcwd
  let getcwd () = errorCatcher (fun () -> getcwd_unsafe ())

  let listdir_unsafe folder =
    let od = Unix.opendir folder in
    let rec getAllEntries l = 
      try
        let newEntry = readdir od in
        let newList = match newEntry with
        | "."
        | ".." -> l
        | _ -> newEntry :: l in
        getAllEntries newList
      with End_of_file -> l in
    let listOfResults = List.rev @@ getAllEntries [] in
    Unix.closedir od ;
    listOfResults
  let listdir folder = errorCatcher (fun () -> listdir_unsafe folder)

  let makedirs_unsafe path = Utils.makedirs systemUnix path 0o777
  let makedirs path = errorCatcher (fun () -> makedirs_unsafe path)

  let mkdir_unsafe folder = Unix.mkdir folder 0o755
  let mkdir folder = errorCatcher (fun () -> mkdir_unsafe folder)

  let rmdir_unsafe = Unix.rmdir
  let rmdir folder = errorCatcher (fun () -> rmdir_unsafe folder)

  let rename_unsafe = Unix.rename
  let rename fo fn = errorCatcher (fun () -> rename_unsafe fo fn)

  let unlink_unsafe = Unix.unlink
  let unlink f = errorCatcher (fun () -> unlink_unsafe f)

  let readlink_unsafe = Unix.readlink
  let readlink f = errorCatcher (fun () -> readlink_unsafe f)

  let stat_unsafe = Unix.stat
  let stat f = errorCatcher (fun () -> stat_unsafe f)

  (* Helper for any Unix functions that return 'process_status' *)
  let _mapProcessStatusToResultType status result = 
    match status with 
    | Unix.WEXITED exitCode -> (
      match exitCode with
      | 0 -> Result result
      | _ -> 
        Error (Printf.sprintf "exit code was: %d" exitCode))
    | Unix.WSIGNALED signalCode ->
        Error (Printf.sprintf "death by signal: %d" signalCode)
    | Unix.WSTOPPED signalCode ->
        Error (Printf.sprintf "death by signal: %d" signalCode)

  let system_unsafe cmd = Unix.system cmd |> ignore
  let system cmd   = 
    match errorCatcher (fun () -> Unix.system cmd) with
    | Error err -> Error err
    | Result procStatus -> _mapProcessStatusToResultType procStatus 0

  let popenAndReadLines_unsafe command =
    let process_output_to_list2 = fun command -> 
      let chan = Unix.open_process_in command in
      let res = ref ([] : string list) in
      let rec process_otl_aux () =  
        let e = input_line chan in
        res := e::!res;
        process_otl_aux() in
      try
        process_otl_aux ()
      with End_of_file ->
        let stat = Unix.close_process_in chan in
        (List.rev !res,stat) in
    let (l,procStatus) = process_output_to_list2 command in
      _mapProcessStatusToResultType procStatus l |> function
      | Result res -> res
      | Error msg -> raise_safe "popenAndReadLines failed with: %s" msg

  let popenAndReadLines command =
    errorCatcher (fun () -> popenAndReadLines_unsafe command)

  let crash_handler crash_dir entries =
    makedirs_unsafe crash_dir ;
    let leaf =
      let open Unix in
      let t = gmtime (time ()) in
      Printf.sprintf "%04d-%02d-%02dT%02d_%02dZ"
        (1900 + t.tm_year)
        (t.tm_mon + 1)
        t.tm_mday
        t.tm_hour
        t.tm_min in
    let log_file = crash_dir +/ leaf in
    log_file |> systemUnix#with_open_out [Open_append; Open_creat] ~mode:0o600 (fun ch ->
      entries |> List.rev |> List.iter (fun (time, ex, level, msg) ->
        let time = Utils.format_time (Unix.gmtime time) in
        Printf.fprintf ch "%s: %s: %s\n" time (Logging.string_of_level level) msg;
        ex |> if_some (fun ex -> Printexc.to_string ex |> Printf.fprintf ch "%s\n");
      )
    );
    Printf.eprintf "Saving execution log to '%s'\n" log_file

  let () = 
    Logging.set_crash_logs_handler (crash_handler "logs") ;
    Logging.log_info "Starting execution" ;
    Pervasives.at_exit @@ (fun () -> Logging.dump_crash_log ())

end;;
