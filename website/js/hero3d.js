import * as THREE from "three";
import { RoomEnvironment } from "./vendor/RoomEnvironment.js";

/* Hero 3D sahnasi: ilova ekranlari o'rnatilgan haqiqiy 3D telefonlar,
   oltin sakkiz uchli yulduzlar, Basmala lavhasi va oltin chang zarralari.
   WebGL bo'lmasa yoki xato chiqsa, oddiy rasmli telefonlar qoladi. */

var canvasEl = null;
const stage = document.getElementById("hero-stage");
if (stage) {
  start().catch(function (err) {
    console.warn("3D sahna ishga tushmadi, oddiy ko'rinish qoldirildi:", err);
    cleanup();
  });
}

function cleanup() {
  if (canvasEl && canvasEl.parentNode) canvasEl.parentNode.removeChild(canvasEl);
  if (stage) stage.classList.remove("webgl-ready");
}

function supportsWebGL() {
  try {
    var c = document.createElement("canvas");
    return !!(c.getContext("webgl2") || c.getContext("webgl"));
  } catch (e) {
    return false;
  }
}

function rrShape(w, h, rt, rb) {
  rt = Math.max(rt, 0.0001);
  rb = Math.max(rb, 0.0001);
  var s = new THREE.Shape();
  var x = -w / 2,
    y = -h / 2;
  s.moveTo(x + rb, y);
  s.lineTo(x + w - rb, y);
  s.absarc(x + w - rb, y + rb, rb, -Math.PI / 2, 0, false);
  s.lineTo(x + w, y + h - rt);
  s.absarc(x + w - rt, y + h - rt, rt, 0, Math.PI / 2, false);
  s.lineTo(x + rt, y + h);
  s.absarc(x + rt, y + h - rt, rt, Math.PI / 2, Math.PI, false);
  s.lineTo(x, y + rb);
  s.absarc(x + rb, y + rb, rb, Math.PI, Math.PI * 1.5, false);
  return s;
}

function starShape(R) {
  var r = R * 0.765;
  var s = new THREE.Shape();
  for (var i = 0; i < 16; i++) {
    var a = (i * Math.PI) / 8 + Math.PI / 8;
    var rad = i % 2 ? r : R;
    var x = Math.cos(a) * rad,
      y = Math.sin(a) * rad;
    if (i) s.lineTo(x, y);
    else s.moveTo(x, y);
  }
  s.closePath();
  return s;
}

function loadTexture(loader, url, maxAniso) {
  return new Promise(function (resolve, reject) {
    loader.load(
      url,
      function (t) {
        t.colorSpace = THREE.SRGBColorSpace;
        t.anisotropy = maxAniso;
        t.generateMipmaps = true;
        t.minFilter = THREE.LinearMipmapLinearFilter;
        resolve(t);
      },
      undefined,
      reject
    );
  });
}

/* iPhone 16 Pro Max (Apple spetsifikatsiyasi): 77.6 x 163.0 x 8.25 mm,
   6.9" ekran 1320x2868 (73.0 x 158.6 mm), titan korpus, Dynamic Island,
   chap tomonda Action + ovoz tugmalari, o'ngda quvvat + Camera Control.
   Birlik: 1 = 50 mm. */
var MM = 1 / 50;
var TONES = {
  desert: 0xeed4b4,
  natural: 0xcbc5ba,
  black: 0x4a4a4e,
  white: 0xe4e3df,
};

