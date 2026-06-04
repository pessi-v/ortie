// Downloads the default nsfwjs model (MobileNetV2, 5-label) once and saves it
// to ./model so the server loads it from disk with no runtime network access.
// Run locally for dev and at Docker build time.
import * as tf from "@tensorflow/tfjs-node";
import * as nsfwjs from "nsfwjs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { mkdirSync } from "node:fs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const out = join(__dirname, "..", "model");
mkdirSync(out, { recursive: true });

console.log("downloading default nsfwjs model…");
const nsfw = await nsfwjs.load();
await nsfw.model.save("file://" + out);
console.log("model saved to", out);
