.PHONY: build

DIRECTORY = $$(pwd)
DBT_PROFILE_PATH = "default"

.DEFAULT: help
help:
	@echo "\n \
	------------------------------ \n \
	++ Airflow Related ++ \n \
	setup-airflow: set up the necessary infrastructure  to run airflow project. \n \
	airflow-webserver: Spin up airflow webserver . \n \
	\n \
	++ Utilities ++ \n \
	cleanup-airflow: WARNING: DELETES PODS, DB, SECRETS, SERVICES and VOLUMES. \n \
	------------------------------ \n"

start-minikube:
	@if ! [ -f "$(DIRECTORY)/manifests/secrets.yaml" ]; then echo "secrets.yaml file is required" && exit 1; fi;
	@if [ "$(DBT_PROFILE_PATH)" = "default" ]; then echo "PATH to dbt profile is required" && exit 1; fi;
	@echo "copying dbt profile to project directory"
	@cp "$(DBT_PROFILE_PATH)" "$(DIRECTORY)/instapro_dbt"
	@echo "starting minikube...."
	@minikube config set cpus 4
	@minikube config set memory 5000
	@minikube start --mount --mount-string "$(DIRECTORY)"/:/usr/local/de-challenge --driver=docker


setup-airflow: start-minikube
	kubectl create namespace airflow
	kubectl apply -f manifests/logs-pvc.yaml -n airflow
	kubectl apply -f manifests/secrets.yaml -n airflow
	helm repo add apache-airflow https://airflow.apache.org
	helm repo update
	helm upgrade --install airflow apache-airflow/airflow -n airflow -f manifests/values.yaml

airflow-webserver:
	kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow

cleanup-airflow:
	@echo "WARNING: DELETES PODS, DB, SECRETS, SERVICES and VOLUMES."
	@echo "deleting airflow namespace"
	@minikube delete
