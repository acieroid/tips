(require "utils.arc")
(= dir* "tips/")
(unless (bound 'maxid*) (= maxid* 0))
(unless (bound 'tips*) (= tips* (table)))
(= title* "awesom's tips")

(deftem tip
  id nil
  title nil
  author nil
  content nil
  tags nil)

(def tip (id) 
  (tips* (errsafe:int id)))

(def load-tips ()
  (each id-str (dir dir*)
    (let id (int id-str)
      (= maxid* (max maxid* id)
         (tips* id) (temload 'tip (string dir* id)))))
   tips*)

(def save-tip (tip)
  (save-table tip (string dir* tip!id)))

(def add-tip (req)
  (with (author (get-user req)
         title (arg req "title")
         content (markdown (arg req "content"))
         tags (tokens (arg req "tags") #\,))
    (let newtip (inst 'tip 
                  'id (++ maxid*) 
                  'title title 
                  'author author
                  'content content
                  'tags tags)
      (save-tip newtip)
      (= (tips* newtip!id) newtip))
    (show-all-tips author)))

(def delete-tip (tip)
  (rmfile (string dir* tip!id))
  (= (tips* tip!id) nil))

(def show-tip-title (tip user)
  (spanclass tip-title 
    (pr (link tip!title (string "tips?id=" tip!id)) " "))
  (br)
  (divclass tip-infos
    (pr "by " tip!author " ")
    (when (or (is tip!author user) (admin user))
      (w/bars 
        (link "edit" (string "edit?id=" tip!id))
        (link "delete" (string "del?id=" tip!id))))
    (br)))

(def show-tip (tip user)
  (divclass tip
    (show-tip-title tip user)
    (pr tip!content)
    (br)
    (pr "tags: ")
    (if (len> tip!tags 1)
        (reduce (fn (x y) (show-tag x) (pr ", ") (show-tag y)) tip!tags)
        (show-tag (car tip!tags))
        (br))))

(def show-tips (pred user)
  (maptable (fn (k v) (when (pred v) (show-tip v user))) tips*))

(def show-all-tips (user)
  (show-tips (fn (x) t) user))

(def map-tips (fun)
  (maptable (fn (k v) (fun v)) tips*))

(def show-tag (tag)
  (link tag (string "tags?t=" tag)))

(def status-bar (user)
  (tag (div class "statusbar")
    (w/bars
      (link "tips")
      (link "add")
      (if user
          (do
            (pr "connected as " 
                (if (admin user) "@" "") user
                " ")
            (w/link (do 
                      (logout-user user)
                      (page  nil
                             (prn "Bye " user)))
                    (pr " (logout)")))
          (link "login or register" "login-register")))))

(mac page (user . body)
  `(whitepage
     (tag head
       (prn "<link rel=\"stylesheet\" type=\"text/css\" href=\"tips.css\">")
       (tag title (pr "tips@awesom")))
     (tag h1 (pr title*))
     (status-bar ,user)
     (br)
     ,@body))

(defopl add req
  (page (get-user req)
    (aform add-tip
      (tab (row "title:" (input "title"))
           (row "content:" (textarea "content" 10 80))
           (row "tags:" (input "tags"))
           (row "" (submit))))))

(defop tips req
  (page (get-user req)
    (aif (tip (arg req "id"))
      (show-tip it (get-user req))
      (show-all-tips (get-user req)))))

(defop tip-list req
  (page (get-user req)
    (map-tips (fn (t) (show-tip-title t (get-user req))))))

(defopr || req (prn "tips"))

(defop tags req
  (page (get-user req)
    (aif (arg req "t")
      (show-tips (fn (t) (find it t!tags)) (get-user req))
      (prerr "No tag selected"))))

(defopl edit req
  (page (get-user req)
    (let user (get-user req)
      (aif (tip (arg req "id"))
        (if (or (admin user) (is it!author user))
          (vars-form user
                     `((string title ,it!title t t) 
                       (mdtext content ,it!content t t)
                       (string tags 
                               ,(if (len> it!tags 1)
                                  (reduce (fn (x y) (string x "," y)) it!tags)
                                  (car it!tags))
                                t t))
                     (fn (name val) 
                       (if (is name 'tags)
                         (= (it 'tags) (tokens val #\,)) 
                         (= (it name) val)))
                     (fn () (do 
                              (save-tip it)
                              (page (get-user req) (prinfo "Tip modified"))))))
        (prerr "You are not the author of this tip")
      (prerr "Bad id")))))

(defopl del req
  (page (get-user req)
    (let user (get-user req)
      (aif (tip (arg req "id"))
        (if (or (admin user) (is it!author user))
          (do 
            (if-confirm 
              (delete-tip it)
              (page user (prinfo "Tip deleted!")))
            (show-tip it user))
          (prerr "You are not the author of this tip"))
        (prerr "Bad id")))))

(defop login-register req
  (let greet (fn (user ip)
               (page user (prinfo "Welcome, " user)))
    (page 
      (get-user req)
      (login-form  "Login" 'login login-handler greet)
      (login-form  "Register" 'register create-handler greet))))

(defop tips.css req
  (pr "
.error { color: #FF0000 }
.info { }
.statusbar { }
.tip-title { font-size: 20px; margin-top: 10px }
.tip-infos { margin-left: 10px }
.tip { border: 1px dashed gray; padding: 5px }
a { color: #003399; text-decoration: none }
a:hover { color: blue; text-decoration: underline }
body { font-family: Verdana, Sans-serif }
"))

(def tsv ((o port 8080))
  (ensure-dir dir*)
  (load-tips)
  (thread (asv port)))
