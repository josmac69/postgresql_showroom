build:
	docker build --build-arg POSTGRES_VERSION=9.6 -t my_postgres:9.6 .
