(defpackage ningle-admin
  (:use :cl
        :ningle-admin/conditions
        :ningle-admin/resource
        :ningle-admin/controllers)
  (:shadowing-import-from :ningle-admin/resource #:list #:get #:delete)
  (:export
   ;; Sub-application & Config
   #:*app*
   #:setup
   #:*mount-path*
   #:*auth-check*
   #:*render-fn*

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

   ;; Controllers
   #:def-controller
   #:render-list
   #:render-add
   #:render-view
   #:execute-save
   #:execute-delete
   #:mount))

(in-package :ningle-admin)

(defun setup (&key (mount-path "/admin") (auth-check (lambda () t)) (render-fn #'djula:render-template*))
  "Configure ningle-admin settings."
  (setf *mount-path* mount-path)
  (setf *auth-check* auth-check)
  (setf *render-fn* render-fn))

;; Default landing route on *app*
(setf (ningle:route *app* "/" :method :GET)
      (lambda (params)
        (declare (ignore params))
        (when *auth-check* (funcall *auth-check*))
        (funcall *render-fn* "dradis/admin/admin.html")))

(defun mount (app &key (auth-check nil) (render-fn nil))
  "Legacy/convenience mounter: mounts routes directly onto an external Ningle app if desired."
  (when auth-check (setf *auth-check* auth-check))
  (when render-fn (setf *render-fn* render-fn))
  (dolist (resource (list-resources))
    (attach-resource-routes app resource)))
