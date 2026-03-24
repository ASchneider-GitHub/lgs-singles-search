#!/bin/bash
docker build -t mtg-app .
docker run -d --name lgs-singles-search -p 5000:5000 mtg-app
sleep 1
docker logs -f lgs-singles-search
