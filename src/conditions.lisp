(defpackage ningle-admin/conditions
  (:use :cl)
  (:export #:admin-error
           #:not-found-error
           #:permission-denied-error))

(in-package :ningle-admin/conditions)

(define-condition admin-error (error)
  ((message :initarg :message :reader error-message :initform "Admin Error"))
  (:report (lambda (condition stream)
             (format stream "~A" (error-message condition)))))

(define-condition not-found-error (admin-error)
  ()
  (:default-initargs :message "Not Found"))

(define-condition permission-denied-error (admin-error)
  ()
  (:default-initargs :message "Permission Denied"))
