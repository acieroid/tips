open Eliom_content.Html5.D
open Eliom_parameter

let login_confirm_service =
  Eliom_service.post_coservice
    ~fallback:Services.main_service
    ~post_params:(string "username" ** string "password")
    ()

let register_confirm_service =
  Eliom_service.post_service
    ~fallback:Services.main_service
    ~post_params:(string "username" ** string "password1" ** string "password2")
    ()

let user =
  Eliom_reference.eref
    ~scope:Eliom_common.default_session_scope
    (None : Data.user option)
let is_admin =
  Eliom_reference.eref
    ~scope:Eliom_common.default_session_scope
    false

let connect_box () =
  lwt user = Eliom_reference.get user in
  lwt admin = Eliom_reference.get is_admin in
  Lwt.return
    (match user with
    | Some u -> [pcdata ("connected as " ^
                         (if admin then "@" else "") ^
                         u.Data.name ^ " ");
                 a ~service:Services.logout_service [pcdata "(logout)"] ()]
    | None -> [a ~service:Services.login_service [pcdata "login"] ();
               pcdata " or ";
               a ~service:Services.register_service [pcdata "register"] ()])

let register_form =
  post_form ~service:register_confirm_service
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
          string_input ~input_type:`Submit ~value:"register" ()
        ]])

let register_body _ _ =
  Lwt.return (register_form ())

let register_confirm () (name, (password1, password2)) =
  let err =
    if (password1 = password2) then
      try
        let user = {Data.name=name; Data.hash=Some (Sha256.string password1)} in
        Data.add_user user;
        None
      with
      | e -> Some "Error when adding the user (another user with the same username probably already exists)"
    else
      Some "Passwords don't match"
  in
  Lwt.return (match err with
  | Some msg -> (p [pcdata ("Can't add user: " ^ msg)])
  | None -> (p [pcdata "User successfully created, you can now ";
                a ~service:Services.login_service [pcdata "log in"] ()]))

let login_form =
  post_form ~service:login_confirm_service
    (fun (username, password) ->
      [fieldset
         [label ~a:[a_for username] [pcdata "username: "];
          string_input ~input_type:`Text ~name:username ();
          br ();
          label ~a:[a_for password] [pcdata "password: "];
          string_input ~input_type:`Password ~name:password ();
          br ();
          string_input ~input_type:`Submit ~value:"login" ()
        ]])

let login_body _ _ =
  Lwt.return (login_form ())

let (>>=) = Lwt.bind
let login_confirm () (name, password) =
  let u = {Data.name=name; Data.hash=Some (Sha256.string password)} in
  if Data.auth_user u then
    Eliom_reference.set user (Some {u with Data.hash=None})
  else
    (* TODO: display error *)
    Lwt.return ()

let register_services () =
  Eliom_registration.Action.register ~service:login_confirm_service
    login_confirm;
  Eliom_registration.Action.register
    ~service:Services.logout_service
    (fun _ _ -> Eliom_state.discard ~scope:Eliom_common.default_session_scope ());
