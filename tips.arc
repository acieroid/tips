;;;; tips.arc -- A tip manager
(require "ui.arc")
(require "elements.arc")
(require "basic.arc")

(= title* "awesom's tips")

(add-to-css ".element-infos { margin-left: 10px }
.element { border: 1px dashed gray; padding: 5px }")

(def show-title (user el)
  (link el!title (string "show?id=" el!id))
  (br)
  (show-element-info user el))

(def show-element (user el)
  (divclass element
            (show-title user el)
            (pr el!content)
            (show-tags el!tags)))

(defpage all req
  (map-elements (fn (el) (show-title user el))))

(element-datas
  `((string title ,element!title t t)
    (text tip ,element!tip t t)
    (toks tags ,element!tags t t)))
