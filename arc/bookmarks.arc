;;;; bookmarks.arc -- A bookmark manager
(require "basic.arc")

(= title* "awesom's links")

(def show-element (user el)
  (divclass link
    (link el!description el!url)
    (pr " in ")
    (show-tags el!tags)
    (pr " by " el!author " ")
    (show-edit-and-delete user el)))

(element-datas
  `((string description ,element!description t t)
    (string url ,element!url t t)
    (toks tags ,element!tags t t)))
