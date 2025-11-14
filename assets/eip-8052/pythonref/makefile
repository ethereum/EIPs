PY = python3
VENV = myenv
PIP = $(VENV)/bin/pip
PYTHON = $(VENV)/bin/python
AUX = *.pyc *.cprof */*.pyc

install:
	$(PY) -m venv $(VENV)
	$(PIP) install eth_abi pandas pycryptodome scipy matplotlib 
	$(PIP) install -e "git+https://github.com/ZKNoxHQ/NTT.git@main#egg=polyntt&subdirectory=assets/pythonref/"

test:
	$(PYTHON) test.py
	$(PYTHON) -m unittest discover -v
	

bench:
	$(PYTHON) -m bench_signature -v

test_keccak_prng:
	$(PYTHON) -m unittest test_keccak_prng -v

test_blake2s_prng:
	$(PYTHON) -m unittest test_blake2s_prng -v

test_keccak:
	$(PYTHON) -m unittest test_keccak -v
 
test_shake:
	$(PYTHON) -m unittest test_shake -v

test_falcon:
	$(PYTHON) -m unittest test_falcon -v

test_falcon_kat:
	$(PYTHON) -m unittest test_falcon_KAT -v

test_recovery_mode:
	$(PYTHON) -m unittest test_falcon_recovery -v

test_epervier:
	$(PYTHON) -m unittest test_falcon_epervier -v

generate_test_vectors:
	$(PYTHON) -m generate_falcon_test_vectors -v
	$(PYTHON) -m generate_epervier_test_vectors -v
	$(PYTHON) -m generate_hashtopoint_test_vectors -v
	$(PYTHON) -m generate_delegate -v
	$(PYTHON) -m generate_falcon_core_test_vectors -v
	forge fmt

generate_hash_test_vectors:
	$(PYTHON) -m generate_hashtopoint_test_vectors -v
	forge fmt

profile:
	rm -f $(AUX)
	rm -rf __pycache__
	touch profile_action.cprof
	$(PY) -m cProfile -o profile_action.cprof profile_action.py
	pyprof2calltree -k -i profile_action.cprof &

clean:
	rm -f $(AUX)
	find . -type d -name "__pycache__" -exec rm -rf {} +
	rm -rf scripts/*.sage.py
	@echo "Clean done"
