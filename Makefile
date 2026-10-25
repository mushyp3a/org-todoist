# Dependency locations; override e.g. `make test DEPS=~/.emacs.d/elpa`
DEPS ?= $(HOME)/.config/emacs/.local/straight/repos
LOAD  = -L . $(foreach d,dash.el s.el ts.el,-L $(DEPS)/$(d))
EMACS ?= emacs

.PHONY: compile test clean

compile:
	$(EMACS) -Q --batch $(LOAD) --eval '(setq byte-compile-error-on-warn t)' -f batch-byte-compile org-todoist.el
	@rm -f org-todoist.elc

test:
	$(EMACS) -Q --batch $(LOAD) -l ert -l test.el -f ert-run-tests-batch-and-exit

clean:
	rm -f *.elc
