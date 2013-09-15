open Eliom_parameter
open Eliom_content.Html5.D

(* TODO:
  - Tips.display (tips list)
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

let home_body _ _ =
  Lwt.return (p [pcdata "TODO: display tips"])
  (* Tips.display (Database.get_n_most_recent_tips 5) *)

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
  (* Users *)
  Eliom_registration.Html5.register ~service:Services.register_service
    (page Users.register_body);
  Eliom_registration.Html5.register ~service:Services.login_service
    (page Users.login_body);
  Eliom_registration.Html5.register ~service:Users.register_confirm_service
    (page Users.register_confirm);
  Users.register_services ()
