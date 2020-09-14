# Docker implementation of the Station Demand Forecasting Tool

Quick and easy install of the Station Demand Forecasting Tool on any modern operating system, using Docker.

It is assumed that you have Docker installed on a host computer. This could be a virtual machine in a cloud environment, such as Google Cloud, AWS, Microsoft Azure, or Digital Ocean. For testing purposes or a very simple model run (a single station) you could use your own computer, provided it has sufficient resources available. 

I have had good results using a DigitalOcean CPU-Optimized virtual machine with 16 or 32 CPUs and using the Docker image created by DigitalOcean that's available in the Marketplace. DigitalOcean virtual machines are charged by the second (*whether running or not*), and the hourly charge for the CPU-Optimized 32 CPU VM is just under $1.00. For new users, [this link](https://m.do.co/c/86d69abc23ef) will get you a $100 (60-day) credit.

The Docker implementation consists of two containers:

1. An instance of Rstudio Server with all the required packages and dependencies installed, including the [sdft R package](https://github.com/station-demand-forecasting-tool/sdft).

2. An instance of PostgreSQL server with the PostGIS and pgRouting extensions installed, and all the database tables required by the model.

Images for these containers are available via the Docker Hub. There is no need to clone this repository or generate the images yourself.

## Setup Instructions

1. Copy the [docker-compose.yml](https://raw.githubusercontent.com/station-demand-forecasting-tool/sdft-docker/master/docker-compose.yml) file from the repository to the host computer (place it in a directory called sdft-docker). 

2. Edit `docker-compose.yml` and replace the two instances of `your_password` with a password of your choice. This will set the postgres user password and the rstudio user password.

3. Edit `docker-compose.yml` and amend the entry:  

   ```yaml
   volumes:
      - c:/sdft:/home/rstudio
   ```

   You should replace `c:/sdft` with the path to a suitable directory on the host computer. In the example above, it is a windows host and the location is `c:/sdft`. This folder will be used to read the input files for a model job. It will also be used to write the outputs from a model job. The location needs to be readable and writeable.

3. In terminal or command prompt change to your `sdft-docker` folder.

4. Run: `docker compose up -d`

5. The images will be downloaded from Docker Hub and inflated; if they are not already stored locally.

6. On successful completion you should see the following:  

   ```bash
   Creating network "sdft-docker_postgresql" with driver "bridge"
   Creating sdft-db ... done
   Creating sdft-ui ... done
   ```

7. You can now connect to the Rstudio server at [http://locahost:8787](http://localhost:8787). Logon with the user `rstudio` and the password you entered in `docker-compose.yml` earlier (if you are installing on a cloud-based VM then you will usually want to configure a tunnel in your SSH client to forward port 8787 on your local computer to port 8787 on your VM).

8. On the PostgreSQL container the database will now be created and the required tables and indexes generated. This process may take some time (perhaps 30-60 minutes). Due to the size of the database once fully generated (around 10GB), this is the most practical method of distribution. This process is only carried out the first time the sdft-db container is built. You can stop and start this container and the database will be preserved.

9. To check on progress, you can attach to the container by running: `docker attach  --sig-proxy=false sdft-db` from the command prompt or terminal. The `--sig-proxy=false` option allows you to use `ctrl-c` to detach from the container without stopping it. Once the database initialisation is complete, you will see the following (assuming you're still attached to the container):

   ```bash
   PostgreSQL init process complete; ready for start up.

    2020-09-14 13:44:12.985 UTC [1] LOG:  starting PostgreSQL 12.4 (Debian 12.4-1.pgdg100+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 8.3.0-6) 8.3.0, 64-bit
    2020-09-14 13:44:12.985 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
    2020-09-14 13:44:12.985 UTC [1] LOG:  listening on IPv6 address "::", port 5432
    2020-09-14 13:44:12.991 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
    2020-09-14 13:44:13.012 UTC [1457] LOG:  database system was shut down at 2020-09-14 13:44:12 UTC
    2020-09-14 13:44:13.018 UTC [1] LOG:  database system is ready to accept connections
    
   ```


## Running a job

This provides brief instructions on running a job in testing mode. Please consult the documentation for further information.

1. In your browser connect to the Rstudio server at [http://localhost:8787](http://localhost:8787).

2. Copy the example job submission CSV files from the SDFT R package to `/home/rstudio/input` by running:
   
   ```r
   dir.create("/home/rstudio/input")
   files <- list.files(file.path(system.file(package = "sdft"), "example_input"), full.names = TRUE)
   file.copy(from=files, to="/home/rstudio/input")
   ```

3. The example files will run a job in testing mode. The testing mode only considers a very small catchment area for a proposed station to speed up processing.

4. Edit `config.csv` and set the number of processor cores to be used for the job. As a minimum, 4 are required. Save the file.

5. Provide your password for the postgres user, using `key_set()` from the keyring package: 
   
   ```r
   library(keyring)
   key_set("postgres")
   ```
   
   When prompted, enter the password that you set earlier in the `docker-compose.yml` file.
   
6. You are now ready to submit the test job:

   ```r
   library(sdft)
   sdft_submit(dbhost = "sdft-db", dirpath = "/home/rstudio")
   ```
   
7. A log file, `sdr.log`, will be generated in the `/home/rstudio/output` folder and will be updated while the job runs.

8. When the job is complete, several files are created in a subfolder of the output folder. The subfolder takes the name of the job as specified in the `config.csv` file. The set of files, assuming you used the example input as provided, are as follows:
   
   * `station_forecast.csv` contains the model forecast
   * `exogenous.csv` contains a summary of the input exogenous data
   * `helst1_catchment.geojson` contains the postcode centroids for the station's probabilistic catchment, along with the probability of the station being chosen as an attribute to each centroid. A interpolated surface can be generated using QGIS to visualise the catchment.
   * `sdr.log` contains information on the job run. The level of detail will depend on the `loglevel` set in the `config.csv` file. This is set to DEBUG for the example test run.
   
## Further information

Please see the [full documentation](https://www.stationdemand.org.uk) (currently a work in progress).