open CalendarLib

let entry tip =
  let title = Atom_feed.plain tip.Data.title
  and id = Xhtml.M.uri_of_string
      (Eliom_uri.make_string_uri
         ~service:Services.show_tip_service tip.Data.id)
  and updated = Calendar.create
      (Date.from_unixfloat
         (Int64.to_float tip.Data.timestamp))
      (Time.midnight ())
  in
  Atom_feed.entry ~updated ~id ~title
    [Atom_feed.html5C [Md.to_html tip.Data.content]]

let body () =
  let updated = Calendar.now () (* TODO: most recent tip's date ? *)
  and id = Xhtml.M.uri_of_string (Eliom_uri.make_string_uri
                                    ~service:Services.atom_service ())
  and title = Atom_feed.plain "awesom's tips" in
  Atom_feed.feed ~id ~updated ~title
    (List.map entry (Data.get_n_most_recent_tips 5))
