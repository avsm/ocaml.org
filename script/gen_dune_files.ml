(* Generate the dune files for the site output in ocaml.org
   by iterating through the `site/` directory and generating
   appropriate dune files depending on the extension.

   This script will be promoted into the ocaml.org/dune files,
   so it is run from within the _build/<context> directory.
*)

open Bos
open Rresult

let toc = "*Table of contents*"

let latest_ocaml_version = "4.11.1" (* TODO *)
let latest_ocaml_version_main = "4.11" (* TODO *)
(* TODO move this to a config file *)
let mpp_options =
  Printf.sprintf {|-so "((!" -sc "!))" -son "{{!" -scn "!}}" -soc "" -scc "" -sec "" -sos "{{<" -scs ">}}" -its -set "LATEST_OCAML_VERSION=%s" -set "LATEST_OCAML_VERSION_MAIN=%s" |} latest_ocaml_version latest_ocaml_version_main

let has_toc file =
  OS.File.read_lines file >>|
  List.exists ((=) toc)

let addsegs src =
  let s = Fpath.segs src |> List.map (fun _ -> "../") |> String.concat "" |> Fpath.v in
  Fpath.(s / "site" // src)

let makedep src fullsrc =
   Fpath.(v ".." // addsegs src / basename fullsrc)

let process_md src ~fullsrc =
  let srcdep = Fpath.to_string (makedep src fullsrc) in
  let _has_toc = OS.File.read_lines fullsrc >>| List.exists ((=) toc) |> R.get_ok in
  let target = Fpath.(set_ext ".html" fullsrc |> basename) in
  let action = Printf.sprintf
    "(run %%{bin:mpp} %s -set filename=%%{dep:%s.tmp} -set page=%%{target} %%{project_root}/template/main.mpp -o %%{target})" mpp_options target in
  Format.printf "(rule (target %s)\n  (deps %%{project_root}/template/main.mpp)\n  (action %s))\n%!" target action;
  Format.printf "(rule (target %s.tmp)\n (action (with-stdout-to %%{target} (with-stdin-from %s (run %%{bin:ocamlorg-md-pp})))))\n" target srcdep;
  Format.printf "\n"
 
let process_default src ~fullsrc =
  Format.printf "(copy_files %a)\n" Fpath.pp (makedep src fullsrc)

let process_file srcdir fullsrc =
  (* Format.printf "processing %a\n%!" Fpath.pp p; *)
  match Fpath.get_ext fullsrc with
  | ".md" -> process_md srcdir ~fullsrc
  | _ -> process_default srcdir ~fullsrc

let handle = function Ok v -> v | Error (`Msg m) -> failwith m

(* Sys.argv.(1) is the relative path from site/ *)
let () =
  let src = Fpath.v Sys.argv.(1) in
  let dir = Fpath.(v "../../.." // (addsegs src)) in
  let is_file r = OS.File.exists r |> R.get_ok in
  OS.Dir.contents dir |> handle |> List.filter is_file |> List.iter (process_file src)
