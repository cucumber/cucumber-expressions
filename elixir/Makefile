default: .deps
	mix format --check-formatted
	mix credo --strict
	mix dialyzer
	mix test --warnings-as-errors --cover
	mix docs
.PHONY: default

.deps: mix.exs
	mix deps.get
	touch $@

update-dependencies:
	mix deps.update --all
.PHONY: update-dependencies

clean:
	rm -rf _build deps doc cover .deps
.PHONY: clean
