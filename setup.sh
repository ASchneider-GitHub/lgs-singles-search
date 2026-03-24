#!/bin/bash
docker build -t lgs-singles-search .
docker run -d --name lgs-singles-search -p 5000:5000 lgs-singles-search
sleep 1
docker logs -f lgs-singles-search
