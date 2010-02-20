;;;; images.arc -- An image viewer (fukung-like)
(require "basic.arc")
(= title* "images")
(= header-links* '("random" "tags" "add"))«

(defopr || _ (prn "random"))

(def show-element (user el)
  (center
    (link (string "<image src=\"" el!url "\"/>") "random")))

(element-datas
  `((string url ,element!url t t)
    (toks tags ,element!tags t t)))