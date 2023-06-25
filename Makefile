.PHONY: build

DIRECTORY = $$(pwd)

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
	@echo "starting minikube...."
	@minikube config set cpus 4
	@minikube config set memory 5000
	@minikube start --mount --mount-string "$(DIRECTORY)"/:/usr/local/de-challenge --driver=docker

setup-airflow: start-minikube
	kubectl create namespace airflow
	kubectl apply -f airflow/manifests/logs-pvc.yaml -n airflow
	helm repo add apache-airflow https://airflow.apache.org
	helm repo update
	helm upgrade --install airflow apache-airflow/airflow -n airflow -f values.yaml

airflow-webserver:
	kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow

cleanup-airflow:
	@echo "WARNING: DELETES PODS, DB, SECRETS, SERVICES and VOLUMES."
	@echo "deleting airflow namespace"
	@minikube delete
