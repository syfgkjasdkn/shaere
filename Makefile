# target: help - Display callable targets
help:
	@echo "This makefile assumes you have elixir installed ...\n"
	@echo "Available targets:"
	@egrep "^# target:" Makefile

# target: setup - sets up the project (fetches deps)
setup:
	- mix deps.get

# target: check - runs some checks on the project (ex_unit, dialyzer)
check:
	- mix test
	- mix dialyzer
