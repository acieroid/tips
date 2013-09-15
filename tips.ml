open Eliom_content.Html5.D
open Eliom_parameter

(* TODO:
   - create database schema if db doesn't exist yet
*)

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

let string_of_timestamp t = "TODO"

let display tips =
  let display_tip tip =
    div ~a:[a_class ["element"]] [
    a ~service:Services.show_tip_service [pcdata tip.Data.title] tip.Data.id;
    br ();
    div ~a:[a_class ["element-infos"]]
      [pcdata ("by " ^ tip.Data.author.Data.name ^ " on " ^
               (string_of_timestamp  tip.Data.timestamp))];
    (* TODO: Md.to_html *)
    pcdata tip.Data.content;
    br ();
    p ~a:[a_class ["tags"]]
      (List.map (fun tag ->
        a ~service:Services.show_tag_service [pcdata tag] tag) tip.Data.tags);
  ]
  in
  div ~a:[a_class ["elements"]]
    (List.map display_tip tips)


let home_body _ _ =
  Lwt.return (display (Data.get_n_most_recent_tips 5))

let todo_body _ _ =
  Lwt.return
    (p [pcdata "TODO"])

let services = [
  (Services.main_service, home_body);
  (Services.all_service, todo_body);
  (Services.random_service, todo_body);
  (Services.tags_service, todo_body);
  (Services.add_service, todo_body);
  (Services.rss_service, todo_body);
]

let _ =
  List.iter (fun (service, f) ->
    Eliom_registration.Html5.register
      ~service:service
      (page f)
  ) services;
  Eliom_registration.Html5.register
    ~service:Services.show_tip_service
    (page todo_body);
  Eliom_registration.Html5.register
    ~service:Services.show_tag_service
    (page todo_body);
  (* Users *)
  Eliom_registration.Html5.register ~service:Services.register_service
    (page Users.register_body);
  Eliom_registration.Html5.register ~service:Services.login_service
    (page Users.login_body);
  Eliom_registration.Html5.register ~service:Users.register_confirm_service
    (page Users.register_confirm);
  Users.register_services ()
