all: print_traversal

print_traversal: .traversal.tlc.ok
	@cat .traversal.tlc.out

.traversal.pcal.ok: traversal.tla
	@echo Translating PCal...
	@pcal traversal > .traversal.pcal.out 2>&1
	@if [[ -n "$$(egrep -i '(unrecoverable|error|expected)' .traversal.pcal.out)" ]]; then \
		cat .traversal.pcal.out && false; \
	else \
		touch .traversal.pcal.ok; \
	fi

.traversal.tlc.ok: .traversal.pcal.ok traversal.cfg
	@echo Running TLC...
	@tlc traversal > .traversal.tlc.out 2>&1
	@touch .traversal.tlc.ok

.PHONY: print_traversal
