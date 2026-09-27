let zaaps = [];

// Mirrors ParseCoordinates() in scripts/travel.ahk
function parseCoordinates(input) {
  let text = input.trim();
  text = text.replace(/^\/travel\s*/i, "");
  text = text.trim();

  const m = text.match(/^(-?\d+)\s*,?\s*(-?\d+)$/);
  if (!m) return null;

  return { x: parseInt(m[1], 10), y: parseInt(m[2], 10) };
}

// Mirrors LoadZaaps() in scripts/travel.ahk
async function loadZaaps() {
  const res = await fetch("data/zaaps.yaml");
  const content = await res.text();

  const re = /area:\s*(.*?)\r?\n\s*subarea:\s*(.*?)\r?\n\s*x:\s*(-?\d+)\r?\n\s*y:\s*(-?\d+)/g;
  const result = [];
  let match;
  while ((match = re.exec(content)) !== null) {
    result.push({
      area: match[1].trim(),
      subarea: match[2].trim(),
      x: parseInt(match[3], 10),
      y: parseInt(match[4], 10),
    });
  }
  return result;
}

// Mirrors ClosestZaap() in scripts/travel.ahk
function closestZaap(x, y, list) {
  let best = list[0];
  let bestDist = (best.x - x) ** 2 + (best.y - y) ** 2;
  for (const z of list) {
    const d = (z.x - x) ** 2 + (z.y - y) ** 2;
    if (d < bestDist) {
      bestDist = d;
      best = z;
    }
  }
  return best;
}

const coordsInput = document.getElementById("coordsInput");
const generateBtn = document.getElementById("generateBtn");
const autoCopy = document.getElementById("autoCopy");
const errorEl = document.getElementById("error");
const output = document.getElementById("output");
const viaEl = document.getElementById("via");

function generate() {
  errorEl.textContent = "";
  output.value = "";
  viaEl.textContent = "";

  const raw = coordsInput.value;
  const coords = parseCoordinates(raw);
  if (!coords) {
    errorEl.textContent = `Could not parse coordinates from: ${raw}`;
    return;
  }

  if (zaaps.length === 0) {
    errorEl.textContent = "No zaaps loaded";
    return;
  }

  const closest = closestZaap(coords.x, coords.y, zaaps);
  const result = `/zaap ${closest.x} ${closest.y}; /travel ${coords.x} ${coords.y}`;

  output.value = result;
  viaEl.textContent = `via ${closest.area} - ${closest.subarea}`;

  if (autoCopy.checked) {
    navigator.clipboard.writeText(result).catch(() => {});
  }
}

generateBtn.addEventListener("click", generate);
coordsInput.addEventListener("keydown", (e) => {
  if (e.key === "Enter") generate();
});

loadZaaps()
  .then((list) => {
    zaaps = list;
  })
  .catch(() => {
    errorEl.textContent = "Failed to load zaaps.yaml";
  });
