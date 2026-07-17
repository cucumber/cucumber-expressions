default: .deps
	mix format --check-formatted
	mix test
.PHONY: default

.deps: mix.exs
	mix deps.get
	touch $@

update-dependencies:
	mix deps.update --all
.PHONY: update-dependencies

clean:
	rm -rf _build deps .deps
.PHONY: clean
