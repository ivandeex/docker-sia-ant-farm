# Docker Sia Ant Farm

[Sia Ant Farm](https://gitlab.com/NebulousLabs/Sia-Ant-Farm) in a Docker container.

## Running Ant Farm in Docker container

### Basic Execution
To start Ant Farm with default configuration
(`config/basic-renter-5-hosts-docker.json`) execute:
```
docker run \
	--publish 127.0.0.1:9980:9980 \
	nebulouslabs/siaantfarm
```
Port `127.0.0.1:9980` above is the renter API address which you can use to
issue commands to the renter. For security reasons you should bind the port to
localhost (see `127.0.0.1:9980` above)

### Change Port
To change port on which you can access the renter (e.g. to 39980) execute:
```
docker run \
	--publish 127.0.0.1:39980:9980 \
	nebulouslabs/siaantfarm
```

### Custom Configuration
By default the Sia Ant Farm docker image has a copy of
`config/basic-renter-5-hosts-docker.json` configuration file.

If you want to execute Ant Farm with a custom configuration, create your custom
configuration e.g. `config/custom-cfg.json`, mount your config directory and
set `CONFIG` environment variable to your custom configuration by executing:
```
docker run \
	--publish 127.0.0.1:9980:9980 \
    --volume $(pwd)/config:/sia-antfarm/config \
    --env CONFIG=config/custom-config.json \
	nebulouslabs/siaantfarm
```

### Persistent Ant Farm Data
There are several ways how to persist Ant Farm data. One way would be to create
local `antfarm-data` directory and mount it the following way:
```
docker run \
	--publish 127.0.0.1:9980:9980 \
    --volume $(pwd)/antfarm-data:/sia-antfarm/antfarm-data \
	nebulouslabs/siaantfarm
```
```