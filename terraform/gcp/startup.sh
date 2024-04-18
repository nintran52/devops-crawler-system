#!/bin/bash
# Docker
curl -fsSL https://get.docker.com/ | sh
sudo usermod -aG docker ubuntu
cd /home/ubuntu
git clone https://github.com/hoalongnatsu/crawler-demo.git && cd crawler-demo
docker network create crawler
docker compose -f docker-compose-server.yaml up -d
curl -sOL https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh
chmod +x wait-for-it.sh
./wait-for-it.sh -t 0 localhost:5432 -- echo "postgres up"
./wait-for-it.sh -t 0 localhost:8083 -- echo "kafka connect up"
sleep 60
docker run --env-file=./migrate/.env.container --net crawler 080196/crawler-app-migrate /app/run init
docker run --env-file=./migrate/.env.container --net crawler 080196/crawler-app-migrate /app/run migrate
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" http://localhost:8083/connectors/ -d @configs/postgres-source.json
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" http://localhost:8083/connectors/ -d @configs/elasticsearch-sink.json
