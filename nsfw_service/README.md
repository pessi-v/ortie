# Ortie NSFW sidecar

A small Node service that classifies images with [nsfwjs](https://github.com/infinitered/nsfwjs)
(TensorFlow.js, MobileNetV2) and returns the 5 class probabilities
(`Drawing, Hentai, Neutral, Porn, Sexy`). Rails (`NsfwDetector`) calls it over HTTP.

Pinned to **Node 20 LTS** (`.mise.toml`) because `@tensorflow/tfjs-node`'s native
binary lags newer Node majors.

## Endpoints
- `GET /health` → `200 {"status":"ok"}` once the model is loaded, else `503`.
- `POST /classify` → raw image bytes (JPEG/PNG) in the body → `{"Neutral":0.99,...}`.

## Local dev
```sh
cd nsfw_service
mise install            # Node 20
npm install
npm run fetch-model     # downloads the model into ./model (once)
PORT=3001 npm start
```
`bin/dev` runs it automatically (see the repo `Procfile.dev`). Rails reaches it via
`NSFW_SERVICE_URL` (default `http://localhost:3001`).

## Docker / Kamal accessory
The image bakes the model in at build time. Kamal does **not** build accessory
images, so build and push it yourself, then boot the accessory:
```sh
docker build -t <registry>/ortie-nsfw:latest nsfw_service
docker push <registry>/ortie-nsfw:latest
kamal accessory boot nsfw
```
See the `accessories.nsfw` stanza in `config/deploy.yml`. The Rails app reaches the
accessory over the shared Docker network via `NSFW_SERVICE_URL`.
