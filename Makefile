setup:
	- mix deps.get

check:
	- mix test
	- mix dialyzer
