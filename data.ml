let database_name = "tips.sqlite"

(* val with_db : (Sqlite3.db -> 'a) -> 'a *)
let with_db f =
  let db = Sqlite3.db_open database_name in
  try
    let res = f db in
    begin match Sqlite3.db_close db with
    | true -> res
    | false -> failwith ("Database not closed (busy): " ^ Sqlite3.errmsg db)
    end
  with
    e -> raise e

let tables = [
  "create table users (id integer primary key not null,
                       name varchar(256) unique not null,
                       password varchar(64) not null)";
  "create table tips (id integer primary key not null,
                      user_id integer not null,
                      title varchar(256) not null,
                      content text not null,
                      foreign key(user_id) references user(id))";
  "create table tags (id integer primary key not null,
                      tag varchar(256) not null)";
  "create table tips_tags (tip_id integer not null,
                           tag_id integer not null,
                           foreign key(tip_id) references tips(id),
                           foreign key(tag_id) references tags(id))"
]

(* val create_schema : unit -> unit *)
let create_schema () =
  with_db (fun db ->
    List.iter (fun query ->
      match Sqlite3.exec db query with
      | Sqlite3.Rc.OK -> ()
      | err ->  failwith ("Error when creating a table (" ^ query ^
                          "): " ^ Sqlite3.errmsg db))
      tables)

(* val execute_query : Sqlite3.db -> string -> Sqlite3.Data.t list -> (Sqlite3.stmt -> 'a) -> 'a list *)
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
        | Sqlite3.Rc.OK -> acc
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
    hash : Sha256.t option
  }

(* val extract_hash : user -> string *)
let extract_hash user =
  match user.hash with
  | Some h -> Sha256.to_hex h
  | None -> failwith "Password not specified"

(* val add_user : user -> unit *)
let add_user user =
  let _ = with_db (fun db ->
    execute_query db "insert into users(name, password) values (?, ?)"
      [Sqlite3.Data.TEXT user.name;
       Sqlite3.Data.TEXT (extract_hash user)]
      (fun _ -> ())) in
  ()

(* val auth_user : user -> bool *)
let auth_user user =
  with_db (fun db ->
    let res = execute_query db
        "select id from users where name = ? and password = ?"
        [Sqlite3.Data.TEXT user.name;
         Sqlite3.Data.TEXT (extract_hash user)]
        (fun s -> match Sqlite3.column s 0 with
        | Sqlite3.Data.INT n -> n
        | _ -> failwith "Invalid ID type")
    in
    match res with
    | [id] -> true
    | _ -> false)

type tag = string

type tip = {
    id : int;
    title : string;
    content : string;
    tags : tag list
  }

(* val add_tip : tip -> int *)
let add_tip tip user =
  with_db (fun db ->
    let _ = execute_query db
        "insert into tips(user_id, title, content) select id, ?, ? from users where name = ?"
        [Sqlite3.Data.TEXT tip.title;
         Sqlite3.Data.TEXT tip.content;
         Sqlite3.Data.TEXT user.name]
        (fun _ -> ()); in
    let tip_id = Sqlite3.last_insert_rowid db in
    List.iter (fun tag ->
      let _ = execute_query db
          "insert or replace into tags(tag) values (?)"
          [Sqlite3.Data.TEXT tag]
          (fun _ -> ()); in
      let tag_id = Sqlite3.last_insert_rowid db in
      let _ = execute_query db
          "insert into tips_tags(tip_id, tag_id) values (?, ?)"
          [Sqlite3.Data.INT tip_id;
           Sqlite3.Data.INT tag_id]
          (fun _ -> ()) in
      ())
      tip.tags;
    Int64.to_int tip_id)

(* val get_tips : string -> tip list *)
let get_tips filter =
  with_db (fun db ->
    execute_query db
      ("select id, title, content from tips " ^ filter) []
      (fun s ->
        match (Sqlite3.column s 0,
               Sqlite3.column s 1,
               Sqlite3.column s 2) with
        | Sqlite3.Data.INT id,
          Sqlite3.Data.TEXT title,
          Sqlite3.Data.TEXT content -> {id = Int64.to_int id;
                                        title = title;
                                        (* TODO: tags *)
                                        content = content; tags = []}
        | _ -> failwith "Invalid query result"))

(* val get_all_tips : unit -> tip list *)
let get_all_tips () =
  get_tips ""

(* val get_n_most_recent_tips : int -> tip *)
let get_n_most_recent_tips n =
  get_tips (Printf.sprintf "order by id desc limit %d" n)

(* val get_random_tip : unit -> tip option *)
let get_random_tip () =
  match get_tips "order by random() limit 1" with
  | [] -> None
  | h::_ -> Some h

(* val get_all_tags : unit -> tag list *)
let get_all_tags () =
  with_db (fun db ->
    execute_query db
      "select tag from tags" []
      (fun s ->
        match Sqlite3.column s 0 with
        | Sqlite3.Data.TEXT tag -> tag
        | _ -> failwith "Invalid query result"))
