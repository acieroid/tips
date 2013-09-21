open Eliom_content.Html5.D
open Eliom_parameter

let add_confirm_service =
  Eliom_service.post_coservice
    ~fallback:Services.main_service
    ~post_params:(string "title" ** string "content" ** string "tags")
    ()

let tip_form tip submit_text =
  post_form ~service:add_confirm_service
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
          string_input ~input_type:`Submit ~value:submit_text ()
        ]])

let edit_form tip =
  tip_form tip "edit"

let add_form =
  tip_form Data.empty_tip "add"

let add_body =
  Lwt.return (add_form ())

let add_confirm () (title, (content, tags)) =
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
          let id = Data.add_tip tip u in
          p [pcdata "Tip correctly added: ";
             a ~service:Services.show_tip_service [pcdata "view"] id]
      | None ->
          p [pcdata "You should ";
             a ~service:Services.register_service [pcdata "register"] ();
             pcdata " to add a tip"])
    with
      e -> p [pcdata "Error when adding the tip"])


let add_body _ _ =
  Lwt.return (add_form ())
