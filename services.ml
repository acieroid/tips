open Eliom_parameter

(* Menu items *)
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

let edit_service =
  Eliom_service.service ~path:["edit"] ~get_params:(suffix (int "id")) ()

(* Footer *)
let rss_service =
  Eliom_service.service ~path:["rss"] ~get_params:unit ()

(* User-related pages *)
let login_service =
  Eliom_service.service ~path:["login"] ~get_params:unit ()

let register_service =
  Eliom_service.service ~path:["register"] ~get_params:unit ()

let logout_service =
  Eliom_service.post_coservice' ~post_params:unit ()

(* Other pages *)
let show_tip_service =
  Eliom_service.service ~path:["tip"] ~get_params:(suffix (int "id")) ()

let show_tag_service =
  Eliom_service.service ~path:["tag"] ~get_params:(suffix (string "tag")) ()
