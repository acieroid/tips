(* packages needed: ocsigenserver, eliom.server
*)
open Eliom_parameter
open Eliom_content.Html5.D

(* TODO:
  - connect_box ()
  - Tips.display (tips list)
*)

let main_service =
  Eliom_service.service ~path:[""] ~get_params:unit ()

let all_service =
  Eliom_service.service ~path:["all"] ~get_params:unit ()

let random_service =
  Eliom_service.service ~path:["random"] ~get_params:unit ()

let tags_service =
  Eliom_service.service ~path:["tags"] ~get_params:unit ()

let add_service =
  Eliom_service.service ~path:["add"] ~get_params:unit ()

let rss_service =
  Eliom_service.service ~path:["rss"] ~get_params:unit ()

let menu () =
  lwt connect = Lwt.return (p [pcdata "TODO: connect box"]) in
  Lwt.return (div [
    (* TODO: String.concat ? *)
    a ~service:main_service [pcdata "home"] ();
    pcdata " | ";
    a ~service:all_service [pcdata "all"] ();
    pcdata " | ";
    a ~service:random_service [pcdata "random"] ();
    pcdata " | ";
    a ~service:tags_service [pcdata "tags"] ();
    pcdata " | ";
    a ~service:add_service [pcdata "add"] ();
    pcdata " | ";
    connect;
  ])

let footer =
  div ~a:[a_class ["footer"]]
    [a ~service:rss_service [pcdata "rss"] ();
     (* pcdata " - " *)
     (* TODO: link to source code *)]

let main_service_body _ _ =
  lwt menu = menu () in
  lwt tips = Lwt.return (p [pcdata "TODO: display tips"])
  (* Tips.display (Database.get_n_most_recent_tips 5) *) in
  Lwt.return
    (html (head (title (pcdata "awesom's tips")) [])
       (body [h1 [pcdata "awesom's tips"];
              menu;
              tips;
              footer]))

let empty_service_body _ _ =
  Lwt.return
    (html (head (title (pcdata "awesom's tips")) [])
       (body [h1 [pcdata "TODO"]]))

let services = [
  (main_service, main_service_body);
  (all_service, empty_service_body);
  (random_service, empty_service_body);
  (tags_service, empty_service_body);
  (add_service, empty_service_body);
  (rss_service, empty_service_body);
]

let _ =
  List.iter (fun (service, f) ->
    Eliom_registration.Html5.register
      ~service:service
      f
  ) services