function makePhone(texture, toneName) {
  var W = 77.6 * MM,
    H = 163 * MM,
    D = 8.25 * MM;
  var group = new THREE.Group();
  var tone = TONES[toneName] || TONES.natural;

  var ti = new THREE.MeshPhysicalMaterial({
    color: tone,
    metalness: 1,
    roughness: 0.4,
    clearcoat: 0.15,
    clearcoatRoughness: 0.5,
    envMapIntensity: 1.3,
  });

  // Titan korpus: deyarli tekis yon yuzalar, yumaloq burchaklar (R ~ 11 mm)
  var bev = 0.012;
  var bodyGeo = new THREE.ExtrudeGeometry(
    rrShape(W - bev * 2, H - bev * 2, 0.208, 0.208),
    {
      depth: D - bev * 2,
      bevelEnabled: true,
      bevelThickness: bev,
      bevelSize: bev,
      bevelSegments: 4,
      curveSegments: 56,
    }
  );
  bodyGeo.center();
  group.add(new THREE.Mesh(bodyGeo, ti));
  var front = D / 2;

  // Old oyna (qora shisha) — korpus bilan bir tekis
  var glassW = W - 0.06,
    glassH = H - 0.06;
  var glass = new THREE.Mesh(
    new THREE.ShapeGeometry(rrShape(glassW, glassH, 0.19, 0.19), 48),
    new THREE.MeshPhysicalMaterial({
      color: 0x040406,
      metalness: 0,
      roughness: 0.05,
      clearcoat: 1,
      clearcoatRoughness: 0.04,
      envMapIntensity: 0.9,
    })
  );
  glass.position.z = front + 0.0015;
  group.add(glass);

  // Ekran: 73.0 x 158.6 mm, burchak ~ 9.5 mm. Rasm nisbati 1320:2868 bilan bir xil.
  var sw = 73.0 * MM,
    sh = 158.6 * MM;
  var scrGeo = new THREE.ShapeGeometry(rrShape(sw, sh, 0.19, 0.19), 48);
  var pos = scrGeo.attributes.position;
  var uv = scrGeo.attributes.uv;
  for (var i = 0; i < pos.count; i++) {
    uv.setXY(i, (pos.getX(i) + sw / 2) / sw, (pos.getY(i) + sh / 2) / sh);
  }
  uv.needsUpdate = true;
  var screen = new THREE.Mesh(
    scrGeo,
    new THREE.MeshBasicMaterial({ map: texture, toneMapped: false })
  );
  screen.position.z = front + 0.003;
  group.add(screen);

  // Shisha aksi
  var c = document.createElement("canvas");
  c.width = 64;
  c.height = 256;
  var g = c.getContext("2d");
  var grad = g.createLinearGradient(0, 0, 64, 256);
  grad.addColorStop(0, "rgba(255,255,255,0.22)");
  grad.addColorStop(0.32, "rgba(255,255,255,0.04)");
  grad.addColorStop(0.33, "rgba(255,255,255,0)");
  g.fillStyle = grad;
  g.fillRect(0, 0, 64, 256);
  var glareGeo = new THREE.ShapeGeometry(rrShape(sw, sh, 0.19, 0.19), 48);
  var gp = glareGeo.attributes.position;
  var gu = glareGeo.attributes.uv;
  for (var j = 0; j < gp.count; j++) {
    gu.setXY(j, (gp.getX(j) + sw / 2) / sw, (gp.getY(j) + sh / 2) / sh);
  }
  gu.needsUpdate = true;
  var glare = new THREE.Mesh(
    glareGeo,
    new THREE.MeshBasicMaterial({
      map: new THREE.CanvasTexture(c),
      transparent: true,
      depthWrite: false,
    })
  );
  glare.position.z = front + 0.006;
  group.add(glare);

  // Dynamic Island: ~126 x 37 pt (440 pt kenglikda) => 20.9 x 6.1 mm
  var diW = 20.9 * MM,
    diH = 6.1 * MM;
  var di = new THREE.Mesh(
    new THREE.ShapeGeometry(rrShape(diW, diH, diH / 2, diH / 2), 24),
    new THREE.MeshBasicMaterial({ color: 0x000000 })
  );
  var diY = sh / 2 - 1.8 * MM - diH / 2;
  di.position.set(0, diY, front + 0.008);
  group.add(di);
  var lens = new THREE.Mesh(
    new THREE.CircleGeometry(0.019, 24),
    new THREE.MeshPhysicalMaterial({
      color: 0x0a1424,
      metalness: 0.2,
      roughness: 0.1,
      clearcoat: 1,
    })
  );
  lens.position.set(diW * 0.28, diY, front + 0.0095);
  group.add(lens);

  // Yon tugmalar (mm bo'yicha yuqoridan: markaz, uzunlik)
  function btn(side, centerMM, lenMM, mat, depth) {
    var len = lenMM * MM;
    var m = new THREE.Mesh(
      new THREE.BoxGeometry(0.02, len, depth || 0.05),
      mat || ti
    );
    m.position.set(side * (W / 2 + 0.007), (81.5 - centerMM) * MM, 0);
    group.add(m);
  }
  btn(-1, 33, 7); // Action button
  btn(-1, 50, 12); // Ovoz +
  btn(-1, 68, 12); // Ovoz -
  btn(1, 58, 20); // Quvvat
  btn(
    1,
    107,
    11,
    new THREE.MeshPhysicalMaterial({
      color: 0x0c0d10,
      metalness: 0.3,
      roughness: 0.12,
      clearcoat: 1,
    }),
    0.035
  ); // Camera Control

  // Orqa tomon: xira shisha + kamera plato (uch ob'ektiv)
  var back = new THREE.Mesh(
    new THREE.ShapeGeometry(rrShape(W - 0.05, H - 0.05, 0.195, 0.195), 48),
    new THREE.MeshPhysicalMaterial({
      color: tone,
      metalness: 0.25,
      roughness: 0.55,
      clearcoat: 0.3,
      envMapIntensity: 0.9,
    })
  );
  back.rotation.y = Math.PI;
  back.position.z = -front - 0.001;
  group.add(back);
  var plateau = new THREE.Mesh(
    new THREE.ExtrudeGeometry(rrShape(0.62, 0.62, 0.15, 0.15), {
      depth: 0.025,
      bevelEnabled: true,
      bevelThickness: 0.01,
      bevelSize: 0.01,
      bevelSegments: 3,
      curveSegments: 24,
    }),
    new THREE.MeshPhysicalMaterial({
      color: tone,
      metalness: 0.45,
      roughness: 0.3,
      clearcoat: 0.6,
    })
  );
  plateau.rotation.y = Math.PI;
  plateau.position.set(W / 2 - 0.44, H / 2 - 0.44, -front - 0.02);
  group.add(plateau);
  var ringMat = new THREE.MeshPhysicalMaterial({
    color: 0xc9cbd0,
    metalness: 1,
    roughness: 0.2,
  });
  var glassMat = new THREE.MeshPhysicalMaterial({
    color: 0x06080c,
    metalness: 0,
    roughness: 0.05,
    clearcoat: 1,
  });
  [
    [0.15, 0.15],
    [0.15, -0.15],
    [-0.15, 0],
  ].forEach(function (l) {
    var ring = new THREE.Mesh(new THREE.CylinderGeometry(0.1, 0.1, 0.05, 40), ringMat);
    ring.rotation.x = Math.PI / 2;
    ring.position.set(plateau.position.x + l[0], plateau.position.y + l[1], -front - 0.065);
    group.add(ring);
    var gl = new THREE.Mesh(new THREE.CylinderGeometry(0.072, 0.072, 0.052, 40), glassMat);
    gl.rotation.x = Math.PI / 2;
    gl.position.copy(ring.position);
    gl.position.z -= 0.002;
    group.add(gl);
  });
  return group;
}

