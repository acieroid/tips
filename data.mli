val create_schema : unit -> unit

type user = {
    name : string;
    hash : Sha256.t option
  }

val add_user : user -> unit
val auth_user : user -> bool

type tag = string

type tip = {
    id : int;
    author : user;
    title : string;
    content : string;
    timestamp : int;
    tags : tag list;
  }

val add_tip : tip -> user -> int
val get_all_tips : unit -> tip list
val get_n_most_recent_tips : int -> tip list
val get_random_tip : unit -> tip option

val get_all_tags : unit -> tag list
