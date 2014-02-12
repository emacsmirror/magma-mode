(require 'f)

(defvar magma-mode-support-path
  (f-dirname load-file-name))

(defvar magma-mode-features-path
  (f-parent magma-mode-support-path))

(defvar magma-mode-root-path
  (f-parent magma-mode-features-path))

(add-to-list 'load-path magma-mode-root-path)

(require 'espuds)
(require 'ert)


(Setup
 ;; Before anything has run
 ;;(setq condition-error-function )
 (setq magma-interactive-use-comint t)
 (setq magma-use-electric-newline t)
 (setq-default indent-tabs-mode nil)
 (setq magma-interactive-program
       (let ((ext (if (eq system-type 'windows-nt) ".bat" ".sh")))
       (f-join magma-mode-root-path "bin" (s-concat "dummymagma" ext))))
 (setq magma-completion-table-file (f-join magma-mode-root-path
                                           "data/dummymagma_symbols.txt"))
 (require 'magma-mode)
 (setq magma-delay "0.001")
)

(Before
 ;; Before each scenario is run
 )

(After
 ;; After each scenario is run
 )

(Teardown
 ;; After when everything has been run
 )

(Fail
 ;; After a scenario has failed
 )
