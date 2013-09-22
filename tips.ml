open Eliom_content.Html5.D
open Eliom_parameter
open CalendarLib

let menu () =
  lwt connect = Users.connect_box () in
  Lwt.return (div [
    (* TODO: String.concat ? *)
    a ~service:Services.main_service [pcdata "home"] ();
    pcdata " | ";
    a ~service:Services.all_service [pcdata "all"] ();
    pcdata " | ";
    a ~service:Services.random_service [pcdata "random"] ();
    pcdata " | ";
    a ~service:Services.tags_service [pcdata "tags"] ();
    pcdata " | ";
    a ~service:Services.add_service [pcdata "add"] ();
    pcdata " | ";
    connect;
  ])

let footer =
  div ~a:[a_class ["footer"]]
    [a ~service:Services.rss_service [pcdata "rss"] ();
     pcdata " - ";
     Raw.a
       ~a:[a_href (Raw.uri_of_string "https://github.com/acieroid/tips")]
       [pcdata "source code"]
   ]

let page f a b =
  lwt menu = menu () in
  lwt content = f a b in
  Lwt.return
    (html (head (title (pcdata "awesom's tips")) [])
       (body [h1 [pcdata "awesom's tips"];
              menu;
              content;
              footer]))

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

let display_tip tip =
  div ~a:[a_class ["element"]] [
  a ~service:Services.show_tip_service [pcdata tip.Data.title] tip.Data.id;
  br ();
  div ~a:[a_class ["element-infos"]]
    [pcdata ("by " ^ tip.Data.author.Data.name ^ " on " ^
             (string_of_timestamp tip.Data.timestamp))];
  (* TODO: Md.to_html *)
  pcdata tip.Data.content;
  br ();
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

let display_tips tips =
  div ~a:[a_class ["elements"]]
    (List.map display_tip tips)

let home_body _ _ =
  Lwt.return (display_tips (Data.get_n_most_recent_tips 5))

let show_tip_body id _ =
  match Data.get_tip id with
  | Some tip -> Lwt.return (display_tip tip)
  | None -> Lwt.return (p [pcdata "No such tip"])

let all_body _ _ =
  Lwt.return (div (List.map display_tip_short (Data.get_all_tips ())))

let tags_body _ _ =
  Lwt.return (display_tags (Data.get_all_tags ()))

let todo_body _ _ =
  Lwt.return
    (p [pcdata "TODO"])

let random_page _ _ =
  Lwt.return (Eliom_service.preapply
                ~service:Services.show_tip_service
                (Data.get_random_tip_id ()))

let services = [
  (Services.main_service, home_body);
  (Services.all_service, all_body);
  (Services.tags_service, tags_body);
  (Services.rss_service, todo_body);
]

let _ =
  List.iter (fun (service, f) ->
    Eliom_registration.Html5.register ~service:service
      (page f)
  ) services;
  Eliom_registration.Html5.register ~service:Services.show_tip_service
    (page show_tip_body);
  Eliom_registration.Html5.register ~service:Services.show_tag_service
    (page todo_body);
  Eliom_registration.Redirection.register ~service:Services.random_service
    ~options:`TemporaryRedirect
    random_page ;
  (* Users *)
  Eliom_registration.Html5.register ~service:Services.register_service
    (page Users.register_body);
  Eliom_registration.Html5.register ~service:Services.login_service
    (page Users.login_body);
  Eliom_registration.Html5.register ~service:Users.register_confirm_service
    (page Users.register_confirm);
  Users.register_services ();
  (* Add *)
  Eliom_registration.Html5.register ~service:Services.add_service
    (page Add.add_body);
  Eliom_registration.Html5.register ~service:Add.add_confirm_service
    (page Add.add_confirm);
  Eliom_registration.Html5.register ~service:Services.edit_service
    (page Add.edit_body);
