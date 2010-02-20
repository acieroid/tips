;;;; basic.arc -- Basic functions that should work for most of the collections
;;;; You can import this file and then define your own functions
(require "ui.arc")
(require "elements.arc")

(def show-element-info (user el)
  (divclass element-infos
    (pr "by " el!author " ")
    (when (or (is el!author user) (admin user))
      (w/bars
        (link "edit" (string "edit?id=" el!id))
        (link "delete" (string "del?id=" el!id))))))
