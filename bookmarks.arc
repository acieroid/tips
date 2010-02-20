;;;; bookmarks.arc -- A bookmark manager
(require "ui.arc")
(require "elements.arc")

(= title* "awesom's links")

(def show-element-info (user el)
  (divclass element-infos
    (pr "by " el!author " ")
    (when (or (is el!author user) (admin user))
      (w/bars
        (link "edit" (string "edit?id=" el!id))
        (link "delete" (string "del?id=" el!id))))))

(def show-element (user el)
  (divclass element
    (link el!url)
    (show-element-info user el)
    (show-tags el!tags)))

(def show-element-form (user add (o element (table)))
  (vars-form user
             `((string url ,element!url t t)
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
