(* Generate the dune files for the site output in ocaml.org
   by iterating through the `site/` directory and generating
   appropriate dune files depending on the extension.

   This script will be promoted into the ocaml.org/dune files.
*)

open Bos
open Rresult

let dune_rules = Hashtbl.create 23
let add_rule p rule =
  let p = Fpath.(parent p / "dune.inc") in
  match Hashtbl.find dune_rules p with
  | rules -> Hashtbl.replace dune_rules p (rule :: rules)
  | exception Not_found -> Hashtbl.add dune_rules p [rule]

let src_dir = Fpath.v "site"
let dst_dir = Fpath.v "ocaml.org"

let target p ext =
  match Fpath.relativize ~root:src_dir p with
  | None -> failwith "target: internal error"
  | Some r -> Fpath.(dst_dir // (set_ext ext r))

let process_md p =
  (* TODO check for TOC *)
  let dst = target p ".html" in
  Format.printf "md %a\n%!" Fpath.pp p;
  let rule = Format.sprintf
{| (rule (target %s) (deps ../) (action (copy %%{deps} %%{target}))) |} (Fpath.basename dst) in
  add_rule p rule
   

let process_file p () =
  (* Format.printf "processing %a\n%!" Fpath.pp p; *)
  match Fpath.get_ext p with
  | ".md" -> process_md p
  | _ -> ()
 

let iter_site () =
  let root = Fpath.v "site" in
  OS.Path.fold ~elements:`Files process_file () [root]

let () =
  iter_site () |> R.get_ok;
  Hashtbl.iter (fun p rules ->
    let r = List.rev rules |> String.concat "\n" in
    Format.printf "%a:\n%s\n\n%!" Fpath.pp p r
  ) dune_rules
