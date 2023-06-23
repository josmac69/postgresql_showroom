start:
	docker compose up -d

stop:
	docker compose down

psql:
	docker exec -it postgres psql -U postgres -d postgres

grafana-bash:
	docker exec -it grafana /bin/bash

open-grafana:
	open http://localhost:3000

open-prometheus:
	open http://localhost:9090

hammerdbcli:
	docker exec -it hammerdb /bin/bash
#	./hammerdbcli auto /app/script.tcl

.PHONY: start \
	stop \
	psql \
	grafana-bash \
	open-grafana \
	open-prometheus


