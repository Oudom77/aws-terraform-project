// CloudNotes — Project Cloud's full-stack note app (Person 2)
//
// One Express server, three tiers:
//   notes  -> database   (RDS MySQL in the cloud, built-in SQLite locally)
//   images -> S3 bucket  (local uploads/ folder when no bucket configured)
//   frontend in public/  (talks to the JSON API below)
//
// The SAME code runs locally and on EC2 — behavior switches on env vars:
//   DATABASE_URL  e.g. mysql://user:pass@rds-endpoint:3306/appdb
//                 (unset = SQLite locally; JSON file if Node has no sqlite)
//   S3_BUCKET     name of Person 3's uploads bucket (unset = save locally)
//   PORT          defaults to 3000 locally; systemd sets 80 on EC2

const path = require("path");
const fs = require("fs");
const crypto = require("crypto");
const express = require("express");
const multer = require("multer");

const DATABASE_URL = process.env.DATABASE_URL || "";
const S3_BUCKET = process.env.S3_BUCKET || "";
const PORT = process.env.PORT || 3000;
const UPLOAD_DIR = path.join(__dirname, "uploads");

// ── Notes storage: three backends, one interface ─────────────────────────────
// list() / create(note) / imageKeyOf(id) / remove(id) / ping()

async function initDb() {
  // 1. Real database — Person 3's RDS MySQL (production path)
  if (DATABASE_URL) {
    const mysql = require("mysql2/promise");
    const u = new URL(DATABASE_URL);
    const pool = mysql.createPool({
      host: u.hostname,
      port: u.port || 3306,
      user: decodeURIComponent(u.username),
      password: decodeURIComponent(u.password),
      database: u.pathname.slice(1),
      connectionLimit: 5,
    });
    await pool.query(`CREATE TABLE IF NOT EXISTS notes (
      id INT AUTO_INCREMENT PRIMARY KEY,
      title VARCHAR(120) NOT NULL DEFAULT '',
      body TEXT NOT NULL,
      color VARCHAR(20) NOT NULL DEFAULT 'yellow',
      image_key VARCHAR(200),
      image_name VARCHAR(200),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`);
    return {
      label: "MySQL (RDS)",
      list: async () =>
        (await pool.query("SELECT * FROM notes ORDER BY id DESC"))[0],
      create: (n) =>
        pool.query(
          "INSERT INTO notes (title, body, color, image_key, image_name) VALUES (?, ?, ?, ?, ?)",
          [n.title, n.body, n.color, n.image_key, n.image_name]
        ),
      imageKeyOf: async (id) => {
        const [rows] = await pool.query("SELECT image_key FROM notes WHERE id = ?", [id]);
        return rows[0] ? rows[0].image_key : null;
      },
      remove: (id) => pool.query("DELETE FROM notes WHERE id = ?", [id]),
      ping: () => pool.query("SELECT 1"),
    };
  }

  // 2. Built-in SQLite — laptop testing (needs Node 22.5+)
  try {
    const { DatabaseSync } = require("node:sqlite");
    const db = new DatabaseSync(path.join(__dirname, "local.db"));
    db.exec(`CREATE TABLE IF NOT EXISTS notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL DEFAULT '',
      body TEXT NOT NULL,
      color TEXT NOT NULL DEFAULT 'yellow',
      image_key TEXT,
      image_name TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )`);
    return {
      label: "SQLite (local file)",
      list: async () => db.prepare("SELECT * FROM notes ORDER BY id DESC").all(),
      create: async (n) =>
        db.prepare(
          "INSERT INTO notes (title, body, color, image_key, image_name) VALUES (?, ?, ?, ?, ?)"
        ).run(n.title, n.body, n.color, n.image_key, n.image_name),
      imageKeyOf: async (id) => {
        const row = db.prepare("SELECT image_key FROM notes WHERE id = ?").get(id);
        return row ? row.image_key : null;
      },
      remove: async (id) => db.prepare("DELETE FROM notes WHERE id = ?").run(id),
      ping: async () => db.prepare("SELECT 1").get(),
    };
  } catch {
    // 3. JSON file — interim EC2 mode before RDS exists (older Node, no sqlite).
    //    Per-instance and wiped on ASG replacement — exactly why we want RDS.
    const FILE = path.join(__dirname, "notes.json");
    const load = () => {
      try {
        return JSON.parse(fs.readFileSync(FILE, "utf8"));
      } catch {
        return { seq: 0, notes: [] };
      }
    };
    const save = (d) => fs.writeFileSync(FILE, JSON.stringify(d));
    return {
      label: "JSON file (no DB yet)",
      list: async () => load().notes.slice().reverse(),
      create: async (n) => {
        const d = load();
        d.notes.push({ id: ++d.seq, ...n });
        save(d);
      },
      imageKeyOf: async (id) => {
        const n = load().notes.find((x) => x.id === Number(id));
        return n ? n.image_key : null;
      },
      remove: async (id) => {
        const d = load();
        d.notes = d.notes.filter((x) => x.id !== Number(id));
        save(d);
      },
      ping: async () => true,
    };
  }
}

