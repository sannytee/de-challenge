# DE Challenge

## Pre-requisites
* Python 3.7.2 or higher
* poetry
    ```shell
    curl -sSL https://install.python-poetry.org | python3 -
    ```
* docker
* hosted postgesql database. I'd recommend [elephantsql](https://www.elephantsql.com/) for this.
* minikube. you can install it using homebrew or binary download
    ```shell
    brew install minikube
    ```
    or
    ```shell
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
    sudo install minikube-darwin-amd64 /usr/local/bin/minikube
    ```


## System Requirements
In general, docker and minikube are going to be both CPU and memory intensive. So the more cores and memory you have, the better off  your experience will be.
* Ideal: 32GB RAM, 8+ cores
* Medium: 16GB RAM, 4 cores
* Masochist: 8GB RAM, 4 cores


## Setup Airflow
To ensure better development experience, Makefile is provided to help with common tasks.
1. Clone the repo
    ```shell
    git clone https://github.com/sannytee/de-challenge.git
   ```
2. cd into the project directory
    ```shell
    cd de-challenge
    ```
3. Install dependencies
    ```shell
    poetry update
    ```
4. Create .dbt directory in computer root folder
   ```shell
   mkdir ~/.dbt
   ```
   NOTE: You will get file Exists if directory exist
5. create a profiles.yml file. Need more info about this file? Check out the [dbt docs](https://docs.getdbt.com/docs/core/connect-data-platform/connection-profiles)
    ```shell
    touch ~/.dbt/profiles.yml
   ```
6. open the ~/.dbt/profiles.yml file and copy the content below to the file
    ```yaml
    instapro_dbt:
      outputs:
        dev:
          type: postgres
          threads: 2
          host: <postgres_host>
          port: 5432
          user: <postgres_user>
          pass: <postgres_pass>
          dbname: <postgres_dbname>
          schema: dev_user
        prod:
          type: postgres
          threads: 2
          host: <postgres_host>
          port: 5432
          user: <postgres_user>
          pass: <postgres_pass>
          dbname: <postgres_dbname>
          schema: prod
      target: dev
    ```
   NOTE:
   * Ensure the indentation matches the sample above
   * values with <> are to be replaced with the appropriate value
7. To set up and run airflow, run the following command
    ```shell
    make setup-airflow DBT_PROFILE_PATH=<path to dbt profile file> DB_CONN=<database connection string>
    ```
   Note:
   * DBT_PROFILE_PATH is the absolute path to the dbt profile file created earlier. This is required to run dbt commands within airflow.
   * DB_CONN is the connection string to the hosted database. The Connection string should be in the following format. VERY IMPORTANT
        ```shell
        <username>:<password>@<host>:<port>/<database>
        ```
     if you are using elephantsql, you can find the connection string in the details tab of your database.
   * Run the command below if you encounter this error: `Exiting due to GUEST_MOUNT_CONFLICT: Sorry, docker does not allow mounts to be changed after container creation`
     ```shell
     make cleanup-airflow
     ```
     The command deletes existing minikube installation. After this is done, You can retry the `make setup-airflow` command
   * Increase docker memory if you run into this error:
     `Exiting due to MK_USAGE`
8. Once airflow is up and running, enable port forwarding to access the airflow UI
    ```shell
    make airflow-webserver
    ```
    NOTE:
    * If you get this error: `error: unable to forward port because pod is not running. Current status=Pending`, just wait for a few minutes and retry
9. Now, you can access the airflow UI at http://localhost:8080. The default username and password is `admin`
10. On the DAGs page, you will see 3 dags with the format `events_pipeline_{schedule}` where schedule is the time interval the dag is scheduled to run.
11. Trigger the `events_pipeline_daily` to orchestrate the entire pipeline. This step should be done before playing around with dbt.

To tear down airflow, run the following command
```shell
make cleanup-airflow
```

## Setup DBT
1. Ensure you already have a profiles.yml file. more info about profiles.yml [here](https://docs.getdbt.com/docs/core/connect-data-platform/connection-profiles)
2. After creating the profiles.yml file, add the code below to file. Ensure they are properly indented
      ```yaml
      instapro_dbt:
        outputs:
          dev:
            type: postgres
            threads: 2
            host: <host>
            port: 5432
            user: <user>
            pass: <password>
            dbname: <database>
            schema: dev_user
          prod:
            type: postgres
            threads: 2
            host: <host>
            port: 5432
            user: <user>
            pass: <password>
            dbname: <database>
            schema: prod
        target: dev
      ```
      NOTE: replace host, user, password, database with the appropriate values
3. cd into the dbt directory
    ```shell
    cd instapro_dbt
    ```
4. run the command to verify that dbt is working correctly
    ```shell
    dbt debug
    ```

## Notes
### Database
postgresql is chosen as the database for this project. The reason for this is because of the following reasons:
1. scalability and performance: postgresql is designed to handle large amounts of data.This is possible due to indexing and partitioning.
With partitioning, data can be distributed across multiple servers. This allows for better performance and scalability.
Additionally, postgresql works well with other tools like apacha spark and kafka. This allows for better integration with other tools.
2. community support: postgresql has a large community. A benefit of this is that there are a lot of resources available online including community forums.

### Airflow
For this project, airflow is  deployed on minikube. It uses the kubernetesExecutor and deployment is done using helm.
The reason for using minikube is to ensure that the development environment is as close to production as possible.
Minikube also provides an interactive dashboard that can be used to monitor resources and utilization.

Also, the kubernetesExecutor allows for better resource management and isolation of tasks.

`KubernetesPodOperator` is used to run dbt commands. The `bashOperator` could have been used. However, this will require passing
a custom docker image that has dbt installed to the Kubernetes executor's base container by providing it to either
the pod_template_file or the pod_override key in the dictionary for the executor_config argument. The downside to that is
airflow must also be installed in the custom docker image. This will result in a large docker image. Hence, the use of
`KubernetesPodOperator` is preferred.

### DBT
DBT is used as the transformation tool for this project. The choice of dbt is because of the following reasons:

* data consistency: dbt allows for the creation of tests that can be used to ensure data consistency.
* scalability: dbt is designed to handle large amounts of data. By specifying the number of threads to use, dbt can be scaled to handle large amounts of data.
* modularity: dbt macros allows for abstraction of common tasks and can be reused across projects.
* extensibility: dbt allows for the creation of custom macros and packages that can be used across projects.

### Changes for production use
This project is designed to be used in a local development environment. However, with a few changes, it can be used in a production environment.
some changes that can be made are:

* use incremental models for models that tends to have large amounts of data. An example of such models is the `availability_snapshot` model.
* configure dbt target  to select either prod or dev based on the environment.
* Use a managed kubernetes service like EKS or GKE instead of minikube.

