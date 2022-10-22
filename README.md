# Play With Cortex

[Cortex](https://github.com/cortexproject/cortex) is a distributed, horizontally scalable, and highly available long term storage for Prometheus.

This lessons will help you to learn Cortex step by step like playing a game. thanks to [play-with-mimir](https://github.com/grafana/mimir/tree/main/docs/sources/tutorials/play-with-grafana-mimir) for this idea.

## Prerequisites

- Git
- Docker and Docker Compose
- Availability of both ports 9000、9002、9090、3000、8001～8003 on your host machine

## Download resources

1. Clone repo to your local with git

```
git clone https://github.com/tsclub/play-with-cortex.git
```

2. Change to specific lesson

```
cd play-with-cortex
git fetch origin 
git checckout lesson1 // or change to other lesson{number}
docker-compose up -d
```

3. Release all Docker resources after test

```
docker-compose down
```

## Step by step

### Lesson 1

Start running your local setup with the following Docker command:

```
git checkout lesson1
docker-compose up -d
```

This command starts:

- Cortex
    - Three instances of monolithic-mode Cortex to provide high availability
    - Multi-tenancy enabled (tenant ID is demo)
- Minio
    - S3-compatible persistent storage for blocks, rules, and alerts.
- Prometheus
    - Scrapes all Cortex metrics, then writes them back to Cortex to ensure availability of ingested metrics.
- Grafana
    - Includes a preinstalled datasource to query Cortex.
    - Includes preinstalled dashboards for monitoring Cortex.
- Load balancer
    - A simple NGINX-based load balancer that exposes Cortex endpoints on the host.

The diagram will like:

![diagram](./images/diagram.png)

The following ports will be exposed on the host:

- Grafana on [http://localhost:3000](http://localhost:3000)
- Cortex on [http://localhost:8001~8003](http://localhost:8001)
- Minio on [http://localhost:9002](http://localhost:9002), super account is `cortex/supersecret`
- Prometheus on [http://localhost:9090](http://localhost:9090)

### Lesson 2

In this Lesson, you'll learn how to use Cortex distributor's HATracker.

You can run test with command:

```
git checkout lesson2
docker-compose up -d
```

When you visit [http://localhost:8001/distributor/ha_tracker](http://localhost:8001/distributor/ha_tracker), you will see HATracker workes.

![ha_tracker.png](./images/ha_tracker.png)

If you stop `prometheus-2`, about 30s later it will auto change master to `prometheus-1`.

#### Details about the change

Change `cortex.yaml` to enable HATracker

```
limits:
  accept_ha_samples: true

distributor:
    ha_tracker:
    enable_ha_tracker: true
    kvstore:
        store: consul
        consul:
        host: consul:8500
```

Note: HATracker's KV store only support consul and etcd, so we use consul here.

Update `docker-compose.yaml` to add consul dependence.

```
services:
  consul:
    image: consul
    command: [ "agent", "-dev" ,"-client=0.0.0.0", "-log-level=info" ]
    ports:
      - 8500:8500
```

We need another Prometheus like existed one

```
 prometheus-2:
    image: prom/prometheus:v2.39.1
    command: ["--config.file=/etc/prometheus/prometheus.yaml", "--enable-feature=expand-external-labels", "--log.level=debug"]
    environment:
      PODNAME: prometheus-2
    volumes:
      - ./config/prometheus:/etc/prometheus
      - data-prometheus-2:/prometheus
    ports:
      - 9091:9090
```

And add `ha_cluster_label` and `ha_replica_label` labels to `prometheus.yaml`

```
global:
  external_labels:
    cluster: demo
    __replica__: ${PODNAME} 
```

Note: `ha_cluster_label` default value is `cluster`, `ha_replica_label` is `__replica__`. you can configurate to another with `limits_config`.