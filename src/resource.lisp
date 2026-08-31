(defpackage ningle-admin/resource
  (:use :cl :ningle-admin/conditions)
  (:shadow #:list #:delete #:get)
  (:export #:*resources*
           #:*register-hook*
           #:resource
           #:register
           #:find-resource
           #:list-resources
           #:unregister
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
           #:list
           #:get
           #:save
           #:delete
           #:populate-form))

(in-package :ningle-admin/resource)

;;; ---------------------------------------------------------------------------
;;; Resource Registry
;;; ---------------------------------------------------------------------------

(defparameter *resources* (make-hash-table :test 'eq)
  "Table mapping resource keyword names to `resource' instances.")

(defvar *register-hook* nil
  "Hook function called with the new `resource' instance when `register' is called.")

(defclass resource ()
  ((name          :initarg :name          :accessor resource-name          :type keyword)
   (model         :initarg :model         :accessor resource-model)
   (form          :initarg :form          :accessor resource-form          :initform nil)
   (url-prefix    :initarg :url-prefix    :accessor resource-url-prefix    :type string)
   (template-list :initarg :template-list :accessor resource-template-list :initform nil)
   (template-view :initarg :template-view :accessor resource-template-view :initform nil)
   (template-add  :initarg :template-add  :accessor resource-template-add  :initform nil)
   (template-var  :initarg :template-var  :accessor resource-template-var  :initform nil)
   (serializer    :initarg :serializer    :accessor resource-serializer    :initform nil)
   (order-by      :initarg :order-by      :accessor resource-order-by      :initform :id)
   (list-fields   :initarg :list-fields   :accessor resource-list-fields   :initform nil)
   (on-create     :initarg :on-create     :accessor resource-on-create     :initform nil)
   (on-save       :initarg :on-save       :accessor resource-on-save       :initform nil)
   (on-delete     :initarg :on-delete     :accessor resource-on-delete     :initform nil))
  (:documentation "Metadata descriptor for an admin CRUD resource."))

(defun register (name &key model form url-prefix template-list template-view template-add template-var serializer (order-by :id) list-fields on-create on-save on-delete)
  "Register a model descriptor in the admin registry."
  (let ((res (make-instance 'resource
                            :name name
                            :model model
                            :form form
                            :url-prefix (or url-prefix (format nil "/~(~A~)" name))
                            :template-list template-list
                            :template-view template-view
                            :template-add template-add
                            :template-var (or template-var (intern (string-downcase name) :keyword))
                            :serializer serializer
                            :order-by order-by
                            :list-fields list-fields
                            :on-create on-create
                            :on-save on-save
                            :on-delete on-delete)))
    (setf (gethash name *resources*) res)
    (when *register-hook*
      (funcall *register-hook* res))
    res))

(defun find-resource (name)
  "Lookup an `resource' descriptor by keyword name."
  (or (gethash name *resources*)
      (error 'not-found-error :message (format nil "Unknown admin resource: ~A" name))))

(defun list-resources ()
  "Return all registered admin resource descriptors."
  (alexandria:hash-table-values *resources*))

(defun unregister (name)
  "Remove a registered resource descriptor by name."
  (remhash name *resources*))

;;; ---------------------------------------------------------------------------
;;; Generic CRUD Protocol
;;; ---------------------------------------------------------------------------

(defgeneric list (resource &key page limit params)
  (:documentation "Fetch a list of items for the admin list view. Returns (values items count)."))

(defgeneric get (resource id)
  (:documentation "Fetch a single model instance by ID or signal a 404 error."))

(defgeneric save (resource params &optional id)
  (:documentation "Create or update a model instance from submitted form parameters. Returns the saved instance."))

(defgeneric delete (resource id)
  (:documentation "Delete a model instance by ID."))

(defgeneric populate-form (resource form instance)
  (:documentation "Populate a cl-forms instance with values from a model instance."))

;;; ---------------------------------------------------------------------------
;;; Default Protocol Implementations
;;; ---------------------------------------------------------------------------

(defmethod list ((res resource) &key (page 1) (limit 15) params)
  (declare (ignore page params))
  (let ((model (resource-model res))
        (order (resource-order-by res)))
    (values
     (if (and limit (> limit 0))
         (mito:select-dao model (sxql:order-by order) (sxql:limit limit))
         (mito:select-dao model (sxql:order-by order)))
     (mito:count-dao model))))

(defmethod get ((res resource) id)
  (let ((numeric-id (if (integerp id) id (parse-integer (or id "") :junk-allowed t))))
    (unless numeric-id
      (error 'not-found-error :message "Not Found"))
    (or (mito:find-dao (resource-model res) :id numeric-id)
        (error 'not-found-error :message "Not Found"))))

(defmethod delete ((res resource) id)
  (let ((numeric-id (if (integerp id) id (parse-integer (or id "") :junk-allowed t))))
    (unless numeric-id
      (error 'not-found-error :message "Not Found"))
    (alexandria:if-let ((instance (mito:find-dao (resource-model res) :id numeric-id)))
      (if (resource-on-delete res)
          (funcall (resource-on-delete res) instance)
          (mito:delete-dao instance))
      (error 'not-found-error :message "Not Found"))))

(defmethod populate-form ((res resource) form instance)
  (declare (ignore res form instance))
  nil)
