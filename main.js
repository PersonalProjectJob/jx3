(function () {
  "use strict";

  document.documentElement.classList.add("js");

  /* ---------- Môn phái · tabs ---------- */

  var tabs = Array.prototype.slice.call(document.querySelectorAll('[role="tab"]'));
  var panels = tabs.map(function (tab) {
    return document.getElementById(tab.getAttribute("aria-controls"));
  });

  function select(index, moveFocus) {
    tabs.forEach(function (tab, i) {
      var active = i === index;
      tab.setAttribute("aria-selected", active ? "true" : "false");
      tab.tabIndex = active ? 0 : -1;
      panels[i].hidden = !active;
      panels[i].classList.remove("is-entering");
    });
    // Mực loang (WebGL) nếu được; không thì dùng chuyển cảnh CSS.
    var fx = false;
    try { fx = !!(window.JXFX && window.JXFX.reveal(panels[index])); } catch (err) { fx = false; }
    if (!fx) panels[index].classList.add("is-entering");
    if (moveFocus) tabs[index].focus({ preventScroll: true });
    tabs[index].scrollIntoView({ block: "nearest", inline: "nearest" });
  }

  tabs.forEach(function (tab, i) {
    tab.addEventListener("click", function () { select(i, false); });
    tab.addEventListener("keydown", function (e) {
      var next = null;
      if (e.key === "ArrowRight") next = (i + 1) % tabs.length;
      else if (e.key === "ArrowLeft") next = (i - 1 + tabs.length) % tabs.length;
      else if (e.key === "Home") next = 0;
      else if (e.key === "End") next = tabs.length - 1;
      if (next === null) return;
      e.preventDefault();
      select(next, true);
    });
  });

  panels.forEach(function (panel, i) {
    panel.hidden = i !== 0;
    panel.addEventListener("animationend", function () {
      panel.classList.remove("is-entering");
    });
  });

  /* Tải sẵn ảnh các phái khác khi trang đã rảnh, để chuyển tab không phải chờ */
  window.addEventListener("load", function () {
    var warm = function () {
      document.querySelectorAll('.panel__figure[loading="lazy"]').forEach(function (img) {
        img.loading = "eager";
      });
    };
    if ("requestIdleCallback" in window) window.requestIdleCallback(warm, { timeout: 3000 });
    else setTimeout(warm, 1500);
  });

  /* ---------- Vách gỗ: cáo thị dán xuống, lệnh bài đung đưa khi cuộn tới ---------- */

  document.querySelectorAll(".board").forEach(function (board) {
    if (!("IntersectionObserver" in window)) { board.classList.add("is-in"); return; }
    var io = new IntersectionObserver(function (entries) {
      if (!entries[0].isIntersecting) return;
      board.classList.add("is-in");
      io.disconnect();
    }, { threshold: 0.2 });
    io.observe(board);
  });

  /* Lệnh bài đung đưa khi chuột chạm vào (hoặc chạm tay trên điện thoại).
   * Hướng theo phía chuột đi tới, biên độ theo tốc độ rê, tắt dần như con lắc. */
  (function swingTokens() {
    var reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
    document.querySelectorAll(".token").forEach(function (token) {
      var anim = null;
      function swing(dir, strength) {
        if (reduce.matches || !token.animate) return;
        var a = Math.max(6, Math.min(16, strength)) * dir;
        if (anim) anim.cancel();
        anim = token.animate(
          [
            { transform: "rotate(0deg)" },
            { transform: "rotate(" + a + "deg)", offset: 0.16 },
            { transform: "rotate(" + (-a * 0.62) + "deg)", offset: 0.38 },
            { transform: "rotate(" + (a * 0.36) + "deg)", offset: 0.58 },
            { transform: "rotate(" + (-a * 0.18) + "deg)", offset: 0.76 },
            { transform: "rotate(" + (a * 0.06) + "deg)", offset: 0.9 },
            { transform: "rotate(0deg)" }
          ],
          { duration: 1500 + Math.abs(a) * 40, easing: "cubic-bezier(0.33, 0, 0.3, 1)" }
        );
      }
      token.addEventListener("pointerenter", function (e) {
        if (e.pointerType === "touch") return;
        var r = token.getBoundingClientRect();
        var dir = e.clientX < r.left + r.width / 2 ? 1 : -1; // chạm từ trái → văng sang phải
        swing(dir, 7 + Math.abs(e.movementX || 0) * 0.5);
      });
      token.addEventListener("pointerdown", function (e) {
        if (e.pointerType !== "touch") return;
        var r = token.getBoundingClientRect();
        swing(e.clientX < r.left + r.width / 2 ? 1 : -1, 10);
      });
    });
  })();

  /* ---------- Ảnh cũ (.polaroid): hiện hình khi cuộn tới, chuyển động nhẹ khi đang hiện ---------- */

  (function oldPhotos() {
    var features = document.querySelectorAll(".polaroid");
    if (!features.length) return;
    var reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
    if (!("IntersectionObserver" in window)) {
      features.forEach(function (f) { f.classList.add("is-developed"); });
      return;
    }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting && e.intersectionRatio >= 0.3) e.target.classList.add("is-developed");
        // Hạt phim, vệt sáng, phóng chậm chỉ chạy khi khối đang trên màn hình
        e.target.classList.toggle("is-live", e.isIntersecting && !reduce.matches);
      });
    }, { threshold: [0, 0.3] });
    features.forEach(function (f) { io.observe(f); });
  })();

  /* ---------- Bảng kỷ niệm: lưới ô ảnh + ô chữ, từng cặp ô đổi chỗ lấp lánh ---------- */

  (function memoryBoard() {
    var data = window.JX_MEMORIES;
    var board = document.getElementById("memo-board");
    if (!data || !board) return;
    var grid = board.querySelector(".memo-tiles");
    var pauseBtn = board.querySelector(".memo-board__pause");
    var reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
    var HOLD = data.interval || 5000;   // mỗi ảnh ở lại khoảng chừng này
    var FADE = 700;

    function shuffle(a) {
      for (var i = a.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1));
        var t = a[i]; a[i] = a[j]; a[j] = t;
      }
      return a;
    }
    var photos = shuffle((data.photos || []).slice());
    var notes = shuffle((data.notes || []).slice());
    var pi = 0, ni = 0, timer = 0, busy = false;
    var tiles = [];          // { el, kind: "photo" | "note", since }
    var state = { userPaused: false, hover: false, focus: false, pageHidden: document.hidden, offscreen: true };

    function slotCount() { return window.innerWidth >= 960 ? 8 : window.innerWidth >= 640 ? 6 : 4; }
    function photoCount(n) { return Math.max(1, Math.min(data.perRound || n / 2, Math.floor(n / 2), photos.length)); }
    function nextPhoto() { var p = photos[pi % photos.length]; pi++; warm(); return p; }
    function nextNote() { var n = notes[ni % notes.length]; ni++; return n; }
    // Tải trước 2 ảnh kế tiếp để ô đổi sang ảnh không bị trống
    var warmed = {};
    function warm() {
      for (var k = 0; k < 2; k++) {
        var p = photos[(pi + k) % photos.length];
        if (p && p.src && !warmed[p.src]) { warmed[p.src] = true; var im = new Image(); im.decoding = "async"; im.src = p.src; }
      }
    }

    function setPhoto(el, p) {
      el.className = "memo-tile memo-tile--photo";
      el.replaceChildren();
      if (p.src) {
        var img = document.createElement("img");
        img.src = p.src;
        img.alt = p.alt || p.caption || "";
        img.decoding = "async";
        el.appendChild(img);
      } else {
        var ph = document.createElement("span");
        ph.className = "memo-tile__placeholder";
        ph.textContent = "Ảnh minh hoạ (chờ duyệt)";
        el.appendChild(ph);
      }
      if (p.caption) {
        var cap = document.createElement("span");
        cap.className = "memo-tile__cap";
        cap.textContent = p.caption;
        el.appendChild(cap);
      }
    }
    function setNote(el, text) {
      el.className = "memo-tile memo-tile--note";
      el.replaceChildren();
      var q = document.createElement("p");
      q.textContent = text;
      el.appendChild(q);
    }

    function build() {
      var n = slotCount(), x = photoCount(n);
      var withPhoto = shuffle(Array.from({ length: n }, function (_, i) { return i; })).slice(0, x);
      grid.replaceChildren();
      tiles = [];
      var now = Date.now();
      for (var i = 0; i < n; i++) {
        var li = document.createElement("li");
        var photo = withPhoto.indexOf(i) !== -1;
        if (photo) setPhoto(li, nextPhoto()); else setNote(li, nextNote());
        // Ảnh đầu tiên lệch tuổi nhau để các lần đổi rải đều, không dồn một lúc
        tiles.push({ el: li, kind: photo ? "photo" : "note", since: now - Math.random() * HOLD });
        grid.appendChild(li);
      }
    }

    // Lấp lánh: một ô hiện lại kèm vệt sáng quét qua
    function swapTile(t, kind) {
      t.el.classList.add("is-out");
      setTimeout(function () {
        if (kind === "photo") setPhoto(t.el, nextPhoto()); else setNote(t.el, nextNote());
        t.kind = kind;
        t.since = Date.now();
        t.el.classList.add("is-out");
        void t.el.offsetWidth;
        t.el.classList.remove("is-out");
        t.el.classList.add("is-in");
        setTimeout(function () { t.el.classList.remove("is-in"); }, 1100);
      }, FADE);
    }

    // Mỗi nhịp: ảnh ở lâu nhất thành chữ, một ô chữ ngẫu nhiên thành ảnh mới → luôn giữ đủ X ảnh
    function tick() {
      if (busy) return;
      var photoTiles = tiles.filter(function (t) { return t.kind === "photo"; });
      var noteTiles = tiles.filter(function (t) { return t.kind === "note"; });
      if (!photoTiles.length || !noteTiles.length) return schedule();
      busy = true;
      var oldest = photoTiles.sort(function (a, b) { return a.since - b.since; })[0];
      var target = shuffle(noteTiles.filter(function (t) { return Date.now() - t.since > FADE * 2; }))[0] || noteTiles[0];
      swapTile(oldest, "note");
      setTimeout(function () { swapTile(target, "photo"); }, 220);
      setTimeout(function () { busy = false; schedule(); }, FADE + 400);
    }

    function running() {
      return !state.userPaused && !state.hover && !state.focus && !state.pageHidden && !state.offscreen && !reduce.matches;
    }
    function schedule() {
      clearTimeout(timer);
      if (!running()) return;
      var x = tiles.filter(function (t) { return t.kind === "photo"; }).length || 1;
      timer = setTimeout(tick, Math.max(900, (HOLD / x) - FADE));
    }

    pauseBtn.addEventListener("click", function () {
      state.userPaused = !state.userPaused;
      pauseBtn.setAttribute("aria-pressed", state.userPaused ? "true" : "false");
      pauseBtn.setAttribute("aria-label", state.userPaused ? "Tiếp tục đổi ảnh" : "Tạm dừng đổi ảnh");
      schedule();
    });
    grid.addEventListener("pointerenter", function () { state.hover = true; schedule(); });
    grid.addEventListener("pointerleave", function () { state.hover = false; schedule(); });
    board.addEventListener("focusin", function () { state.focus = true; schedule(); });
    board.addEventListener("focusout", function (e) { if (!board.contains(e.relatedTarget)) { state.focus = false; schedule(); } });
    document.addEventListener("visibilitychange", function () { state.pageHidden = document.hidden; schedule(); });
    if ("IntersectionObserver" in window) {
      new IntersectionObserver(function (entries) { state.offscreen = !entries[0].isIntersecting; schedule(); }, { threshold: 0.25 }).observe(board);
    } else {
      state.offscreen = false;
    }
    reduce.addEventListener("change", schedule);
    if (reduce.matches) pauseBtn.hidden = true;

    var lastCount = slotCount(), rz = 0;
    window.addEventListener("resize", function () {
      clearTimeout(rz);
      rz = setTimeout(function () { if (slotCount() !== lastCount) { lastCount = slotCount(); build(); schedule(); } }, 200);
    });

    build();
    schedule();
  })();

  /* ---------- Hero · luân phiên 9 môn phái ---------- */

  (function heroRotation() {
    var casts = Array.prototype.slice.call(document.querySelectorAll(".hero__cast .cast"));
    var picker = document.querySelector(".hero__picker");
    var hero = document.querySelector(".hero");
    if (!casts.length || !picker || !hero) return;

    var INTERVAL = 7000;
    var title = document.querySelector(".hero__title");
    var status = document.getElementById("hero-status");
    var dots = Array.prototype.slice.call(picker.querySelectorAll(".picker__dot"));
    var pauseBtn = picker.querySelector(".picker__pause");
    var reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
    var current = 0, timer = 0;
    // Lý do tạm dừng được giữ riêng, để cuộn ra/vào màn hình không ghi đè lựa chọn "Tạm dừng" của người dùng.
    var state = { userPaused: false, hover: false, focus: false, pageHidden: document.hidden, offscreen: false };

    function running() {
      return !state.userPaused && !state.hover && !state.focus && !state.pageHidden && !state.offscreen && !reduce.matches;
    }

    // Tiêu đề, chấm vị trí và màu đều đọc từ ảnh đang hiển thị, để không bao giờ lệch nhau.
    function paint(i) {
      var img = casts[i];
      var words = img.dataset.name.split(" ");
      var first = document.createElement("span");
      var rest = document.createElement("span");
      first.textContent = words[0];
      rest.textContent = words.slice(1).join(" ");
      title.replaceChildren(first, document.createTextNode(" "), rest); // span mới tự chạy lại hiệu ứng mực thấm
      picker.style.setProperty("--sect", img.style.getPropertyValue("--sect"));
      dots.forEach(function (d, k) {
        if (k === i) d.setAttribute("aria-current", "true");
        else d.removeAttribute("aria-current");
      });
    }

    function show(i, manual) {
      i = (i + casts.length) % casts.length;
      if (i === current) return;
      current = i;
      var next = casts[i];
      next.loading = "eager";
      casts.forEach(function (img) {
        if (img === next) return;
        img.classList.remove("no-fade", "is-revealing", "is-active");
      });
      next.classList.add("is-active");
      paint(i); // cập nhật tên + chấm trước, để hiệu ứng có lỗi cũng không làm lệch
      // Mực loang nếu được; không thì ảnh mờ dần bằng CSS.
      var fx = false;
      try { fx = !!(window.JXFX && window.JXFX.reveal(next, next)); } catch (err) { fx = false; }
      next.classList.toggle("no-fade", fx);
      if (!fx) next.classList.remove("is-revealing");
      if (manual) status.textContent = "Môn phái: " + next.dataset.name;
    }

    function schedule() {
      clearTimeout(timer);
      if (!running()) return;
      timer = setTimeout(function () {
        var upcoming = casts[(current + 1) % casts.length];
        upcoming.loading = "eager";
        var ready = upcoming.decode ? upcoming.decode() : Promise.resolve();
        ready.catch(function () {}).then(function () {
          if (running()) show(current + 1, false);
          schedule();
        });
      }, INTERVAL);
    }

    dots.forEach(function (dot, k) {
      dot.addEventListener("click", function () { show(k, true); schedule(); });
    });

    picker.querySelectorAll("[data-step]").forEach(function (btn) {
      btn.addEventListener("click", function () {
        show(current + Number(btn.dataset.step), true);
        schedule();
      });
    });

    pauseBtn.addEventListener("click", function () {
      state.userPaused = !state.userPaused;
      pauseBtn.setAttribute("aria-pressed", state.userPaused ? "true" : "false");
      pauseBtn.setAttribute("aria-label", state.userPaused ? "Tiếp tục luân phiên" : "Tạm dừng luân phiên");
      schedule();
    });

    picker.addEventListener("pointerenter", function () { state.hover = true; schedule(); });
    picker.addEventListener("pointerleave", function () { state.hover = false; schedule(); });
    picker.addEventListener("focusin", function () { state.focus = true; schedule(); });
    picker.addEventListener("focusout", function (e) {
      if (!picker.contains(e.relatedTarget)) { state.focus = false; schedule(); }
    });
    document.addEventListener("visibilitychange", function () { state.pageHidden = document.hidden; schedule(); });
    new IntersectionObserver(function (entries) {
      state.offscreen = !entries[0].isIntersecting; schedule();
    }).observe(hero);
    reduce.addEventListener("change", schedule);

    // Người dùng bật giảm chuyển động: không tự luân phiên, ẩn nút tạm dừng vì không cần.
    if (reduce.matches) pauseBtn.hidden = true;

    paint(0);
    schedule();
  })();

  /* ---------- Video hero: tự phát, tạm dừng khi rời hero ---------- */

  (function heroVideo() {
    var btn = document.querySelector(".video--hero[data-yt]");
    var hero = document.querySelector(".hero");
    if (!btn || !hero) return;

    var id = btn.dataset.yt;
    var title = btn.getAttribute("aria-label").replace("Phát video: ", "");
    // Mở trang trực tiếp từ file (file://) thì YouTube không nhận được địa chỉ trang và báo lỗi 153.
    var canEmbed = location.protocol === "http:" || location.protocol === "https:";
    var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    var saveData = !!(navigator.connection && navigator.connection.saveData);
    var player = null, wrap = null, muteBtn = null;
    var pausedByPage = false;   // dừng vì cuộn khỏi hero / ẩn tab, không phải do người xem bấm
    var heroVisible = true;

    function loadApi(cb) {
      if (window.YT && window.YT.Player) return cb();
      var prev = window.onYouTubeIframeAPIReady;
      window.onYouTubeIframeAPIReady = function () { if (prev) prev(); cb(); };
      var s = document.createElement("script");
      s.src = "https://www.youtube.com/iframe_api";
      s.async = true;
      s.onerror = function () { btn.hidden = false; }; // không tải được API: giữ ảnh bìa
      document.head.appendChild(s);
    }

    function playing() {
      return player && player.getPlayerState && player.getPlayerState() === 1;
    }

    function showMute(on) {
      if (muteBtn) muteBtn.hidden = !on;
    }

    function unmute() {
      if (!player || !player.isMuted || !player.isMuted()) return;
      player.unMute();
      player.setVolume(100);
      showMute(false);
    }

    // Lần đầu người xem bấm/gõ phím ở bất kỳ đâu: trình duyệt cho phép bật tiếng.
    function unmuteOnFirstGesture() {
      var once = function () {
        unmute();
        document.removeEventListener("pointerdown", once, true);
        document.removeEventListener("keydown", once, true);
      };
      document.addEventListener("pointerdown", once, true);
      document.addEventListener("keydown", once, true);
    }

    function build(autoplay) {
      wrap = document.createElement("div");
      wrap.className = "video__frame";
      var target = document.createElement("div");
      wrap.appendChild(target);

      muteBtn = document.createElement("button");
      muteBtn.type = "button";
      muteBtn.className = "video__unmute";
      muteBtn.hidden = true;
      muteBtn.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M4 9v6h4l5 4V5L8 9H4z" /><path d="M16 9l5 6M21 9l-5 6" /></svg><span>Bật tiếng</span>';
      muteBtn.addEventListener("click", unmute);
      wrap.appendChild(muteBtn);

      btn.hidden = true;
      btn.after(wrap);

      loadApi(function () {
        player = new window.YT.Player(target, {
          host: "https://www.youtube-nocookie.com",
          videoId: id,
          playerVars: { autoplay: 1, rel: 0, playsinline: 1, modestbranding: 1 },
          events: {
            onReady: function (e) {
              var iframe = e.target.getIframe();
              iframe.title = title;
              e.target.unMute();
              e.target.setVolume(100);
              if (autoplay && !heroVisible) return; // đã cuộn đi trước khi trình phát sẵn sàng
              e.target.playVideo();
              // Trình duyệt chặn phát có tiếng: phát không tiếng + nút "Bật tiếng".
              // Trạng thái 1 = đang phát, 3 = đang tải (đã được phép phát).
              setTimeout(function () {
                var st = e.target.getPlayerState();
                if (st !== 1 && st !== 3 && heroVisible && !document.hidden) {
                  e.target.mute();
                  e.target.playVideo();
                  showMute(true);
                  unmuteOnFirstGesture();
                } else if (e.target.isMuted()) {
                  showMute(true);
                  unmuteOnFirstGesture();
                }
              }, 1800);
            },
            onStateChange: function (e) {
              if (e.data === 1) {
                pausedByPage = false;
                // Hero bắt đầu phát: dừng các video tính năng đang phát
                document.querySelectorAll(".video__frame iframe").forEach(function (f) {
                  if (f !== player.getIframe() && f.contentWindow) f.contentWindow.postMessage(JSON.stringify({ event: "command", func: "pauseVideo", args: [] }), "*");
                });
              }
              if (e.data === 1 && player.isMuted && !player.isMuted()) showMute(false);
            }
          }
        });
      });
    }

    function pauseForPage() {
      if (playing()) { player.pauseVideo(); pausedByPage = true; }
    }
    function resumeForPage() {
      if (player && pausedByPage && heroVisible && !document.hidden) { player.playVideo(); }
    }

    new IntersectionObserver(function (entries) {
      heroVisible = entries[0].intersectionRatio > 0.25;
      if (heroVisible) resumeForPage(); else pauseForPage();
    }, { threshold: [0, 0.25, 0.5] }).observe(hero);

    document.addEventListener("visibilitychange", function () {
      if (document.hidden) pauseForPage(); else resumeForPage();
    });

    document.addEventListener("jx:video-play", function (e) {
      if (!player || !player.getIframe || e.detail.frame === player.getIframe()) return;
      if (playing()) { player.pauseVideo(); pausedByPage = false; }
    });

    // Nút ảnh bìa: dùng khi không tự phát (file://, giảm chuyển động, tiết kiệm dữ liệu).
    btn.addEventListener("click", function () {
      if (!canEmbed) {
        window.open("https://www.youtube.com/watch?v=" + encodeURIComponent(id), "_blank", "noopener");
        return;
      }
      if (!wrap) build(false);
    });

    if (canEmbed && !reduce && !saveData) {
      if (document.readyState === "complete") build(true);
      else window.addEventListener("load", function () { build(true); }, { once: true });
    }
  })();

  /* ---------- Video minh hoạ tính năng: ảnh bìa trước, bấm mới tải trình phát ---------- */

  document.querySelectorAll(".video[data-yt]:not(.video--hero)").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var id = encodeURIComponent(btn.dataset.yt);
      // Mở từ file:// thì YouTube báo lỗi 153: mở video ở tab mới thay vì nhúng.
      if (location.protocol !== "http:" && location.protocol !== "https:") {
        window.open("https://www.youtube.com/watch?v=" + id, "_blank", "noopener");
        return;
      }
      var wrap = document.createElement("div");
      wrap.className = "video__frame";
      var frame = document.createElement("iframe");
      frame.src = "https://www.youtube-nocookie.com/embed/" + id + "?autoplay=1&rel=0&playsinline=1&enablejsapi=1&origin=" + encodeURIComponent(location.origin);
      frame.title = btn.getAttribute("aria-label").replace("Phát video: ", "");
      frame.allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture";
      frame.allowFullscreen = true;
      frame.referrerPolicy = "strict-origin-when-cross-origin";
      wrap.appendChild(frame);
      btn.replaceWith(wrap);
      frame.focus();
      // Đăng ký nghe trạng thái của trình phát này (YouTube IFrame API qua postMessage)
      frame.addEventListener("load", function () {
        frame.contentWindow.postMessage(JSON.stringify({ event: "listening", id: id, channel: "widget" }), "*");
      });
      pauseOthers(frame);
    });
  });

  // Chỉ một video phát tại một thời điểm: video nào bắt đầu phát thì các video khác tạm dừng.
  function pauseOthers(except) {
    document.querySelectorAll(".video__frame iframe").forEach(function (f) {
      if (f === except || !f.contentWindow) return;
      f.contentWindow.postMessage(JSON.stringify({ event: "command", func: "pauseVideo", args: [] }), "*");
    });
    document.dispatchEvent(new CustomEvent("jx:video-play", { detail: { frame: except } }));
  }
  window.addEventListener("message", function (e) {
    if (!/^https:\/\/www\.youtube(-nocookie)?\.com$/.test(e.origin)) return;
    var data;
    try { data = typeof e.data === "string" ? JSON.parse(e.data) : e.data; } catch (err) { return; }
    var state = data && data.info && typeof data.info === "object" ? data.info.playerState : (data && data.event === "onStateChange" ? data.info : undefined);
    if (state !== 1) return; // 1 = đang phát
    var src = null;
    document.querySelectorAll(".video__frame iframe").forEach(function (f) { if (f.contentWindow === e.source) src = f; });
    if (src) pauseOthers(src);
  });

  /* ---------- Tin tức ---------- */

  var root = document.getElementById("news");
  var news = Array.isArray(window.JX_NEWS) ? window.JX_NEWS : [];

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text) node.textContent = text;
    return node;
  }

  function formatDate(iso) {
    if (!iso) return "—";
    var d = new Date(iso + "T00:00:00");
    if (isNaN(d.getTime())) return iso;
    return d.toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit", year: "numeric" });
  }

  // Chuyên mục → màu mép phong thư
  var CAT = { "thông báo": "notice", "hướng dẫn": "guide", "sự kiện": "event", "bảo trì": "maint" };
  function catKey(c) { return CAT[(c || "").trim().toLowerCase()] || "other"; }

  function titleNode(tag, item, className) {
    var wrap = el(tag, className);
    if (item.url) {
      var a = el("a", "news-title-link", item.title);
      a.href = item.url;
      if (/^https?:/.test(item.url)) { a.target = "_blank"; a.rel = "noopener"; }
      wrap.appendChild(a);
    } else {
      wrap.textContent = item.title;
    }
    return wrap;
  }

  function timeNode(item, className) {
    var t = el("time", className, formatDate(item.date));
    if (item.date) t.dateTime = item.date;
    return t;
  }

  if (root) {
    if (!news.length) {
      root.appendChild(el("p", "section__lede", "Chưa có tin nào."));
    } else {
      // Tin chính: lá thư mở
      var lead = news[0];
      var letter = el("article", "letter letter--" + catKey(lead.category));
      var mark = el("span", "letter__mark", "讯");
      mark.setAttribute("aria-hidden", "true");
      mark.lang = "zh-Hans";
      letter.appendChild(mark);
      var top = el("div", "letter__top");
      top.appendChild(el("span", "letter__seal", lead.category));
      top.appendChild(timeNode(lead, "letter__date"));
      letter.appendChild(top);
      letter.appendChild(titleNode("h3", lead, "letter__title"));
      if (lead.summary) letter.appendChild(el("p", "letter__summary", lead.summary));
      if (lead.url) {
        var more = el("a", "cta-link letter__more", "Đọc tiếp ");
        more.href = lead.url;
        if (/^https?:/.test(lead.url)) { more.target = "_blank"; more.rel = "noopener"; }
        var arrow = el("span", "", "→"); arrow.setAttribute("aria-hidden", "true");
        more.appendChild(arrow);
        letter.appendChild(more);
      }
      root.appendChild(letter);

      // Các tin còn lại: phong thư xếp chồng
      if (news.length > 1) {
        var list = el("ol", "envelopes");
        news.slice(1).forEach(function (item) {
          var li = el("li", "envelope envelope--" + catKey(item.category));
          var head = el("div", "envelope__head");
          head.appendChild(el("span", "envelope__cat", item.category));
          head.appendChild(timeNode(item, "envelope__date"));
          li.appendChild(head);
          li.appendChild(titleNode("p", item, "envelope__title"));
          list.appendChild(li);
        });
        root.appendChild(list);
      }

      // Thư bay vào khi cuộn tới
      var section = root.closest(".news");
      if (section && "IntersectionObserver" in window) {
        var io = new IntersectionObserver(function (entries) {
          if (!entries[0].isIntersecting) return;
          section.classList.add("is-in");
          io.disconnect();
        }, { threshold: 0.2 });
        io.observe(section);
      } else if (section) {
        section.classList.add("is-in");
      }
    }
  }
})();
