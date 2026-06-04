import express from "express";
import * as tf from "@tensorflow/tfjs-node";
import * as nsfwjs from "nsfwjs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PORT = process.env.PORT || 3000;
const MODEL_URL = "file://" + join(__dirname, "model", "model.json");

// Loaded once at boot; requests are served from this warm model.
let model = null;

const app = express();
app.use(express.raw({ type: "*/*", limit: "20mb" }));

app.get("/health", (_req, res) => {
  if (model) res.json({ status: "ok" });
  else res.status(503).json({ status: "loading" });
});

// Body is raw image bytes (JPEG/PNG). Returns the 5 nsfwjs class probabilities.
app.post("/classify", async (req, res) => {
  if (!model) return res.status(503).json({ error: "model not loaded" });
  if (!req.body || req.body.length === 0) return res.status(400).json({ error: "empty body" });

  let image;
  try {
    image = tf.node.decodeImage(req.body, 3);
    const predictions = await model.classify(image);
    const scores = Object.fromEntries(predictions.map((p) => [p.className, p.probability]));
    res.json(scores);
  } catch (e) {
    res.status(500).json({ error: String(e?.message || e) });
  } finally {
    image?.dispose();
  }
});

app.listen(PORT, () => console.log(`nsfw service listening on :${PORT}`));

nsfwjs
  .load(MODEL_URL, { size: 224 })
  .then((m) => {
    model = m;
    console.log("nsfw model loaded from", MODEL_URL);
  })
  .catch((e) => {
    console.error("failed to load nsfw model:", e);
    process.exit(1);
  });
