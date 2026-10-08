/*
 * Kiểm tra data/sects.js + data/skills.js + data/skill-roles.js sau khi chạy scripts/build-data.mjs.
 * Chạy: node scripts/check-data.mjs   (thoát mã 1 nếu có assert sai)
 *
 * Kiểm cấu trúc dữ liệu nguồn (270 chiêu / 35 bộ / 9 phái / 18 tâm pháp, id, tham chiếu, icon, mojibake)
 * và chấp nhận phần chủ dự án sửa tay: intro / note / story (mô tả ngắn và tiểu sử của phái), video / skillVideo ({ yt, title }), keySkills, desc và ring (draft, scores, why, summary) của từng tâm pháp.
 * Phần sửa tay chỉ bị báo lỗi khi sai dạng (mã YouTube không hợp lệ, có yt mà thiếu title, chiêu then chốt sai phái hoặc quá 3, điểm ring sai dạng, desc không phải null/chuỗi không rỗng...).
 * Ring của TỪNG tâm pháp (điểm đánh giá tổng quan, không đếm số chiêu): draft boolean; scores null HOẶC đủ 6 khoá số nguyên 3..10 (thấp nhất 3, không bao giờ về 0); why null HOẶC đủ 6 khoá chuỗi không rỗng
 * (bắt buộc khi scores khác null); summary null hoặc chuỗi không rỗng; không còn total/counts/axes (dạng cũ bị báo lỗi).
 * JX_SKILL_ROLES (data/skill-roles.js): đúng 270 id chiêu, mỗi chiêu 1 đến 3 nhãn khác nhau thuộc 6 nhãn hợp lệ, why là chuỗi.
 * Kiểm thêm window.JX_VIDEO_SOURCE (nguồn chung của mọi video): 4 chuỗi không rỗng, url bắt đầu bằng https://www.youtube.com/.
 *
 * Dùng như thư viện: import { checkData, checkRoles } from "./check-data.mjs" rồi gọi checkData(sects, skills, sets, opts) / checkRoles(roles, skills).
 */
import { readFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

export const ORDER = ["thien-sach", "thuan-duong", "van-hoa", "that-tu", "thieu-lam", "tang-kiem", "ngu-doc", "duong-mon", "minh-giao"];
export const AXIS_KEYS = ["sat_thuong", "khong_che", "ho_tro", "tri_lieu", "phong_thu", "co_dong"];
export const MAX_ROLE_TAGS = 3;
export const YT_ID = /^[A-Za-z0-9_-]{11}$/;
export const MAX_KEY_SKILLS = 3;
export const STORY_MIN = 120;
export const STORY_MAX = 900;

const isYtOrNull = (v) => v === null || (typeof v === "string" && YT_ID.test(v));
const isNonEmptyString = (v) => typeof v === "string" && v.trim() !== "";

/** Nguồn chung của mọi video (window.JX_VIDEO_SOURCE): 4 chuỗi không rỗng, url là liên kết YouTube. */
export function checkVideoSource(src) {
  assert.ok(src && typeof src === "object", "JX_VIDEO_SOURCE phải là object");
  for (const key of ["channel", "handle", "url", "about"]) {
    assert.ok(isNonEmptyString(src[key]), "JX_VIDEO_SOURCE." + key + " phải là chuỗi không rỗng");
  }
  assert.ok(src.url.startsWith("https://www.youtube.com/"), "JX_VIDEO_SOURCE.url phải bắt đầu bằng https://www.youtube.com/, nhận " + src.url);
}

/** Phân loại vai trò (window.JX_SKILL_ROLES): đủ đúng tập id chiêu, 1 đến 3 nhãn khác nhau hợp lệ, why là chuỗi. */
export function checkRoles(ROLES, SKILLS) {
  assert.ok(ROLES && typeof ROLES === "object" && !Array.isArray(ROLES), "JX_SKILL_ROLES phải là object");
  const roleIds = Object.keys(ROLES);
  const skillIds = new Set(SKILLS.map((k) => k.id));
  assert.equal(roleIds.length, SKILLS.length, "JX_SKILL_ROLES phải có đúng " + SKILLS.length + " chiêu, nhận " + roleIds.length);
  for (const id of skillIds) assert.ok(Object.prototype.hasOwnProperty.call(ROLES, id), "JX_SKILL_ROLES thiếu chiêu " + id);
  for (const id of roleIds) assert.ok(skillIds.has(id), "JX_SKILL_ROLES có id không phải chiêu nào: " + id);
  for (const id of roleIds) {
    const r = ROLES[id];
    assert.ok(r && typeof r === "object" && !Array.isArray(r), id + ": vai trò phải là object { tags, why }");
    assert.ok(Array.isArray(r.tags), id + ": tags phải là mảng");
    assert.ok(r.tags.length >= 1 && r.tags.length <= MAX_ROLE_TAGS, id + ": tags phải có 1 đến " + MAX_ROLE_TAGS + " nhãn, nhận " + r.tags.length);
    assert.equal(new Set(r.tags).size, r.tags.length, id + ": tags không được trùng nhãn");
    for (const t of r.tags) assert.ok(AXIS_KEYS.includes(t), id + ": nhãn lạ " + JSON.stringify(t) + " (hợp lệ: " + AXIS_KEYS.join(", ") + ")");
    assert.equal(typeof r.why, "string", id + ": why phải là chuỗi");
  }
}

/**
 * Kiểm cấu trúc. Ném AssertionError ở lỗi đầu tiên.
 * opts.iconExists(rel): kiểm file icon (mặc định: có tồn tại trong thư mục gốc repo).
 * Trả về { iconFiles, iconNull, warnings }.
 */
export function checkData(SECTS, SKILLS, SETS, opts = {}) {
  const iconExists = opts.iconExists || ((rel) => existsSync(join(ROOT, rel)));
  const warnings = []; // hiện không còn cảnh báo nào, giữ trường trả về để tương thích

  assert.deepEqual(SECTS.map((s) => s.id), ORDER, "9 phái đúng id/thứ tự");
  assert.equal(SKILLS.length, 270, "270 chiêu");
  assert.equal(SECTS.reduce((n, s) => n + s.xinfa.length, 0), 18, "18 tâm pháp");
  assert.equal(SETS.length, 35, "35 bộ");
  assert.equal(new Set(SKILLS.map((s) => s.id)).size, SKILLS.length, "id chiêu duy nhất");
  assert.equal(new Set(SETS.map((s) => s.id)).size, SETS.length, "id bộ duy nhất");

  const sectById = new Map(SECTS.map((s) => [s.id, s]));
  const setById = new Map(SETS.map((s) => [s.id, s]));
  const skillById = new Map(SKILLS.map((k) => [k.id, k]));

  for (const s of SECTS) {
    assert.equal(s.xinfa.length, 2, s.id + " có 2 tâm pháp");

    // Phần chủ dự án có thể điền tay
    // video (giới thiệu phái) và skillVideo (học kỹ năng): { yt, title }; có yt thì bắt buộc có title để ghi nguồn
    for (const field of ["video", "skillVideo"]) {
      const v = s[field];
      assert.ok(v && typeof v === "object" && !Array.isArray(v) && "yt" in v && "title" in v, s.id + ": " + field + " là { yt, title }");
      assert.ok(isYtOrNull(v.yt), s.id + ": " + field + ".yt phải là null hoặc mã YouTube 11 ký tự, nhận " + JSON.stringify(v.yt));
      assert.ok(v.title === null || isNonEmptyString(v.title), s.id + ": " + field + ".title phải là null hoặc chuỗi không rỗng, nhận " + JSON.stringify(v.title));
      if (v.yt !== null) assert.ok(isNonEmptyString(v.title), s.id + ": " + field + " có yt thì title phải là chuỗi không rỗng (để ghi nguồn)");
    }

    // Mô tả ngắn của phái (hiện cạnh video giới thiệu): intro bắt buộc chuỗi không rỗng, note null hoặc chuỗi không rỗng
    assert.ok(isNonEmptyString(s.intro), s.id + ": intro phải là chuỗi không rỗng, nhận " + JSON.stringify(s.intro));
    assert.ok("note" in s && (s.note === null || isNonEmptyString(s.note)), s.id + ": note phải là null hoặc chuỗi không rỗng, nhận " + JSON.stringify(s.note));

    // Tiểu sử ngắn: chuỗi không rỗng, 120..900 ký tự (ngưỡng bảo vệ khỏi dán nhầm nội dung quá dài hoặc quá cụt)
    assert.ok(isNonEmptyString(s.story), s.id + ": story phải là chuỗi không rỗng, nhận " + JSON.stringify(s.story));
    const storyLen = [...s.story].length;
    assert.ok(storyLen >= STORY_MIN && storyLen <= STORY_MAX, s.id + ": story phải dài " + STORY_MIN + ".." + STORY_MAX + " ký tự, nhận " + storyLen);

    assert.ok(Array.isArray(s.keySkills), s.id + ": keySkills là mảng");
    assert.ok(s.keySkills.length <= MAX_KEY_SKILLS, s.id + ": keySkills tối đa " + MAX_KEY_SKILLS + " chiêu, nhận " + s.keySkills.length);
    for (const ks of s.keySkills) {
      assert.ok(ks && typeof ks === "object", s.id + ": mỗi keySkills là { skill, yt }");
      assert.ok(skillById.has(ks.skill), s.id + ": keySkills trỏ chiêu không tồn tại: " + ks.skill);
      assert.equal(skillById.get(ks.skill).sect, s.id, s.id + ": keySkills " + ks.skill + " thuộc phái khác");
      assert.ok("yt" in ks && isYtOrNull(ks.yt), s.id + ": keySkills " + ks.skill + " có yt phải là null hoặc mã YouTube 11 ký tự, nhận " + JSON.stringify(ks.yt));
    }

    for (const x of s.xinfa) {
      const where = s.id + "/" + (x && x.id);
      assert.ok(x && typeof x === "object", s.id + ": mỗi tâm pháp là object");
      for (const key of ["id", "name", "tag"]) assert.ok(isNonEmptyString(x[key]), where + ": " + key + " phải là chuỗi không rỗng");
      assert.ok("desc" in x && (x.desc === null || isNonEmptyString(x.desc)), where + ": desc phải là null hoặc chuỗi không rỗng, nhận " + JSON.stringify(x.desc));
      assert.ok(x.ring && typeof x.ring === "object" && !Array.isArray(x.ring), where + ": có ring");
      assert.equal(typeof x.ring.draft, "boolean", where + ": ring.draft là boolean");
      // ring = điểm đánh giá tổng quan (biên tập tay), không đếm số chiêu: scores null hoặc 6 khoá số nguyên 3..10 (thấp nhất 3)
      assert.ok("scores" in x.ring && "why" in x.ring && "summary" in x.ring, where + ": ring phải có scores, why, summary (null nếu chưa chấm)");
      if (x.ring.scores !== null) {
        const sc = x.ring.scores;
        assert.ok(sc && typeof sc === "object" && !Array.isArray(sc), where + ": ring.scores là null hoặc object");
        assert.deepEqual(Object.keys(sc).sort(), AXIS_KEYS.slice().sort(), where + ": ring.scores phải có đúng 6 khoá " + AXIS_KEYS.join(", "));
        for (const key of AXIS_KEYS) assert.ok(Number.isInteger(sc[key]) && sc[key] >= 3 && sc[key] <= 10, where + ": ring.scores." + key + " phải là số nguyên 3..10 (thấp nhất 3), nhận " + JSON.stringify(sc[key]));
        assert.ok(x.ring.why !== null, where + ": có ring.scores thì ring.why bắt buộc");
      }
      if (x.ring.why !== null) {
        const w = x.ring.why;
        assert.ok(w && typeof w === "object" && !Array.isArray(w), where + ": ring.why là null hoặc object");
        assert.deepEqual(Object.keys(w).sort(), AXIS_KEYS.slice().sort(), where + ": ring.why phải có đúng 6 khoá " + AXIS_KEYS.join(", "));
        for (const key of AXIS_KEYS) assert.ok(isNonEmptyString(w[key]), where + ": ring.why." + key + " phải là chuỗi không rỗng, nhận " + JSON.stringify(w[key]));
      }
      assert.ok(x.ring.summary === null || isNonEmptyString(x.ring.summary), where + ": ring.summary phải là null hoặc chuỗi không rỗng, nhận " + JSON.stringify(x.ring.summary));
      for (const key of ["total", "counts", "axes"]) assert.ok(!(key in x.ring), where + ": ring." + key + " là dạng cũ (đếm số chiêu), đã bỏ");
    }
  }

  for (const st of SETS) assert.ok(sectById.has(st.sect), "bộ " + st.id + " tham chiếu phái tồn tại");

  let iconFiles = 0, iconNull = 0;
  let prev = null;
  for (const k of SKILLS) {
    assert.ok(sectById.has(k.sect), k.id + ": sect tồn tại");
    assert.ok(setById.has(k.set), k.id + ": set tồn tại");
    assert.equal(typeof k.tang, "number", k.id + ": tang là number");
    if (k.xinfa !== null) assert.ok(sectById.get(k.sect).xinfa.some((x) => x.id === k.xinfa), k.id + ": xinfa thuộc phái");
    assert.ok(!/\(\d{5,}/.test(k.mota) && !k.extra.some((e) => /\(\d{5,}/.test(e)), k.id + ": còn số tuyệt đối");
    assert.ok(k.cast === null || typeof k.cast === "string");
    assert.ok(k.cooldown === null || typeof k.cooldown === "string");
    if (k.icon === null) iconNull++;
    else {
      assert.equal(k.icon, `assets/skills/${k.id}.png`);
      assert.ok(iconExists(k.icon), "thiếu file " + k.icon);
      iconFiles++;
    }
    // thứ tự: phái tăng dần; trong cùng phái + bộ thì tang không giảm
    if (prev) {
      const a = ORDER.indexOf(prev.sect), b = ORDER.indexOf(k.sect);
      assert.ok(a <= b, "thứ tự phái");
      if (prev.sect === k.sect && prev.set === k.set) assert.ok(prev.tang <= k.tang, "tang tăng dần trong bộ: " + k.id);
    }
    prev = k;
  }
  assert.equal(iconFiles + iconNull, SKILLS.length, "mỗi chiêu hoặc có icon hoặc icon null");
  return { iconFiles, iconNull, warnings };
}

// "Â" đơn lẻ là chữ Việt hợp lệ ("Âm"), nên chỉ bắt khi theo sau là ký tự Latin-1/C1 (dấu hiệu UTF-8 bị đọc sai).
export const MOJIBAKE = /[ÃÄÂ][\u0080-¿ŒœŠšŸŽžƒˆ˜–-›€™]|á»|â€|�/;

function main() {
  const load = (rel) => {
    const src = readFileSync(join(ROOT, rel), "utf8");
    const window = {};
    new Function("window", src)(window);
    return { src, window };
  };
  const sectsFile = load("data/sects.js");
  const skillsFile = load("data/skills.js");
  const rolesFile = load("data/skill-roles.js");
  checkVideoSource(sectsFile.window.JX_VIDEO_SOURCE);
  const { iconFiles, iconNull, warnings } = checkData(sectsFile.window.JX_SECTS, skillsFile.window.JX_SKILLS, skillsFile.window.JX_SETS);

  checkRoles(rolesFile.window.JX_SKILL_ROLES, skillsFile.window.JX_SKILLS);

  for (const [name, f] of [["sects.js", sectsFile], ["skills.js", skillsFile], ["skill-roles.js", rolesFile]]) {
    assert.ok(!MOJIBAKE.test(f.src), "mojibake trong " + name);
  }

  // Không để file PNG thừa không có chiêu nào trỏ tới
  const dir = join(ROOT, "assets", "skills");
  const pngs = readdirSync(dir).filter((f) => f.endsWith(".png"));
  assert.equal(pngs.length, iconFiles, "số file png trên đĩa bằng số chiêu có icon");
  const iconBytes = pngs.reduce((n, f) => n + statSync(join(dir, f)).size, 0);
  const jsBytes = statSync(join(ROOT, "data", "skills.js")).size;
  const sectsBytes = statSync(join(ROOT, "data", "sects.js")).size;

  console.log("OK: 9 phái, 18 tâm pháp, 35 bộ, 270 chiêu, id duy nhất, tham chiếu hợp lệ, tang là number");
  console.log("OK: intro (chuỗi không rỗng) + note (null hoặc chuỗi không rỗng) + story (chuỗi 120..900 ký tự) ở cả 9 phái; JX_VIDEO_SOURCE (4 chuỗi không rỗng, url YouTube); video + skillVideo { yt, title } (yt null hoặc 11 ký tự, có yt thì có title) ở cả 9 phái");
  console.log("OK: keySkills (tối đa 3, đúng phái); 18 tâm pháp: desc (null hoặc chuỗi không rỗng), ring (draft boolean; scores null hoặc 6 khoá số nguyên 3..10 (thấp nhất 3); why null hoặc 6 khoá chuỗi không rỗng, bắt buộc khi có scores; summary null hoặc chuỗi không rỗng)");
  console.log("OK: JX_SKILL_ROLES: đủ 270 id đúng tập id chiêu, mỗi chiêu 1-3 nhãn khác nhau thuộc 6 nhãn hợp lệ, why là chuỗi");
  console.log(`icon: ${iconFiles} file tồn tại + ${iconNull} null; không còn "(\\d{5,}"; không mojibake`);
  console.log(`bytes: data/skills.js=${jsBytes} data/sects.js=${sectsBytes} assets/skills=${iconBytes} (${pngs.length} file) tổng=${jsBytes + sectsBytes + iconBytes}`);
  for (const w of warnings) console.log("CẢNH BÁO: " + w);
}

// Chỉ chạy khi gọi trực tiếp, không chạy khi được import
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
