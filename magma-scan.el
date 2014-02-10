;;; magma-scan.el --- Scan magma input for completion candidates. ;

;; Copyright (C) 2007-2014 Luk Bettale
;;               2013-2014 Thibaut Verron
;; Licensed under the GNU General Public License.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;;; Commentary:

;; Documentation available in README.org or on
;; https://github.com/ThibautVerron/magma-mode

;;; Code:

(defvar-local magma-working-directory magma-default-directory)

(defun magma-scan-completion-file (file)
  (interactive)
  (with-temp-buffer
    (condition-case nil
        (insert-file-contents file)
      (error (message "The index file does not exist, so I cannot enable completion. Please see the comments to build it.")))
    (split-string (buffer-string) "\n" t)))

(defvar magma-scan-anonymous-temp-file (make-temp-file ".magmascan"))

(defconst magma-scan-defun-regexp "\\(function\\|procedure\\|intrinsics\\)[[:space:]]+\\(\\sw+\\)[[:space:]]*(")

(defun magma-scan-make-filename (file)
  "Make the name of the file holding the completion candidates
  for the file FILE"
  (if file
      (let* ((fullfile (f-long file))
             (path (f-dirname fullfile))
             (base (f-filename fullfile)))
        (f-join path (concat ".scan-" base ".el")))
    magma-scan-anonymous-temp-file))

(defun magma-scan-changedirectory-el (dir)
  "Elisp code to insert to perform a cd to DIR from the current directory held in magma-working-directory"
  (concat "(setq magma-working-directory (f-expand \"" dir "\" magma-working-directory))\n"))

(defun magma-scan-load-el (file)
  "Elisp code to insert to load the definitions from another file"
  (concat "(magma-load-or-rescan (f-expand \"" file "\" magma-working-directory))\n"))

(defun magma-scan-file (file outfile)
  "Scan the file file for definitions, and write the result into file OUTFILE."
  (write-region ";;; This file was generated automatically.\n\n" nil outfile)
  (let ((defs
         (with-temp-buffer
           (let ((magma-mode-hook nil))
             (magma-mode))
           (insert "\n")
           (insert-file-contents-literally file)
           (goto-char (point-min))
           
           ;; Get rid of the comments
           (comment-kill (count-lines (point-min) (point-max)))
           (goto-char (point-min))
           
           ;; And scan
           (setq moreLines t)
           (setq defs nil)
           
           (while moreLines
             (beginning-of-line)
             (cond
              ((looking-at "ChangeDirectory(\"\\(.*\\)\");")
               (write-region (magma-scan-changedirectory-el
                              (match-string-no-properties 1))
                             nil outfile t))
              ((looking-at "load \"\\(.*\\)\";")
               (let* ((file (match-string-no-properties 1)))
                 (write-region (magma-scan-load-el file)
                               nil outfile t)))
              ((looking-at magma-scan-defun-regexp)
               (setq defs
                     (-union (list (match-string-no-properties 2))
                             defs))
               )
              )
             (end-of-line) ;; So that forward-line really goes to the next line
             (setq moreLines (= 0 (forward-line 1))))
             defs)))
    (let ((defsline
            (concat "(setq magma-completion-table (-union '("
                    (-reduce-r-from
                     (apply-partially 'format "\"%s\" %s") "" defs)
                            ") magma-completion-table))\n")))
      (write-region defsline nil outfile t))))
    
(defun magma-load-or-rescan (file &optional forcerescan)
  "Load the completion file associated to file, rebuilding it if
  needed"
  (if (f-exists? file)
      (let ((loadfile (magma-scan-make-filename file)))
        (when (or forcerescan
                  (file-newer-than-file-p file loadfile))
          (magma-scan-file file loadfile))
        (load loadfile nil t))
    (magma--debug-message
     (format "Skipping nonexistent file %s" file))))

(defun magma-scan (&optional forcerescan)
  "Scan the current buffer for completions (unless it isn't needed)"
  (interactive "P")
  (magma-load-or-rescan (buffer-file-name) forcerescan)
  )

(provide 'magma-scan)

;;; magma-scan.el ends here
