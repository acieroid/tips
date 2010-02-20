;;; Functions to show an element, to be redefined by the user to match 
;;; the elements he wants to manipulate
(def show-element-info (el user)
  (divclass element-infos
    (pr "By " el!author " ")
    (when (or (is el!author user) (admin user))
      (w/bars
        (link "edit" (string "edit?id=" el!id))
        (link "delete" (string "del?id=" el!id))))
    (br)))

(def show-element (el user)
  (divclass element
    (show-element-info el user)
    (pr el!datas)
    (br)
    (pr "tags: ")
    (show-tags el!tags)))

(def show-element-form (user)
  (aform [page user (add-element _) (prinfo "Element added")]
    (tab (row "datas:" (textarea "datas" 10 80))
         (row "tags:" (input "tags"))
         (row "" (submit)))))
