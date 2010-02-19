;;;; elements.arc - Manage elements and all stuff related
(require "utils.arc")

;;; Parameters
(= dir* "elements/")
(defvar maxid* 0)
(defvar elements* (table))
(defvar ids* nil)
(defvar tags* nil)

;;; The template
(deftem element
  id nil
  author nil
  tags nil
  date nil
  datas nil)

;;; Return the element with this id, or else nil
(def element (id)
  (elements* (errsafe:int id)))

;;; Add the tags that are in TAGS but not in TAGS* to TAGS*
(def add-tags (tags)
  (= tags* (union is tags tags*)))

;;; Load all the elements from DIR*
(def load-elements ()
  (each id-str (dir dir*)
    (with (id (int id-str)
           element (temload 'element (string dir* id)))
      (add-tags element!tas)
      (= maxid* (max maxid* id)
         (element* id) element
         ids* (cons element!id ids*))))
  elements*)

;;; Save an element to the disk
(def save-element (el)
  (save-table el (string dir* el!id)))

;;; Add an element to ELEMENTS* and save it to the hard-drive
(def add-element (req)
  (with (author (get-user req)
         tags (tokens (arg req "tags") #\,)
         datas nil) ; TODO
    (let new-el (inst 'element
                 'id (++ maxid*)
                 'author author
                 'tags tags
                 'date (date)
                 'datas datas)
      (save-element new-el)
      (= (elements* new-el!id) new-el))))

;;; Delete a tip from the database and from the disk
(def delete-element (el)
  (rmfile (string dir* el!id))
  (= (elements* el!id) nil))

;;; Return an random existing id
(def random-id ()
  (random-elt ids*))

;;; Show a tag
(def show-tag (tag)
  (link tag (string "tag?t=" (urlencode tag))))

;;; Show a list of tags
(def show-tags (tags (o separator ", "))
  (if (cdr tags)
      (reduce (fn (x y) (show-tag x) (pr separator) (show-tag y)) tags)
      (show-tag (car tags))))

;;; Mapping functions over elements
(def map-elements-if (pred fun)
  (maptable (fn (k v) (when (pred v) (fun v))) elements*))

(def map-elements (fun)
  (map-elements-if (fn _ t) fun))
