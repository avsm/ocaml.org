(* Generate the dune files for the site output in ocaml.org
   by iterating through the `site/` directory and generating
   appropriate dune files for each subdirectory. *)

open Bos
open Rresult

let src_dir = Fpath.v "site"
let dst_dir = Fpath.v "ocaml.org"

let dune_file r = Printf.sprintf
{|(include dune.inc)
(rule (with-stdout-to dune.inc.gen (run %%{bin:ocamlorg-gen-dune-files} %s)))
(rule (alias runtest) (action (diff dune.inc dune.inc.gen)))
|} (Fpath.to_string r)

let mk_dir p =
  let rel = Fpath.relativize ~root:src_dir p |> Option.get in
  let dst = Fpath.(dst_dir // rel) in
  Format.eprintf "x %a\n%!" Fpath.pp dst;
  begin
    OS.Dir.create ~path:true dst >>= fun _ ->
    OS.File.write Fpath.(dst / "dune") (dune_file rel) >>= fun () ->
    OS.File.write Fpath.(dst / "dune.inc") ""
  end |> function
  | Ok () -> ()
  | Error (`Msg msg) -> failwith msg

let rec iter_site p =
  OS.Dir.contents ~dotfiles:false p |> R.get_ok |>
  List.iter (fun f ->
    match Fpath.basename f with
    | "." | ".." -> ()
    | _ when Sys.is_directory (Fpath.to_string f) ->
       mk_dir f;
       iter_site f
    | _ -> ()
  )

let () = iter_site src_dir
