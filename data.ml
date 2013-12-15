let database_name = "tips.sqlite"

let with_db f =
  let db = Sqlite3.db_open database_name in
  let res = f db in
  match Sqlite3.db_close db with
  | true -> res
  | false -> failwith ("Database not closed (busy): " ^ Sqlite3.errmsg db)

let tables = [
  "create table users (id integer primary key not null,
                       name varchar(256) unique not null,
                       password varchar(64) not null)";
  "create table tips (id integer primary key not null,
                      user_id integer not null,
                      title varchar(256) not null,
                      content text not null,
                      timestamp integer not null,
                      foreign key(user_id) references user(id))";
  "create table tags (id integer primary key not null,
                      tag varchar(256) unique not null)";
  "create table tips_tags (tip_id integer not null,
                           tag_id integer not null,
                           foreign key(tip_id) references tips(id),
                           foreign key(tag_id) references tags(id))"
]


let create_schema () =
  with_db (fun db ->
    List.iter (fun query ->
      match Sqlite3.exec db query with
      | Sqlite3.Rc.OK -> ()
      | err ->  failwith ("Error when creating a table (" ^ query ^
                          "): " ^ Sqlite3.errmsg db))
      tables)

let execute_query db q args f =
  let query = Sqlite3.prepare db q in
  List.iteri (fun n arg ->
    match Sqlite3.bind query (succ n) arg with
    | Sqlite3.Rc.OK -> ()
    | err -> failwith
          ("Error when binding parameter to a query (" ^ q ^
           "): " ^ Sqlite3.errmsg db))
    args;
  let rec retrieve acc =
    match Sqlite3.step query with
    | Sqlite3.Rc.DONE ->
        begin match Sqlite3.finalize query with
        | Sqlite3.Rc.OK -> List.rev acc
        | err -> failwith
              ("Error when finalizing a query (" ^ q ^
               "): " ^ Sqlite3.errmsg db)
        end
    | Sqlite3.Rc.BUSY -> retrieve acc
    | Sqlite3.Rc.ROW -> retrieve ((f query)::acc)
    | err -> failwith
          ("Error when executing a query (" ^ q ^
           "): " ^ Sqlite3.errmsg db)
  in
  retrieve []

type user = {
    name : string;
    hash : Bcrypt.hash_t option
  }

let empty_user = {
  name = "";
  hash = None;
}

let extract_hash user =
  match user.hash with
  | Some h -> Bcrypt.string_of_hash h
  | None -> failwith "Password not specified"

let add_user user =
  let _ = with_db (fun db ->
    execute_query db "insert into users(name, password) values (?, ?)"
      [Sqlite3.Data.TEXT user.name;
       Sqlite3.Data.TEXT (extract_hash user)]
      (fun _ -> ())) in
  ()

let auth_user user password =
  with_db (fun db ->
    let res = execute_query db
        "select id, password from users where name = ?"
        [Sqlite3.Data.TEXT user.name]
        (fun s -> match Sqlite3.column s 0, Sqlite3.column s 1 with
        | Sqlite3.Data.INT n, Sqlite3.Data.TEXT hash ->
          if Bcrypt.verify password (Bcrypt.hash_of_string hash) then
            Some n
          else
            None
        | _ -> failwith "Invalid ID type")
    in
    match res with
    | [Some id] -> true
    | _ -> false)

type tag = string

type tip = {
    id : int;
    author : user;
    title : string;
    content : string;
    timestamp : int64;
    tags : tag list;
  }

let empty_tip = {
  id = 0;
  author = empty_user;
  title = "";
  content = "";
  timestamp = Int64.of_int 0;
  tags = [];
}

