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

let validate_title title =
  if String.length title > 256 then
    failwith "Title length too long (should be less than 256 characters)"
  else
    title

let validate_content content =
  (* TODO: validate markdown: 
     call Markdown.parse_text and see if it returns an exception *)
  content

let split_tags tags =
  Str.split (Str.regexp " ?, ?") tags
