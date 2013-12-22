open Eliom_content.Html5.D
open Eliom_parameter
open CalendarLib

let import_confirm_service =
  Eliom_service.post_coservice
    ~fallback:Services.main_service
    ~post_params:(string "author" ** string "title" **
                  string "date" ** string "content" **
                  string "tags")
    ()

let import_form () =
  post_form ~service:import_confirm_service
    (fun (author, (title, (date, (content, tags)))) ->
       [fieldset
         [label ~a:[a_for author] [pcdata "author: "];
          string_input ~input_type:`Text ~name:author ();
          br ();
          label ~a:[a_for title] [pcdata "title: "];
          string_input ~input_type:`Text ~name:title ();
          br ();
          label ~a:[a_for date] [pcdata "date (YYYY-MM-DD): "];
          string_input ~input_type:`Text ~name:date ();
          br ();
          label ~a:[a_for content] [pcdata "content: "];
          textarea ~name:content ();
          br ();
          label ~a:[a_for tags] [pcdata "tags (comma separated): "];
          string_input ~input_type:`Text ~name:tags ();
          br ();
          string_input ~input_type:`Submit ~value:"add" ()
        ]]) ()

let parse_date s =
  try
    Scanf.sscanf s "%04d-%02d-%02d"
      (fun year month day ->
         Int64.of_float (Date.to_unixfloat (Date.make year month day)))
  with
    Scanf.Scan_failure _ -> failwith ("Malformed date: " ^ s)
 
let import_confirm () (author, (title, (date, (content, tags)))) =
  lwt admin = Users.is_admin () in
  Lwt.return (
    try
      let user = (if Data.user_exists author then
                    { Data.name = author;
                      Data.hash = None }
                  else
                    failwith ("user '" ^ author ^ "' doesn't exist")) in
      if admin then 
        let  tip = {
          Data.id = 0;
          Data.author = user;
          Data.title = Data.validate_title title;
          Data.content = Data.validate_content content;
          Data.tags = Data.split_tags tags;
          Data.timestamp = parse_date date;
        } in
        let id = Data.add_tip tip user in
        p [pcdata "Tip correctly imported: ";
           a ~service:Services.show_tip_service [pcdata "view"] id]
      else
        p [pcdata "Only administrators can import tips."]
    with
    Failure reason -> p [pcdata "Error when adding the tip: ";
                         pcdata reason])

let import_body () () =
  lwt admin = Users.is_admin () in
  Lwt.return (if admin then
                import_form ()
              else
                p [pcdata "Only administrators can import tips."])
