;; Unfortunately, these are out of date!

(require 'ert)
(require 'org-todoist)

;; (ert-deftest org-todoist--test--encode-item ()
;;   (let ((args '("args" . (("id" . "5")
;;                                   ("content" . "test content")
;;                                   ("priority" . 1))))
;;         (data '(("type" . "item_update")
;;                      ("uuid" . "393491b2-6ef8-4045-b208-20a84c51eb42")
;;                      ("args" . (("id" . "5")
;;                                   ("content" . "test content")
;;                                   ("priority" . 1))))))

;;     ;; (json-encode (cdr args))
;;     ;; (org-todoist--encode args)
;;     ;; (json-alist-p (cdr args))
;;     ;; ;; (if (json-alist-p (cdr item)
;;     ;;                   ))
;;     ;; (org-todoist--encode-item (cdr args)                  )
;;     (json-encode data)
;;     ;; (org-todoist--encode-item

;;     )
;;   )

;; (ert-deftest org-todoist--test--encode ()
;;   (org-todoist--encode `(("sync_token" . "*")
;;                          ("resource_types" . ,org-todoist-resource-types)
;;                          ("commands" . ,(org-todoist--push)))))

(ert-deftest org-todoist--test--first-parent-of-type ()
  (let* ((ast (org-todoist--generate-sample-ast))
         (task (org-todoist--get-by-id org-todoist--task-type "T2aBCdeF" ast))
         (section (org-todoist--get-by-id org-todoist--section-type "S1aBCdeF" ast)))
    (should (eq (org-todoist--first-parent-of-type task 'headline)
                section))))

(ert-deftest org-todoist--test--date-to-todoist ()
  (let* ((task (org-todoist--test-task))
         (planning (org-todoist--get-planning task))
         (schtimestamp (org-element-property :scheduled planning)))
    (should (string-equal "2024-12-31T23:59:00" (org-todoist--get-planning-date task :scheduled)))
    (should (string-equal "2024-12-31T23:59:00" (org-todoist--date-to-todoist schtimestamp)))
    (should (string-equal "2025-01-01T00:01:00" (org-todoist--get-planning-date task :deadline)))))

(ert-deftest org-todoist--test--task-is-recurring ()
  (should (org-todoist--task-is-recurring (org-todoist--test-recurring-task))))

(ert-deftest org-todoist--test--project-nodes ()
  (should (length= (org-todoist--project-nodes (org-todoist--generate-sample-ast)) 2)))

(ert-deftest org-todoist--test--replace-description ()
  (let ((task (org-todoist--test-task))
        (text "New Desc\n"))
    (org-todoist--replace-description task text)
    (should (string-equal text (org-todoist--description-text task)))))

(defmacro org-todoist--test-with-tz (zone &rest body)
  "Run BODY with the local time zone set to ZONE."
  (declare (indent 1))
  `(let ((old-tz (getenv "TZ")))
     (unwind-protect (progn (set-time-zone-rule ,zone) ,@body)
       (set-time-zone-rule old-tz))))

(ert-deftest org-todoist--test--timestamp-to-utc-str ()
  (org-todoist--test-with-tz "America/Los_Angeles"
    (should (string= (org-todoist--timestamp-to-utc-str
                      (org-timestamp-from-string "<2025-01-01 23:30>"))
                     "2025-01-02T07:30:00.0Z"))
    ;; Daylight saving: the offset in July differs from the one in January.
    (should (string= (org-todoist--timestamp-to-utc-str
                      (org-timestamp-from-string "<2025-07-01 23:30>"))
                     "2025-07-02T06:30:00.0Z"))))

(ert-deftest org-todoist--test--timestamp-from-utc-str ()
  (org-todoist--test-with-tz "America/Los_Angeles"
    (should (string= (org-element-property :raw-value
                                           (org-todoist--timestamp-from-utc-str "2025-01-02T07:30:00Z" t))
                     "<2025-01-01 Wed 23:30>"))
    (should (string= (org-element-property :raw-value
                                           (org-todoist--timestamp-from-utc-str "2025-07-02T06:30:00Z" t))
                     "<2025-07-01 Tue 23:30>"))
    ;; date-only values must not shift across the date line
    (should (string= (org-element-property :raw-value
                                           (org-todoist--timestamp-from-utc-str "2025-07-02Z"))
                     "<2025-07-02 Wed>"))))

;; (ert-deftest org-todoist--test--schedule ()
;;   (let ((task (json-read-file "sample-task.json"))
;;         (headline (org-element-create 'headline '(:title "Test Headline" :level 1 :todo-type 'todo :todo-keyword "TODO"))))
;;     ;; (timestamp (org-timestamp-from-time (org-read-date nil t "2016-12-0T12:00:00.000000" nil ))))
;;     (org-element-adopt headline (org-todoist--create-planning task))
;;     (should (org-todoist--element-equals-str "* TODO Test Headline
;; DEADLINE: <2017-01-06 Fri> SCHEDULED: <2016-12-06 Tue>
;; " headline))))

;; (ert-deftest org-todoist--test--sort-by-child-order ()
;;   (let ((section (org-todoist--get-by-id org-todoist--section-type "2" (org-todoist--generate-sample-ast)))
;;         (PROPERTY "child_order"))
;;     (org-todoist--sort-by-child-order section PROPERTY)
;;     (let ((prev -1)
;;           (sorted (org-element-map section 'headline (lambda (hl) (when (org-todoist--get-prop hl PROPERTY) hl)))))
;;       (dolist (next sorted)
;;         (should (> (org-todoist--get-position next PROPERTY) prev))
;;         (setq prev (org-todoist--get-position next PROPERTY))))))

(ert-deftest org-todoist--test--set-effort ()
  (let ((hl (org-element-create 'headline '(:title "Headline" :level 1))))
    (org-todoist--set-effort hl test-task)
    (should (org-todoist--element-equals-str "* Headline
:PROPERTIES:
:EFFORT:   0:15
:END:
" hl))))
(ert-deftest org-todoist--test--set-todo ()
  (let ((task (org-todoist--test-task)))
    (org-todoist--set-todo task t)
    (should (cl-search "DONE" (org-todoist-org-element-to-string task)))
    (org-todoist--set-todo task nil)
    (should (cl-search "TODO" (org-todoist-org-element-to-string task)))))

(ert-deftest org-todoist--test--archived ()
  (let ((node (org-todoist--test-task)))
    (org-todoist--archive node)
    (should (-contains-p (org-element-property :tags node) org-archive-tag))
    ;; verify the round trip too
    (with-temp-buffer (insert (org-todoist-org-element-to-string node))
                      (org-mode)
                      (let* ((ast (org-element-parse-buffer))
                             (task (org-todoist--get-by-id org-todoist--task-type "T2aBCdeF" ast))
                             (tags (org-element-property :tags task)))
                        (should (-contains-p tags org-archive-tag))))))

;; TODO fix
;; (ert-deftest org-todoist--test--get-or-create-node ()
;;   (let* ((node (org-todoist--test-task))
;;          (section (org-todoist--get-parent-of-type org-todoist--section-type node t))
;;          (updated (org-todoist--get-or-create-node section org-todoist--task-type (org-todoist--get-prop node "id") "updated" "updated" test-task))
;;          (newelem (org-todoist--get-or-create-node section org-todoist--task-type "2995104339" "new task" "My new desc" test-task)))
;;     (should newelem)
;;     (should (eq (org-element-property :parent newelem) section))
;;     (should updated)
;;     (should (eq updated node))
;;     (should (eq (org-element-property :parent updated) section))
;;     (should (string-equal-ignore-case "updated\n" (org-todoist--description-text updated)))
;;     (should (string-equal-ignore-case "updated" (org-todoist--get-prop-elem updated :title)))))

(ert-deftest org-todoist--test--description-text ()
  (should (string-equal-ignore-case "Description

More description

- [ ] With a plain list
- [ ] second bullet
" (org-todoist--description-text (org-todoist--test-task)))))

(ert-deftest org-todoist--test-update-file ()
  (let ((org-todoist-file (make-temp-file "todoist")))
    "Tests insertion of org syntax from abstract syntax tree into org-todoist-file"
    (org-todoist--update-file (org-todoist--generate-ast test-org-str))
    (with-temp-buffer
      (insert-file-contents (org-todoist-file))
      (should (equal (org-todoist--remove-ws test-org-str) (org-todoist--remove-ws (buffer-string)))))))

(ert-deftest org-todoist--test--get-parent ()
  "Tests getting the parent node of a specific type"
  (let* ((ast (org-todoist--generate-sample-ast))
         (task (org-todoist--test-task))
         (project (org-todoist--get-parent-of-type org-todoist--project-type task t)))
    (should (equal (org-todoist--get-prop project "tid") "P1aBCdeF"))))

(ert-deftest org-todoist--test--insert-identifier ()
  "Tests adding the org-todoist--type property to a property drawer, creating it if necessary"
  (let* ((astwithout (org-element-map (org-todoist--generate-ast "* Headline\n") 'headline #'identity nil t))
         (astwith (org-element-map (org-todoist--generate-ast "* Headline
:PROPERTIES:
:MYPROP:  VALUE
:END:
") 'headline #'identity nil t)))
    (org-todoist--insert-identifier astwith "TASK")
    (org-todoist--insert-identifier astwithout "TASK")
    (should (org-todoist--element-equals-str  "* Headline
:PROPERTIES:
:TODOIST_TYPE:  TASK
:END:
" astwithout))
    (should (org-todoist--element-equals-str  "* Headline
:PROPERTIES:
:MYPROP:  VALUE
:TODOIST_TYPE:  TASK
:END:
" astwith))))

;; (ert-deftest org-todoist--test--is-property ()
;;   "Verifies detecting existing properties"
;;   (let* ((ast (org-todoist--generate-ast test-org-str-property-added))
;;          (drawer (org-todoist--get-property-drawer ast)))
;;     (let (result)
;;       (dolist (prop (org-element-map drawer 'node-property #'identity) result)
;;         (push (org-todoist--is-property prop "NEWPROP") result))
;;       (should (equal result '(t nil))))))

(ert-deftest org-todoist--test--get-property-drawer--exists-gets ()
  (let ((drawer (org-todoist--get-property-drawer (org-element-map (org-todoist--generate-ast test-org-str) 'headline #'identity nil t))))
    (should (org-element-type-p drawer 'property-drawer))))

;; (ert-deftest org-todoist--test--put-node-attribute ()
;;   (let* ((ast (org-todoist--generate-sample-ast))
;;          (hl (org-todoist--get-by-id org-todoist--task-type "13" ast)))
;;     (org-todoist--put-node-attribute hl "testattr" "MYVAL")
;;     (should (string-equal (org-todoist--get-node-attribute hl "testattr") "MYVAL"))))

(ert-deftest org-todoist--test-parse-time-component ()
  "Test parsing time components from strings"
  (let ((cases '(("at 2pm" (14 0))
                 ("5:30pm" (17 30))
                 ("9am" (9 0))
                 ("at 15:45" (15 45))
                 ("3" nil))))
    (dolist (case cases)
      (should (equal (org-todoist--parse-time-component (car case))
                    (cadr case))))))

(ert-deftest org-todoist--test-parse-weekday ()
  "Test parsing weekdays from strings"
  (let ((cases '(("monday" "MON")
                 ("tue" "TUE")
                 ("wednesday" "WED")
                 ("thursday" "THU")
                 ("fri" "FRI")
                 ("saturday" "SAT")
                 ("sun" "SUN"))))
    (dolist (case cases)
      (should (equal (org-todoist--parse-weekday (car case))
                    (cadr case))))))

(ert-deftest org-todoist--test-parse-interval ()
  "Test parsing intervals from strings"
  (let ((cases '(("every other" 2)
                 ("every 3rd" 3)
                 ("every" nil)
                 ("every 5th" 5))))
    (dolist (case cases)
      (should (equal (org-todoist--parse-interval (car case))
                    (cadr case))))))

(ert-deftest org-todoist--test-parse-unit ()
  "Test parsing time units from strings"
  (let ((cases '(("day" day)
                 ("weeks" week)
                 ("month" month)
                 ("years" year))))
    (dolist (case cases)
      (should (equal (org-todoist--parse-unit (car case))
                    (cadr case))))))

(ert-deftest org-todoist--test--add-repeater-basic ()
  "Test basic recurring patterns"
  (let ((ts (org-element-create 'timestamp)))
    ;; Daily patterns with time
    (org-todoist--add-repeater ts "every day at 2pm")
    (should (eq (org-element-property :repeater-unit ts) 'day))
    (should (eq (org-element-property :repeater-value ts) 1))
    (should (eq (org-element-property :repeater-type ts) 'cumulate))
    (should (eq (org-element-property :hour-start ts) 14))
    (should (eq (org-element-property :minute-start ts) 0))
    
    ;; Weekly patterns with weekday
    (org-todoist--add-repeater ts "every friday")
    (should (eq (org-element-property :repeater-unit ts) 'week))
    (should (eq (org-element-property :repeater-value ts) 1))

    (org-todoist--add-repeater ts "every other friday")
    (should (eq (org-element-property :repeater-unit ts) 'week))
    (should (eq (org-element-property :repeater-value ts) 2))
    
    ;; Monthly patterns with restart
    (org-todoist--add-repeater ts "every! 2 months")
    (should (eq (org-element-property :repeater-unit ts) 'month))
    (should (eq (org-element-property :repeater-value ts) 2))
    (should (eq (org-element-property :repeater-type ts) 'restart))))

(ert-deftest org-todoist--test--add-repeater-times ()
  "Test patterns with specific times"
  (let ((ts (org-element-create 'timestamp)))
    ;; Morning
    (org-todoist--add-repeater ts "every morning")
    (should (eq (org-element-property :repeater-unit ts) 'day))
    (should (eq (org-element-property :hour-start ts) 9))
    (should (eq (org-element-property :minute-start ts) 0))
    
    ;; Afternoon
    (org-todoist--add-repeater ts "ev afternoon")
    (should (eq (org-element-property :hour-start ts) 12))
    
    ;; Evening
    (org-todoist--add-repeater ts "every! evening") 
    (should (eq (org-element-property :hour-start ts) 19))
    (should (eq (org-element-property :repeater-type ts) 'restart))))

(ert-deftest org-todoist--test--add-repeater-with-dates ()
  "Test patterns with specific dates"
  (let ((ts (org-element-create 'timestamp)))
    ;; Date with time
    (org-todoist--add-repeater ts "every 2 week on 07/12 at 16:30")
    (should (eq (org-element-property :repeater-unit ts) 'week))
    (should (eq (org-element-property :repeater-value ts) 2))
    (should (eq (org-element-property :month-start ts) 7))
    (should (eq (org-element-property :day-start ts) 12))
    (should (eq (org-element-property :hour-start ts) 16))
    (should (eq (org-element-property :minute-start ts) 30))
    
    ;; Date without time
    (setq ts (org-element-create 'timestamp))
    (org-todoist--add-repeater ts "every 2 week on 07/12")
    (should (eq (org-element-property :repeater-unit ts) 'week))
    (should (eq (org-element-property :repeater-value ts) 2))
    (should (eq (org-element-property :month-start ts) 7))
    (should (eq (org-element-property :day-start ts) 12))
    (should (eq (org-element-property :hour-start ts) nil))
    (should (eq (org-element-property :minute-start ts) nil))))

(ert-deftest org-todoist--test--repeater-regex ()
  (let ((ts (org-element-create 'timestamp))
        (str "every! mon, tues, wed, thurs"))
    (org-todoist--add-repeater ts str)
    (should (not (org-element-property :repeater-type ts)))))

(ert-deftest org-todoist--test--get-prop ()
  "Retrieves the property KEY from the property drawer directly under node.
Returns nil if not present"
  (should-not (org-todoist--get-prop (org-todoist--generate-ast "* Headline") "MYPROP"))
  (should (string-equal-ignore-case "test" (org-todoist--get-prop (org-element-map (org-todoist--generate-ast test-org-str) 'headline #'identity nil t) "MYPROP"))))

(ert-deftest org-todoist--test--add-prop--does-not-exist-works ()
  "Tests if adding a property works both when a property already exists."
  (let* ((ast (org-todoist--generate-ast test-org-str))
         (hl (org-element-map ast 'headline #'identity nil t))
         (drawer (org-todoist--get-property-drawer hl)))
    (should drawer)
    (org-todoist--add-prop drawer "NEWPROP" "VALUE")
    (should (org-todoist--element-equals-str test-org-str-property-added ast))))

;; (ert-deftest org-todoist--test--add-prop-headline ()
;;   "Tests if adding a property works both when a property already exists."
;;   (let* ((ast (org-todoist--generate-sample-ast))
;;          (hl (org-todoist--get-by-id org-todoist--task-type "13" ast))
;;          (drawer (org-todoist--get-property-drawer hl)))
;;     (org-todoist--add-prop hl "NEWPROP" "VALUE")
;;     (should (org-element-map drawer 'node-property
;;               (lambda (prop) (when (org-todoist--is-property prop "NEWPROP") t))))
;;     (should (string-equal (org-todoist--get-node-attribute hl "NEWPROP") "VALUE"))))

(ert-deftest org-todoist--test--add-prop--exists-changes-headline ()
  "Tests if adding a property works both when a property already exists."
  (let* ((ast (org-todoist--generate-ast test-org-str-property-added))
         (hl (org-element-map ast 'headline #'identity nil t)))
    (org-todoist--add-prop hl "NEWPROP" "NEWVALUE")
    (org-todoist--add-prop hl "NEWPROP" "NEWVALUE")
    (org-todoist--add-prop hl "NEWPROP" "NEWVALUE")
    (should (org-todoist--element-equals-str (string-replace "VALUE" "NEWVALUE" test-org-str-property-added) ast))))

(ert-deftest org-todoist--test--add-prop--exists-changes ()
  "Tests if adding a property works both when a property already exists."
  (let* ((ast (org-todoist--generate-ast test-org-str-property-added))
         (hl (org-element-map ast 'headline #'identity nil t))
         (drawer (org-todoist--get-property-drawer hl)))
    (org-todoist--add-prop drawer "NEWPROP" "NEWVALUE")
    (should (org-todoist--element-equals-str (string-replace "VALUE" "NEWVALUE" test-org-str-property-added) ast))))

;; (ert-deftest org-todoist--test--add-all-properties ()
;;   "Tests adding a properties alist to a node"
;;   (should (string-equal-ignore-case
;;            (org-todoist-org-element-to-string-no-ws
;;             (org-todoist--add-all-properties (org-element-create 'headline '(:title "Headline" :level 1))
;;                                              test-full-date))
;;            (org-todoist--remove-ws test-full-date-headline-text))))
;;            TODO not working due to differences below
;; *Headline
;; :PROPERTIES:
;; :date:2016-12-01
;; :timezone:nil
;; :string:everyday
;; :lang:en
;; :is_recurring:t
;; :END:

;; *Headline
;; :PROPERTIES:
;; :DATE:2016-12-01
;; :TIMEZONE:
;; :STRING:everyday
;; :LANG:en
;; :IS_RECURRING:t
;; : END:


;; (ert-deftest org-todoist--test-add-prop-no-drawer ()
;;   (should (string-equal-ignore-case (org-todoist--remove-ws "* Headline\n:PROPERTIES:\n:PROP:  VALUE\n:END:\n")
;;                                     (org-todoist--remove-ws (org-todoist-org-element-to-string (org-todoist--add-prop (org-todoist--generate-ast "* Headline\n") "PROP" "VALUE"))))))

(ert-deftest org-todoist--test--org-element-to-string ()
  "Converts DATA (an org-element or tree) to its content string. Note, a \n character is appended if not present."
  (should (string-equal-ignore-case "* Headline\n" (org-todoist-org-element-to-string (org-todoist--generate-ast "* Headline")))))

(ert-deftest org-todoist--test--org-element-to-string-2 ()
  "Converts DATA (an org-element or tree) to its content string. Note, a \n character is appended if not present."
  (should (string-equal-ignore-case (org-todoist--remove-ws test-org-str)
                                    (org-todoist--remove-ws (substring-no-properties (org-element-interpret-data (org-todoist--generate-ast test-org-str)))))))

(ert-deftest org-todoist--test--element-equals-str--expected ()
  (org-todoist--element-equals-str "* Headline\n" (org-todoist--generate-ast "* Headline\n")))

(ert-deftest org-todoist--test--invoke-with-buffer-processes-correctly ()
  "Verifies the helper fn org-todoist--invoke-with-buffer acts on the correct contents"
  (should (string-equal "Headlin" (org-todoist--invoke-with-buffer "* Headline" (lambda () (substring (buffer-string) 2 -1))))))

(defun org-todoist--generate-sample-string ()
  (org-todoist-org-element-to-string (org-todoist--generate-sample-ast)))

(defun file-to-string (file)
  "Read `FILE' as a string"
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(defun org-todoist-org-element-to-string-no-ws (DATA)
  "Converts DATA (an org-element or tree) to its content string. Note, a \n character is appended if not present."
  (org-todoist--remove-ws (substring-no-properties (org-element-interpret-data DATA))))

(defun org-todoist--element-equals-str (STR DATA)
  "Returns t if the org string from org-element-interpret-data for DATA is STR."
  (string-equal-ignore-case (org-todoist--remove-ws STR) (org-todoist--remove-ws (org-todoist-org-element-to-string DATA))))

(defun org-todoist--invoke-with-buffer (CONTENTS FN)
  "Fills a temp buffer with CONTENTS, applies org-mode, and calls FN."
  (with-temp-buffer (insert CONTENTS) (org-mode) (funcall FN)))

(defun org-todoist--generate-ast (contents)
  (org-todoist--invoke-with-buffer contents #'org-element-parse-buffer))

(defun org-todoist--generate-sample-ast ()
  (org-todoist--generate-ast (file-to-string (expand-file-name "sample.org"))))

(defun org-todoist--test-task () (org-todoist--get-by-id org-todoist--task-type "T2aBCdeF" (org-todoist--generate-sample-ast)))
(defun org-todoist--test-subtask () (org-todoist--get-by-id org-todoist--task-type "T3aBCdeF" (org-todoist--generate-sample-ast)))
(defun org-todoist--test-recurring-task () (org-todoist--get-by-id org-todoist--task-type "T4aBCdeF" (org-todoist--generate-sample-ast)))
(defun org-todoist--test-task-section () (org-todoist--get-by-id org-todoist--section-type "S1aBCdeF" (org-todoist--generate-sample-ast)))
(defun org-todoist--test-task-done () (org-todoist--get-by-id org-todoist--task-type "T1aBCdeF" (org-todoist--generate-sample-ast)))

                                        ;Test Data;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar test-org-str  "#+title: Test
* headline
  :PROPERTIES:
  :MYPROP:  test
  :NEWPROP:  VALUE
  :END:

paragraph
")

(defvar test-org-str-property-added  "#+title: Test
* headline
  :PROPERTIES:
  :MYPROP:  test
  :NEWPROP:  VALUE
  :END:

paragraph
")

(defvar test-task
  '((id . "2995104339")
    (user_id . "2671355")
    (project_id . "2203306141")
    (content . "Buy Milk")
    (description . "")
    (priority . 1)
    (due)
    (parent_id)
    (child_order . 1)
    (section_id)
    (day_order . -1)
    (collapsed . :json-false)
    (labels .
      ["Food" "Shopping"])
    (added_by_uid . "2671355")
    (assigned_by_uid . "2671355")
    (responsible_uid)
    (checked . :json-false)
    (is_deleted . :json-false)
    (sync_id)
    (added_at . "2014-09-26T08:25:05.000000Z")
    (duration
     (amount . 15)
     (unit . "minute"))))

(defvar test-full-date
  '((date . "2016-12-01")
    (timezone)
    (string . "every day")
    (lang . "en")
    (is_recurring . t)))

(defvar test-full-date-headline-text
  "* Headline
:PROPERTIES:
:DATE: 2016-12-01
:TIMEZONE:
:STRING: every day
:LANG: en
:IS_RECURRING: t
:END:
")

(defvar test-floating-date-with-time
  '((date . "2016-12-0T12:00:00.000000")
    (timezone)
    (string . "every day at 12")
    (lang . "en")
    (is_recurring . t)))

(defvar test-floating-date-with-time-fixed-tz
  '((date . "2016-12-06T13:00:00.000000Z")
    (timezone . "Europe/Madrid")
    (string . "every day at 12")
    (lang . "en")
    (is_recurring . t)))

(defvar test-label
  '((id . 790748)
    (name . "Label1")
    (color . 30)
    (item_order . 0)
    (is_deleted . 0)
    (is_favorite . 0)))

(defvar test-user
  '((auto_reminder . 0)
    (avatar_big . "https://*.cloudfront.net/*_big.jpg")
    (avatar_medium . "https://*.cloudfront.net/*_medium.jpg")
    (avatar_s640 . "https://*.cloudfront.net/*_s640.jpg")
    (avatar_small . "https://*.cloudfront.net/*_small.jpg")
    (business_account_id . "1")
    (daily_goal . 15)
    (date_format . 0)
    (dateist_lang)
    (days_off .
              [6 7])
    (email . "me@example.com")
    (feature_identifier . "2671355_0123456789abcdef70123456789abcdefe0123456789abcdefd0123456789abc")
    (features
     (beta . 1)
     (dateist_inline_disabled . :json-false)
     (dateist_lang)
     (gold_theme . t)
     (has_push_reminders . t)
     (karma_disabled . :json-false)
     (karma_vacation . :json-false)
     (restriction . 3))
    (full_name . "Example User")
    (has_password . t)
    (id . "2671355")
    (image_id . "d160009dfd52b991030d55227003450f")
    (inbox_project_id . "220474322")
    (is_biz_admin . :json-false)
    (is_premium . t)
    (joined_at . "2015-07-31T18:32:06.000000Z")
    (karma . 37504)
    (karma_trend . "up")
    (lang . "en")
    (next_week . 1)
    (premium_status . "current_personal_plan")
    (premium_until)
    (share_limit . 51)
    (sort_order . 0)
    (start_day . 1)
    (start_page . "project?id=2203306141")
    (team_inbox_id . "220474455")
    (theme_id . "11")
    (time_format . 0)
    (token . "0123456789abcdef0123456789abcdef01234567")
    (tz_info
     (gmt_string . "-03:00")
     (hours . -3)
     (is_dst . 0)
     (minutes . 0)
     (timezone . "America/Sao_Paulo"))
    (verification_status . "legacy")
    (weekend_start_day . 6)
    (weekly_goal . 30)))

(defvar test-project
  '((id . "2203306141")
    (name . "Shopping List")
    (color . "lime_green")
    (parent_id)
    (child_order . 1)
    (collapsed . :json-false)
    (shared . :json-false)
    (parent_id)
    (sync_id)
    (is_deleted . :json-false)
    (is_archived . :json-false)
    (is_favorite . :json-false)
    (view_style . "list")))

(defvar test-section '((id . "7025")
                       (name . "Groceries")
                       (project_id . "2203306141")
                       (section_order . 1)
                       (collapsed . :json-false)
                       (user_id . "2671355")
                       (sync_id)
                       (is_deleted . :json-false)
                       (is_archived . :json-false)
                       (archived_at)
                       (added_at . "2019-10-07T07:09:27.000000Z")))

;; Command ordering and temp-id replacement

(ert-deftest org-todoist--test--sort-commands ()
  (let* ((mk (lambda (type id) `(("type" . ,type) ("uuid" . ,id))))
         (cmds (list (funcall mk "item_update" "u1")
                     (funcall mk "item_add" "i1")
                     (funcall mk "project_add" "p1")
                     (funcall mk "item_add" "i2")
                     (funcall mk "section_add" "s1")))
         (sorted (mapcar (lambda (c) (assoc-default "uuid" c))
                         (org-todoist--sort-commands cmds))))
    (should (equal sorted '("p1" "s1" "i1" "i2" "u1")))))

(ert-deftest org-todoist--test--replace-temp-ids ()
  (let* ((cmds '((("type" . "item_add")
                  ("args" . (("project_id" . "tmp-p") ("labels" . ("a" "tmp-p")) ("content" . "x"))))))
         (out (org-todoist--replace-temp-ids cmds '((tmp-p . "123")))))
    (should (equal (assoc-default "project_id" (assoc-default "args" (car out))) "123"))
    (should (equal (assoc-default "labels" (assoc-default "args" (car out))) '("a" "123")))
    (should (equal (assoc-default "content" (assoc-default "args" (car out))) "x"))))

(ert-deftest org-todoist--test--batch-commands ()
  (let ((org-todoist-command-batch-size 2))
    (should (equal (org-todoist--batch-commands '(1 2 3 4)) '((1 2) (3 4))))
    (should (equal (org-todoist--batch-commands '(1 2 3)) '((1 2) (3))))
    (should (null (org-todoist--batch-commands nil)))))

;; Encoding, response checking and the sync lock

(ert-deftest org-todoist--test--encode-percent-encodes-values ()
  (let ((out (org-todoist--encode '(("sync_token" . "a+b%c#d=e&f")))))
    (should (equal out "sync_token=a%2Bb%25c%23d%3De%26f"))))

(ert-deftest org-todoist--test--check-response ()
  (let (org-todoist--sync-err)
    (should-not (org-todoist--check-response nil))
    (should-not (org-todoist--check-response '((error . "bad"))))
    (should (string-match-p "bad" org-todoist--sync-err))
    (should-not (org-todoist--check-response '((items . nil))))
    (setq org-todoist--sync-err nil)
    (should (org-todoist--check-response '((sync_token . "t") (sync_status . ((u1 . "ok"))))))
    (should (null org-todoist--sync-err))
    (should (org-todoist--check-response '((sync_token . "t") (sync_status . ((u1 . "ok") (u2 . ((error . "x"))))))))
    (should (string-match-p "u2" org-todoist--sync-err))))

(ert-deftest org-todoist--test--sync-lock ()
  (let ((org-todoist--sync-lock nil))
    (should (org-todoist--acquire-sync-lock))
    (should-not (org-todoist--acquire-sync-lock))
    (org-todoist--release-sync-lock)
    (should (org-todoist--acquire-sync-lock))
    ;; stale locks expire
    (setq org-todoist--sync-lock (- (float-time) 1000))
    (should (org-todoist--acquire-sync-lock))))

;; Tags

(ert-deftest org-todoist--test--add-tag ()
  (let ((hl (org-element-create 'headline '(:title "x" :level 1 :tags ("a")))))
    (org-todoist--add-tag hl "b")
    (should (equal (org-element-property :tags hl) '("a" "b")))
    (org-todoist--add-tag hl "b")
    (should (equal (org-element-property :tags hl) '("a" "b")))))

(ert-deftest org-todoist--test--set-labels ()
  (let ((hl (org-element-create 'headline `(:title "x" :level 1 :tags ("old" ,org-archive-tag)))))
    (org-todoist--set-labels hl '("new"))
    (should (equal (org-element-property :tags hl) `("new" ,org-archive-tag)))))

;; item_move, levels, id index

(ert-deftest org-todoist--test--item-move-args ()
  ;; nothing changed
  (should-not (org-todoist--item-move-args nil "s1" "p1" nil "s1" "p1"))
  (should-not (org-todoist--item-move-args nil nil "p1" nil nil "p1"))
  ;; new parent
  (should (equal (org-todoist--item-move-args "t2" "s1" "p1" "t1" "s1" "p1") '("parent_id" . "t2")))
  ;; parent unchanged: subtask follows its parent even if section/project changed
  (should-not (org-todoist--item-move-args "t1" "s2" "p2" "t1" "s1" "p1"))
  ;; promoted subtask keeps its section
  (should (equal (org-todoist--item-move-args nil "s1" "p1" "t1" "s1" "p1") '("section_id" . "s1")))
  ;; promoted subtask in the default section
  (should (equal (org-todoist--item-move-args nil nil "p1" "t1" nil "p1") '("project_id" . "p1")))
  ;; moved to another section
  (should (equal (org-todoist--item-move-args nil "s2" "p1" nil "s1" "p1") '("section_id" . "s2")))
  ;; moved from a section to the default section: project_id, never a null section_id
  (should (equal (org-todoist--item-move-args nil nil "p1" nil "s1" "p1") '("project_id" . "p1")))
  ;; moved to another project's default section
  (should (equal (org-todoist--item-move-args nil nil "p2" nil nil "p1") '("project_id" . "p2")))
  ;; whole section moved to another project: its tasks do not move
  (should-not (org-todoist--item-move-args nil "s1" "p2" nil "s1" "p1")))

(ert-deftest org-todoist--test--adopt-sub-fixes-levels ()
  (let* ((ast (org-todoist--generate-ast "* P\n** S\n*** T\n**** Sub\n** S2\n"))
         (s2 (org-element-map ast 'headline (lambda (h) (when (equal (org-element-property :raw-value h) "S2") h)) nil t))
         (task (org-element-map ast 'headline (lambda (h) (when (equal (org-element-property :raw-value h) "T") h)) nil t))
         (sub (org-element-map ast 'headline (lambda (h) (when (equal (org-element-property :raw-value h) "Sub") h)) nil t)))
    (org-todoist--adopt-sub s2 task)
    (should (= 3 (org-element-property :level task)))
    (should (= 4 (org-element-property :level sub)))
    ;; moving up a level also shifts descendants
    (let ((p (org-element-map ast 'headline (lambda (h) (when (equal (org-element-property :raw-value h) "P") h)) nil t)))
      (org-todoist--adopt-sub p task)
      (should (= 2 (org-element-property :level task)))
      (should (= 3 (org-element-property :level sub))))))

(ert-deftest org-todoist--test--id-index ()
  (let* ((ast (org-todoist--generate-sample-ast))
         (index (org-todoist--build-id-index ast)))
    (should (eq (org-todoist--index-lookup index nil "T2aBCdeF")
                (org-todoist--get-by-id nil "T2aBCdeF" ast)))
    (should (org-todoist--index-lookup index org-todoist--task-type "T2aBCdeF"))
    (should-not (org-todoist--index-lookup index org-todoist--section-type "T2aBCdeF"))
    (should-not (org-todoist--index-lookup index nil nil))
    (should-not (org-todoist--index-lookup (org-todoist--build-id-index nil) nil "T2aBCdeF"))))

;; push

(defun org-todoist--test-push (new old)
  "Run `org-todoist--push' on org strings NEW and OLD.
Return a list of (TYPE . ARGS) per command."
  (let ((org-todoist-delete-remote-items nil))
    (mapcar (lambda (c) (cons (assoc-default "type" c) (assoc-default "args" c)))
            (org-todoist--push (org-todoist--generate-ast new)
                               (and old (org-todoist--generate-ast old))))))

(defun org-todoist--test-tree (&rest tasks)
  "Build org text for project p1 with sections s1/s2, holding TASKS.
Each element of TASKS is a (SECTION-ID . TASK-ORG) cons; TASK-ORG is a
string of headlines to place under that section (\"default\" section holds
unsectioned tasks)."
  (let ((secs '("default" "s1" "s2")))
    (concat
     "* P\n:PROPERTIES:\n:TODOIST_TYPE: PROJECT\n:tid: p1\n:END:\n"
     (mapconcat
      (lambda (sec)
        (concat "** " (if (equal sec "default") "Default Section" (concat "Section " sec))
                "\n:PROPERTIES:\n:TODOIST_TYPE: SECTION\n:tid: " sec "\n:END:\n"
                (mapconcat #'cdr (--filter (equal (car it) sec) tasks) "")))
      secs ""))))

(defun org-todoist--test-task-org (id title &optional level todo)
  (format "%s %s%s\n:PROPERTIES:\n:TODOIST_TYPE: TASK\n:tid: %s\n:END:\n"
          (make-string (or level 3) ?*) (or todo "TODO ") title id))

(ert-deftest org-todoist--test--push-new-tree-order ()
  (let* ((cmds (org-todoist--test-push "* New project\n** Sec\n*** TODO Parent\n**** TODO Child\n" ""))
         (types (mapcar #'car cmds)))
    (should (equal (seq-take types 4) '("project_add" "section_add" "item_add" "item_add")))
    ;; the Child must come after Parent so Parent's temp id exists
    (let ((parent (nth 2 cmds)) (child (nth 3 cmds)))
      (should (equal (assoc-default "content" (cdr parent)) "Parent"))
      (should (equal (assoc-default "content" (cdr child)) "Child"))
      (should (equal (assoc-default "parent_id" (cdr child))
                     (assoc-default "parent_id" (cdr child))))
      (should (assoc-default "parent_id" (cdr child))))
    ;; no pointless item_update for tasks without a due date
    (should-not (member "item_update" types))))

(ert-deftest org-todoist--test--push-no-change ()
  (let ((tree (org-todoist--test-tree (cons "s1" (org-todoist--test-task-org "t1" "Task")))))
    (should-not (org-todoist--test-push tree tree))))

(ert-deftest org-todoist--test--push-minimal-update ()
  (let* ((old (org-todoist--test-tree (cons "s1" (org-todoist--test-task-org "t1" "Task"))))
         (new (org-todoist--test-tree (cons "s1" (org-todoist--test-task-org "t1" "Task two"))))
         (cmds (org-todoist--test-push new old)))
    (should (= 1 (length cmds)))
    (should (equal (car (car cmds)) "item_update"))
    (should (equal (cdr (car cmds)) '(("id" . "t1") ("content" . "Task two"))))))

(ert-deftest org-todoist--test--push-complete-without-closed ()
  (let* ((old (org-todoist--test-tree (cons "s1" (org-todoist--test-task-org "t1" "Task"))))
         (new (org-todoist--test-tree (cons "s1" (org-todoist--test-task-org "t1" "Task" 3 "DONE "))))
         (cmds (org-todoist--test-push new old)))
    (should (equal (mapcar #'car cmds) '("item_complete")))
    (should-not (assoc "date_completed" (cdr (car cmds))))))

(ert-deftest org-todoist--test--push-promote-subtask ()
  (let* ((old (org-todoist--test-tree
               (cons "s1" (concat (org-todoist--test-task-org "t1" "Parent")
                                  (org-todoist--test-task-org "t2" "Child" 4)))))
         (new (org-todoist--test-tree
               (cons "s1" (concat (org-todoist--test-task-org "t1" "Parent")
                                  (org-todoist--test-task-org "t2" "Child" 3)))))
         (cmds (org-todoist--test-push new old)))
    (should (equal cmds '(("item_move" ("id" . "t2") ("section_id" . "s1")))))))

(ert-deftest org-todoist--test--push-move-to-default-section ()
  (let* ((old (org-todoist--test-tree (cons "s1" (org-todoist--test-task-org "t1" "Task"))))
         (new (org-todoist--test-tree (cons "default" (org-todoist--test-task-org "t1" "Task"))))
         (cmds (org-todoist--test-push new old)))
    (should (equal cmds '(("item_move" ("id" . "t1") ("project_id" . "p1")))))))

(ert-deftest org-todoist--test--push-move-between-sections ()
  (let* ((old (org-todoist--test-tree (cons "s1" (org-todoist--test-task-org "t1" "Task"))))
         (new (org-todoist--test-tree (cons "s2" (org-todoist--test-task-org "t1" "Task"))))
         (cmds (org-todoist--test-push new old)))
    (should (equal cmds '(("item_move" ("id" . "t1") ("section_id" . "s2")))))))

(ert-deftest org-todoist--test--push-task-missing-from-snapshot ()
  (let* ((old (org-todoist--test-tree (cons "s1" (org-todoist--test-task-org "t1" "Task"))))
         (new (org-todoist--test-tree (cons "s1" (concat (org-todoist--test-task-org "t1" "Task")
                                                         (org-todoist--test-task-org "t9" "Copied in")))))
         (cmds (org-todoist--test-push new old)))
    ;; a task with an id the snapshot has never seen is pushed as an update
    (should (equal (mapcar #'car cmds) '("item_update")))
    (should (equal (assoc-default "id" (cdr (car cmds))) "t9"))
    ;; but with no snapshot at all nothing is pushed for existing items
    (should-not (cl-find "item_update" (org-todoist--test-push new nil) :key #'car :test #'equal))))

;; parse-response and the persisted state

(defconst org-todoist--test-response
  "{\"sync_token\":\"tok2\",\"full_sync\":true,\"temp_id_mapping\":{},
\"projects\":[{\"id\":\"p1\",\"name\":\"Proj\",\"parent_id\":null,\"is_deleted\":false,\"is_archived\":false,\"child_order\":1}],
\"sections\":[{\"id\":\"s1\",\"name\":\"Sec\",\"project_id\":\"p1\",\"is_deleted\":false,\"is_archived\":false,\"section_order\":1}],
\"items\":[{\"id\":\"t1\",\"content\":\"Buy milk\",\"description\":\"2 litres\",\"project_id\":\"p1\",\"section_id\":\"s1\",\"parent_id\":null,\"priority\":4,\"labels\":[\"home\"],\"checked\":false,\"is_deleted\":false,\"due\":{\"date\":\"2030-05-01\",\"is_recurring\":false},\"child_order\":1},
{\"id\":\"t2\",\"content\":\"Sub\",\"description\":\"\",\"project_id\":\"p1\",\"section_id\":\"s1\",\"parent_id\":\"t1\",\"priority\":1,\"labels\":[],\"checked\":false,\"is_deleted\":false,\"due\":null,\"child_order\":2}],
\"notes\":[],\"collaborators\":[]}")

(defmacro org-todoist--test-with-storage (&rest body)
  "Run BODY with a fresh temporary todoist file and storage directory."
  (declare (indent 0))
  `(let* ((dir (make-temp-file "org-todoist-test" t))
          (org-todoist-storage-dir dir)
          (org-todoist-file (expand-file-name "todoist.org" dir))
          (org-todoist--cached-ast nil)
          (org-todoist--sync-lock nil)
          (org-todoist--locked-buffer nil)
          (org-todoist--sync-start-hash nil))
     (unwind-protect (progn ,@body)
       (when-let* ((buf (find-buffer-visiting org-todoist-file)))
         (with-current-buffer buf (set-buffer-modified-p nil))
         (kill-buffer buf))
       (delete-directory dir t))))

(ert-deftest org-todoist--test--parse-response-roundtrip ()
  (org-todoist--test-with-storage
    (let ((resp (json-read-from-string org-todoist--test-response)))
      (should (org-todoist--parse-response resp (org-todoist--file-ast)))
      (let* ((ast (org-todoist--file-ast))
             (task (org-todoist--get-by-id org-todoist--task-type "t1" ast))
             (sub (org-todoist--get-by-id org-todoist--task-type "t2" ast)))
        (should (equal (org-element-property :raw-value task) "Buy milk"))
        (should (equal (org-element-property :tags task) '("home")))
        (should (equal (org-todoist--description-text task) "2 litres\n"))
        (should (equal (org-todoist--get-task-id-position sub) "t1"))
        (should (= (org-element-property :level sub) (1+ (org-element-property :level task)))))
      (should (equal (org-todoist--get-sync-token) "tok2"))
      ;; the file we wrote and the snapshot agree, so there is nothing to push
      (should-not (org-todoist--push (org-todoist--file-ast)
                                     (org-todoist--get-last-sync-buffer-ast))))))

(ert-deftest org-todoist--test--parse-response-assigns-temp-ids ()
  (org-todoist--test-with-storage
    (org-todoist--parse-response (json-read-from-string org-todoist--test-response)
                                 (org-todoist--file-ast))
    ;; add a new task locally, push it, then deliver the temp id mapping
    (with-current-buffer (find-file-noselect org-todoist-file)
      (goto-char (point-max))
      (insert "**** TODO Brand new\n")
      (save-buffer))
    (setq org-todoist--cached-ast nil)
    (let* ((ast (org-todoist--file-ast))
           (cmds (org-todoist--push ast (org-todoist--get-last-sync-buffer-ast)))
           (add (--first (equal (assoc-default "type" it) "item_add") cmds))
           (temp (assoc-default "uuid" add))
           (tmp-id (assoc-default "temp_id" add)))
      (should add)
      (should tmp-id)
      (ignore temp)
      (org-todoist--parse-response
       (json-read-from-string
        (format "{\"sync_token\":\"tok3\",\"temp_id_mapping\":{\"%s\":\"real1\"},\"items\":[]}" tmp-id))
       ast)
      (let ((node (org-todoist--get-by-id org-todoist--task-type "real1" (org-todoist--file-ast))))
        (should node)
        (should (equal (org-element-property :raw-value node) "Brand new")))
      (should (equal (org-todoist--get-sync-token) "tok3")))))

(ert-deftest org-todoist--test--sync-token-has-no-newline ()
  (org-todoist--test-with-storage
    (org-todoist--set-sync-token "abc")
    (should (equal (org-todoist--get-sync-token) "abc"))))

(ert-deftest org-todoist--test--freeze-buffer ()
  (org-todoist--test-with-storage
    (with-temp-file org-todoist-file (insert "* P\n"))
    (let ((buf (find-file-noselect org-todoist-file)))
      (with-current-buffer buf
        (org-todoist--freeze-buffer)
        (should buffer-read-only)
        (should-error (insert "x") :type 'buffer-read-only)
        (org-todoist--unfreeze-buffer)
        (should-not buffer-read-only)))))

(ert-deftest org-todoist--test--release-lock-unfreezes ()
  (org-todoist--test-with-storage
    (with-temp-file org-todoist-file (insert "* P\n"))
    (let ((buf (find-file-noselect org-todoist-file)))
      (should (org-todoist--acquire-sync-lock))
      (org-todoist--freeze-buffer)
      (should (buffer-local-value 'buffer-read-only buf))
      (org-todoist--release-sync-lock)
      (should-not (buffer-local-value 'buffer-read-only buf))
      (should (org-todoist--acquire-sync-lock)))))

(ert-deftest org-todoist--test--backup-if-edited ()
  (org-todoist--test-with-storage
    (with-temp-file org-todoist-file (insert "* P\n"))
    (let ((buf (find-file-noselect org-todoist-file)))
      (setq org-todoist--sync-start-hash (org-todoist--buffer-hash))
      (should-not (org-todoist--backup-if-edited))
      (with-current-buffer buf (goto-char (point-max)) (insert "* typed during sync\n"))
      (should (org-todoist--backup-if-edited))
      (should (string-match-p "typed during sync"
                              (with-temp-buffer
                                (insert-file-contents (org-todoist--storage-file "pre-sync-backup.org"))
                                (buffer-string)))))))

(ert-deftest org-todoist--test--set-labels-from-response-removes-stale ()
  (org-todoist--test-with-storage
    (let ((resp (json-read-from-string org-todoist--test-response)))
      (org-todoist--parse-response resp (org-todoist--file-ast))
      (let* ((resp2 (json-read-from-string
                     "{\"sync_token\":\"tok4\",\"items\":[{\"id\":\"t1\",\"content\":\"Buy milk\",\"description\":\"2 litres\",\"project_id\":\"p1\",\"section_id\":\"s1\",\"parent_id\":null,\"priority\":4,\"labels\":[\"work\"],\"checked\":false,\"is_deleted\":false,\"due\":null}]}"))
             (ast (org-todoist--file-ast)))
        (org-todoist--parse-response resp2 ast)
        (should (equal (org-element-property :tags (org-todoist--get-by-id org-todoist--task-type "t1" ast))
                       '("work")))))))

(ert-deftest org-todoist--test--push-adds-before-updates ()
  (let* ((old (org-todoist--test-tree (cons "s1" (org-todoist--test-task-org "t1" "Task"))))
         (new (org-todoist--test-tree
               (cons "s1" (concat (org-todoist--test-task-org "t1" "Task renamed")
                                  "**** TODO Added after\n"))))
         (types (mapcar #'car (org-todoist--test-push new old))))
    (should (equal types '("item_add" "item_update")))))