// ── File storage: S3 when configured, local folder otherwise ─────────────────

function initStorage() {
  if (S3_BUCKET) {
    const { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand } =
      require("@aws-sdk/client-s3");
    const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
    const s3 = new S3Client({}); // region + credentials come from the instance role
    return {
      label: "S3 bucket: " + S3_BUCKET,
      save: (key, file) =>
        s3.send(new PutObjectCommand({
          Bucket: S3_BUCKET, Key: key, Body: file.buffer, ContentType: file.mimetype,
        })),
      url: (key) =>
        getSignedUrl(s3, new GetObjectCommand({ Bucket: S3_BUCKET, Key: key }), {
          expiresIn: 3600,
        }),
      remove: (key) =>
        s3.send(new DeleteObjectCommand({ Bucket: S3_BUCKET, Key: key })).catch(() => {}),
    };
  }
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
  return {
    label: "local folder",
    save: (key, file) => fs.promises.writeFile(path.join(UPLOAD_DIR, key), file.buffer),
    url: (key) => "/uploads/" + key,
    remove: (key) => fs.promises.unlink(path.join(UPLOAD_DIR, key)).catch(() => {}),
  };
}

// ── Which EC2 instance is this? (IMDSv2; falls back on a laptop) ─────────────

async function instanceIdentity() {
  try {
    const base = "http://169.254.169.254/latest";
    const token = await (await fetch(base + "/api/token", {
      method: "PUT",
      headers: { "X-aws-ec2-metadata-token-ttl-seconds": "60" },
      signal: AbortSignal.timeout(300),
    })).text();
    const meta = async (p) =>
      (await fetch(base + p, {
        headers: { "X-aws-ec2-metadata-token": token },
        signal: AbortSignal.timeout(300),
      })).text();
    return {
      instance: await meta("/meta-data/instance-id"),
      az: await meta("/meta-data/placement/availability-zone"),
    };
  } catch {
    return { instance: "local-dev", az: "your laptop" };
  }
}

// ── The app ──────────────────────────────────────────────────────────────────

async function main() {
  const db = await initDb();
  const storage = initStorage();
  const app = express();
  const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 },
  });

  app.use(express.static(path.join(__dirname, "public")));
  app.use("/uploads", express.static(UPLOAD_DIR)); // local mode only

  app.get("/api/meta", async (req, res) => {
    res.json({ ...(await instanceIdentity()), database: db.label, storage: storage.label });
  });

  app.get("/api/notes", async (req, res) => {
    const rows = await db.list();
    res.json(await Promise.all(rows.map(async (n) => ({
      id: n.id,
      title: n.title,
      body: n.body,
      color: n.color,
      imageUrl: n.image_key ? await storage.url(n.image_key) : null,
      imageName: n.image_name,
    }))));
  });

  app.post("/api/notes", upload.single("image"), async (req, res) => {
    const title = (req.body.title || "").trim().slice(0, 120);
    const body = (req.body.body || "").trim().slice(0, 2000);
    const color = (req.body.color || "yellow").slice(0, 20);
    if (!body && !title && !req.file) return res.status(400).json({ error: "empty note" });

    let key = null;
    if (req.file) {
      key = crypto.randomUUID() + path.extname(req.file.originalname);
      await storage.save(key, req.file);
    }
    await db.create({
      title, body, color,
      image_key: key,
      image_name: req.file ? req.file.originalname : null,
    });
    res.status(201).json({ ok: true });
  });

  app.delete("/api/notes/:id", async (req, res) => {
    const key = await db.imageKeyOf(req.params.id);
    if (key) await storage.remove(key);
    await db.remove(req.params.id);
    res.json({ ok: true });
  });

  // Liveness stays independent from shared dependencies so a DB outage does
  // not make the ASG replace otherwise healthy application instances.
  app.get("/health", (req, res) => res.send("ok"));

  app.get("/ready", async (req, res) => {
    try {
      await db.ping();
      res.send("ok");
    } catch {
      res.status(500).send("db unreachable");
    }
  });

  app.listen(PORT, "0.0.0.0", () =>
    console.log(`CloudNotes on :${PORT} — db: ${db.label}, files: ${storage.label}`)
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
