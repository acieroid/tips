open Eliom_content.Html5.D
open Eliom_parameter

let add_confirm_service =
  Eliom_service.post_coservice
    ~fallback:Services.main_service
    ~post_params:(string "title" ** string "content" ** string "tags")
    ()

let edit_confirm_service =
  Eliom_service.post_coservice
    ~fallback:Services.main_service
    ~post_params:(string "title" ** string "content" ** string "tags")
    ()

let tip_form tip submit_type =
  post_form ~service:(match submit_type with
  | `Add -> add_confirm_service
  | `Edit -> edit_confirm_service)
    (fun (title, (content, tags)) ->
      [fieldset
         [label ~a:[a_for title] [pcdata "title: "];
          string_input ~input_type:`Text ~name:title () ~value:tip.Data.title;
          br ();
          label ~a:[a_for content] [pcdata "content: "];
          textarea ~name:content () ~value:tip.Data.content;
          br ();
          label ~a:[a_for tags] [pcdata "tags (comma separated): "];
          string_input ~input_type:`Text ~name:tags ()
            ~value:(String.concat "," tip.Data.tags);
          br ();
          string_input ~input_type:`Submit
            ~value:(match submit_type with
            | `Add -> "add"
            | `Edit -> "edit") ()
        ]])

let tip_form_confirm submit_type (title, (content, tags)) =
  lwt user = Eliom_reference.get Users.user in
  Lwt.return (
    try
      (match user with
      | Some u ->
          let tip = {
            Data.id = 0;
            Data.author = u;
            Data.title = Data.validate_title(title);
            Data.content = Data.validate_content(content);
            Data.tags = Data.split_tags(tags);
            Data.timestamp = Data.now ();
          } in
          let id, text = match submit_type with
          | `Add -> Data.add_tip tip u, "added"
          | `Edit -> Data.update_tip tip u, "updated" in
          p [pcdata ("Tip correctly " ^ text ^ ": ");
             a ~service:Services.show_tip_service [pcdata "view"] id]
      | None ->
          p [pcdata "You should ";
             a ~service:Services.register_service [pcdata "register"] ();
             pcdata " to add or edit a tip"])
    with
       Failure reason -> p [pcdata "Error when adding/updating the tip: ";
                            pcdata reason])

let edit_form tip () =
  lwt user = Eliom_reference.get Users.user in
  Lwt.return (
    match user with
    | Some u when u.Data.name = tip.Data.author.Data.name ->
        tip_form tip `Edit ()
    | Some _ ->
        p [pcdata "You are not the author of this tip, you can't edit it."]
    | None ->
        p [pcdata "Please ";
           a ~service:Services.register_service [pcdata "register"] ();
           pcdata "."])

let add_form () =
  lwt user = Eliom_reference.get Users.user in
  Lwt.return (
    match user with
    | Some u -> tip_form Data.empty_tip `Add ()
    | None ->
        p [pcdata "Please ";
           a ~service:Services.register_service [pcdata "register"] ();
           pcdata "."])

let add_confirm () values =
  tip_form_confirm `Add values

let edit_confirm () values =
  tip_form_confirm `Edit values

let add_body _ _ =
  add_form ()

let edit_body id _ =
  (match Data.get_tip id with
  | Some tip -> edit_form tip ()
  | None -> Lwt.return (div [p [pcdata "Tip doesn't exists"]]))
