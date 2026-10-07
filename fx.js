/*
 * Hiệu ứng WebGL thuần (không thư viện):
 *   1. Mực loang khi chuyển môn phái / nhân vật hero → window.JXFX.reveal(target, img?)
 *   2. Hoa đào + lá trúc bay           → canvas [data-fx="petals"]
 *
 * Nguyên tắc: nội dung không phụ thuộc WebGL. Không có WebGL, mất context,
 * hoặc người dùng bật giảm chuyển động → trang giữ nguyên bản tĩnh/CSS.
 */
(function () {
  "use strict";

  var motionQuery = window.matchMedia("(prefers-reduced-motion: reduce)");

  /* ---------- Tiện ích ---------- */

  // Đọc màu từ token CSS (kể cả oklch) và đổi sang RGB 0–1 cho shader.
  var probe = document.createElement("canvas").getContext("2d", { willReadFrequently: true });
  function tokenRGB(name, scope) {
    var value = getComputedStyle(scope || document.documentElement).getPropertyValue(name).trim();
    if (!value || !probe) return [0.1, 0.1, 0.1];
    probe.clearRect(0, 0, 1, 1);
    probe.fillStyle = "#000";
    probe.fillStyle = value;
    probe.fillRect(0, 0, 1, 1);
    var d = probe.getImageData(0, 0, 1, 1).data;
    return [d[0] / 255, d[1] / 255, d[2] / 255];
  }

  function createGL(canvas, keep) {
    var opts = { alpha: true, premultipliedAlpha: true, antialias: false, powerPreference: "low-power", preserveDrawingBuffer: !!keep };
    return canvas.getContext("webgl", opts) || canvas.getContext("experimental-webgl", opts);
  }

  function program(gl, vs, fs) {
    function sh(type, src) {
      var s = gl.createShader(type);
      gl.shaderSource(s, src);
      gl.compileShader(s);
      if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(s));
      return s;
    }
    var p = gl.createProgram();
    gl.attachShader(p, sh(gl.VERTEX_SHADER, vs));
    gl.attachShader(p, sh(gl.FRAGMENT_SHADER, fs));
    gl.linkProgram(p);
    if (!gl.getProgramParameter(p, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(p));
    return p;
  }

  function dpr() { return Math.min(window.devicePixelRatio || 1, window.innerWidth < 640 ? 1.5 : 2); }

  var NOISE = [
    "float hash(vec2 p){ p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }",
    "float noise(vec2 p){ vec2 i = floor(p), f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);",
    "  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y); }",
    "float fbm(vec2 p){ float v = 0.0, a = 0.5; for (int i = 0; i < 5; i++){ v += a * noise(p); p *= 2.03; a *= 0.5; } return v; }"
  ].join("\n");

  /* =====================================================================
   * 1. Mực loang khi chuyển môn phái
   * ===================================================================== */

  var Ink = (function () {
    var canvas = document.createElement("canvas");
    canvas.className = "fx-ink";
    canvas.setAttribute("aria-hidden", "true");
    var gl = null, prog, buf, tex, loc = {}, raf = 0, active = null, broken = false;

    var VS = "attribute vec2 a_pos; varying vec2 v_uv;" +
      "void main(){ v_uv = vec2(a_pos.x * 0.5 + 0.5, 0.5 - a_pos.y * 0.5); gl_Position = vec4(a_pos, 0.0, 1.0); }";

    var FS = [
      "precision mediump float;",
      "uniform sampler2D u_tex; uniform float u_t; uniform vec3 u_ink; uniform vec2 u_origin; uniform float u_aspect; uniform float u_seed;",
      "varying vec2 v_uv;",
      NOISE,
      "void main(){",
      "  vec4 c = texture2D(u_tex, v_uv);",                       // premultiplied
      "  vec2 p = v_uv - u_origin; p.x *= u_aspect;",
      "  float r = length(p);",
      "  float n = fbm(v_uv * 3.5 + u_seed) - 0.5;",
      "  float grain = fbm(v_uv * 40.0 + u_seed * 3.0) - 0.5;",    // xơ giấy ở mép mực
      "  float d = u_t * 1.55 - (r + n * 0.5 + grain * 0.06);",
      "  float reveal = smoothstep(0.0, 0.07, d);",
      "  float fringe = smoothstep(-0.015, 0.03, d) * (1.0 - smoothstep(0.03, 0.2, d));",
      "  vec3 col = c.rgb * reveal; float a = c.a * reveal;",
      "  col = mix(col, u_ink * a, fringe * 0.8);",                // viền mực ăn vào nhân vật
      "  float stain = smoothstep(-0.02, 0.12, d + 0.05) * smoothstep(0.7, 0.1, r);",
      "  stain *= 0.5 * (1.0 - smoothstep(0.55, 1.0, u_t));",      // vệt mực tan dần về cuối
      "  col += u_ink * stain * (1.0 - a); a += stain * (1.0 - a);",
      "  gl_FragColor = vec4(col, a);",
      "}"
    ].join("\n");

    function init() {
      if (gl || broken) return !!gl;
      try {
        gl = createGL(canvas, true);
        if (!gl) { broken = true; return false; }
        prog = program(gl, VS, FS);
        buf = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, buf);
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
        tex = gl.createTexture();
        ["u_tex", "u_t", "u_ink", "u_origin", "u_aspect", "u_seed"].forEach(function (n) { loc[n] = gl.getUniformLocation(prog, n); });
        loc.a_pos = gl.getAttribLocation(prog, "a_pos");
        canvas.addEventListener("webglcontextlost", function (e) {
          e.preventDefault(); broken = true; gl = null; finish();
        });
        return true;
      } catch (err) {
        broken = true; gl = null; // shader lỗi: giữ chuyển cảnh CSS
        return false;
      }
    }

    function finish() {
      cancelAnimationFrame(raf);
      if (active) active.classList.remove("is-revealing");
      active = null;
      if (canvas.parentNode) canvas.parentNode.removeChild(canvas);
    }

    function draw(t, ink, origin, aspect, seed) {
      gl.viewport(0, 0, canvas.width, canvas.height);
      gl.clearColor(0, 0, 0, 0);
      gl.clear(gl.COLOR_BUFFER_BIT);
      gl.useProgram(prog);
      gl.bindBuffer(gl.ARRAY_BUFFER, buf);
      gl.enableVertexAttribArray(loc.a_pos);
      gl.vertexAttribPointer(loc.a_pos, 2, gl.FLOAT, false, 0, 0);
      gl.uniform1i(loc.u_tex, 0);
      gl.uniform1f(loc.u_t, t);
      gl.uniform3fv(loc.u_ink, ink);
      gl.uniform2fv(loc.u_origin, origin);
      gl.uniform1f(loc.u_aspect, aspect);
      gl.uniform1f(loc.u_seed, seed);
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    }

    // Vùng ảnh thực sự hiển thị (ảnh dùng object-fit: contain thì nhỏ hơn hộp <img>).
    function contentRect(img) {
      var bw = img.offsetWidth, bh = img.offsetHeight;
      var nw = img.naturalWidth, nh = img.naturalHeight;
      var cs = getComputedStyle(img);
      if (cs.objectFit !== "contain" || !nw || !nh) return { x: 0, y: 0, w: bw, h: bh };
      var k = Math.min(bw / nw, bh / nh);
      var w = nw * k, h = nh * k;
      var pos = cs.objectPosition.split(" ");
      var fx = parseFloat(pos[0]) / 100, fy = parseFloat(pos[1] || pos[0]) / 100;
      if (isNaN(fx)) fx = 0.5;
      if (isNaN(fy)) fy = 0.5;
      return { x: (bw - w) * fx, y: (bh - h) * fy, w: w, h: h };
    }

    function run(target, img) {
      var art = img.parentNode;
      var r = contentRect(img);
      var w = r.w, h = r.h;
      if (!w || !h) return false;
      var ratio = dpr();
      canvas.width = Math.round(w * ratio);
      canvas.height = Math.round(h * ratio);
      canvas.style.left = img.offsetLeft + r.x + "px";
      canvas.style.top = img.offsetTop + r.y + "px";
      canvas.style.width = w + "px";
      canvas.style.height = h + "px";
      art.appendChild(canvas);

      gl.bindTexture(gl.TEXTURE_2D, tex);
      gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
      try {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img);
      } catch (err) {
        // Mở trang từ file:// thì ảnh bị coi là khác nguồn, WebGL không được đọc.
        // Tắt mực loang cho cả phiên, để chuyển cảnh CSS thay thế.
        broken = true;
        if (canvas.parentNode) canvas.parentNode.removeChild(canvas);
        return false;
      }
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

      var ink = tokenRGB("--sect", target);
      var origin = [0.45 + Math.random() * 0.1, 0.42 + Math.random() * 0.12];
      var aspect = w / h;
      var seed = Math.random() * 50;
      var start = performance.now(), dur = 1150;

      active = target;
      target.classList.add("is-revealing");
      (function frame(now) {
        if (!gl) return finish();
        var x = Math.min(1, (now - start) / dur);
        var t = x < 0.5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2; // ease-in-out: giọt mực rơi, rồi loang
        draw(t, ink, origin, aspect, seed);
        if (x < 1) raf = requestAnimationFrame(frame);
        else finish();
      })(start);
      return true;
    }

    return {
      // target: phần tử nhận màu --sect và class is-revealing; img: ảnh cần loang (mặc định .panel__figure trong target).
      reveal: function (target, img) {
        if (motionQuery.matches || broken || !init()) return false;
        finish();
        img = img || target.querySelector(".panel__figure");
        if (!img) return false;
        if (img.complete && img.naturalWidth) return run(target, img);
        // Ảnh chưa tải xong: ẩn tạm, chờ decode rồi chạy.
        target.classList.add("is-revealing");
        active = target;
        (img.decode ? img.decode() : Promise.reject())
          .then(function () {
            if (active !== target || target.hidden) return;
            active = null;
            if (!run(target, img)) { target.classList.remove("is-revealing"); finish(); }
          })
          .catch(function () { finish(); });
        return true;
      }
    };
  })();

  /* =====================================================================
   * 2. Hoa đào + lá trúc bay
   * ===================================================================== */

  function Petals(canvas) {
    var host = canvas.parentNode;
    var gl = createGL(canvas);
    if (!gl) return;

    var VS = [
      "attribute vec2 a_pos; attribute vec4 a_attr; uniform vec2 u_res;",
      "varying float v_rot; varying float v_flip; varying float v_type; varying float v_alpha;",
      "void main(){",
      "  vec2 clip = a_pos / u_res * 2.0 - 1.0; clip.y = -clip.y;",
      "  gl_Position = vec4(clip, 0.0, 1.0);",
      "  gl_PointSize = a_attr.x;",
      "  v_rot = a_attr.y; v_flip = a_attr.z; v_type = step(0.0, a_attr.w); v_alpha = abs(a_attr.w);",
      "}"
    ].join("\n");

    var FS = [
      "precision mediump float;",
      "uniform vec3 u_petal; uniform vec3 u_leaf;",
      "varying float v_rot; varying float v_flip; varying float v_type; varying float v_alpha;",
      "void main(){",
      "  vec2 p = gl_PointCoord * 2.0 - 1.0;",
      "  float c = cos(v_rot), s = sin(v_rot);",
      "  p = mat2(c, -s, s, c) * p;",
      "  p.x /= max(abs(cos(v_flip)), 0.18);",                       // lật mặt khi rơi
      "  float a; vec3 col;",
      "  if (v_type < 0.5) {",                                       // cánh hoa đào
      "    float d = length(vec2(p.x * 1.3, p.y * 0.95 + 0.05));",
      "    a = 1.0 - smoothstep(0.7, 0.8, d);",
      "    a *= smoothstep(0.08, 0.26, length(p - vec2(0.0, -0.78)));", // khía đầu cánh
      "    col = mix(u_petal, u_petal * 0.86, smoothstep(0.45, 0.0, abs(p.x)) * 0.6);",
      "  } else {",                                                  // lá trúc
      "    float taper = 1.0 - smoothstep(0.1, 1.0, abs(p.y));",
      "    a = 1.0 - smoothstep(0.82, 0.92, length(vec2(p.x * 4.2 / max(taper, 0.25), p.y)));",
      "    col = mix(u_leaf, u_leaf * 0.75, smoothstep(0.1, 0.0, abs(p.x)));",
      "  }",
      "  a *= v_alpha;",
      "  gl_FragColor = vec4(col * a, a);",
      "}"
    ].join("\n");

    var prog;
    try { prog = program(gl, VS, FS); } catch (err) {
      return;
    }

    var leafRatio = parseFloat(canvas.dataset.leaf || "0.3");
    var count = window.innerWidth < 640 ? +(canvas.dataset.countMobile || 10) : +(canvas.dataset.count || 20);
    var STRIDE = 6; // x, y, size, rot, flip, alpha*(type)
    var data = new Float32Array(count * STRIDE);
    var parts = [];
    var W = 0, H = 0, ratio = 1;
    var wind = 22, windTarget = 22;

    var buf = gl.createBuffer();
    var aPos = gl.getAttribLocation(prog, "a_pos");
    var aAttr = gl.getAttribLocation(prog, "a_attr");
    var uRes = gl.getUniformLocation(prog, "u_res");
    var uPetal = gl.getUniformLocation(prog, "u_petal");
    var uLeaf = gl.getUniformLocation(prog, "u_leaf");
    var petal = tokenRGB("--color-petal"), leaf = tokenRGB("--color-leaf");

    function spawn(p, anywhere) {
      p.leaf = Math.random() < leafRatio;
      p.z = 0.45 + Math.random() * 0.55;                       // độ sâu: xa thì nhỏ, chậm, nhạt
      p.size = (p.leaf ? 52 : 34) * p.z * (0.8 + Math.random() * 0.5);
      p.x = anywhere ? Math.random() * W : -40 + Math.random() * W * 0.6;
      p.y = anywhere ? Math.random() * H : -40 - Math.random() * H * 0.3;
      if (!anywhere && Math.random() < 0.5) { p.x = -40; p.y = Math.random() * H * 0.7; }
      p.rot = Math.random() * 6.28;
      p.vr = (Math.random() - 0.5) * 1.6;
      p.flip = Math.random() * 6.28;
      p.vf = 0.8 + Math.random() * 1.6;
      p.phase = Math.random() * 6.28;
      p.alpha = (p.leaf ? 0.55 : 0.8) * (0.55 + p.z * 0.45);
    }

    for (var i = 0; i < count; i++) { parts.push({}); }

    function resize() {
      var r = host.getBoundingClientRect();
      ratio = dpr();
      W = r.width; H = r.height;
      canvas.width = Math.max(1, Math.round(W * ratio));
      canvas.height = Math.max(1, Math.round(H * ratio));
      parts.forEach(function (p) { spawn(p, true); });
    }

    var t = 0, last = 0, raf = 0;
    var state = { visible: false, pageVisible: !document.hidden, motion: !motionQuery.matches, lost: false };

    function step(dt) {
      wind += (windTarget - wind) * Math.min(1, dt * 1.5);
      for (var i = 0; i < parts.length; i++) {
        var p = parts[i];
        var fall = (p.leaf ? 26 : 20) + 34 * p.z;
        p.y += fall * dt;
        p.x += (wind * p.z + Math.sin(t * 0.9 + p.phase) * 16) * dt;
        p.rot += p.vr * dt;
        p.flip += p.vf * dt;
        if (p.y > H + 40 || p.x > W + 40) spawn(p, false);
        var o = i * STRIDE;
        data[o] = p.x * ratio; data[o + 1] = p.y * ratio;
        data[o + 2] = p.size * ratio; data[o + 3] = p.rot; data[o + 4] = p.flip;
        data[o + 5] = p.leaf ? p.alpha : -p.alpha;
      }
    }

    function render() {
      gl.viewport(0, 0, canvas.width, canvas.height);
      gl.clearColor(0, 0, 0, 0);
      gl.clear(gl.COLOR_BUFFER_BIT);
      gl.enable(gl.BLEND);
      gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
      gl.useProgram(prog);
      gl.uniform2f(uRes, canvas.width, canvas.height);
      gl.uniform3fv(uPetal, petal);
      gl.uniform3fv(uLeaf, leaf);
      gl.bindBuffer(gl.ARRAY_BUFFER, buf);
      gl.bufferData(gl.ARRAY_BUFFER, data, gl.DYNAMIC_DRAW);
      gl.enableVertexAttribArray(aPos);
      gl.vertexAttribPointer(aPos, 2, gl.FLOAT, false, STRIDE * 4, 0);
      gl.enableVertexAttribArray(aAttr);
      gl.vertexAttribPointer(aAttr, 4, gl.FLOAT, false, STRIDE * 4, 8);
      gl.drawArrays(gl.POINTS, 0, parts.length);
    }

    function loop(now) {
      var dt = Math.min(0.05, (now - last) / 1000 || 0.016);
      last = now; t += dt;
      step(dt); render();
      raf = requestAnimationFrame(loop);
    }

    function update() {
      var run = state.visible && state.pageVisible && state.motion && !state.lost;
      if (run && !raf) { last = performance.now(); canvas.classList.add("is-live"); raf = requestAnimationFrame(loop); }
      else if (!run && raf) { cancelAnimationFrame(raf); raf = 0; }
      if (!state.motion || state.lost) canvas.classList.remove("is-live");
    }

    resize();
    new ResizeObserver(function () { resize(); }).observe(host);
    new IntersectionObserver(function (entries) {
      state.visible = entries[0].isIntersecting; update();
    }, { rootMargin: "80px" }).observe(host);
    document.addEventListener("visibilitychange", function () { state.pageVisible = !document.hidden; update(); });
    motionQuery.addEventListener("change", function () { state.motion = !motionQuery.matches; update(); });
    canvas.addEventListener("webglcontextlost", function (e) { e.preventDefault(); state.lost = true; update(); });
    host.addEventListener("pointermove", function (e) {
      var r = host.getBoundingClientRect();
      windTarget = 22 + ((e.clientX - r.left) / r.width - 0.5) * 50; // gió nhẹ theo con trỏ
    }, { passive: true });
    host.addEventListener("pointerleave", function () { windTarget = 22; });
  }

  document.querySelectorAll('canvas[data-fx="petals"]').forEach(function (c) { Petals(c); });

  window.JXFX = { reveal: Ink.reveal };
})();
