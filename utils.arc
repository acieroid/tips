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
