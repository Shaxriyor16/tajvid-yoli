// Kichik SVG diagramma yordamchilari (tashqi kutubxonasiz).

const NS = "http://www.w3.org/2000/svg";

export function sparkline(values, color) {
  const w = 120,
    h = 46;
  const max = Math.max(1, ...values);
  const pts = values.map((v, i) => [
    (i / Math.max(1, values.length - 1)) * w,
    h - 4 - (v / max) * (h - 12),
  ]);
  const d = smooth(pts);
  const id = "sg" + Math.random().toString(36).slice(2, 7);
  return `<svg class="spark" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none" aria-hidden="true" style="color:${color}">
    <defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${color}" stop-opacity=".35"/><stop offset="1" stop-color="${color}" stop-opacity="0"/></linearGradient></defs>
    <path d="${d} L${w},${h} L0,${h} Z" fill="url(#${id})"/>
    <path d="${d}" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" vector-effect="non-scaling-stroke"/>
  </svg>`;
}

// Monoton-yaqin silliq egri chiziq (Catmull-Rom -> Bezier)
function smooth(p) {
  if (p.length < 2) return p.length ? `M${p[0][0]},${p[0][1]}` : "";
  let d = `M${p[0][0].toFixed(1)},${p[0][1].toFixed(1)}`;
  for (let i = 0; i < p.length - 1; i++) {
    const p0 = p[i - 1] || p[i],
      p1 = p[i],
      p2 = p[i + 1],
      p3 = p[i + 2] || p2;
    const c1x = p1[0] + (p2[0] - p0[0]) / 6;
    const c1y = p1[1] + (p2[1] - p0[1]) / 6;
    const c2x = p2[0] - (p3[0] - p1[0]) / 6;
    const c2y = p2[1] - (p3[1] - p1[1]) / 6;
    d += ` C${c1x.toFixed(1)},${c1y.toFixed(1)} ${c2x.toFixed(1)},${c2y.toFixed(1)} ${p2[0].toFixed(1)},${p2[1].toFixed(1)}`;
  }
  return d;
}

/** parts: [{label, value, color}] -> donut SVG matni */
export function donut(parts, total) {
  const r = 70,
    c = 2 * Math.PI * r;
  const sum = parts.reduce((a, p) => a + p.value, 0);
  let off = 0;
  const gap = parts.filter((p) => p.value > 0).length > 1 ? 5 : 0;
  const segs = parts
    .filter((p) => p.value > 0)
    .map((p) => {
      const len = (p.value / sum) * c;
      const dash = Math.max(0, len - gap);
      const s = `<circle cx="95" cy="95" r="${r}" fill="none" stroke="${p.color}" stroke-width="22" stroke-dasharray="${dash.toFixed(2)} ${(c - dash).toFixed(2)}" stroke-dashoffset="${(-off).toFixed(2)}"><title>${p.label}: ${p.value}</title></circle>`;
      off += len;
      return s;
    })
    .join("");
  const track = `<circle cx="95" cy="95" r="${r}" fill="none" stroke="rgba(127,127,127,.18)" stroke-width="22"/>`;
  return `<svg viewBox="0 0 190 190" role="img" aria-label="Provayderlar bo'yicha taqsimot (jami ${total})">${track}${segs}</svg>`;
}

/** Maydon (area) diagrammasi interaktiv tooltip bilan. series: [{label, value}] */
export function areaChart(el, series, { color = "#e8c77b", unit = "ta" } = {}) {
  el.innerHTML = "";
  el.style.position = "relative";
  const W = Math.max(280, el.clientWidth || 600);
  const H = el.clientHeight || 250;
  const m = { l: 34, r: 12, t: 12, b: 28 };
  const iw = W - m.l - m.r,
    ih = H - m.t - m.b;
  const max = Math.max(...series.map((s) => s.value), 0);
  const yMax = max <= 4 ? 4 : Math.ceil(max / 4) * 4;
  const x = (i) => m.l + (i / Math.max(1, series.length - 1)) * iw;
  const y = (v) => m.t + ih - (v / yMax) * ih;
  const pts = series.map((s, i) => [x(i), y(s.value)]);
  const d = smooth(pts);
  const id = "ag" + Math.random().toString(36).slice(2, 7);

  const svg = document.createElementNS(NS, "svg");
  svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
  svg.setAttribute("role", "img");
  svg.setAttribute("aria-label", "Ro'yxatdan o'tish dinamikasi");
  let grid = "";
  for (let i = 0; i <= 4; i++) {
    const v = (yMax / 4) * i;
    const yy = y(v);
    grid += `<line x1="${m.l}" x2="${W - m.r}" y1="${yy}" y2="${yy}" stroke="rgba(127,127,127,.18)" stroke-dasharray="3 5"/><text x="${m.l - 8}" y="${yy + 4}" text-anchor="end" font-size="11" fill="currentColor" opacity=".5">${v}</text>`;
  }
  const every = Math.ceil(series.length / 6);
  let xs = "";
  series.forEach((s, i) => {
    if (i % every === 0 || i === series.length - 1) {
      xs += `<text x="${x(i)}" y="${H - 8}" text-anchor="middle" font-size="11" fill="currentColor" opacity=".5">${s.label}</text>`;
    }
  });
  svg.innerHTML = `
    <defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${color}" stop-opacity=".42"/><stop offset="1" stop-color="${color}" stop-opacity="0"/></linearGradient></defs>
    ${grid}${xs}
    <path d="${d} L${x(series.length - 1)},${y(0)} L${x(0)},${y(0)} Z" fill="url(#${id})"/>
    <path d="${d}" fill="none" stroke="${color}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
    <line class="vl" y1="${m.t}" y2="${m.t + ih}" stroke="${color}" stroke-opacity=".5" stroke-dasharray="3 4" visibility="hidden"/>
    <circle class="dot" r="6" fill="${color}" stroke="#fff" stroke-width="2.5" visibility="hidden"/>
    <rect class="hit" x="${m.l}" y="${m.t}" width="${iw}" height="${ih}" fill="transparent"/>`;
  el.appendChild(svg);

  const tip = document.createElement("div");
  tip.className = "tip";
  tip.hidden = true;
  el.appendChild(tip);
  const vl = svg.querySelector(".vl"),
    dot = svg.querySelector(".dot"),
    hit = svg.querySelector(".hit");
  const show = (clientX) => {
    const r = svg.getBoundingClientRect();
    const px = ((clientX - r.left) / r.width) * W;
    const i = Math.max(0, Math.min(series.length - 1, Math.round(((px - m.l) / iw) * (series.length - 1))));
    const s = series[i];
    vl.setAttribute("x1", x(i));
    vl.setAttribute("x2", x(i));
    vl.setAttribute("visibility", "visible");
    dot.setAttribute("cx", x(i));
    dot.setAttribute("cy", y(s.value));
    dot.setAttribute("visibility", "visible");
    tip.hidden = false;
    tip.innerHTML = `<b>${s.value} ${unit}</b>${s.full || s.label}`;
    tip.style.left = (x(i) / W) * r.width + "px";
    tip.style.top = (y(s.value) / H) * r.height + "px";
  };
  const hide = () => {
    vl.setAttribute("visibility", "hidden");
    dot.setAttribute("visibility", "hidden");
    tip.hidden = true;
  };
  hit.addEventListener("pointermove", (e) => show(e.clientX));
  hit.addEventListener("pointerdown", (e) => show(e.clientX));
  hit.addEventListener("pointerleave", hide);
}
