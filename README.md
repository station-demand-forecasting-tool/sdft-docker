# Docker implementation of the Station Demand Forecasting Tool

A quick and easy install of the Station Demand Forecasting Tool on any modern operating system, using Docker.

It is assumed that you have Docker installed and running on a host computer. This could be a virtual machine in a cloud environment, such as Google Cloud, AWS, Microsoft Azure, or Digital Ocean. For testing purposes or a very simple model run (a single station) you could use your own computer, provided it has sufficient resources available.

We have had good results using a DigitalOcean CPU-Optimized virtual machine with 16 or 32 CPUs and using the Docker image created by DigitalOcean that's available in the Marketplace. DigitalOcean virtual machines are charged by the second (*whether running or not*), and the hourly charge for the CPU-Optimized 32 CPU VM is just under $1.00. For new users, [this link](https://m.do.co/c/86d69abc23ef) will get you a $100 (60-day) credit.

The Docker implementation consists of two containers:

1. An instance of Rstudio Server with all the required packages and dependencies installed, including the [sdft R package](https://github.com/station-demand-forecasting-tool/sdft).

2. An instance of PostgreSQL server with the PostGIS and pgRouting extensions installed, and all the database tables required by the model.

Images for these containers are published on the **GitHub Container Registry (GHCR)** under this repository. There is no need to clone this repository or generate the images yourself. Packages are public, so anonymous pull works without a GitHub login.

## Setup Instructions

1. Copy the [docker-compose.yml](https://raw.githubusercontent.com/station-demand-forecasting-tool/sdft-docker/master/docker-compose.yml) and [.env.example](https://raw.githubusercontent.com/station-demand-forecasting-tool/sdft-docker/master/.env.example) files from the repository to the host computer (place them in a directory called `sdft-docker`).

2. Copy `.env.example` to `.env` and set:

   - `POSTGRES_PASSWORD` — PostgreSQL superuser password
   - `PASSWORD` — RStudio Server password for user `rstudio`
   - `SDFT_HOST_DIR` — path on the ***host*** that will be bind-mounted to `/home/rstudio` in the UI container

   This folder is used to read model job inputs and write outputs. It must be readable and writeable by the `rstudio` user in the RStudio container (UID 1000). On Linux:

   ```bash
   mkdir /sdft/
   chown 1000 /sdft/
   ```

   Then set `SDFT_HOST_DIR=/sdft` in `.env`. On Windows, an example value is `c:/sdft`.

   **Maintainers:** prefer Doppler instead of a committed `.env`. Bind the project secrets, then run Compose via:

   ```bash
   doppler run -- docker compose up -d
   ```

3. Confirm the Compose file points at the GHCR tags you want (default `v2.0.0`):

   - `ghcr.io/station-demand-forecasting-tool/sdft-docker/sdft-db:v2.0.0`
   - `ghcr.io/station-demand-forecasting-tool/sdft-docker/sdft-ui:v2.0.0`

   Package pages:

   - [sdft-db packages](https://github.com/station-demand-forecasting-tool/sdft-docker/pkgs/container/sdft-docker%2Fsdft-db)
   - [sdft-ui packages](https://github.com/station-demand-forecasting-tool/sdft-docker/pkgs/container/sdft-docker%2Fsdft-ui)

4. In a terminal, change to your `sdft-docker` folder.

5. Run: `docker compose up -d`

6. The images will be pulled from GHCR and started if they are not already stored locally.

7. On successful completion you should see the network and both containers created (`sdft-db`, `sdft-ui`).

8. Connect to the RStudio server at [http://localhost:8787](http://localhost:8787). Log on with user `rstudio` and the password from your `.env` (or Doppler). If you are installing on a cloud VM, tunnel port 8787 or open it in the firewall as appropriate (by default, the DigitalOcean Docker Marketplace image may allow external access to `http://yourdropletipaddress:8787`).

9. On first start with an empty named volume, the PostgreSQL container creates the database and loads required tables and indexes. This can take 30–60 minutes and yields a database of around 10GB. Later stop/start cycles reuse the `pgdata` named volume. To reset the database, remove the Compose project’s `pgdata` volume after stopping the stack.

10. To watch init progress: `docker attach --sig-proxy=false sdft-db`. `Ctrl-C` detaches without stopping the container. When init finishes you will see PostgreSQL ready for connections (version string will match the current image base).

## Running a job

This provides brief instructions on running a job in testing mode. Please consult the [documentation](https://www.stationdemand.org.uk) for further information.

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

   You will first be asked to provide a password for the 'system' keyring. This is a new password and you can provide whatever you like here. You will then be prompted for the password to set for the "postgres" service. You should enter the same value as `POSTGRES_PASSWORD`.

6. You are now ready to submit the test job:

   ```r
   library(sdft)
   sdft_submit(dbhost = "sdft-db", dirpath = "/home/rstudio")
   ```

7. A log file, `sdr.log`, will be generated in the `/home/rstudio/output` folder and will be updated while the job runs.

8. When the job is complete, several files are created in a subfolder of the output folder. The subfolder takes the name of the job as specified in the `config.csv` file. The set of files, assuming you used the example input as provided, are as follows:

   * `station_forecast.csv` contains the model forecast (remember, this will not be a correct forecast when testing mode is used)
   * `exogenous.csv` contains a summary of the input exogenous data
   * `helst1_catchment.geojson` contains the postcode centroids for the station's probabilistic catchment, along with the probability of the station being chosen as an attribute to each centroid. A interpolated surface can be generated using QGIS to visualise the catchment.
   * `sdr.log` contains information on the job run. The level of detail will depend on the `loglevel` set in the `config.csv` file. This is set to DEBUG for the example test run.

## Getting help

To report an issue, bug, or to make a feature request, please [create an issue in this repository](https://github.com/station-demand-forecasting-tool/sdft-docker/issues).

## Further information

Please see the [full documentation](https://www.stationdemand.org.uk).
