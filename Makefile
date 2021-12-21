SHELL := $(shell which bash)
.SHELLFLAGS := -ec
OUT := ./out
DEBUG := 0

# Files and directories

## Typescript
TS_LIB := $(shell find . -name "*.lib.ts")
TS := $(shell find . -name "*.ts")
DENO_DIR := $(OUT)/deno

## All
SRC := $(TS)
INS := $(shell find . -name "*.in")
OUTS := $(shell find . -name "*.out")
TEST_DIRS := $(shell find praxis -mindepth 1 -type d)

# Executables

## Typescript
TSC := tsc
DENO := deno

# Flags

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

%.main.ts: %.lib.ts $(OUT)
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
	echo cat "$(<:.out=.in)" \| deno run $(DENO_RUN_FLAGS) "$$ts"
	cat "$(<:.out=.in)" | $(DENO_ENV) $(DENO) run $(DENO_RUN_FLAGS) "$$ts" > "$@.debug" || true
	cat "$@.debug" | grep -v DEBUG > "$@" || true
	if [[ $$(cat "$<") != $$(cat "$@") ]]; then
	  printf "Test failed: %s\n" "$<"
	  printf "Debug output: \n%s\n" "$$(cat $@.debug | grep DEBUG)"
	  printf "Expected:\n%s\n\n" "$$(cat $<)"
	  printf "Actual:\n%s\n\n" "$$(cat $@)"
	  printf "Diff:\n%s\n" "$$(diff $< $@)"
	fi

$(OUT)/%.ts.js: %.ts $(OUT)
	@mkdir -p "$(dir $@)"
	ts="$(filter %.ts,$^)"
	echo $(TSC) "$$ts"
	$(TSC) $(TSC_FLAGS) --outFile "$@" "$$ts"

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

.PHONY: lint
lint: ts-lint

.PHONY: unit
unit: ts-unit

.PHONY: test
test: ts-test

.DEFAULT: all
.PHONY: all
all: fmt lint unit test

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