let find_or_insert_tag tag db =
  let r = execute_query db
      "select id from tags where tag = ?"
      [Sqlite3.Data.TEXT tag]
      (fun s ->
        match Sqlite3.column s 0 with
        | Sqlite3.Data.INT id -> id
        | _ -> failwith "Invalid query result") in
  match r with
  | id::_ ->
      (* tag already exists *)
      id
  | [] ->
      (* tag don't exists, add it *)
      let _ = execute_query db
          "insert into tags(tag) values (?)"
          [Sqlite3.Data.TEXT tag]
          (fun _ -> ()); in
      Sqlite3.last_insert_rowid db

let add_tip tip user =
  with_db (fun db ->
    let _ = execute_query db
        "insert into tips(user_id, title, content, timestamp) select id, ?, ?, ? from users where name = ?"
        [Sqlite3.Data.TEXT tip.title;
         Sqlite3.Data.TEXT tip.content;
         Sqlite3.Data.INT (Int64.of_float (Unix.time ()));
         Sqlite3.Data.TEXT user.name]
        (fun _ -> ()) in
    let tip_id = Sqlite3.last_insert_rowid db in
    List.iter (fun tag ->
      let tag_id = find_or_insert_tag tag db in
      let _ = execute_query db
          "insert into tips_tags(tip_id, tag_id) values (?, ?)"
          [Sqlite3.Data.INT tip_id;
           Sqlite3.Data.INT tag_id]
          (fun _ -> ()) in
      ())
      tip.tags;
    Int64.to_int tip_id)

let delete_tip id =
  with_db (fun db ->
    let _ = execute_query db
        "delete from tips where id = ?"
        [Sqlite3.Data.INT (Int64.of_int id)]
        (fun _ -> ()) in
    ())

let update_tip tip user =
  if user = tip.author then
    with_db (fun db ->
      let tip_id = Int64.of_int tip.id in
      let _ = execute_query db
          "update tips set title=?, content=? where id=?"
          [Sqlite3.Data.TEXT tip.title;
           Sqlite3.Data.TEXT tip.content;
           Sqlite3.Data.INT tip_id]
          (fun _ -> ())
      in
      let _ = execute_query db
          "delete from tips_tags where tip_id=?"
          [Sqlite3.Data.INT tip_id] in
      List.iter (fun tag ->
        let tag_id = find_or_insert_tag tag db in
        let _ = execute_query db
            "insert into tips_tags(tip_id, tag_id) values (?, ?)"
            [Sqlite3.Data.INT tip_id;
             Sqlite3.Data.INT tag_id]
            (fun _ -> ()) in
        ())
        tip.tags;
      tip.id)
  else
    failwith "User is not the author of the tip"

let get_tips filter =
  with_db (fun db ->
    let fill_tags tip =
      let tags = execute_query db
          ("select tags.tag from tags join tips_tags on tags.id = tips_tags.tag_id where tips_tags.tip_id = ?")
          [Sqlite3.Data.INT (Int64.of_int tip.id)]
          (fun s ->
            match (Sqlite3.column s 0) with
            | Sqlite3.Data.TEXT tag -> tag
            | _ -> failwith "Invalid query result") in
      {tip with tags = tags} in
    let tips =
      execute_query db
        ("select tips.id, tips.title, tips.content, tips.timestamp, users.name from tips join users on tips.user_id = users.id " ^
         filter) []
        (fun s ->
          match (Sqlite3.column s 0, Sqlite3.column s 1,
                 Sqlite3.column s 2, Sqlite3.column s 3,
                 Sqlite3.column s 4) with
          | Sqlite3.Data.INT id,
            Sqlite3.Data.TEXT title,
            Sqlite3.Data.TEXT content,
            Sqlite3.Data.INT timestamp,
            Sqlite3.Data.TEXT username ->
              {id = Int64.to_int id;
               author = {name=username; hash=None};
               title = title;
               content = content;
               timestamp = timestamp;
               tags = []}
          | _ -> failwith "Invalid query result") in
    List.map fill_tags tips)

let get_tip id =
  match get_tips (Printf.sprintf "where tips.id = %d" id) with
  | (h::_) -> Some h
  | [] -> None

let get_all_tips () =
  get_tips "order by tips.timestamp desc"

let get_n_most_recent_tips n =
  get_tips (Printf.sprintf "order by tips.timestamp desc limit %d" n)

let get_tips_with_tag tag =
  let valid = Str.string_match (Str.regexp "[a-z0-9A-Z]") tag 0 in
  if valid then
    get_tips (Printf.sprintf "where tips.id in (select tip_id from tips_tags where tag_id = (select id from tags where tag = \"%s\")) order by tips.timestamp desc" tag)
  else
    []

let get_random_tip () =
  match get_tips "order by random() limit 1" with
  | [] -> None
  | h::_ -> Some h

let get_random_tip_id () =
  match get_random_tip () with
  | Some t -> t.id
  | None -> failwith "No tip exists"

let get_all_tags () =
  with_db (fun db ->
    execute_query db
      "select tag from tags" []
      (fun s ->
        match Sqlite3.column s 0 with
        | Sqlite3.Data.TEXT tag -> tag
        | _ -> failwith "Invalid query result"))

let now () =
  Int64.of_float (Unix.time ())

let validate_title title =
  if String.length title > 256 then
    failwith "Title length too long (should be less than 256 characters)"
  else
    title

let validate_content content =
  (* TODO: validate markdown *)
  content

let split_tags tags =
  Str.split (Str.regexp " ?, ?") tags
