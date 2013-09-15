open Eliom_content.Html5.D
open Eliom_parameter

(* TODO:
  - login service
  - register service
  - use a cookie for the username? *)
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
    | None -> div [p [a ~service:Services.login_service [pcdata "login"] ();
                      pcdata " or ";
                      a ~service:Services.register_service [pcdata "register"] ()]])

let register_form () =
  post_form ~service:Services.register_confirm_service
    (fun (username, (password1, password2)) ->
      [fieldset
         [label ~a:[a_for username] [pcdata "username: "];
          string_input ~input_type:`Text ~name:username ();
          br ();
          label ~a:[a_for password1] [pcdata "password: "];
          string_input ~input_type:`Password ~name:password1 ();
          br ();
          label ~a:[a_for password2] [pcdata "password (again): "];
          string_input ~input_type:`Password ~name:password2 ();
          br ();
          string_input ~input_type:`Submit ~value:"Register" ()
        ]])

let register_body _ _ =
  Lwt.return (register_form () ())

let register_confirm () (name, (password1, password2)) =
  let err =
    if (password1 = password2) then
      try
        let user = {Data.name=name; Data.hash=Some (Sha256.string password1)} in
        Data.add_user user;
        None
      with
        (* TODO: more precise errors *)
      | e -> Some "Error when adding the user (another user with the same username probably already exists)"
    else
      Some "Passwords don't match"
  in
  Lwt.return (match err with
  | Some msg -> (p [pcdata ("Can't add user: " ^ msg)])
  | None -> (p [pcdata "User successfully created, you can now ";
                a ~service:Services.login_service [pcdata "log in"] ()]))