function makePlate(text) {
  var c = document.createElement("canvas");
  c.width = 768;
  c.height = 360;
  var g = c.getContext("2d");
  var r = 70;
  g.beginPath();
  g.moveTo(r, 6);
  g.arcTo(762, 6, 762, 354, r);
  g.arcTo(762, 354, 6, 354, r);
  g.arcTo(6, 354, 6, 6, r);
  g.arcTo(6, 6, 762, 6, r);
  g.closePath();
  var grad = g.createLinearGradient(0, 0, 768, 360);
  grad.addColorStop(0, "#16604f");
  grad.addColorStop(1, "#0a2e27");
  g.fillStyle = grad;
  g.fill();
  g.lineWidth = 5;
  g.strokeStyle = "rgba(232,199,123,0.55)";
  g.stroke();
  g.fillStyle = "#e8c77b";
  g.textAlign = "center";
  g.textBaseline = "middle";
  g.direction = "rtl";
  g.font = "130px Amiri, 'Noto Naskh Arabic', serif";
  g.fillText(text, 384, 190);
  var tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 8;
  return new THREE.Mesh(
    new THREE.PlaneGeometry(1.7, 0.8),
    new THREE.MeshBasicMaterial({ map: tex, transparent: true, toneMapped: false })
  );
}

async function start() {
  if (!supportsWebGL()) return;
  var reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var coarse = window.matchMedia("(pointer: coarse)").matches;
  var urls = (stage.getAttribute("data-screens") || "").split(",");
  if (urls.length < 2) return;

  var renderer = new THREE.WebGLRenderer({
    antialias: true,
    alpha: true,
    powerPreference: "high-performance",
  });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, coarse ? 1.5 : 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.05;
  renderer.setClearColor(0x000000, 0);
  canvasEl = renderer.domElement;
  canvasEl.className = "stage";
  canvasEl.setAttribute("aria-hidden", "true");
  canvasEl.addEventListener("webglcontextlost", function (e) {
    e.preventDefault();
    stop();
    cleanup();
  });

  var scene = new THREE.Scene();
  var camera = new THREE.PerspectiveCamera(30, 1, 0.1, 60);

  var pmrem = new THREE.PMREMGenerator(renderer);
  var envRT = pmrem.fromScene(new RoomEnvironment(), 0.04);
  scene.environment = envRT.texture;

  // Yorug'lik: iliq oltin asosiy, zumrad aks
  var key = new THREE.DirectionalLight(0xffe2a6, 2.8);
  key.position.set(3, 4, 5);
  scene.add(key);
  var rim = new THREE.DirectionalLight(0xcfe9e0, 1.1);
  rim.position.set(-4, 1.5, -3);
  scene.add(rim);
  scene.add(new THREE.AmbientLight(0xffffff, 0.35));

  var loader = new THREE.TextureLoader();
  var aniso = renderer.capabilities.getMaxAnisotropy();
  var tex = await Promise.all([
    loadTexture(loader, urls[0].trim(), aniso),
    loadTexture(loader, urls[1].trim(), aniso),
  ]);
  try {
    await document.fonts.load("120px Amiri", "بِسْمِ اللَّهِ");
  } catch (e) {}

  var rig = new THREE.Group();
  scene.add(rig);

  var phoneA = makePhone(tex[0], "desert");
  phoneA.position.set(-0.6, 0, 0.2);
  phoneA.rotation.set(0.04, 0.32, -0.05);
  rig.add(phoneA);

  var phoneB = makePhone(tex[1], "natural");
  phoneB.position.set(1.3, 0.3, -1.2);
  phoneB.rotation.set(0.05, 0.5, 0.05);
  phoneB.scale.setScalar(0.94);
  rig.add(phoneB);

  // Oltin sakkiz uchli yulduzlar
  var goldMat = new THREE.MeshPhysicalMaterial({
    color: 0xf0c15f,
    metalness: 1,
    roughness: 0.2,
    clearcoat: 0.5,
    envMapIntensity: 1.8,
    emissive: 0x7a5410,
    emissiveIntensity: 0.55,
  });
  var stars = [];
  [
    { p: [-2.0, 1.7, 0.6], s: 0.42, sp: 0.5 },
    { p: [2.6, 1.9, -0.4], s: 0.3, sp: -0.7 },
    { p: [2.2, -1.5, 0.8], s: 0.36, sp: 0.6 },
    { p: [-2.1, -1.0, -0.2], s: 0.24, sp: -0.8 },
    { p: [0.4, 2.15, -1.4], s: 0.22, sp: 0.9 },
  ].forEach(function (d, i) {
    var geo = new THREE.ExtrudeGeometry(starShape(1), {
      depth: 0.16,
      bevelEnabled: true,
      bevelThickness: 0.05,
      bevelSize: 0.05,
      bevelSegments: 4,
    });
    geo.center();
    var m = new THREE.Mesh(geo, goldMat);
    m.position.set(d.p[0], d.p[1], d.p[2]);
    m.scale.setScalar(d.s);
    m.userData = { base: d.p[1], speed: d.sp, phase: i * 1.7 };
    rig.add(m);
    stars.push(m);
  });

  // Basmala lavhasi
  var plate = makePlate("بِسْمِ اللَّهِ");
  plate.position.set(-1.6, -1.6, 1.1);
  plate.rotation.set(-0.05, 0.28, 0.06);
  rig.add(plate);

  // Oltin chang zarralari
  var N = coarse ? 70 : 140;
  var pa = new Float32Array(N * 3);
  for (var i = 0; i < N; i++) {
    pa[i * 3] = (Math.random() - 0.5) * 8;
    pa[i * 3 + 1] = (Math.random() - 0.5) * 5.5;
    pa[i * 3 + 2] = (Math.random() - 0.5) * 4 - 0.5;
  }
  var pg = new THREE.BufferGeometry();
  pg.setAttribute("position", new THREE.BufferAttribute(pa, 3));
  var dust = new THREE.Points(
    pg,
    new THREE.PointsMaterial({
      size: 0.045,
      color: 0xe8c77b,
      transparent: true,
      opacity: 0.65,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
    })
  );
  scene.add(dust);

  stage.insertBefore(canvasEl, stage.firstChild);

  var state = { tx: 0, ty: 0, px: 0, py: 0, p: 0 };
  var running = false,
    visible = true,
    raf = 0,
    w = 1,
    h = 1;

  function resize() {
    var r = stage.getBoundingClientRect();
    var cw = canvasEl.clientWidth || r.width;
    var ch = canvasEl.clientHeight || r.height;
    if (cw === w && ch === h) return;
    w = cw;
    h = ch;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    var dist = Math.max(9.2, 9.0 / camera.aspect);
    camera.position.set(0, 0.1, dist);
    camera.lookAt(0, 0, 0);
    camera.updateProjectionMatrix();
  }

  function render(t) {
    var time = t / 1000;
    state.px += (state.tx - state.px) * 0.06;
    state.py += (state.ty - state.py) * 0.06;
    var rect = stage.getBoundingClientRect();
    state.p = Math.min(1, Math.max(0, -rect.top / Math.max(rect.height, 1)));

    var sway = reduced ? 0 : Math.sin(time * 0.5) * 0.06;
    rig.rotation.y = state.px * 0.38 + sway + state.p * 1.1;
    rig.rotation.x = state.py * 0.14 - state.p * 0.15;
    rig.position.y = state.p * 0.9;

    if (!reduced) {
      phoneA.position.y = Math.sin(time * 0.9) * 0.07;
      phoneB.position.y = 0.3 + Math.sin(time * 0.9 + 1.4) * 0.07;
      plate.position.y = -1.6 + Math.sin(time * 1.1 + 0.6) * 0.05;
      stars.forEach(function (s) {
        s.rotation.y += 0.01 * s.userData.speed;
        s.rotation.x = Math.sin(time * 0.6 + s.userData.phase) * 0.4;
        s.position.y = s.userData.base + Math.sin(time * 0.8 + s.userData.phase) * 0.12;
      });
      dust.rotation.y = time * 0.03;
      dust.position.y = Math.sin(time * 0.2) * 0.1;
    }
    renderer.render(scene, camera);
  }

  function loop(t) {
    if (!running) return;
    render(t);
    raf = requestAnimationFrame(loop);
  }
  function play() {
    if (running || reduced || !visible || document.hidden) return;
    running = true;
    raf = requestAnimationFrame(loop);
  }
  function stop() {
    running = false;
    cancelAnimationFrame(raf);
  }
  window.__stopHero3d = stop;

  if (!coarse && !reduced) {
    window.addEventListener(
      "pointermove",
      function (e) {
        state.tx = (e.clientX / window.innerWidth - 0.5) * 2;
        state.ty = (e.clientY / window.innerHeight - 0.5) * 2;
      },
      { passive: true }
    );
  }
  if (reduced) {
    window.addEventListener(
      "scroll",
      function () {
        render(performance.now());
      },
      { passive: true }
    );
  }

  new ResizeObserver(function () {
    resize();
    if (!running) render(performance.now());
  }).observe(stage);
  new IntersectionObserver(function (en) {
    visible = en[0].isIntersecting;
    if (visible) play();
    else stop();
  }).observe(stage);
  document.addEventListener("visibilitychange", function () {
    if (document.hidden) stop();
    else play();
  });

  resize();
  render(performance.now());
  stage.classList.add("webgl-ready");
  play();
}
