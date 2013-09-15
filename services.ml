open Eliom_parameter

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

let login_service =
  Eliom_service.service ~path:["login"] ~get_params:unit ()

let register_service =
  Eliom_service.service ~path:["register"] ~get_params:unit ()

(*
let login_confirm_service =
  Eliom_service.post_service
    ~fallback:main_service
    ~post_params:(string "username" ** string "password")
    ()
*)
let register_confirm_service =
  Eliom_service.post_service
    ~fallback:main_service
    ~post_params:(string "username" ** string "password1" ** string "password2")
    ()

let logout_service =
  Eliom_service.post_coservice' ~post_params:unit ()
