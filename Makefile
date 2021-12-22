SHELL := $(shell which bash)
.SHELLFLAGS := -euc
OUT := ./out
DEBUG := 0

# Files and directories

VENV_DIR := $(OUT)/venv
VENV := $(VENV_DIR)/bin/activate

## Typescript
TS_LIB := $(shell find . -name "*.lib.ts")
TS_MAIN := $(shell find . -name "*.main.ts")
TS := $(shell find . -name "*.ts")
DENO_DIR := $(OUT)/deno
TS_RADAMSA_TGTS := $(addprefix $(OUT)/,$(TS_MAIN:.main.ts=.radamsa.ts.log))

## All
SRC := $(TS)
INS := $(shell find . -name "*.in")
OUTS := $(shell find . -name "*.out")
TEST_DIRS := $(shell find praxis -mindepth 1 -type d)

# Executables

SEMGREP := semgrep
RADAMSA := radamsa

## Typescript
TSC := tsc
DENO := deno

# Flags

SEMGREP_CONFIG := semgrep.yaml
SEMGREP_FLAGS := --config p/ci --error --quiet --strict
SEMGREP_DIRS := praxis
RADAMSA_FLAGS :=
RADAMSA_TESTCASES := 64

## Typescript
TSC_FLAGS := \
  --alwaysStrict \
  --strict
DENO_ENV := \
  env \
  DEBUG=$(DEBUG) \
  DENO_DIR=$(DENO_DIR)
DENO_RUN_FLAGS := \
  --allow-env \
  --quiet

# Targets

DEPS := $(VENV_DIR)/requirements.log

## Typescript
TS_OUT := $(addprefix $(OUT)/,$(TS:=.out))
TS_JS := $(addprefix $(OUT)/,$(TS:=.js))
TS_FMT := $(addprefix $(OUT)/,$(TS:=.fmt.log))
TS_LINT := $(addprefix $(OUT)/,$(TS:=.lint.log))
TS_UNIT := $(addprefix $(OUT)/,$(TS_LIB:=.unit.log))
TS_TEST := $(addprefix $(OUT)/,$(INS:.in=.test.ts.log))

# All lines in each rule are passed to the shell as one command
.ONESHELL:

$(OUT): Makefile
	mkdir -p $(OUT)

$(VENV) $(VENV_DIR): $(OUT)
	virtualenv $(VENV_DIR)

$(VENV_DIR)/requirements.log: requirements.txt $(VENV) $(OUT)
	@echo "pip install -r requirements.txt"
	@./$(VENV_DIR)/bin/pip install -q -r requirements.txt |& tee "$@"

%.lib.ts: $(OUT)
	@touch "$@"

%.main.ts: %.lib.ts
	@touch "$@"

%.test.ts: %.lib.ts
	@touch "$@"

$(OUT)/%.ts.fmt.log: %.ts $(OUT)
	@mkdir -p "$(dir $@)"
	ts="$(filter %.ts,$^)"
	echo deno fmt "$$ts"
	$(DENO_ENV) $(DENO) fmt "$$ts" > "$@"

$(OUT)/%.ts.lint.log: %.ts $(OUT)
	@mkdir -p "$(dir $@)"
	ts="$(filter %.ts,$^)"
	echo deno lint "$$ts"
	$(DENO_ENV) $(DENO) lint "$$ts" > "$@"


$(OUT)/%.lib.ts.unit.log: %.test.ts $(OUT)
	@mkdir -p "$(dir $@)"
	ts="$(filter %.ts,$^)"
	echo deno test "$$ts"
	$(DENO_ENV) $(DENO) test $(DENO_RUN_FLAGS) "$$ts" |& tee "$@"

# This has overly-conservative dependencies, but... whatever.
$(OUT)/%.test.ts.log: %.out $(TS) $(INS) $(OUT)
	@mkdir -p "$(dir $@)"
	ts="$(shell dirname $<).main.ts"
	echo cat "$(<:.out=.in)" \| deno run "$$ts"
	cat "$(<:.out=.in)" | $(DENO_ENV) $(DENO) run $(DENO_RUN_FLAGS) "$$ts" > "$@.debug" || true
	cat "$@.debug" | grep -v DEBUG > "$@" || true
	difference=$$(diff -u "$<" "$@" || true)
	printf "%s\n" "$$difference" > "$@.diff"
	if [[ -n $$difference ]]; then
	  printf "Test failed: %s\n" "$<"
	  printf "Debug output: \n%s\n" "$$(cat $@.debug | grep DEBUG)"
	  printf "Expected:\n%s\n\n" "$$(cat $<)"
	  printf "Actual:\n%s\n\n" "$$(cat $@)"
	  printf "Diff:\n%s\n" "$$difference"
	fi

# TODO(lb): Construct a regex verifier for lines of output for each problem
$(OUT)/%.radamsa.ts.log: %.main.ts $(INS)
	@mkdir -p "$(dir $@)"
	ts="$<"
	d="$(<:.main.ts=)"
	mkdir -p "$(OUT)/$$d"
	for i in $$(seq 0 $(RADAMSA_TESTCASES)); do
	  $(RADAMSA) $(RADAMSA_FLAGS) "$$d"/*.in > "$(OUT)/$$d/radamsa-$$i"
	  echo cat "$(OUT)/$$d/$$i" \| deno run "$$ts"
	  cat "$(OUT)/$$d/radamsa-$$i" | $(DENO_ENV) $(DENO) run $(DENO_RUN_FLAGS) "$$ts" >> "$@" || true
	done

$(OUT)/%.ts.js: %.ts $(OUT)
	@mkdir -p "$(dir $@)"
	ts="$(filter %.ts,$^)"
	echo $(TSC) "$$ts"
	$(TSC) $(TSC_FLAGS) --outFile "$@" "$$ts"

$(OUT)/semgrep.log: $(SRC) $(OUT)
	@echo $(SEMGREP)
	$(SEMGREP) $(SEMGREP_FLAGS) $(SEMGREP_DIRS) |& tee "$@"

.PHONY: ts-fmt
ts-fmt: $(TS_FMT)

.PHONY: ts-lint
ts-lint: $(TS_LINT)

.PHONY: ts-unit
ts-unit: $(TS_UNIT)

.PHONY: ts-test
ts-test: $(TS_TEST)

.PHONY: typescript
typescript: ts-fmt ts-lint ts-unit ts-test

.PHONY: fmt
fmt: ts-fmt

.PHOHY: ts-radamsa
ts-radamsa: $(TS_RADAMSA_TGTS)

.PHONY: venv
venv: $(VENV)

.PHONY: deps
deps: $(DEPS)

.PHONY: semgrep
semgrep: $(OUT)/semgrep.log

.PHONY: lint
lint: ts-lint semgrep

.PHONY: unit
unit: ts-unit

.PHONY: test
test: ts-test

.PHOHY: radamsa
radamsa: ts-radamsa

.DEFAULT: all
.PHONY: all
all: fmt lint unit test radamsa

.PHONY: entr
entr:
	for f in Makefile $(SRC); do printf "%s\n" $$f; done | \
	  entr -c -s "$(MAKE) all"

.PHONY: clean-praxis
clean-praxis:
	rm -rf $(OUT)/praxis

.PHONY: clean
clean:
	rm -rf $(OUT)
