DATA_ENV_DIR := .
PROJECT_DIR := $(notdir $(shell find . -type d -name 'app' -exec dirname {} \; | grep -v '/\.' | sort -u))
REMOTE_NAME := $(shell grep '^ *remote =' .dvc/config | awk -F'=' '{print $$2}' | tr -d ' \"')
CONDA_ENV := make_p122dvc347
MAKEFLAGS += --no-print-directory

.SILENT:
.ONESHELL:
.PHONY: review-process clean check-env setup-conda-env pull push info help

review-process: clean check-env

clean:
	@echo "## Cleaning current project"
	find . -name '*.pyc' -delete

check-env:
	@if [ "$$CONDA_DEFAULT_ENV" = "$(CONDA_ENV)" ]; then \
		echo "## Conda environment $(CONDA_ENV) successfully activated ✅"; \
	else \
		$(MAKE) setup-conda-env; \
	fi

setup-conda-env:
	@if conda env list | grep -q $(CONDA_ENV); then \
		echo "## Activating existing environment $(CONDA_ENV)"; \
		. $$(conda info --base)/etc/profile.d/conda.sh && conda activate $(CONDA_ENV); \
	else \
		echo "## Creating and activating environment $(CONDA_ENV)"; \
		conda create -y -n $(CONDA_ENV) python=3.12.2; \
		. $$(conda info --base)/etc/profile.d/conda.sh && conda activate $(CONDA_ENV); \
		conda run -n $(CONDA_ENV) pip install dvc==3.47.0 dvc-gs==3.0.1; \
	fi
	echo "## Conda environment $(CONDA_ENV) is ready and packages are installed ✅"

pull: review-process
	@echo "## Pulling data from bucket"
	conda run -n $(CONDA_ENV) dvc pull

push: review-process
	@echo "## Pushing data and weights to bucket"
	conda run -n $(CONDA_ENV) dvc add test.txt && \
	git add test.txt.dvc && \
	git commit -m "Weights added with dvc add command" && \
	conda run -n $(CONDA_ENV) dvc push && \
	git add test.txt.dvc && \
	git commit -m "Weights pushed with dvc push -r storage command"

info: review-process
	@echo "## Checking if DVC is available..."
	@conda run -n $(CONDA_ENV) which dvc
	@echo "## Executing dvc doctor command"
	@conda run -n $(CONDA_ENV) dvc doctor

help:
	@echo "Usage:"
	@echo "  make clean          - Clean the project from all compilable files."
	@echo "  make check-env      - Check if the required Conda environment is active, activate or create it if necessary."
	@echo "  make pull           - Pull data using DVC."
	@echo "  make push           - Push data and weights using DVC."
	@echo "  make info           - Run DVC doctor to check the setup."

# test-print-dir-name:
# 	@echo "The directory name is $(PROJECT_DIR)"

# test-print-remote-name:
# 	@echo "The bucket name is $(REMOTE_NAME)"
