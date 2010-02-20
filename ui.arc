;;;; ui.arc - The user inteface (the pages)
(require "elements.arc")
(require "utils.arc")

(= title* "undefined title"
   url* "http://localhost:8080"
   desc* "undefined description"
   perpage* 10
   header-links* '("home" "all" "random" "tags" "add"))

(mac page (user . body)
  `(whitepage
     (tag head
       (prn "<link rel=\"stylesheet\" type=\"text/css\" href=\"css\">")
       (tag title (pr title*)))
     (tag h1 (pr title*))
     (header ,user)
     (br)
     ,@body
     (hr)
     (footer ,user)))

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

(def header (user)
  (tag (div class "header")
    (w/bars
      (map-w/bars header-links* link)
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

(def footer (user)
  (tag (div class "footer")
    (w/bars
      (link "rss"))))

(defpagel login req
  (prn "You're already logged in"))

(defpagel add req
  (show-element-form user t))

(defpage show req
  (aif (element (arg req "id"))
    (show-element user it)
    (prerr "Bad id")))

(defpage home req
  (loop (= id maxid*
           n 0)
        (and (> id 0)
             (< n perpage*))
    (-- id)
    (awhen (elements* id)
      (show-element user it)
      (++ n))))

;;; Not really useful for generic elements, should be redefined to show a 
;;; shorter form of the element (eg. the title)
(defpage all req
  (map-elements (fn (el) (show-element user el))))

(defpage random req
  (show-element user (elements* (random-id))))

(defpage tags req
  (show-tags tags*))

(defpage tag req
  (aif (arg req "t")
    (show-elements user (fn (el) (find it el!tags)))
    (prerr "No tag selected")))

(defpage edit req
  (aif (element (arg req "id"))
    (if (or (admin user) (is it!author user))
        (show-element-form user nil it)
        (prerr "You are not the author of this element"))
    (prerr "Bad id")))

(defpage del req
  (aif (element (arg req "id"))
    (if (or (admin user) (is it!author user))
      (do 
        (if-confirm 
          (delete-element it)
          (page user (prinfo "Element deleted!")))
        (show-element user it))
      (prerr "You are not the author of this element"))
    (prerr "Bad id")))


(= css* ".error { color: #FF0000 }
.info { }
.header { text-align: center }
.footer { text-align: center }
a { color: #003399; text-decoration: none }
a:hover { color: blue; text-decoration: underline }
hr { color: #AACCBB; size: 25 }
body { font-family: Verdana, Sans-serif }
")

(defop css req
  (pr css*))

(defop rss req
  (tag (rss version "2.0")
    (tag channel
      (tag title (pr title*))
      (tag link (pr url*))
      (tag description (pr desc*))
      (map-tips (fn (tip)
        (tag item
           (tag title (pr tip!title))
           (tag link (pr url* "/show?id=" tip!id))
           (tag description (cdata (pr tip!content)))))))))
               
;;; The index
(defopr || req (prn "home"))

(def start ((o port 8080))
  (ensure-dir dir*)
  (load-elements)
  (thread (asv port)))
