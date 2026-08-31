(defsystem "ningle-admin"
  :version "0.1.0"
  :author "nmunro"
  :license "BSD3-Clause"
  :description "A declarative CRUD admin interface for Ningle and Mito web applications"
  :depends-on (:alexandria
               :cl-forms
               :cl-forms.djula
               :djula
               :ingle
               :mito
               :mito-pager
               :ningle
               :str
               :sxql)
  :components ((:module "src"
                :serial t
                :components
                ((:file "conditions")
                 (:file "resource")
                 (:file "controllers")
                 (:file "main"))))
  :in-order-to ((test-op (test-op "ningle-admin/tests"))))

(defsystem "ningle-admin/tests"
  :author "nmunro"
  :license "BSD3-Clause"
  :depends-on ("ningle-admin"
               :rove)
  :components ((:module "tests"
                :components
                ((:file "main"))))
  :description "Test system for ningle-admin"
  :perform (test-op (op c) (symbol-call :rove :run c)))
