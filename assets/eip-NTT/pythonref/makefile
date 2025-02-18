PY = python3
VENV = myenv
PIP = $(VENV)/bin/pip
PYTHON = $(VENV)/bin/python
AUX = *.pyc *.cprof */*.pyc

install:
	$(PY) -m venv $(VENV)
	$(PIP) install pycryptodome

generate_ntt_constants:
	$(PYTHON) -m polyntt.scripts.generate_ntt_constants

generate_test_vectors:
	$(PYTHON) -m polyntt.scripts.generate_test_vectors
	$(PYTHON) -m polyntt.scripts.generate_test_vectors_solidity

test: generate_test_vectors
	$(PYTHON) -m unittest $(if $(TEST),polyntt.tests.$(TEST),discover -s polyntt.tests) -v

bench:
	$(PYTHON) -m polyntt.bench_iterative_recursive
	
clean:
	rm -f $(AUX)
	rm -rf __pycache__ */__pycache__
	rm -rf scripts/*.sage.py
	@echo "Clean done"
