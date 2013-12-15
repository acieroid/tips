open Eliom_content.Html5.D
open CalendarLib

let string_of_timestamp t =
  let date = Date.from_unixfloat (Int64.to_float t) in
  Printer.Date.to_string date

let display_tags tags =
  let tag_link tag =
    a ~service:Services.show_tag_service [pcdata tag] tag in
  p ~a:[a_class ["tags"]]
    (match tags with
    | [] -> []
    | _ ->
        List.tl (List.fold_right (fun tag l ->
          [pcdata ", "; tag_link tag] @ l)
                   tags []))

let display_tip user tip =
  div ~a:[a_class ["element"]] [
  a ~service:Services.show_tip_service [pcdata tip.Data.title] tip.Data.id;
  br ();
  div ~a:[a_class ["element-infos"]]
    ((pcdata ("by " ^ tip.Data.author.Data.name ^ " on " ^
             (string_of_timestamp tip.Data.timestamp)) ::
        match user with
        | Some u ->
          [] (* TODO *)
        | _ -> []));
  Md.to_html tip.Data.content;
  display_tags tip.Data.tags;
]

let display_tip_short tip =
  div [
  a ~service:Services.show_tip_service [pcdata tip.Data.title] tip.Data.id;
  br ();
  div ~a:[a_class ["element-infos"]]
    [pcdata ("by " ^ tip.Data.author.Data.name ^ " on " ^
             (string_of_timestamp  tip.Data.timestamp))];
]

let display_tips user tips =
  div ~a:[a_class ["elements"]]
    (List.map (display_tip user) tips)
