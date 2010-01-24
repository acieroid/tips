;;;; tips.arc - Manage and show tips and tags
(load "utils.arc")

;;; Parameters
(= dir* "tips/")
(unless (bound 'maxid*) (= maxid* 0))
(unless (bound 'tips*) (= tips* (table)))

(deftem tip
  id nil
  title nil
  author nil
  content nil
  tags nil)

;;; Return the tip that matches the id or nil
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
    (pr (link tip!title (string "tip?id=" tip!id)) " "))
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

;;; Map a function through the tips that satisfies pred
(def map-tips-if (pred fun)
  (maptable (fn (k v) (when (pred v) (fun v))) tips*))

;;; Map a function through all the tips
(def map-tips (fun)
  (map-tips-if (fn _ t) fun))

;;; Show the tips that satisfies pred
(def show-tips (pred user)
  (map-tips-if pred [show-tip _ user]))

(def show-all-tips (user)
  (map-tips [show-tip _ user]))

(def show-tag (tag)
  (link tag (string "tags?t=" (urlencode tag))))

