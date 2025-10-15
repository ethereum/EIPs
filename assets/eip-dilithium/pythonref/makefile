PY = python3
VENV = myenv
PIP = $(VENV)/bin/pip
PYTHON = $(VENV)/bin/python
AUX = *.pyc *.cprof */*.pyc

install:
	$(PY) -m venv $(VENV)
	$(PIP) install -r requirements.txt
	$(PIP) install -e "git+https://github.com/ZKNoxHQ/NTT.git@main#egg=polyntt&subdirectory=assets/pythonref/"

test:
	$(PYTHON) -m unittest $(if $(TEST),dilithium_py.tests.$(TEST),discover -s dilithium_py.tests) -v
	
example:
	$(PYTHON) -m dilithium_py.example
# 	$(PYTHON) -m dilithium_py.example_zk

generate_test_vectors:
	$(PYTHON) -m dilithium_py.generate_ethdilithium_test_vectors
	$(PYTHON) -m dilithium_py.generate_dilithium_test_vectors
	$(PYTHON) -m dilithium_py.generate_KAT_example
	$(PYTHON) -m dilithium_py.generate_sampleinball_keccak_test_vectors
	forge fmt
	
clean:
	rm -f $(AUX)
	find . -type d -name "__pycache__" -exec rm -rf {} +
	rm -rf scripts/*.sage.py
	@echo "Clean done"
