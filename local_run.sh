docker build -t aeternity/local .
docker run -it --env-file=env.list -v ${PWD}:/src aeternity/local
