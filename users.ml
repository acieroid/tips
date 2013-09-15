open Eliom_content.Html5.D
open Eliom_parameter

(* TODO: use a cookie for the username? *)
let username =
  Eliom_reference.eref ~scope:Eliom_common.default_session_scope
    (None : string option)
let is_admin =
  Eliom_reference.eref ~scope:Eliom_common.default_session_scope
    false

let disconnect_box () =
  post_form Services.logout_service
    (fun _ -> [fieldset
                 [string_input
                    ~input_type:`Submit
                    ~value:"(logout)" ()]]) ()

let connect_box () =
  lwt user = Eliom_reference.get username in
  lwt admin = Eliom_reference.get is_admin in
  Lwt.return
    (match user with
    | Some name -> div [p [pcdata ("connected as" ^ (if admin then "@" else ""))];
                        disconnect_box ()]
    | None -> p [a ~service:Services.login_service [pcdata "login"] ();
                 pcdata " or ";
                 a ~service:Services.register_service [pcdata "register"] ()])

