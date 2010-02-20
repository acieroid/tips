;;;; tips.arc -- A tip manager
(require "ui.arc")
(require "elements.arc")

(= title* "awesom's tips")

(def show-element (user el)
  (link el!title (string "show?id=" el!id))
  (br)
  (show-element-info user el)
  (pr el!content)
  (show-tags el!tags))

(def show-element-form (user add (o element (table)))
  (vars-form user
             `((string title ,element!title t t)
               (text tip ,element!tip t t)
               (toks tags ,element!tags t t))
             (fn (name val) (= (element name) val))
             (fn ()
               (do 
                 (if add 
                     (add-element user element)
                     (save-element element))
                 (page user 
                       (prinfo "Element added/modified:")
                       (show-element user element))))))
