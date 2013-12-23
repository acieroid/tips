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

(* Taken from Cumulus *)
let (get_user, set_user, unset_user) =
  let session_scope = Eliom_common.default_session_scope in
  let eref = Eliom_reference.eref
               ~scope:session_scope
               ~persistent:"tips_user_v1"
               None in
  ((fun () -> Eliom_reference.get eref),
   (fun user ->
      let cookie_scope =
        Eliom_common.cookie_scope_of_user_scope session_scope
      in
      Lwt.bind
        (Eliom_state.set_persistent_data_cookie_exp_date
           ~cookie_scope
           (Some (Int32.to_float Int32.max_int)))
        (fun () ->
           Eliom_reference.set eref (Some user))),
   (fun () -> Eliom_reference.unset eref))

let (is_admin, set_admin, unset_admin) =
  let do_query () = 
    lwt user = get_user () in
    Lwt.return (match user with
      | Some u -> Db.is_admin u
      | None -> false) in
  let session_scope = Eliom_common.default_session_scope in
  let eref = Eliom_reference.eref
               ~scope:session_scope
               None in
  ((fun () ->
    lwt v = Eliom_reference.get eref in
    match v with
      | None ->
        lwt admin = do_query () in
        lwt _ = Eliom_reference.set eref (Some admin) in
        Lwt.return admin
      | Some admin -> Lwt.return admin),
   (fun admin -> Eliom_reference.set eref (Some admin)),
   (fun () -> Eliom_reference.unset eref))

let connect_box () =
  lwt user = get_user () in
  lwt admin = is_admin () in
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
        let user = {Data.name=name; Data.hash=Some (Bcrypt.hash password1)} in
        Db.add_user user;
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

let login_confirm () (name, password) =
  let u = {Data.name=name; Data.hash=None} in
  let auth, admin = Db.auth_user u password in
  if auth then begin
    Lwt.bind (set_user {u with Data.hash=None})
      (fun _ -> set_admin admin)
  end else
    (* TODO: display error *)
    Lwt.return ()

let register_services () =
  Eliom_registration.Action.register ~service:login_confirm_service
    login_confirm;
  Eliom_registration.Action.register
    ~service:Services.logout_service
    (fun _ _ -> Eliom_state.discard ~scope:Eliom_common.default_session_scope ());
