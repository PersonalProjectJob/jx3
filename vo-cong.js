(function () {
  "use strict";

  /* ---------- Dữ liệu ---------- */

  var SECTS = window.JX_SECTS;
  var SKILLS = window.JX_SKILLS;
  var SETS = window.JX_SETS || [];

  var main = document.getElementById("main");
  var tabsEl = document.getElementById("vc-tabs");
  var panelEl = document.getElementById("vc-panel");

  if (!Array.isArray(SECTS) || !Array.isArray(SKILLS) || !SECTS.length || !tabsEl || !panelEl) {
    if (main) {
      main.innerHTML = '<div class="container vc"><p class="vc__notice">Không tải được dữ liệu võ công. Tải lại trang để thử lại.</p></div>';
    }
    return;
  }

  var overviewEl = document.getElementById("vc-overview");
  var keyEl = document.getElementById("vc-key");
  var keyListEl = document.getElementById("vc-keylist");
  var finderEl = document.querySelector("#vc-catalog .finder");
  var catalogTitleEl = document.getElementById("vc-catalog-title");
  var searchEl = document.getElementById("vc-search");
  var statusEl = document.getElementById("vc-status");
  var listEl = document.getElementById("vc-list");
  var countEl = document.getElementById("vc-count");

  // Sáu nhãn vai trò, theo chiều kim đồng hồ từ trên của vòng chỉ số. Số trục của vòng đọc từ danh sách này.
  var AXES = [
    { key: "sat_thuong", label: "Sát thương" },
    { key: "khong_che", label: "Khống chế" },
    { key: "ho_tro", label: "Hỗ trợ" },
    { key: "tri_lieu", label: "Trị liệu" },
    { key: "phong_thu", label: "Phòng thủ" },
    { key: "co_dong", label: "Cơ động" }
  ];
  var axisLabel = Object.create(null);
  AXES.forEach(function (a) { axisLabel[a.key] = a.label; });

  // Phân loại vai trò của từng chiêu (data/skill-roles.js). Thiếu file hoặc thiếu chiêu thì chỉ bỏ dòng "Vai trò", không lỗi.
  var rolesById = Object.create(null);
  (function () {
    var src = window.JX_SKILL_ROLES;
    if (!src || typeof src !== "object") return;
    Object.keys(src).forEach(function (id) {
      var r = src[id];
      if (r && Array.isArray(r.tags)) rolesById[id] = r.tags;
    });
  })();

  // Kích thước ảnh nhân vật (để giữ đúng tỉ lệ, tránh nhảy bố cục)
  var ART_SIZE = {
    "thien-sach": [934, 1000], "thuan-duong": [850, 938], "van-hoa": [859, 861],
    "that-tu": [899, 1000], "thieu-lam": [1053, 873], "tang-kiem": [1207, 929],
    "ngu-doc": [923, 902], "duong-mon": [974, 850], "minh-giao": [956, 744]
  };

  // Bảng tra không có prototype: khoá lấy từ URL như "constructor" hay "__proto__" không được trùng thuộc tính của Object.
  var sectById = Object.create(null);
  var setById = Object.create(null);
  var skillById = Object.create(null);
  var skillsBySect = Object.create(null);
  SECTS.forEach(function (s) { sectById[s.id] = s; skillsBySect[s.id] = []; });
  SETS.forEach(function (s) { setById[s.id] = s; });
  SKILLS.forEach(function (k) {
    skillById[k.id] = k;
    if (skillsBySect[k.sect]) skillsBySect[k.sect].push(k);
  });

  /* ---------- Tiện ích ---------- */

  function esc(v) {
    return String(v == null ? "" : v)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
  }

  function fold(v) {
    return String(v == null ? "" : v)
      .toLowerCase()
      .replace(/đ/g, "d")
      .normalize("NFD")
      .replace(/[̀-ͯ]/g, "");
  }

  function dash(v) { return v == null || v === "" ? "—" : esc(v); }

  var haystack = null;
  function buildHaystack() {
    haystack = SKILLS.map(function (k) {
      return fold([k.name, k.poem, k.mota].concat(k.extra || []).join(" "));
    });
  }

  /* ---------- Trạng thái + hash ---------- */

  var state = { sect: SECTS[0].id, xinfa: "", query: "" };

  function parseHash() {
    var raw = location.hash.replace(/^#/, "");
    var parts = raw.split("/");
    var sectId = "", xinfaId = "";
    // Giải mã riêng từng phần: một phần hỏng không làm mất phần còn lại (tâm pháp hỏng vẫn giữ phái).
    try { sectId = decodeURIComponent(parts[0] || ""); } catch (err) { sectId = ""; }
    try { xinfaId = decodeURIComponent(parts[1] || ""); } catch (err) { xinfaId = ""; }
    var sect = sectId ? sectById[sectId] : null;
    if (!sect) return { sect: SECTS[0].id, xinfa: "" };
    var okXinfa = (sect.xinfa || []).some(function (x) { return x.id === xinfaId; });
    return { sect: sect.id, xinfa: okXinfa ? xinfaId : "" };
  }

  // Tâm pháp đầu của phái là mặc định (hiện sẵn, không cần ghi vào hash). Chỉ khi người dùng tự đổi tâm pháp mới ghi "#phái/tâm-pháp".
  function firstXinfa(sect) {
    var list = sect.xinfa || [];
    return list.length ? list[0].id : "";
  }

  function writeHash(withXinfa) {
    var h = "#" + state.sect + (withXinfa && state.xinfa ? "/" + state.xinfa : "");
    if (location.hash === h) return;
    try { history.replaceState(null, "", location.pathname + location.search + h); } catch (err) { /* file:// hoặc iframe: bỏ qua */ }
  }

  /* ---------- Đếm tổng ---------- */

  (function () {
    var seen = Object.create(null), sets = 0;
    SKILLS.forEach(function (k) { if (k.set != null && !seen[k.set]) { seen[k.set] = 1; sets += 1; } });
    countEl.textContent = SKILLS.length + " chiêu thức · " + SECTS.length + " môn phái · " + sets + " bộ võ công";
  })();

  /* ---------- Tab môn phái ---------- */

  tabsEl.innerHTML = SECTS.map(function (s) {
    return '<button class="tab" role="tab" type="button" id="tab-' + esc(s.id) + '" style="--sect: var(--color-sect-' + esc(s.id) + ')" aria-controls="vc-panel" aria-selected="false" tabindex="-1">' +
      '<span class="tab__han" lang="zh-Hans">' + esc(s.han) + '</span><span class="tab__vi">' + esc(s.name) + '</span></button>';
  }).join("");
  var tabs = Array.prototype.slice.call(tabsEl.querySelectorAll('[role="tab"]'));

  function markTabs() {
    tabs.forEach(function (tab, i) {
      var active = SECTS[i].id === state.sect;
      tab.setAttribute("aria-selected", active ? "true" : "false");
      tab.tabIndex = active ? 0 : -1;
    });
    panelEl.setAttribute("aria-labelledby", "tab-" + state.sect);
    panelEl.style.setProperty("--sect", "var(--color-sect-" + state.sect + ")");
  }

  tabs.forEach(function (tab, i) {
    tab.addEventListener("click", function () { selectSect(SECTS[i].id, "", false); });  // đổi phái: tâm pháp về tâm pháp đầu
    tab.addEventListener("keydown", function (e) {
      var next = null;
      if (e.key === "ArrowRight") next = (i + 1) % tabs.length;
      else if (e.key === "ArrowLeft") next = (i - 1 + tabs.length) % tabs.length;
      else if (e.key === "Home") next = 0;
      else if (e.key === "End") next = tabs.length - 1;
      if (next === null) return;
      e.preventDefault();
      selectSect(SECTS[next].id, "", true);
    });
  });

  function selectSect(id, xinfa, moveFocus, fromHash) {
    var changed = id !== state.sect;
    var sect = sectById[id];
    state.sect = id;
    // Chưa chọn hoặc id lạ thì rơi về tâm pháp đầu của phái
    state.xinfa = (sect.xinfa || []).some(function (x) { return x.id === xinfa; }) ? xinfa : firstXinfa(sect);
    markTabs();
    if (changed || !overviewEl.firstChild) { renderOverview(); renderKeySkills(); renderXFilter(); }
    renderXinfa();
    syncXFilter();
    renderCatalog();
    var tab = tabs[SECTS.indexOf(sect)];
    if (moveFocus) tab.focus({ preventScroll: true });
    centerTab(tab);
    if (!fromHash) writeHash(false);
  }

  // Đổi tâm pháp trong cùng phái (bấm hoặc phím, từ hàng tab đầu trang hoặc hàng nút trên danh sách chiêu):
  // không dựng lại video, chỉ đổi vòng chỉ số, nội dung và danh sách bộ chiêu.
  function selectXinfa(xinfaId, moveFocus) {
    var sect = sectById[state.sect];
    if (!(sect.xinfa || []).some(function (x) { return x.id === xinfaId; })) return;
    state.xinfa = xinfaId;
    renderXinfa();
    syncXFilter();
    if (!isSearching()) renderCatalog();  // đang tìm thì kết quả tìm toàn cục giữ nguyên, quay về danh sách tâm pháp khi xoá ô tìm
    if (moveFocus) {
      var btn = xtabButtons().filter(function (b) { return b.getAttribute("data-xinfa") === xinfaId; })[0];
      if (btn) btn.focus({ preventScroll: true });
    }
    writeHash(true);
  }

  // Đưa tab đang chọn vào giữa ô cuộn ngang (tab kế bên có thể bị cắt, tab đang chọn luôn hiện đủ).
  function centerTab(tab) {
    var box = tabsEl.getBoundingClientRect();
    var r = tab.getBoundingClientRect();
    var delta = (r.left + r.width / 2) - (box.left + box.width / 2);
    if (Math.abs(delta) < 1) return;
    tabsEl.scrollLeft += delta;
  }

  // Font web nạp xong làm tab rộng ra sau lần căn đầu tiên: căn lại tab đang chọn cho tới khi người dùng tự cuộn
  // hoặc hết thời gian chờ ổn định bố cục. Không bao giờ giật vị trí khi người dùng đang kéo tay.
  var tabsTouched = false;
  var tabsSettling = true;
  function recenterActive() {
    if (tabsTouched) return;
    var tab = tabs[SECTS.indexOf(sectById[state.sect])];
    if (tab) centerTab(tab);
  }
  ["pointerdown", "wheel", "touchstart", "keydown"].forEach(function (type) {
    tabsEl.addEventListener(type, function () { tabsTouched = true; }, { passive: true });
  });
  setTimeout(function () { tabsSettling = false; }, 3000);
  if (document.fonts && document.fonts.ready && typeof document.fonts.ready.then === "function") {
    document.fonts.ready.then(recenterActive);
  }
  window.addEventListener("load", recenterActive);
  if (typeof ResizeObserver === "function") {
    var tabsObserver = new ResizeObserver(function () { if (tabsSettling) recenterActive(); });
    tabsObserver.observe(tabsEl);
    tabs.forEach(function (tab) { tabsObserver.observe(tab); });
  }

  /* ---------- Tổng quan phái ---------- */

  function videoButton(yt, label, size) {
    return '<button class="video' + (size ? " video--" + size : "") + '" type="button" data-yt="' + esc(yt) + '" aria-label="Phát video: ' + esc(label) + '">' +
      '<img src="https://i.ytimg.com/vi/' + encodeURIComponent(yt) + '/hqdefault.jpg" alt="" width="480" height="360" loading="lazy" decoding="async" />' +
      '<span class="video__play" aria-hidden="true"><svg viewBox="0 0 24 24" focusable="false"><path d="M8 5.5v13l10-6.5z"/></svg></span></button>';
  }

  // Nguồn video: lấy từ data/sects.js (JX_VIDEO_SOURCE); thiếu hoặc sai dạng thì dùng giá trị mặc định trùng dữ liệu.
  var VIDEO_SOURCE = (function () {
    var s = window.JX_VIDEO_SOURCE || {};
    return {
      channel: typeof s.channel === "string" && s.channel ? s.channel : "VÕ LÂM TRUYỀN KỲ 3",
      url: typeof s.url === "string" && /^https:\/\/www\.youtube\.com\//.test(s.url) ? s.url : "https://www.youtube.com/@VLTKPhienBan3D"
    };
  })();

  // Dòng nguồn ngay dưới khung video: Nguồn: “<tiêu đề>” · kênh YouTube chính thức <kênh>.
  // Không có tiêu đề thì bỏ liên kết tiêu đề, chỉ ghi kênh. Khoảng trắng liên tiếp trong tiêu đề gộp thành một.
  function sourceLine(yt, title) {
    var clean = typeof title === "string" ? title.replace(/\s+/g, " ").trim() : "";
    var channel = '<a href="' + esc(VIDEO_SOURCE.url) + '" target="_blank" rel="noopener">' + esc(VIDEO_SOURCE.channel) + '</a>';
    if (!clean) return '<p class="source">Nguồn: kênh YouTube chính thức ' + channel + '</p>';
    return '<p class="source">Nguồn: “<a href="https://www.youtube.com/watch?v=' + encodeURIComponent(yt) + '" target="_blank" rel="noopener">' + esc(clean) + '</a>” · kênh YouTube chính thức ' + channel + '</p>';
  }

  var SCORE_MIN = 3;    // điểm thấp nhất: không trục nào về 0, đa giác không bao giờ co về tâm
  var SCORE_MAX = 10;   // thang điểm tuyệt đối 3..10 (data/sects.js: ring.scores), không chuẩn hoá giữa các tâm pháp

  // Điểm của tâm pháp: object 6 khoá số nguyên 3..10 (số < 3 trong dữ liệu được ép lên 3), hoặc null nếu chưa chấm/sai dạng (khi đó ẩn vòng, danh sách điểm và nhận định).
  function readScores(ring) {
    var sc = ring && ring.scores;
    if (!sc || typeof sc !== "object") return null;
    var out = Object.create(null);
    for (var i = 0; i < AXES.length; i++) {
      var v = Number(sc[AXES[i].key]);
      if (!isFinite(v)) return null;
      out[AXES[i].key] = Math.max(SCORE_MIN, Math.min(SCORE_MAX, Math.round(v)));
    }
    return out;
  }

  // Lý do chấm điểm của một trục (chuỗi hoặc rỗng).
  function whyOf(ring, key) {
    var w = ring && ring.why;
    return w && typeof w === "object" && typeof w[key] === "string" ? w[key].trim() : "";
  }

  // Vòng chỉ số N trục (N = AXES.length) của MỘT tâm pháp, vẽ theo điểm/10. Màu chỉ qua class CSS (theo màu phái, --sect).
  function ringSvg(xinfa, scores) {
    var n = AXES.length;
    var cx = 190, cy = 120, R = 84;
    function pt(i, r) {
      var a = i * 2 * Math.PI / n;
      return [cx + r * Math.sin(a), cy - r * Math.cos(a)];
    }
    function fmt(p) { return p[0].toFixed(1) + "," + p[1].toFixed(1); }
    var grid = [0.2, 0.4, 0.6, 0.8, 1].map(function (f) {
      var pts = AXES.map(function (_, i) { return fmt(pt(i, R * f)); }).join(" ");
      return '<polygon class="ring__grid" points="' + pts + '"/>';
    }).join("");
    var spokes = AXES.map(function (_, i) {
      var p = pt(i, R);
      return '<line class="ring__axis" x1="' + cx + '" y1="' + cy + '" x2="' + p[0].toFixed(1) + '" y2="' + p[1].toFixed(1) + '"/>';
    }).join("");
    var dataPts = AXES.map(function (a, i) { return pt(i, R * scores[a.key] / SCORE_MAX); });
    var area = '<polygon class="ring__area" points="' + dataPts.map(fmt).join(" ") + '"/>';
    var dots = dataPts.map(function (p) {
      return '<circle class="ring__dot" cx="' + p[0].toFixed(1) + '" cy="' + p[1].toFixed(1) + '" r="3.5"/>';
    }).join("");
    var labels = AXES.map(function (a, i) {
      var p = pt(i, R);
      var s = Math.sin(i * 2 * Math.PI / n), c = Math.cos(i * 2 * Math.PI / n);
      var anchor = Math.abs(s) < 0.2 ? "middle" : (s > 0 ? "start" : "end");
      var x = p[0] + (anchor === "start" ? 10 : anchor === "end" ? -10 : 0);
      var y = p[1] + (c > 0.8 ? -12 : c < -0.8 ? 22 : 5);
      // Trục điểm cao (>= 8) in đậm theo màu phái
      return '<text class="ring__label' + (scores[a.key] >= 8 ? ' ring__label--hi' : '') + '" text-anchor="' + anchor + '" x="' + x.toFixed(1) + '" y="' + y.toFixed(1) + '">' + esc(a.label) + '</text>';
    }).join("");
    var summary = "Đánh giá tổng quan của tâm pháp " + xinfa.name + ": " + AXES.map(function (a) { return a.label + " " + scores[a.key] + "/" + SCORE_MAX; }).join(", ");
    return '<svg class="ring" viewBox="0 0 380 ' + (cy + R + 34) + '" role="img" aria-label="' + esc(summary) + '" focusable="false">' +
      grid + spokes + area + dots + labels + '</svg>';
  }

  // Danh sách 6 dòng điểm theo thứ tự trục cố định (đúng thứ tự quanh vòng, để các tâm pháp so sánh được): tên trục, điểm/10, lý do, thanh điểm.
  function scoreList(ring, scores) {
    return '<ul class="scorelist">' + AXES.map(function (a) {
      var why = whyOf(ring, a.key);
      return '<li class="score' + (scores[a.key] >= 8 ? ' score--hi' : '') + '" style="--score: ' + scores[a.key] + '">' +
        '<div class="score__head"><span class="score__name">' + esc(a.label) + '</span><span class="score__val">' + scores[a.key] + '/' + SCORE_MAX + '</span></div>' +
        (why ? '<p class="score__why">' + esc(why) + '</p>' : '') +
        '<span class="score__bar" aria-hidden="true"><span class="score__fill"></span></span></li>';
    }).join("") + '</ul>';
  }

  function ownSkills(sectId, xinfaId) {
    return (skillsBySect[sectId] || []).filter(function (k) { return k.xinfa === xinfaId; });
  }

  function sharedCount(sectId) {
    return (skillsBySect[sectId] || []).filter(function (k) { return k.xinfa == null; }).length;
  }

  function findXinfa(sect, id) {
    var list = sect.xinfa || [];
    for (var i = 0; i < list.length; i++) if (list[i].id === id) return list[i];
    return null;
  }

  function xtabButtons() {
    return Array.prototype.slice.call(overviewEl.querySelectorAll('.xtab'));
  }

  // Phần cố định theo phái: tiêu đề, video/ảnh, hàng chọn tâm pháp và khung nội dung tâm pháp.
  // Video "Học kỹ năng" là dữ liệu cấp phái: dựng một lần ở đây (cột trái của panel, dưới phần chữ) và renderXinfa không đụng tới,
  // nên đổi tâm pháp không làm iframe đang phát bị dựng lại. renderXinfa chỉ điền .xpanel__text và .xpanel__ring.
  function renderOverview() {
    var sect = sectById[state.sect];
    var yt = sect.video && sect.video.yt;
    var size = ART_SIZE[sect.id] || [900, 900];
    var media = yt
      ? videoButton(yt, "Giới thiệu phái " + sect.name) + sourceLine(yt, sect.video.title)
      :'<figure class="sectart"><span class="sectart__ghost" lang="zh-Hans" aria-hidden="true">' + esc(sect.han) + '</span>' +
        '<img class="sectart__img" src="assets/sects/' + esc(sect.id) + '.webp" alt="Nhân vật phái ' + esc(sect.name) + '" width="' + size[0] + '" height="' + size[1] + '" loading="lazy" decoding="async" /></figure>';

    var sv = sect.skillVideo;
    var svYt = sv && typeof sv === "object" && sv.yt ? sv.yt : "";
    var skillVideo = svYt
      ? '<div class="xvideo">' + videoButton(svYt, "Học kỹ năng phái " + sect.name) + sourceLine(svYt, sv.title) + '</div>'
      : "";

    var xs = sect.xinfa || [];
    var xtabs = xs.length
      ? '<div class="xtabs" role="tablist" aria-label="Tâm pháp phái ' + esc(sect.name) + '">' + xs.map(function (x) {
          return '<button class="xtab" role="tab" type="button" id="xtab-' + esc(x.id) + '" data-xinfa="' + esc(x.id) + '" aria-controls="vc-xpanel" aria-selected="false" tabindex="-1">' +
            '<span class="xtab__name">' + esc(x.name) + '</span><span class="xtab__tag">' + esc(x.tag) + '</span></button>';
        }).join("") + '</div>' +
        '<div class="xpanel" id="vc-xpanel" role="tabpanel" tabindex="0">' +
          '<div class="xpanel__grid">' +
            '<div class="xpanel__info"><div class="xpanel__text"></div>' + skillVideo + '</div>' +
            '<div class="xpanel__ring"></div>' +
          '</div>' +
        '</div>'
      : '';

    // Mô tả ngắn, ghi chú và tiểu sử của phái (sect.intro / sect.note / sect.story từ data/sects.js) ở cột phải cạnh video/ảnh; mỗi phần thiếu hoặc sai dạng thì chỉ ẩn phần đó, không có phần nào thì ẩn cột.
    var introText = typeof sect.intro === "string" ? sect.intro.trim() : "";
    var noteText = typeof sect.note === "string" ? sect.note.trim() : "";
    var storyText = typeof sect.story === "string" ? sect.story.trim() : "";
    var intro = introText || noteText || storyText
      ? '<div class="overview__intro">' +
          (introText ? '<p class="sectintro">' + esc(introText) + '</p>' : '') +
          (noteText ? '<p class="sectnote">' + esc(noteText) + '</p>' : '') +
          (storyText ? '<p class="sectstory">' + esc(storyText) + '</p>' : '') +
        '</div>'
      : '';

    overviewEl.innerHTML =
      '<h2 class="vc__sect">' + esc(sect.name) + '</h2>' +
      '<div class="overview__top">' +
        '<div class="overview__media">' + media + '</div>' +
        intro +
      '</div>' +
      xtabs;
  }

  // Nội dung của tâm pháp đang chọn: tên, tag, giới thiệu (nếu có), số chiêu riêng/chung (cột trái, video phái nằm dưới) và vòng chỉ số (cột phải).
  function renderXinfa() {
    var sect = sectById[state.sect];
    var btns = xtabButtons();
    var panel = document.getElementById("vc-xpanel");
    if (!btns.length || !panel) return;
    var textEl = panel.querySelector(".xpanel__text");
    var ringEl = panel.querySelector(".xpanel__ring");
    if (!textEl || !ringEl) return;
    btns.forEach(function (b) {
      var active = b.getAttribute("data-xinfa") === state.xinfa;
      b.setAttribute("aria-selected", active ? "true" : "false");
      b.tabIndex = active ? 0 : -1;
    });
    var x = findXinfa(sect, state.xinfa);
    if (!x) { textEl.innerHTML = ""; ringEl.innerHTML = ""; return; }
    panel.setAttribute("aria-labelledby", "xtab-" + x.id);

    var own = ownSkills(sect.id, x.id);
    var shared = sharedCount(sect.id);

    // Chưa chấm điểm (ring.scores null): ẩn vòng, danh sách điểm và nhận định
    var ring = x.ring || {};
    var scores = readScores(ring);
    var verdict = "";
    if (scores) {
      if (typeof ring.summary === "string" && ring.summary.trim()) verdict += '<p class="xsummary">' + esc(ring.summary.trim()) + '</p>';
      if (ring.draft === true) verdict += '<p class="xnote">Nhận định tự động từ mô tả chiêu, đang chờ duyệt.</p>';
    }

    var desc = typeof x.desc === "string" && x.desc.trim() ? '<p class="xdesc">' + esc(x.desc) + '</p>' : "";

    textEl.innerHTML =
      '<h3 class="vc__h3 vc__h3--sm xpanel__name">' + esc(x.name) + '</h3>' +
      '<p class="xpanel__tag">' + esc(x.tag) + '</p>' +
      verdict +
      desc +
      '<p class="xfacts">' + own.length + ' chiêu riêng · ' + shared + ' chiêu dùng chung với tâm pháp còn lại của phái</p>';
    ringEl.hidden = !scores;
    ringEl.innerHTML = scores
      ? '<h4 class="vc__h4">Đánh giá tổng quan của tâm pháp</h4><p class="ringscale">Thang ' + SCORE_MIN + '–' + SCORE_MAX + ' (thấp nhất ' + SCORE_MIN + ')</p>' +
        ringSvg(x, scores) + scoreList(ring, scores)
      : "";
  }

  /* ---------- Hàng nút tâm pháp trên danh sách chiêu ---------- */

  // Nhóm 2 nút (mỗi tâm pháp của phái) đặt dưới tiêu đề danh sách, trên ô tìm: đổi tâm pháp mà không phải cuộn lên đầu trang.
  // Dựng lại khi đổi phái; đổi tâm pháp chỉ đổi aria-pressed (nút giữ nguyên nên tiêu điểm bàn phím không mất).
  // Bàn phím: mỗi nút là một điểm dừng Tab (nút bật/tắt thường, không roving).
  var xfilterEl = null;
  if (finderEl && finderEl.parentNode) {
    xfilterEl = document.createElement("div");
    xfilterEl.className = "xfilter";
    xfilterEl.setAttribute("role", "group");
    xfilterEl.hidden = true;
    finderEl.parentNode.insertBefore(xfilterEl, finderEl);
    xfilterEl.addEventListener("click", function (e) {
      var btn = e.target.closest ? e.target.closest(".xchip") : null;
      if (!btn) return;
      selectXinfa(btn.getAttribute("data-xinfa"), false);
      btn.focus({ preventScroll: true });
    });
  }

  function renderXFilter() {
    if (!xfilterEl) return;
    var sect = sectById[state.sect];
    var xs = sect.xinfa || [];
    xfilterEl.setAttribute("aria-label", "Chọn tâm pháp phái " + sect.name + " để xem chiêu thức");
    xfilterEl.innerHTML = xs.map(function (x) {
      return '<button class="xchip" type="button" data-xinfa="' + esc(x.id) + '" aria-pressed="false">' +
        esc(x.name) + ' · ' + sectSkillsFor(x.id).length + '</button>';
    }).join("");
  }

  function syncXFilter() {
    if (!xfilterEl) return;
    Array.prototype.forEach.call(xfilterEl.querySelectorAll(".xchip"), function (b) {
      b.setAttribute("aria-pressed", b.getAttribute("data-xinfa") === state.xinfa ? "true" : "false");
    });
  }

  overviewEl.addEventListener("click", function (e) {
    var btn = e.target.closest ? e.target.closest(".xtab") : null;
    if (btn) selectXinfa(btn.getAttribute("data-xinfa"), false);
  });
  overviewEl.addEventListener("keydown", function (e) {
    var btn = e.target.closest ? e.target.closest(".xtab") : null;
    if (!btn) return;
    var list = xtabButtons();
    var i = list.indexOf(btn), next = null;
    if (e.key === "ArrowRight") next = (i + 1) % list.length;
    else if (e.key === "ArrowLeft") next = (i - 1 + list.length) % list.length;
    else if (e.key === "Home") next = 0;
    else if (e.key === "End") next = list.length - 1;
    if (next === null) return;
    e.preventDefault();
    selectXinfa(list[next].getAttribute("data-xinfa"), true);
  });


  /* ---------- Chiêu then chốt ---------- */

  function iconBox(skill, cls) {
    if (skill.icon) {
      return '<img class="' + cls + '" src="' + esc(skill.icon) + '" alt="" width="48" height="48" loading="lazy" decoding="async" />';
    }
    return '<span class="' + cls + ' ' + cls + '--empty" aria-hidden="true"></span>';
  }

  // Mục này chỉ hiện khi phái có chiêu then chốt (video "Học kỹ năng" đã dời lên panel tâm pháp).
  function renderKeySkills() {
    var sect = sectById[state.sect];
    var rows = [];
    (sect.keySkills || []).forEach(function (ks) {
      var sk = skillById[ks.skill];
      if (!sk) return;
      var media = ks.yt
        ? '<div class="keyrow__media">' + videoButton(ks.yt, "Chiêu " + sk.name, "key") + '</div>'
        : '<div class="keyrow__media keyrow__media--icon">' + iconBox(sk, "skill__icon") + '</div>';
      var meta = "Tầng " + esc(sk.tang) + (sk.cooldown ? " · hồi " + esc(sk.cooldown) : "");
      rows.push('<li class="keyrow">' + media +
        '<div class="keyrow__body"><p class="skill__name">' + esc(sk.name) + '</p>' +
        '<p class="keyrow__meta">' + meta + '</p>' +
        (sk.mota ? '<p class="skill__desc">' + esc(sk.mota) + '</p>' : '') + '</div></li>');
    });
    keyListEl.innerHTML = rows.join("");
    keyListEl.hidden = rows.length === 0;
    keyEl.hidden = rows.length === 0;
  }

  /* ---------- Hàng chiêu ---------- */

  // own = true: chiêu riêng của tâm pháp đang chọn, thêm nhãn nhỏ "Riêng" cạnh tên.
  function skillRow(k, showSet, own) {
    var setInfo = setById[k.set];
    var tags = rolesById[k.id];
    var roles = tags && tags.length
      ? '<p class="skill__roles">Vai trò: ' + tags.map(function (t) { return esc(axisLabel[t] || t); }).join(" · ") + '</p>' : "";
    var tail = [];
    if (k.vukhi) tail.push("Vũ khí: " + esc(k.vukhi));
    if (showSet && setInfo) tail.push("Bộ " + esc(setInfo.name));
    var extra = k.extra && k.extra.length
      ? '<ul class="skill__extra">' + k.extra.map(function (e) { return '<li>' + esc(e) + '</li>'; }).join("") + '</ul>' : "";
    return '<li class="skill" style="--sect: var(--color-sect-' + esc(k.sect) + ')">' +
      '<div class="skill__tier"><span class="skill__tier-label">Tầng</span><span class="skill__tier-num">' + esc(k.tang) + '</span></div>' +
      '<div class="skill__body">' +
        '<div class="skill__head">' + iconBox(k, "skill__icon") +
          '<div class="skill__title"><p class="skill__name"><span class="skill__nm">' + esc(k.name) + '</span>' +
          (own ? '<span class="skill__own">Riêng</span>' : '') + '</p>' +
          (k.poem ? '<p class="skill__poem">' + esc(k.poem) + '</p>' : '') +
          (tail.length ? '<p class="skill__tail">' + tail.join(" · ") + '</p>' : '') +
          roles +
          '</div></div>' +
        '<dl class="skill__stats">' +
          '<div><dt>Cự ly</dt><dd>' + dash(k.culy) + '</dd></div>' +
          '<div><dt>Hao</dt><dd>' + dash(k.hao) + '</dd></div>' +
          '<div><dt>Thi triển</dt><dd>' + dash(k.cast) + '</dd></div>' +
          '<div><dt>Điều chỉnh</dt><dd>' + dash(k.cooldown) + '</dd></div>' +
        '</dl>' +
        (k.mota ? '<p class="skill__desc">' + esc(k.mota) + '</p>' : '') +
        extra +
      '</div></li>';
  }

  /* ---------- Danh mục ---------- */

  function sectSkillsFor(xinfaId) {
    var all = skillsBySect[state.sect] || [];
    if (!xinfaId) return all;
    return all.filter(function (k) { return k.xinfa == null || k.xinfa === xinfaId; });
  }

  function tierRange(list) {
    var lo = Infinity, hi = -Infinity;
    list.forEach(function (k) { var t = Number(k.tang); if (t < lo) lo = t; if (t > hi) hi = t; });
    if (!isFinite(lo)) return "";
    return lo === hi ? "Tầng " + lo : "Tầng " + lo + " đến " + hi;
  }

  function renderBySet() {
    var list = sectSkillsFor(state.xinfa);
    var order = [], groups = Object.create(null);
    list.forEach(function (k) {
      var key = String(k.set);
      if (!groups[key]) { groups[key] = []; order.push(key); }
      groups[key].push(k);
    });
    listEl.innerHTML = order.map(function (key, idx) {
      var items = groups[key];
      var info = setById[key] || { name: key, sub: "" };
      var range = tierRange(items);
      return '<details class="set"' + (idx === 0 ? " open" : "") + '>' +
        '<summary class="set__sum"><span class="set__name">' + esc(info.name) + '</span>' +
        '<span class="set__meta">' + items.length + ' chiêu' + (range ? " · " + range : "") + '</span>' +
        (info.sub ? '<span class="set__sub">' + esc(info.sub) + '</span>' : '') + '</summary>' +
        '<ul class="skills">' + items.map(function (k) { return skillRow(k, false, !!state.xinfa && k.xinfa === state.xinfa); }).join("") + '</ul></details>';
    }).join("");
  }

  var MIN_QUERY = 2;   // dưới ngần này ký tự (sau khi chuẩn hoá) thì chưa tìm
  var PAGE = 60;       // số hàng dựng mỗi lô khi liệt kê kết quả tìm kiếm

  function renderSearch(normalized) {
    if (!haystack) buildHaystack();
    var tokens = normalized.split(/\s+/).filter(Boolean);
    var bySect = Object.create(null);
    SKILLS.forEach(function (k, i) {
      var h = haystack[i];
      for (var t = 0; t < tokens.length; t++) if (h.indexOf(tokens[t]) === -1) return;
      (bySect[k.sect] = bySect[k.sect] || []).push(k);
    });
    // Xếp theo thứ tự phái, trong phái giữ thứ tự dữ liệu
    var ordered = [];
    SECTS.forEach(function (s) { if (bySect[s.id]) ordered = ordered.concat(bySect[s.id]); });
    listEl.innerHTML = "";
    if (!ordered.length) {
      statusEl.textContent = "Không tìm thấy chiêu thức phù hợp.";
      return;
    }
    statusEl.textContent = ordered.length + " chiêu thức";

    var moreWrap = document.createElement("div");
    moreWrap.className = "catalog__more";
    var moreBtn = document.createElement("button");
    moreBtn.type = "button";
    moreBtn.className = "btn btn--ghost catalog__more-btn";
    moreWrap.appendChild(moreBtn);
    listEl.appendChild(moreWrap);

    var shown = 0, lastSect = null, lastUl = null;

    function appendBatch(to) {
      var i = shown, firstRow = null;
      while (i < to) {
        var sectId = ordered[i].sect, j = i;
        while (j < to && ordered[j].sect === sectId) j++;
        var rowsHtml = ordered.slice(i, j).map(function (k) { return skillRow(k, true); }).join("");
        var before = lastUl ? lastUl.children.length : 0;
        if (lastUl && lastSect === sectId) {
          lastUl.insertAdjacentHTML("beforeend", rowsHtml);
          if (!firstRow) firstRow = lastUl.children[before];
        } else {
          var sect = sectById[sectId];
          var sec = document.createElement("section");
          sec.className = "hitgroup";
          sec.style.setProperty("--sect", "var(--color-sect-" + sectId + ")");
          sec.innerHTML = '<h4 class="hitgroup__title"><span class="hitgroup__name">' + esc(sect.name) + '</span><span class="hitgroup__n">' + bySect[sectId].length + ' chiêu</span></h4>' +
            '<ul class="skills">' + rowsHtml + '</ul>';
          listEl.insertBefore(sec, moreWrap);
          lastUl = sec.querySelector("ul");
          lastSect = sectId;
          if (!firstRow) firstRow = lastUl.firstElementChild;
        }
        i = j;
      }
      shown = to;
      return firstRow;
    }

    function syncMore() {
      var left = ordered.length - shown;
      if (left <= 0) { moreWrap.hidden = true; return; }
      moreBtn.textContent = "Hiện thêm " + left + " chiêu thức";
    }

    moreBtn.addEventListener("click", function () {
      var first = appendBatch(Math.min(ordered.length, shown + PAGE));
      syncMore();
      if (moreWrap.hidden && first) {
        // Nút biến mất: chuyển tiêu điểm tới hàng đầu của lô mới để người dùng đang dùng bàn phím không bị mất chỗ.
        first.tabIndex = -1;
        first.focus({ preventScroll: false });
      }
    });

    appendBatch(Math.min(ordered.length, PAGE));
    syncMore();
  }

  function isSearching() { return fold(state.query).trim().length >= MIN_QUERY; }

  // Danh sách theo bộ chỉ gồm chiêu tâm pháp đang chọn dùng được (chiêu riêng + chiêu dùng chung). Đang tìm kiếm thì hiện kết quả tìm toàn cục.
  function renderCatalog() {
    var normalized = fold(state.query).trim();
    if (xfilterEl) xfilterEl.hidden = normalized.length >= MIN_QUERY || !xfilterEl.firstChild;
    if (normalized.length >= MIN_QUERY) {
      catalogTitleEl.textContent = "Kết quả tìm kiếm";
      renderSearch(normalized);
      return;
    }
    var sect = sectById[state.sect];
    var list = sectSkillsFor(state.xinfa);
    var x = state.xinfa ? findXinfa(sect, state.xinfa) : null;
    catalogTitleEl.textContent = x
      ? list.length + " chiêu thức · " + x.name
      : "Toàn bộ " + list.length + " chiêu thức";
    statusEl.textContent = normalized.length === 1 ? "Gõ ít nhất " + MIN_QUERY + " ký tự" : "";
    renderBySet();
  }

  var timer = null;
  searchEl.addEventListener("input", function () {
    clearTimeout(timer);
    var v = searchEl.value;
    timer = setTimeout(function () { state.query = v; renderCatalog(); }, v === "" ? 0 : 150);
  });
  searchEl.addEventListener("search", function () {
    if (searchEl.value === "") { clearTimeout(timer); state.query = ""; renderCatalog(); }
  });

  /* ---------- Video: ảnh bìa trước, bấm mới tải trình phát ---------- */

  function pauseFrame(frame) {
    if (frame.contentWindow) frame.contentWindow.postMessage(JSON.stringify({ event: "command", func: "pauseVideo", args: [] }), "*");
  }

  panelEl.addEventListener("click", function (e) {
    var btn = e.target.closest ? e.target.closest(".video[data-yt]") : null;
    if (!btn) return;
    var id = encodeURIComponent(btn.getAttribute("data-yt"));
    // Mở từ file:// thì YouTube báo lỗi 153: mở video ở tab mới thay vì nhúng.
    if (location.protocol !== "http:" && location.protocol !== "https:") {
      window.open("https://www.youtube.com/watch?v=" + id, "_blank", "noopener");
      return;
    }
    var wrap = document.createElement("div");
    wrap.className = "video__frame";
    var frame = document.createElement("iframe");
    frame.src = "https://www.youtube-nocookie.com/embed/" + id + "?autoplay=1&rel=0&playsinline=1&enablejsapi=1&origin=" + encodeURIComponent(location.origin);
    frame.title = (btn.getAttribute("aria-label") || "").replace("Phát video: ", "");
    frame.allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture";
    frame.allowFullscreen = true;
    frame.referrerPolicy = "strict-origin-when-cross-origin";
    wrap.appendChild(frame);
    // Chỉ một video phát một lúc
    Array.prototype.forEach.call(panelEl.querySelectorAll(".video__frame iframe"), pauseFrame);
    btn.replaceWith(wrap);
    frame.focus();
  });

  /* ---------- Khởi động ---------- */

  function applyHash() {
    var h = parseHash();
    selectSect(h.sect, h.xinfa, false, true);
  }
  window.addEventListener("hashchange", applyHash);
  state.sect = "";
  applyHash();
})();
