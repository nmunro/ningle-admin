(defpackage ningle-admin
  (:use :cl
        :ningle-admin/conditions
        :ningle-admin/resource
        :ningle-admin/controllers)
  (:shadowing-import-from :ningle-admin/resource #:list #:get #:delete)
  (:export
   ;; Conditions
   #:admin-error
   #:not-found-error
   #:permission-denied-error

   ;; Resource Class & Registry
   #:resource
   #:register
   #:find-resource
   #:list-resources
   #:unregister

   ;; Slot Accessors
   #:resource-name
   #:resource-model
   #:resource-form
   #:resource-url-prefix
   #:resource-template-list
   #:resource-template-view
   #:resource-template-add
   #:resource-template-var
   #:resource-serializer
   #:resource-order-by
   #:resource-list-fields
   #:resource-on-create
   #:resource-on-save
   #:resource-on-delete

   ;; Generic CRUD Protocol
   #:list
   #:get
   #:save
   #:delete
   #:populate-form

   ;; Controllers & Mounting
   #:*auth-check*
   #:def-controller
   #:render-list
   #:render-add
   #:render-view
   #:execute-save
   #:execute-delete
   #:mount))

(in-package :ningle-admin)

(defun mount (app &key (auth-check nil) (render-fn #'djula:render-template*))
  "Mount all registered admin resource routes onto the NINGLE APP instance."
  (when auth-check
    (setf *auth-check* auth-check))

  (dolist (resource (list-resources))
    (let ((prefix (resource-url-prefix resource))
          (name   (resource-name resource)))

      ;; 1. List
      (ningle:route app prefix :method :GET
                    (lambda (params)
                      (when *auth-check* (funcall *auth-check*))
                      (render-list name params :render-fn render-fn)))

      ;; 2. Add form
      (ningle:route app (format nil "~A/new" prefix) :method :GET
                    (lambda (params)
                      (when *auth-check* (funcall *auth-check*))
                      (render-add name params :render-fn render-fn)))

      ;; 3. Create
      (ningle:route app (format nil "~A/new" prefix) :method :POST
                    (lambda (params)
                      (when *auth-check* (funcall *auth-check*))
                      (execute-save name params)))

      ;; 4. View / Edit form
      (ningle:route app (format nil "~A/:id" prefix) :method :GET
                    (lambda (params)
                      (when *auth-check* (funcall *auth-check*))
                      (render-view name params :render-fn render-fn)))

      ;; 5. Update
      (ningle:route app (format nil "~A/:id" prefix) :method :POST
                    (lambda (params)
                      (when *auth-check* (funcall *auth-check*))
                      (execute-save name params)))

      ;; 6. Delete
      (ningle:route app (format nil "~A/:id" prefix) :method :DELETE
                    (lambda (params)
                      (when *auth-check* (funcall *auth-check*))
                      (execute-delete name params))))))
