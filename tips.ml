open Eliom_content.Html5.D
open Eliom_parameter

(* TODO:
  - display errors in a box (login error, ...)
  - persistent login
  - improve css
*)

let menu () =
  lwt connect = Users.connect_box () in
  Lwt.return (div ~a:[a_class ["header"]] ([
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
    [a ~service:Services.atom_service [pcdata "atom"] ();
     pcdata " - ";
     Raw.a
       ~a:[a_href (Raw.uri_of_string "https://github.com/acieroid/tips")]
       [pcdata "source code"]
   ]

let page f a b =
  let css = make_uri ~service:(Eliom_service.static_dir ()) ["css"; "tips.css"] in
  lwt menu = menu () in
  lwt content = f a b in
  Lwt.return
    (html (head (title (pcdata "awesom's tips"))
             [css_link css ()])
       (body [h1 [pcdata "awesom's tips"];
              menu;
              content;
              footer]))

let home_body _ _ =
  lwt user = Eliom_reference.get Users.user in
  Lwt.return (Tip.display_tips user (Data.get_n_most_recent_tips 5))

let show_tip_body id _ =
  lwt user = Eliom_reference.get Users.user in
  match Data.get_tip id with
  | Some tip -> Lwt.return (Tip.display_tip user tip)
  | None -> Lwt.return (p [pcdata "No such tip"])

let all_body _ _ =
  Lwt.return (div (List.map Tip.display_tip_short (Data.get_all_tips ())))

let tags_body _ _ =
  Lwt.return (Tip.display_tags (Data.get_all_tags ()))

let show_tag_body tag _ =
  Lwt.return (div (List.map Tip.display_tip_short (Data.get_tips_with_tag tag)))

let atom_body _ _ =
  Lwt.return (Atom.body ())

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
    random_page;
  Eliom_atom.Reg.register ~service:Services.atom_service
    atom_body;
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
  Eliom_registration.Html5.register ~service:Add.edit_confirm_service
    (page Add.edit_confirm);
  Eliom_registration.Html5.register ~service:Services.delete_service
    (page Add.delete_body);
  (* To import old data *)
  Eliom_registration.Html5.register ~service:Services.import_tip_service
    (page Import.import_body);
  Eliom_registration.Html5.register ~service:Import.import_confirm_service
    (page Import.import_confirm);
