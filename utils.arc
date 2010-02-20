(attribute div class opstring)
(mac divclass (class . body)
  `(tag (div class (string ',class))
     ,@body))

(mac prerr msg
  `(divclass error (prn ,@msg)))
(mac prinfo msg
  `(divclass info (prn ,@msg)))

(mac y-or-n (q if-y if-n)
  `(divclass info
     (prn ,q)
     (w/bars
       (w/link ,if-y (pr "Yes"))
       (w/link ,if-n (pr "No")))))

(mac if-confirm body
  `(divclass info
     (prn "Are you sure ?")
     (w/link (do ,@body) (pr "Yes"))))

(def hr ()
  (tag hr))

;;; Same as for, but with start >= end
(mac revfor (var start end . body)
  `(for ,var ,end ,start
     (let ,var (- ,start ,var )
       ,@body)))

;;; Identical to the Common Lisp's defvar
(mac defvar (var value)
  `(unless (bound ',var) (= ,var ,value)))

;;; map FUN through LIST and print a bar between each element
;;; (FUN should print something)
(mac map-w/bars (list fun)
  `(if (cdr ,list)
       (reduce (fn (x y) (,fun x) (pr bar*) (,fun y)) ,list)
       (,fun (car ,list))))
