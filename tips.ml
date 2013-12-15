open Eliom_content.Html5.D
open Eliom_parameter

(* TODO:
  - admin
  - display errors in a box (login error, ...)
  - tags page
  - delete/edit links
  - css
*)

let menu () =
  lwt connect = Users.connect_box () in
  Lwt.return (div ([
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
  ] @ connect))

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
  Lwt.return (Tip.display_tips (Data.get_n_most_recent_tips 5))

let show_tip_body id _ =
  match Data.get_tip id with
  | Some tip -> Lwt.return (Tip.display_tip tip)
  | None -> Lwt.return (p [pcdata "No such tip"])

let all_body _ _ =
  Lwt.return (div (List.map Tip.display_tip_short (Data.get_all_tips ())))

let tags_body _ _ =
  Lwt.return (Tip.display_tags (Data.get_all_tags ()))

let show_tag_body tag _ =
  Lwt.return (div (List.map Tip.display_tip_short (Data.get_tips_with_tag tag)))

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
    (page show_tag_body);
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
  (* Tip management *)
  Eliom_registration.Html5.register ~service:Services.add_service
    (page Add.add_body);
  Eliom_registration.Html5.register ~service:Add.add_confirm_service
    (page Add.add_confirm);
  Eliom_registration.Html5.register ~service:Services.edit_service
    (page Add.edit_body);
  Eliom_registration.Html5.register ~service:Services.delete_service
    (page Add.delete_body);
