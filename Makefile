IMAGE="floryn90/hugo:0.154.0-ext-alpine"

CONTAINER_NAME="wdes.fr"
PROJECT_NAME="wdes.fr"

version:
	docker run --name ${CONTAINER_NAME} --rm -it ${IMAGE} --version

init:
	docker run --name ${CONTAINER_NAME} --rm -it -v $(PWD):/app --workdir /app ${IMAGE} new site ${PROJECT_NAME}

build:
	docker run --name ${CONTAINER_NAME} --rm -v $(PWD):/app --workdir /app/${PROJECT_NAME} ${IMAGE} build

serve:
	docker run --name ${CONTAINER_NAME} --rm -v $(PWD):/app -p 8111:8111 --workdir /app/${PROJECT_NAME} ${IMAGE} serve --bind 0.0.0.0 --port 8111 --baseURL localhost

fix-perms:
	find ./ -type d -exec chmod 0777 {} \;
	find ./ -type f -exec chmod 0666 {} \;

date:
	date +'%Y-%m-%dT%H:%M:%SZ' --utc
