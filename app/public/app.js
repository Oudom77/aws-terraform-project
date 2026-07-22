// CloudNotes frontend — talks to the Express JSON API.

let color = "yellow";

const $ = (id) => document.getElementById(id);

// Header badge: which instance served us, and which tiers are in use
fetch("/api/meta")
  .then((r) => r.json())
  .then((m) => {
    $("badge").innerHTML =
      `Served by <b>${m.instance}</b> in <b>${m.az}</b> · ` +
      `notes → ${m.database} · images → ${m.storage}`;
  })
  .catch(() => ($("badge").textContent = "api unreachable"));

// Color swatches
$("swatches").addEventListener("click", (e) => {
  const btn = e.target.closest(".swatch");
  if (!btn) return;
  color = btn.dataset.color;
  document.querySelectorAll(".swatch").forEach((s) => s.classList.remove("selected"));
  btn.classList.add("selected");
  $("composer").className = "note-card color-" + color;
});

// Show picked filename next to the paperclip
$("image").addEventListener("change", () => {
  $("attach-name").textContent = $("image").files[0] ? $("image").files[0].name : "";
});

async function loadNotes() {
  const notes = await (await fetch("/api/notes")).json();
  $("empty").hidden = notes.length > 0;
  $("board").innerHTML = notes
    .map(
      (n) => `
      <div class="note-card color-${escapeHtml(n.color)}">
        <button class="del" data-id="${n.id}" title="Delete">✕</button>
        ${n.imageUrl ? `<img src="${escapeAttr(n.imageUrl)}" alt="${escapeAttr(n.imageName || "")}">` : ""}
        ${n.title ? `<h3>${escapeHtml(n.title)}</h3>` : ""}
        ${n.body ? `<p>${escapeHtml(n.body)}</p>` : ""}
      </div>`
    )
    .join("");
}

$("board").addEventListener("click", async (e) => {
  const btn = e.target.closest(".del");
  if (!btn) return;
  await fetch("/api/notes/" + btn.dataset.id, { method: "DELETE" });
  loadNotes();
});

$("composer").addEventListener("submit", async (e) => {
  e.preventDefault();
  const form = new FormData();
  form.append("title", $("title").value);
  form.append("body", $("body").value);
  form.append("color", color);
  if ($("image").files[0]) form.append("image", $("image").files[0]);

  const res = await fetch("/api/notes", { method: "POST", body: form });
  if (res.ok) {
    $("title").value = "";
    $("body").value = "";
    $("image").value = "";
    $("attach-name").textContent = "";
    loadNotes();
  }
});

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c])
  );
}
function escapeAttr(s) {
  return escapeHtml(s);
}

loadNotes();
