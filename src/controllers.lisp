(defpackage ningle-admin/controllers
  (:use :cl
        :ningle-admin/conditions
        :ningle-admin/resource)
  (:shadowing-import-from :ningle-admin/resource #:list #:get #:delete)
  (:export #:*auth-check*
           #:def-controller
           #:render-list
           #:render-add
           #:render-view
           #:execute-save
           #:execute-delete))

(in-package :ningle-admin/controllers)

(defvar *auth-check* (lambda () t)
  "Function invoked before executing any admin controller action.
Should return non-nil if authorized, or signal an error (e.g. `permission-denied-error' or HTTP 404).")

(defmacro def-controller (name args &body body)
  (multiple-value-bind (remaining-forms declarations doc-string)
      (alexandria:parse-body body :documentation t)
    `(defun ,name ,args
       ,@(when doc-string (cl:list doc-string))
       ,@declarations
       (when *auth-check*
         (funcall *auth-check*))
       ,@remaining-forms)))

;;; ---------------------------------------------------------------------------
;;; Generic Controller Actions
;;; ---------------------------------------------------------------------------

(defun render-list (resource-name params &key (render-fn #'djula:render-template*))
  (let* ((resource (find-resource resource-name))
         (page     (or (parse-integer (or (ingle:get-param "page" params) "1") :junk-allowed t) 1))
         (limit    (or (parse-integer (or (ingle:get-param "limit" params) "15") :junk-allowed t) 15)))
    (flet ((fetch (limit offset)
             (list resource :page page :limit limit :params params)))
      (mito-pager:with-pager ((items pager #'fetch :page page :limit limit))
        (let* ((data (if (resource-serializer resource)
                         (mapcar (resource-serializer resource) items)
                         items))
               (template (resource-template-list resource))
               (var-name (intern (format nil "~A" (resource-name resource)) :keyword)))
          (funcall render-fn template var-name data :pager pager :resource resource))))))

(defun render-add (resource-name params &key (render-fn #'djula:render-template*))
  (declare (ignore params))
  (let ((resource (find-resource resource-name)))
    (if (resource-form resource)
        (let ((form (cl-forms:find-form (resource-form resource))))
          (setf (slot-value form 'cl-forms::action) (format nil "~A/new" (resource-url-prefix resource)))
          (funcall render-fn (resource-template-add resource) :form form :resource resource))
        (funcall render-fn (resource-template-add resource) :resource resource))))

(defun render-view (resource-name params &key (render-fn #'djula:render-template*))
  (let* ((resource (find-resource resource-name))
         (id       (ingle:get-param :id params))
         (item     (get resource id))
         (form     (when (resource-form resource)
                     (cl-forms:find-form (resource-form resource))))
         (var-name (resource-template-var resource)))
    (when form
      (setf (slot-value form 'cl-forms::action) (format nil "~A/~A" (resource-url-prefix resource) id))
      (populate-form resource form item))
    (funcall render-fn (resource-template-view resource) var-name item :form form :resource resource)))

(defun execute-save (resource-name params)
  (let* ((resource (find-resource resource-name))
         (id       (ingle:get-param :id params)))
    (save resource params id)
    (ingle:redirect (resource-url-prefix resource))))

(defun execute-delete (resource-name params)
  (let ((resource (find-resource resource-name))
        (id       (ingle:get-param :id params)))
    (delete resource id)
    (setf (lack.response:response-status ningle:*response*) 204)
    ""))
