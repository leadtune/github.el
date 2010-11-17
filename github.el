(defun github/repo-root (directory)
  "Gets the root directory"
  (cond
   ((file-directory-p (format "%s/.git" directory))
    directory)
   ((equal (directory-file-name directory) directory)
    (error "No .git directory found"))
   (t
    (github/repo-root (file-name-directory (directory-file-name directory))))))

(defun github/line-range-at-pos ()
  "returns the line-range if a region is selected, otherwise current line"
  (if (region-active-p)
             (format "%s-%s"
                     (save-excursion (goto-char (region-beginning))
                                     (line-number-at-pos))
                     (save-excursion (goto-char (region-end))
                                     (line-number-at-pos)))
           (format "%s" (line-number-at-pos))))

(defun github/get-config (key repo-root)
   (replace-regexp-in-string "\n"
                             ""
                             (shell-command-to-string (format "cd %S && git config %S" repo-root key))))

(defun github/last-commit-for-file (relative-file-name repo-root)
  (replace-regexp-in-string "\n"
                            ""
                            (shell-command-to-string
                             (format "cd %S && git rev-list HEAD --max-count 1 -- %S"
                                     repo-root
                                     relative-file-name))))

(defun github/reveal-in-browser ()
  "Opens the given revision/file/line in the browser"
  (interactive)
  (let* ((repo-root (github/repo-root (file-name-directory buffer-file-name)))
         (relative-file-name (replace-regexp-in-string (format "^%s/*" (regexp-quote repo-root))
                                                       ""
                                                       buffer-file-name))
         (revision (github/last-commit-for-file relative-file-name repo-root))
         (origin-url (github/get-config "remote.origin.url" repo-root))
         (github? (string-match "github.com[:/]\\(.+\\)\\.git" origin-url))
         (github-path (match-string 1 origin-url))
         (github-web-url (format "https://github.com/%s/blob/%s/%s#L%s"
                                 github-path
                                 revision
                                 relative-file-name
                                 (github/line-range-at-pos))))
    (if (not github?)
        (message "%s is not a github origin" origin-url)
      (shell-command
       (format "open %s"
               (replace-regexp-in-string
                " " "%20"
                github-web-url))))))

(provide 'github)
