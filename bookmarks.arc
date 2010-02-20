;;;; bookmarks.arc -- A bookmark manager
(require "basic.arc")

(= title* "awesom's links")

(def show-element (user el)
  (divclass element
    (link el!url)
    (show-element-info user el)
    (show-tags el!tags)))

(element-datas
  `((string url ,element!url t t)
    (toks tags ,element!tags t t)))
