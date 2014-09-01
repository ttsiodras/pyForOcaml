(*
 * In your bash...
 *
 *     export OCAMLRUNPARAM=b
 *
 * ...before you run, if you want to see exception callstacks.
 *)

open Common   (* for raise_safe                       *)
open Logging  (* for log_debug, log_warning, log_info *)
open Py       (* for my Python universe               *)

let test_args args = 
  print_string "Testing cmdline arguments...\n\t" ;
  flush stdout ;
  print_endline @@ String.concat "\n\t" @@ Array.to_list args ;
  flush stdout

let test_popen () = 
  print_string "Testing popen...\n\t" ;
  flush stdout ;
  Os.popenAndReadLines "lsr"
  |> fallback ["(failed)"]
  |> String.concat "\n\t"
  |> print_endline

let test_getcwd () = 
  print_endline "Testing getcwd..." ;
  flush stdout ;
  Os.getcwd ()
  |> fallback "(failed)"
  |> Printf.printf "\t%s\n"

let test_exceptionCallStack () =
  print_endline "Tests concluded.\n\nChecking exception call stack (must raise!)...\n" ;
  if not (Os.Path.exists_unsafe "foo") then ( Os.mkdir_unsafe "foo" ) ;
  Os.chdir_unsafe "foo" ;
  Os.rmdir_unsafe "../foo" ;
  Os.getcwd_unsafe ()
  |> Printf.printf "\t%s\n"

let test_realpath () = 
  print_endline "Testing realpath..." ;
  flush stdout ;
  let () = match Os.Path.realpath "../foo" with 
  | Result s -> Printf.printf "\t%s\n" s
  | Error msg -> raise_safe "(failed): %s" msg in
  flush stdout

let test_system () = 
  print_endline "Testing system..." ;
  flush stdout ;
  Os.system "cd /bin && echo -e '\tPerfect...' " |> ignore ;
  match Os.system "cd /bina && echo Perfect... " with
  | Result _ -> ()
  | Error msg -> prerr_endline msg

let test_listdir () =
  print_string "Testing listdir...\n\t" ;
  print_endline @@ String.concat "\n\t" @@ Os.listdir_unsafe "." ;
  if not (Os.Path.exists_unsafe "foo") then ( Os.mkdir_unsafe "foo" ) ;
  Os.chdir_unsafe "foo" ;
  Os.rmdir_unsafe "../foo" ;
  print_string "Testing failed listdir...\n\t" ;
  Os.listdir "."
  |> fallback ["(failed)"]
  |> String.concat ","
  |> print_endline ;
  Os.chdir_unsafe ".."

let main args =
  test_args args ;
  test_popen () ;
  test_getcwd () ;
  test_realpath () ;
  test_system () ;
  test_listdir () ;
  Time.sleep 5
  (*; test_exceptionCallStack ()*)

let _ =
  Utils.handle_exceptions main Sys.argv
