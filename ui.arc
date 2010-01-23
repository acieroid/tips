;;;; ui.arc - The user inteface (the pages)
(load "tips.arc")
(load "utils.arc")

(= title* "awesom's tips"
   url* "http://localhost:8080"
   desc* "Some useful tips about programming and computers")

(mac page (user . body)
  `(whitepage
     (tag head
       (prn "<link rel=\"stylesheet\" type=\"text/css\" href=\"tips.css\">")
       (tag title (pr title*)))
     (tag h1 (pr title*))
     (status-bar ,user)
     (br)
     ,@body))

;;; define a new page, bind "user" variable
(mac defpage (name req . body)
  `(defop ,name ,req
     (let user (get-user req)
       (page user
         ,@body))))

; TODO: use better handlers
(def login-register-form ()
  (let greet (fn (user ip)
               (page user (prinfo "Welcome, " user)))
    (login-form  "Login" 'login login-handler greet)
    (login-form  "Register" 'register create-handler greet)))

;;; define a page only for logged users
(mac defpagel (name req . body)
  `(defpage ,name ,req
     (if user 
       ,@body
       (login-register-form))))

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
          (link "login or register" "login")))))

(defpagel login req
  (prn "You're already logged in"))

(defpagel add req
  (aform [page user (add-tip _)]
    (tab (row "title:" (input "title"))
         (row "content:" (textarea "content" 10 80))
         (row "tags:" (input "tags"))
         (row "" (submit)))))

(defpage tips req
  (aif (tip (arg req "id"))
    (show-tip it user)
    (show-all-tips user)))

(defpage tip-list req
  (map-tips (fn (t) (show-tip-title t user))))

(defpage tags req
  (aif (arg req "t")
    (show-tips (fn (t) (find it t!tags)) user)
    (prerr "No tag selected")))

(defpage edit req
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
    (prerr "Bad id")))

(defpage del req
  (aif (tip (arg req "id"))
    (if (or (admin user) (is it!author user))
      (do 
        (if-confirm 
          (delete-tip it)
          (page user (prinfo "Tip deleted!")))
        (show-tip it user))
      (prerr "You are not the author of this tip"))
    (prerr "Bad id")))

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

(defop rss req
  (tag (rss version "2.0")
    (tag channel
      (tag title (pr title*))
      (tag link (pr url*))
      (tag description (pr desc*))
      (map-tips (fn (tip)
        (tag item
           (tag title (pr tip!title))
           (tag link (pr url* "/tips?id=" tip!id))
           (tag description (cdata (pr tip!content)))))))))

               
;;; The index
(defopr || req (prn "tips"))

(def tsv ((o port 8080))
  (ensure-dir dir*)
  (load-tips)
  (thread (asv port)))
