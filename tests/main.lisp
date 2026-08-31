(defpackage ningle-admin/tests/main
  (:use :cl :rove :ningle-admin)
  (:shadowing-import-from :ningle-admin #:list #:get #:delete))
(in-package :ningle-admin/tests/main)

;; Dummy model for unit testing
(defclass test-item ()
  ((id   :initarg :id   :accessor item-id)
   (name :initarg :name :accessor item-name)))

(deftest test-registry-lifecycle
  (testing "registering, finding, and unregistering admin resources"
    (let ((res (register :test-item
                         :model 'test-item
                         :url-prefix "/admin/items"
                         :template-list "items.html")))
      (ok (equal (resource-name res) :test-item))
      (ok (equal (resource-url-prefix res) "/admin/items"))
      (ok (eq (find-resource :test-item) res))
      (ok (signals (find-resource :unknown-item) 'not-found-error))

      (unregister :test-item)
      (ok (signals (find-resource :test-item) 'not-found-error)))))

(deftest test-auth-check-hook
  (testing "def-controller honors *auth-check*"
    (let ((*auth-check* (lambda () (error 'permission-denied-error))))
      (def-controller test-guarded-action ()
        "success")
      (ok (signals (test-guarded-action) 'permission-denied-error)))

    (let ((*auth-check* (lambda () t)))
      (def-controller test-allowed-action ()
        "success")
      (ok (string= (test-allowed-action) "success")))))
