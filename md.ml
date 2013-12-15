open Eliom_parameter
open Eliom_content.Html5.D

module Html = Xhtml_f.Make(Eliom_content.Xml)
(* TODO: how to have this compatible with Eliom_content.Html5.D ? *)
module M = MarkdownHTML.Make_xhtml(Html)

(* Mostly taken from Cumulus' feed.ml *)
let to_html (str : string) : 'a elt  =
  let render_pre ~kind s = Html.pre [Html.pcdata s] in
  let render_link {Markdown.href_target; href_desc} =
    Html.a ~a:[Html.a_href (uri_of_string (fun () -> href_target))] [Html.pcdata href_desc]
  in
  let render_img {Markdown.img_src; img_alt} =
    Html.img ~src:(uri_of_string (fun () -> img_src)) ~alt:img_alt ()
  in
  p (totl (Html.toeltl
             (M.to_html ~render_pre ~render_link ~render_img
                (Markdown.parse_text str))))
