open Eliom_parameter
open Eliom_content.Html5.D
(*
module Html = Xhtml_f.Make(Eliom_content.Xml)
(* TODO: how to have this compatible with Eliom_content.Html5.D ? *)
module M = MarkdownHTML.Make_xhtml(Html)

(* Mostly taken from Cumulus' feed.ml *)
let to_html str =
  let render_pre ~kind s = pre [pcdata s] in
  let render_link {Markdown.href_target; href_desc} =
    a ~a:[a_href (uri_of_string (fun () -> href_target))] [pcdata href_desc]
  in
  let render_img {Markdown.img_src; img_alt} =
    img ~src:(uri_of_string (fun () -> img_src)) ~alt:img_alt ()
  in
  p (totl (toeltl
             (M.to_html ~render_pre ~render_link ~render_img
                (Markdown.parse_text str))))
*)
