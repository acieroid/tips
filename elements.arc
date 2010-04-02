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
  date nil)

;;; Return the element with this id, or else nil
(def element (id)
  (elements* (errsafe:int id)))

;;; Increase the counter of the tag in TAGS, or add one initialized to 1
(def add-tag (tag (o acc tags*))
  (if acc
      ; already in tags*, we increment it
      (if (is (caar acc) tag)
          (= (cdr (car acc)) (inc (cdr (car acc))))
          (add-tag tag (cdr acc)))
      ; not in tags*, we add it
      (push (cons tag 1) tags* )))

;;; Add the tags that are in TAGS but not in TAGS* to TAGS*
(def add-tags (tags)
  (map add-tag tags))

;;; Load all the elements from DIR*
(def load-elements ()
  (each id-str (dir dir*)
    (withs (id (int id-str)
            element (load-table (string dir* id)))
      (add-tags element!tags)
      (push element!id ids*)
      (= maxid* (max maxid* id)
         (elements* id) element)))
  elements*)

;;; Save an element to the disk
(def save-element (el)
  (save-table el (string dir* el!id)))

;;; Add an ELEMENT to ELEMENTS* after having filled the date, the author and the
;;; id tags, then save it to the hard-drive
(def add-element (user el)
  (= el!id (++ maxid*)
     el!author user
     el!date (date)
     (elements* el!id) el)
  (add-tags el!tags)
  (push el!id ids*)
  (save-element el))

;;; Delete a tip from the database and from the disk
;;; TODO: delete the obsoletes tags
(def delete-element (el)
  (rmfile (string dir* el!id))
  (rem el!id ids*)
  (= (elements* el!id) nil))

;;; Return an random existing id
(def random-id ()
  (rand-elt ids*))

;;; Show a tag
(def show-tag (tag)
  (let tag (if (is (type tag) 'cons)
               (car tag)
               tag)
  (link tag (string "tag?t=" (urlencode tag)))))

;;; Show a list of tags
(def show-tags (tags (o separator ", "))
  (let bar* separator 
    (map-w/bars tags show-tag)))

;;; Mapping functions over elements
(def map-elements-if (pred fun)
  (maptable (fn (k v) (when (pred v) (fun v))) elements*))

(def map-elements (fun)
  (map-elements-if (fn _ t) fun))

;;;; Showing lists of elements
;;;; show-element should be defined (look at basic.arc)

;;; Show elements that matches PRED
(def show-elements (user pred)
  (map-elements-if pred [show-element user _]))

;;; Show all the elements
(def show-all-elements (user)
  (map-elements [show-element user _]))
