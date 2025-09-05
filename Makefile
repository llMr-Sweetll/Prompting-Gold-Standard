# Prompting-Gold-Standard Quickstart Makefile
# Usage examples:
#   make rag PROVIDER=openai MODEL=gpt-4o-mini
#   make paper PROVIDER=anthropic TOPIC="Productivity impacts of remote work"
#   make analysis DATASET=dataset.md
#   make kb PROVIDER=azure SOURCES=sources.txt

SHELL := /bin/bash

SCRIPTS_DIR := Examples/quickstarts
PROVIDER ?= openai
MODEL ?=
CTX ?=
Q ?=
TOPIC ?=
DATASET ?=
SOURCES ?=

.PHONY: help rag paper analysis kb

help:
	@echo "Targets: rag, paper, analysis, kb"
	@echo "Variables: PROVIDER (openai|anthropic|azure|ollama), MODEL, CTX, Q, TOPIC, DATASET, SOURCES"
	@echo "Examples:"
	@echo "  make rag PROVIDER=openai MODEL=gpt-4o-mini"
	@echo "  make paper PROVIDER=openai TOPIC='Productivity impacts of remote work'"
	@echo "  make analysis DATASET=dataset.md"
	@echo "  make kb PROVIDER=anthropic SOURCES=sources.txt"

rag:
	bash $(SCRIPTS_DIR)/run_rag.sh --provider=$(PROVIDER) $(if $(MODEL),--model=$(MODEL),) $(if $(CTX),--context=$(CTX),) $(if $(Q),--question=$(Q),)

paper:
	@if [ -z "$(TOPIC)" ]; then echo "TOPIC is required, e.g., make paper TOPIC='Your topic'"; exit 1; fi
	bash $(SCRIPTS_DIR)/run_paper.sh --provider=$(PROVIDER) $(if $(MODEL),--model=$(MODEL),) --topic="$(TOPIC)" $(if $(CTX),--context=$(CTX),)

analysis:
	bash $(SCRIPTS_DIR)/run_analysis.sh --provider=$(PROVIDER) $(if $(MODEL),--model=$(MODEL),) $(if $(DATASET),--dataset=$(DATASET),)

kb:
	bash $(SCRIPTS_DIR)/run_kb.sh --provider=$(PROVIDER) $(if $(SOURCES),--sources=$(SOURCES),)

