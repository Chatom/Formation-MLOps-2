SHELL := /bin/bash
.SHELLFLAGS = -ec
.ONESHELL:
.SILENT:

.EXPORT_ALL_VARIABLES:
REPO_DIRECTORY:=$(shell pwd)
AIRFLOW_HOME?=${REPO_DIRECTORY}/airflow
PYTHONPATH:=${PYTHONPATH}:${REPO_DIRECTORY}

.PHONY: help
help:
	echo "❓ Utiliser \`make <target>' où <target> peut être"
	grep -E '^\.PHONY: [a-zA-Z0-9_-]+ .*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = "(: |##)"}; {printf "\033[36m%-30s\033[0m %s\n", $$2, $$3}'

.PHONY: conda-env  ## 🐍 créé l'environnement conda python_indus_avancee, et le récréé s'il existe déjà
conda-env:
	conda create -yqf --name python_indus_avancee

.PHONY: dependencies  ## ⏬ installe les dépendances de production
dependences:
	pip install -r requirements.txt

.PHONY: dependences-de-test  ## 🧪 installe toutes les dépendances, y compris celles de test
dependences-de-test:
	$(MAKE) dependencies && pip install -r requirements_test.txt && pip install -e .

.PHONY: tests  ## ✅ lance tous les tests
tests:
	$(MAKE) tests-unitaires && $(MAKE) tests-fonctionnels

.PHONY: tests-unitaires  ## ✅ lance les tests unitaires
tests-unitaires:
	python -m pytest --cov=formation_indus_ds_avancee/ tests/test_unit/ -vv -p no:warnings

.PHONY: tests-fonctionnels  ## ✅ lance les tests fonctionnels
tests-fonctionnels:
	python -m behave tests/test_functional/features

.PHONY: distribution  ## 📦 crée le package au format wheel
distribution:
	python3 setup.py sdist bdist_wheel

.PHONY: instructions  ## 📄 Génère les instructions de TPs au format codelabs
instructions:
	$(MAKE) -C TP_instructions/ instructions

.PHONY: dataset  ## 🔽 télécharge les données et les dézippe dans le dossier data/
dataset:
	curl -L https://opendata-renewables.engie.com/media/datasets/01c55756-5cd6-4f60-9f63-2d771bb25a1a.zip \
		-o data/la-haute-borne-data-2017-2020.zip
	unzip data/la-haute-borne-data-2017-2020.zip -d data/
	rm data/la-haute-borne-data-2017-2020.zip

.PHONY: airflow-setup  ## 💨  Initialize airflow backend: initdb > variables > connections
airflow-setup:
	echo "AIRFLOW_HOME is: ${AIRFLOW_HOME}"
	airflow initdb

.PHONY: airflow-webserver  ## 🌐  Run airflow web server
airflow-webserver:
	echo "AIRFLOW_HOME is: ${AIRFLOW_HOME}"
	airflow webserver --port 8080

airflow-scheduler:
	echo "AIRFLOW_HOME is: ${AIRFLOW_HOME}"
	airflow scheduler
