;;; moonbit-ts-mode.el --- a moonbit major mode -*- lexical-binding:t; -*-

;; Copyright (C) 2024-present CHEN Xian'an (a.k.a `realazy').
;; Copyright (C) 2025 include-yy <yy@egh0bww1.com>

;; Author: realazy <xianan.chen@gmail.com>
;; Maintainer: realazy <xianan.chen@gmail.com>
;; Maintainer: include-yy <yy@egh0bww1.com>

;; Package-Version: 0.1.0
;; Package-Requires: ((emacs "31.0"))
;; Keywords: languages
;; URL: https://github.com/include-yy/moonbit-ts-mode
;; ORIG-URL: https://github.com/cxa/moonbit-mode

;; SPDX-License-Identifier: GPL-3.0-or-later

;; Moonbit-ts-mode is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; Moonbit-ts-mode is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with moonbit-ts-mode.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides major modes for MoonBit.

;;; Code:

(defgroup moonbit-ts-mode nil
  "Support for MoonBit code."
  :tag "MoonBit"
  :group 'languages)

(defface t-alt-type-face
  '((t . (:inherit font-lock-preprocessor-face)))
  "Face for 2nd consecutive type to distinguish the 1st one,
e.g. `Int' in `type UserId Int'."
  :group 'moonbit)

;; TODO: for, import, extern, interface, derive?
(defvar t--keywords
  '("if" "while" "break" "continue" "return" "match" "else" "as" "loop" "test"
    "fn" "type" "let" "mut" "enum" "struct"  "trait" "pub" "priv"
    "readonly")
  "MoonBit keywords.")

(defvar t--operators
  '((pipe_operator) "*" "/" "%" "+" "-" ">" ">=" "<=" "<" "==" "!=" "=" "+=" "-=" "*=" "/=")
  "MoonBit operators.")

(defvar t--font-lock-rules
  `( :language moonbit
     :feature comment
     ([(comment) (docstring)] @font-lock-comment-face)

     :language moonbit
     :feature literal
     ((boolean_literal) @font-lock-constant-face
      [(float_literal) (integer_literal)] @font-lock-number-face
      ;; TODO: only highlight char inside ''
      (char_literal) @font-lock-string-face
      (byte_literal
       ["b'" "'"] @font-lock-comment-face)
      (byte_literal
       ;; TODO: wait for moonbit-treesit to support non escape sequence
       (escape_sequence) @font-lock-string-face))

     :language moonbit
     :feature string
     ((string_fragment) @font-lock-string-face
      ;; TODO: multiline_string_separator
      (multiline_string_fragment) @font-lock-string-face
      (interpolator
       "\\(" @font-lock-misc-punctuation-face
       ")" @font-lock-misc-punctuation-face))

     :language moonbit
     :feature keyword
     ([,@moonbit--keywords] @font-lock-keyword-face)

     :language moonbit
     :feature bracket
     (["(" ")" "[" "]" "{" "}"] @font-lock-bracket-face)

     :language moonbit
     :feature delimiter
     ([(dot_operator) (colon) (colon_colon) ","] @font-lock-delimiter-face)

     :language moonbit
     :feature operator
     ([,@moonbit--operators] @font-lock-operator-face)

     :language moonbit
     :feature indentifier
     (;; lowercase
      (lowercase_identifier) @font-lock-variable-name-face
      (qualified_identifier
       (lowercase_identifier) @font-lock-variable-use-face)
      (package_identifier) @font-lock-constant-face
      (labeled_identifier) @font-lock-variable-name-face
      ;; top level `let' consider as constant
      (value_definition
       (lowercase_identifier) @font-lock-constant-face)
      (apply_expression
       (simple_expression
        (qualified_identifier
         (lowercase_identifier) @font-lock-function-call-face)))
      ;; for pipe function without args
      (binary_expression
       (pipe_operator)
       (expression
        (simple_expression
         (qualified_identifier
          (lowercase_identifier) @font-lock-function-call-face))))
      
      ;; uppercase
      (uppercase_identifier) @font-lock-type-face
      ;; make constructor alternative
      (enum_constructor (uppercase_identifier) @moonbit-alt-type-face)
      (constructor_expression (uppercase_identifier) @moonbit-alt-type-face)
      ;; for `B' in `type A B'
      (type_definition
       (type 
        (apply_type
         (qualified_type_identifier) @moonbit-alt-type-face))))))

(defvar t--treesit-indent-rules
  `((moonbit
     ((parent-is "structure") column-0 0)
     ((node-is "}") parent-bol 0)
     ((node-is ")") parent-bol 0)
     ((node-is "]") parent-bol 0)
     ((parent-is ,(rx (one-or-more letter) (or "_definition" "_expression")))
      parent-bol tab-width)
     ((parent-is "multiline_string_literal") parent-bol 0))))

(defun t--treesit-defun-name (node)
  "Return the defun name of NODE.
Return nil if there is no name or if NODE is not a defun node."
  (treesit-node-text
   (treesit-node-child node 1)))

(defun t--setup ()
  "Setup treesit."
  (treesit-parser-create 'moonbit)
  ;; Fontification
  (setq-local treesit-font-lock-feature-list
              '(( comment literal string 
                  keyword bracket delimiter operator indentifier)))
  (setq-local treesit-font-lock-settings
              (apply #'treesit-font-lock-rules moonbit--font-lock-rules))
  ;; Indent
  (setq-local treesit-simple-indent-rules moonbit--treesit-indent-rules)
  ;; Navigation
  (setq-local treesit-defun-type-regexp
              (rx (or "function_definition" "anonymous_lambda_expression"
                      "named_lambda_expression")))
  ;; Imenu
  (setq-local treesit-defun-name-function #'moonbit--treesit-defun-name)
  (setq-local treesit-simple-imenu-settings
              `(("Function" "\\`function_definition\\'" nil nil)
                ("Value" "\\`value_definition\\'" nil nil)
                ("Enum" "\\`enum_definition\\'" nil nil)
                ("Struct" "\\`struct_definition\\'" nil nil)
                ("Newtype" "\\`type_definition\\'" nil nil)))
  (treesit-major-mode-setup))

(define-derived-mode moonbit-ts-mode prog-mode "MoonBit"
  "Major mode for editing MoonBit."
  (when (treesit-ready-p 'moonbit)
    (moonbit-mode--ts-setup)))

(add-to-list 'auto-mode-alist '("\\.mbt\\'" . moonbit-ts-mode))

(provide 'moonbit-ts-mode)

;;; moonbit-mode.el ends here

;; Local Variables:
;; read-symbol-shorthands: (("t-" . "moonbit-ts-mode-"))
;; End:
