(attribute div class opstring)n
(mac div (class . body)
  `(tag (div class ,class)
     ,@body))

(def prerr (msg)
  (div "error" (prn msg)))
(def prinfo (msg)
  (div "info" (prn msg)))

(mac y-or-n (q if-y if-n)
  `(div "info" 
     (prn ,q)
     (w/bars
       (w/link ,if-y (pr "Yes"))
       (w/link ,if-n (pr "No")))))

(mac if-confirm body
  `(div "info"
     (prn "Are you sure ?")
     (w/link (do ,@body) (pr "Yes"))))
