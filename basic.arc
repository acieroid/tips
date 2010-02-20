;;;; basic.arc -- Basic functions that should work for most of the collections 
;;;; and some useful macros to avoir duplicated code
(require "ui.arc")
(require "elements.arc")

(def show-element-info (user el)
  (divclass element-infos
    (pr "by " el!author " ")
    (when (or (is el!author user) (admin user))
      (w/bars
        (link "edit" (string "edit?id=" el!id))
        (link "delete" (string "del?id=" el!id))))))

(mac element-datas (datas)
  `(def show-element-form (user add (o element (table)))
     (vars-form user
                ,datas
                (fn (name val) (= (element name) val))
                (fn ()
                  (do
                    (if add
                        (add-element user element)
                        (save-element element))
                    (page user
                          (prinfo "Element " (if add "added" "modified") ":")
                          (show-element user element)))))))
                        