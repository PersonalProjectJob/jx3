/*
 * Sinh dữ liệu tĩnh cho trang Võ công từ file nguồn "index (3).html" (nằm ngoài repo) và data/skill-roles.js.
 *
 * Cách chạy (từ gốc repo, Node >= 18, không cần cài gì):
 *   node scripts/build-data.mjs "C:\Users\AD\Documents\GitHub\jx3\Ability\index (3).html" [--reset]
 *
 * Cờ:
 *   (không cờ)    Nếu data/sects.js đã có thì ĐỌC nó và GIỮ NGUYÊN phần biên tập tay: theo id phái là intro, note, story, video, skillVideo,
 *                 keySkills và window.JX_VIDEO_SOURCE; theo id tâm pháp là desc và TOÀN BỘ ring (draft, scores, why, summary).
 *                 Chỉ tính lại xinfa (id, name, tag), han, name. Phái/tâm pháp chưa có trong file cũ (hoặc có ring ở dạng cũ
 *                 counts/total/axes) nhận mặc định: intro/note chép nguyên văn từ panel__desc/panel__note của index.html và story là tiểu sử ngắn có sẵn (bảng SECTS dưới đây), video/skillVideo { yt: null, title: null }, keySkills [], desc null,
 *                 ring { draft: true, scores: null, why: null, summary: null } (chưa chấm điểm: trang ẩn vòng chỉ số).
 *   --reset       Bỏ qua toàn bộ phần giữ: về trạng thái mặc định (intro/note/story về giá trị mặc định trong bảng SECTS, video/skillVideo null, keySkills rỗng, desc null,
 *                 ring chưa chấm điểm, JX_VIDEO_SOURCE mặc định). MẤT HẾT điểm ring đã nhập tay và mã video.
 *   (Cờ --reset-ring cũ đã bỏ: ring không còn tính từ chiêu nên không có gì để "tính lại"; dùng cờ này sẽ báo cờ không hợp lệ.)
 *   data/sects.js chưa tồn tại thì mọi thứ lấy mặc định như --reset.
 *
 * Đầu vào thứ hai: data/skill-roles.js (window.JX_SKILL_ROLES, sửa tay được, build-data KHÔNG ghi đè). Trang dùng file này để hiện dòng
 * "Vai trò" của từng chiêu (KHÔNG dùng để tính vòng chỉ số). Thiếu chiêu nào, hoặc nhãn lạ, hoặc quá 3 nhãn -> báo lỗi và thoát mã 1
 * (không đoán, không ghi file nào).
 *
 * Đầu ra (kết quả giống hệt nhau nếu nguồn và phần biên tập không đổi):
 *   data/sects.js           window.JX_VIDEO_SOURCE + window.JX_SECTS — 9 phái, 18 tâm pháp (mỗi tâm pháp có ring riêng), video
 *   data/skills.js          window.JX_SETS + window.JX_SKILLS — bộ và chiêu thức
 *   assets/skills/<id>.png  icon từng chiêu (giải mã base64, ghi nguyên PNG)
 *
 * Quy ước:
 *  - Làm sạch mô tả: xoá "(NNNNN điểm ...)" có từ 5 chữ số trở lên (số tuyệt đối của nhân vật mẫu).
 *  - Vòng chỉ số (ring) là DỮ LIỆU BIÊN TẬP (điểm đánh giá tổng quan 3..10 cho 6 trục), KHÔNG tính từ số chiêu. Build chỉ giữ hoặc
 *    đặt mặc định, không bao giờ tự sinh điểm.
 *  - Nc lạ (không có trong bảng ánh xạ) -> báo lỗi và dừng, không đoán.
 */
import { readFileSync, writeFileSync, mkdirSync, readdirSync, unlinkSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const args = process.argv.slice(2);
const KNOWN_FLAGS = ["--reset"];
const badFlag = args.find((a) => a.startsWith("--") && !KNOWN_FLAGS.includes(a));
if (badFlag) {
  console.error("Cờ không hợp lệ: " + badFlag + ". Cờ hỗ trợ: " + KNOWN_FLAGS.join(", "));
  process.exit(1);
}
const RESET = args.includes("--reset");
const srcPath = args.find((a) => !a.startsWith("--"));
if (!srcPath) {
  console.error('Thiếu đường dẫn nguồn. Dùng: node scripts/build-data.mjs "<đường dẫn index (3).html>" [--reset]');
  process.exit(1);
}

// Nguồn chung của mọi video: kênh YouTube chính thức. Chỉ ghi đúng những gì kênh tự nhận.
const DEFAULT_VIDEO_SOURCE = {
  channel: "VÕ LÂM TRUYỀN KỲ 3",
  handle: "@VLTKPhienBan3D",
  url: "https://www.youtube.com/@VLTKPhienBan3D",
  about: "Kênh video chính thức của Võ Lâm Truyền Kỳ phiên bản 3D",
};

/* ---------- Đọc data/sects.js cũ (để giữ phần sửa tay) ---------- */
const sectsPath = join(ROOT, "data", "sects.js");
const keepOld = !RESET && existsSync(sectsPath);
const oldById = new Map();
let oldVideoSource = null;
if (keepOld) {
  const w = {};
  new Function("window", readFileSync(sectsPath, "utf8"))(w);
  if (Array.isArray(w.JX_SECTS)) for (const s of w.JX_SECTS) if (s && typeof s.id === "string") oldById.set(s.id, s);
  if (w.JX_VIDEO_SOURCE && typeof w.JX_VIDEO_SOURCE === "object") oldVideoSource = w.JX_VIDEO_SOURCE;
}
const oldXinfa = (sectId, xinfaId) => {
  const so = oldById.get(sectId);
  const list = so && Array.isArray(so.xinfa) ? so.xinfa : [];
  return list.find((x) => x && x.id === xinfaId) || null;
};
const keepVideo = (v) => ({
  yt: v && typeof v === "object" && v.yt != null ? v.yt : null,
  title: v && typeof v === "object" && v.title != null ? v.title : null,
});

/* ---------- Bảng phái + tâm pháp (tên/tag, và intro/note của phái, lấy nguyên văn từ index.html: panel__desc / panel__note; story là tiểu sử ngắn do biên tập viết) ---------- */
const SECTS = [
  { id: "thien-sach", name: "Thiên Sách", han: "天策", common: "Nội công Thiên Sách",
    intro: "Kỵ binh Đại Đường dưới trướng Lý thị. Thương dài, xung trận đi đầu.", note: null,
    story: "Thiên Sách Phủ đặt ở Lạc Dương, khởi từ phủ tướng của Lý Thế Dân thuở còn là Tần Vương và về sau là lực lượng thân cận của hoàng tộc họ Lý. Đệ tử không theo tôn giáo nào, chỉ một lòng trung với nhà Đường, giỏi trường thương và chiến đấu trên lưng ngựa. Khi loạn An Sử nổ ra, phủ bị quân Lang Nha vây hãm, cầm cự để Huyền Tông kịp rời Trường An, rồi cùng quân Thương Vân giành lại phủ. Chính Thiên Sách đứng ra kết nối các phái, mở đường cho Hạo Khí Minh.",
    xinfa: [["Ngạo Huyết Chiến Ý", "Ngoại công"], ["Thiết Lao Luật", "Phòng thủ · Ngoại công"]] },
  { id: "thuan-duong", name: "Thuần Dương", han: "纯阳", common: "Nội công Thuần Dương",
    intro: "Đạo môn trên Hoa Sơn. Kiếm khí và trận pháp, khống chế cả một vùng.", note: null,
    story: "Thuần Dương Cung là đạo quán trên núi Hoa Sơn, do đạo sĩ Lữ Thuần Dương dựng nên và hưng thịnh dưới triều Đường Huyền Tông. Đệ tử luyện nội công trước rồi mới học kiếm, chia hai nhánh: khí tông theo Tử Hà Công, kiếm tông theo Thái Hư Kiếm Ý, lấy tĩnh chế động, ít màng danh lợi. Sau khi Lữ Thuần Dương quy ẩn, Lý Vong Sinh nối ngôi chưởng môn; đại đệ tử Tạ Vân Lưu vì vướng vào biến cố triều đình mà rời sư môn.",
    xinfa: [["Tử Hà Công", "Nội công · Hỗn nguyên"], ["Thái Hư Kiếm Ý", "Ngoại công"]] },
  { id: "van-hoa", name: "Vạn Hoa", han: "万花", common: "Nội công Vạn Hoa",
    intro: "Cốc ẩn giữa trăm hoa. Ngòi bút vừa điểm huyệt vừa cứu người.", note: null,
    story: "Vạn Hoa Cốc ẩn trong một sơn cốc kín, chỉ vào được qua đường hầm bí mật, được ví như cõi Đào Nguyên. Cốc do Đông Phương Vũ Hiên cùng các bậc văn nhân tài tử dựng nên, nơi tụ hội những người tinh thông cầm, kỳ, thư, họa và y thuật. Đệ tử dùng bút để điểm huyệt tiệt mạch và chữa bệnh cứu người, giữ lập trường trung lập, ít can dự vào tranh chấp giang hồ. Cốc còn cất giữ bộ bí kíp Vạn Hoa, trong đó nổi tiếng nhất là võ kinh và y kinh.",
    xinfa: [["Hoa Gian Du", "Nội công · Hỗn nguyên"], ["Ly Kinh Dịch Đạo", "Trị liệu · Hỗn nguyên"]] },
  { id: "that-tu", name: "Thất Tú", han: "七秀", common: "Nội công Thất Tú",
    intro: "Song kiếm hoà cùng vũ điệu, đẹp mà sát.", note: "Chỉ dành cho nhân vật nữ.",
    story: "Thất Tú Phường nằm ven hồ ở Dương Châu, được xếp vào những nơi phong nhã bậc nhất Đại Đường cùng Vạn Hoa Cốc và Trường Ca Môn. Nơi đây khởi từ Ức Doanh Lâu của Công Tôn Đại Nương, nhận nuôi cô nhi và dạy múa nhạc, về sau mới đổi tên thành Thất Tú Phường. Đệ tử phần lớn là nữ, chia ngoại phường biểu diễn và nội phường là cấm địa luyện võ; sở trường song kiếm hoà cùng vũ điệu, với hai tâm pháp Băng Tâm Quyết và Vân Thường Tâm Kinh.",
    xinfa: [["Băng Tâm Quyết", "Nội công · Âm tính"], ["Vân Thường Tâm Kinh", "Trị liệu · Âm tính"]] },
  { id: "thieu-lam", name: "Thiếu Lâm", han: "少林", common: "Nội công Thiếu Lâm",
    intro: "Thiền trượng và quyền cước. Bất động như núi giữa vòng vây.", note: "Chỉ dành cho nhân vật nam.",
    story: "Thiếu Lâm Tự dưới chân núi Thiếu Thất, Tung Sơn, là tổ đình Thiền tông từ khi Bồ Đề Đạt Ma đến truyền đạo. Đầu nhà Đường, tăng binh của chùa từng giúp Lý Thế Dân dẹp loạn nên được triều đình trọng vọng. Chùa chỉ nhận đệ tử nam, lấy côn pháp làm gốc, nội công Dịch Cân Kinh và Tẩy Tủy Kinh đi cùng Phật pháp. Trong giang hồ, Thiếu Lâm đứng cùng Thiên Sách trong vụ Đại Quang Minh Tự, và phải đối đầu những thế lực ngoại bang nhòm ngó Dịch Cân Kinh như Nhất Đao Lưu và Bồ Đề Hội.",
    xinfa: [["Dịch Cân Kinh", "Nội công · Dương tính"], ["Tẩy Tủy Kinh", "Phòng thủ · Dương tính"]] },
  { id: "tang-kiem", name: "Tàng Kiếm", han: "藏剑", common: "Nội công Tàng Kiếm",
    intro: "Diệp gia bên Tây Hồ. Khinh kiếm, trọng kiếm luân phiên, sát thương dồn dập.", note: null,
    story: "Tàng Kiếm Sơn Trang nằm bên Tây Hồ, Hàng Châu, vốn là thế gia rèn kiếm Giang Nam của họ Diệp. Diệp Mạnh Thu bỏ con đường khoa cử để theo kiếm đạo và dựng sơn trang; đại trang chủ đời hai là Diệp Anh. Mười năm một lần, sơn trang mở Danh Kiếm Đại Hội, trao thanh kiếm tôi luyện suốt mười năm cho người mạnh nhất. Môn phái dùng cả khinh kiếm lẫn trọng kiếm, theo Nho gia và đề cao hiệp nghĩa; họ Diệp được xếp vào tứ đại thế gia thời Thiên Bảo cùng Đường gia, Liễu gia và Dương gia.",
    xinfa: [["Vấn Thủy Quyết", "Ngoại công · Khinh kiếm"], ["Sơn Cư Kiếm Ý", "Ngoại công · Trọng kiếm"]] },
  { id: "ngu-doc", name: "Ngũ Độc", han: "五毒", common: "Nội công Ngũ Độc",
    intro: "Miêu Cương cổ độc. Tiếng sáo gọi trùng, độc ngấm dần không thoát.", note: null,
    story: "Ngũ Độc Giáo, giáo đồ tự gọi là Ngũ Tiên Giáo và không thích bị gọi là Ngũ Độc, đặt tổng đàn sâu trong làng người Miêu ở Tây Nam, sau Vô Tâm Lĩnh. Giáo có lai lịch cổ xưa mà chính giáo đồ cũng không rõ, thờ Xi Vưu và nhận mình là hậu duệ Cửu Lê. Võ học là cổ thuật và độc thuật, điều khiển bọ cạp, thiềm thừ, rắn, rết, nhện; tiếng sáo gọi trùng là vũ khí đặc trưng. Giáo chủ hiện nay là Khúc Vân; thời Thiên Bảo giáo từng chia rẽ khi tả trưởng lão Ô Mông Quý nổi loạn rồi lập Thiên Nhất Giáo.",
    xinfa: [["Độc Kinh", "Nội công · Độc tính"], ["Bổ Thiên Quyết", "Trị liệu · Độc tính"]] },
  // index.html đang ghi "Thiên La Quỷ Đạo" (lỗi); dùng "Ngụy" theo nguồn.
  { id: "duong-mon", name: "Đường Môn", han: "唐门", common: "Nội công Đường Môn",
    intro: "Ám khí và cơ quan đất Thục. Ẩn mình, bắn từ xa, không ai thấy người.", note: null,
    story: "Đường Môn khởi từ những gia tộc sát thủ vùng Ba Thục, sau mở rộng sang buôn bán muối, binh khí, tơ lụa mà trở thành một trong tứ đại thế gia. Đường Gia Bảo tường cao ngói đen, cơ quan dày đặc, là cấm địa; người ngoài chỉ được đến chợ và bến sông Đường Gia Tập. Đệ tử sở trường ám khí, nỏ, cơ quan và độc, dùng Thiên Cơ Hạp, không theo tôn giáo mà chỉ trung thành với gia tộc. Môn chủ hiện nay là Đường Ngạo Thiên, người quyết khôi phục danh tiếng của Đường Môn.",
    xinfa: [["Kinh Vũ Quyết", "Ngoại công"], ["Thiên La Ngụy Đạo", "Nội công · Độc tính"]] },
  { id: "minh-giao", name: "Minh Giáo", han: "明教", common: "Nội công Minh Giáo",
    intro: "Song loan đao từ Tây Vực. Ẩn thân giữa ánh sáng và bóng tối.", note: null,
    story: "Minh Giáo do Lục Nguy Lâu lập ra, có gốc từ Hỏa giáo của Ba Tư; ông là người Hán lớn lên nơi đất Ba Tư rồi mang giáo về Trung Nguyên. Giáo thờ Minh Tôn, lấy Thánh Hỏa Điển làm điển tịch, dùng loan đao, nổi tiếng ẩn tung và vũ đạo dị vực. Trong vụ Đại Quang Minh Tự, Thiên Sách phối hợp Thiếu Lâm và các phái đánh vào, phần lớn cao tầng của giáo thiệt mạng; Lục Nguy Lâu thoát được, về sau giáo chia hai nhánh và ông đưa người về Thánh Mộ Sơn nơi sa mạc Tây Vực.",
    xinfa: [["Phần Ảnh Thánh Quyết", "Nội công · Âm dương"], ["Minh Tôn Lưu Ly Thể", "Phòng thủ · Âm dương"]] },
];

// Sáu nhãn vai trò (khớp data/skill-roles.js). Thứ tự này cũng là thứ tự khoá trong ring.scores / ring.why.
const AXIS_KEYS = ["sat_thuong", "khong_che", "ho_tro", "tri_lieu", "phong_thu", "co_dong"];
const MAX_TAGS = 3;

/* ---------- Đọc data/skill-roles.js (phân loại vai trò, sửa tay) ---------- */
const rolesPath = join(ROOT, "data", "skill-roles.js");
if (!existsSync(rolesPath)) {
  console.error("LỖI: thiếu data/skill-roles.js (phân loại vai trò 270 chiêu). Không đoán nhãn, dừng.");
  process.exit(1);
}
const rolesWin = {};
new Function("window", readFileSync(rolesPath, "utf8"))(rolesWin);
const ROLES = rolesWin.JX_SKILL_ROLES;
if (!ROLES || typeof ROLES !== "object" || Array.isArray(ROLES)) {
  console.error("LỖI: data/skill-roles.js phải gán window.JX_SKILL_ROLES là object.");
  process.exit(1);
}

/* ---------- Tiện ích ---------- */
function slug(s) {
  return s
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d").replace(/Đ/g, "d")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

let cleanedCount = 0;
function clean(s) {
  if (!/\(\d{5,}/.test(s)) return s; // chuỗi không có số tuyệt đối thì giữ nguyên từng byte
  cleanedCount++;
  return s
    .replace(/\s*\(\d{5,}[^)]*\)/g, "")
    .replace(/[ \t]{2,}/g, " ")
    .replace(/\s+([,.;:])/g, "$1")
    .trim();
}

/* ---------- Đọc nguồn ---------- */
const html = readFileSync(srcPath, "utf8");
const start = html.indexOf("const DATA=");
if (start < 0) throw new Error("Không thấy `const DATA=` trong nguồn");
const arrStart = start + "const DATA=".length;
const end = html.indexOf("}]}];", arrStart);
if (end < 0) throw new Error("Không thấy phần kết thúc của DATA");
const DATA = JSON.parse(html.slice(arrStart, end + "}]}]".length));

/* ---------- Ánh xạ nc -> phái / tâm pháp ---------- */
const ncMap = new Map();
for (const s of SECTS) {
  ncMap.set(s.common, { sect: s.id, xinfa: null });
  for (const [name] of s.xinfa) ncMap.set(name, { sect: s.id, xinfa: slug(name) });
}

/* ---------- Chuẩn hoá chiêu ---------- */
function parseThi(thi) {
  let cast = null, cooldown = null;
  for (const t of thi || []) {
    if (t === "Thi triển nhanh") cast = "Nhanh";
    else if (t.startsWith("Thi triển: ")) cast = t.slice("Thi triển: ".length);
    else if (t.startsWith("Điều chỉnh: ")) {
      const v = t.slice("Điều chỉnh: ".length).trim();
      cooldown = v === "0" ? null : v;
    } else throw new Error("Dòng thi[] lạ: " + t);
  }
  return { cast, cooldown };
}

const setSect = new Map(); // tên bộ -> {sect: count}
const sets = []; // theo thứ tự nguồn
const skills = [];
const seenIds = new Set();
const missingIcon = [];

for (const set of DATA) {
  const setId = slug(set.name);
  sets.push({ id: setId, name: set.name, sub: set.sub, sect: null });
  const tally = {};
  for (const sk of set.skills) {
    const map = ncMap.get(sk.nc);
    if (!map) throw new Error(`nc không có trong bảng ánh xạ: "${sk.nc}" (chiêu ${sk.name}, bộ ${set.name})`);
    tally[map.sect] = (tally[map.sect] || 0) + 1;
    const tang = Number(String(sk.tang).replace(/^Tầng\s*/, ""));
    if (!Number.isInteger(tang)) throw new Error(`tang lạ: ${sk.tang} (${sk.name})`);
    const id = slug(sk.name);
    if (seenIds.has(id)) throw new Error("Trùng id chiêu: " + id);
    seenIds.add(id);

    let icon = null;
    if (sk.icon) {
      const m = /^data:image\/png;base64,(.+)$/.exec(sk.icon);
      if (!m) throw new Error("icon không phải PNG base64: " + sk.name);
      icon = { id, buf: Buffer.from(m[1], "base64") };
    } else missingIcon.push(sk.name);

    const { cast, cooldown } = parseThi(sk.thi);
    skills.push({
      _set: setId, _setIdx: sets.length - 1, _seq: skills.length, _icon: icon,
      id, name: sk.name, poem: sk.poem, sect: map.sect, set: setId,
      xinfa: map.xinfa, tang,
      culy: sk.culy === "Không" ? null : sk.culy,
      hao: sk.hao, vukhi: sk.vukhi, cast, cooldown,
      mota: clean(sk.mota), extra: (sk.extra || []).map(clean),
      icon: icon ? `assets/skills/${id}.png` : null,
    });
  }
  const sectsOfSet = Object.entries(tally).sort((a, b) => b[1] - a[1]);
  sets[sets.length - 1].sect = sectsOfSet[0][0];
  if (sectsOfSet.length > 1) {
    console.warn(`CẢNH BÁO: bộ "${set.name}" chứa chiêu của nhiều phái ${JSON.stringify(tally)} -> gán ${sectsOfSet[0][0]}`);
  }
}

/* ---------- Sắp xếp: phái -> bộ -> tang tăng dần (ổn định) ---------- */
const sectOrder = new Map(SECTS.map((s, i) => [s.id, i]));
// Chiêu thuộc phái theo skill.sect; thứ tự bộ theo nguồn. Một bộ gán 1 phái; chiêu lạc phái vẫn xếp theo phái của chính nó.
skills.sort((a, b) =>
  sectOrder.get(a.sect) - sectOrder.get(b.sect) ||
  a._setIdx - b._setIdx ||
  a.tang - b.tang ||
  a._seq - b._seq);
sets.sort((a, b) => sectOrder.get(a.sect) - sectOrder.get(b.sect));
// Array.prototype.sort ổn định (Node >= 12) nên thứ tự nguồn được giữ khi cùng phái.

/* ---------- Kiểm data/skill-roles.js: đủ chiêu, nhãn hợp lệ (không đoán) ---------- */
{
  const problems = [];
  const ids = new Set(skills.map((k) => k.id));
  for (const k of skills) {
    const r = Object.prototype.hasOwnProperty.call(ROLES, k.id) ? ROLES[k.id] : null;
    if (!r) { problems.push("thiếu chiêu trong skill-roles.js: " + k.id); continue; }
    const t = r.tags;
    if (!Array.isArray(t) || t.length < 1 || t.length > MAX_TAGS || new Set(t).size !== t.length || t.some((x) => !AXIS_KEYS.includes(x))) {
      problems.push("tags sai (cần 1 đến " + MAX_TAGS + " nhãn khác nhau thuộc " + AXIS_KEYS.join(", ") + "): " + k.id + " = " + JSON.stringify(t));
    }
  }
  for (const id of Object.keys(ROLES)) if (!ids.has(id)) problems.push("skill-roles.js có id không phải chiêu nào: " + id);
  if (problems.length) {
    console.error("LỖI: data/skill-roles.js không khớp danh sách chiêu (" + problems.length + " vấn đề). Không ghi file nào.");
    for (const p of problems.slice(0, 30)) console.error("  - " + p);
    process.exit(1);
  }
}

/* ---------- Vòng chỉ số của từng tâm pháp: dữ liệu biên tập, chỉ giữ hoặc đặt mặc định ---------- */
const isScores = (o) => !!o && typeof o === "object" && !Array.isArray(o) && AXIS_KEYS.every((k) => Number.isInteger(o[k]) && o[k] >= 3 && o[k] <= 10);
const isWhy = (o) => !!o && typeof o === "object" && !Array.isArray(o) && AXIS_KEYS.every((k) => typeof o[k] === "string" && o[k].trim() !== "");
const isNullOrText = (v) => v === null || (typeof v === "string" && v.trim() !== "");
// Ring ở dạng mới (draft + scores + why + summary) thì giữ nguyên; ring dạng cũ (counts/total/axes) hoặc hỏng thì bỏ, dùng mặc định.
const keepableRing = (r) => !!r && typeof r === "object" && typeof r.draft === "boolean" &&
  (r.scores === null || isScores(r.scores)) && (r.scores === null ? r.why === null || isWhy(r.why) : isWhy(r.why)) && isNullOrText(r.summary);
const defaultRing = () => ({ draft: true, scores: null, why: null, summary: null });
const keptNote = []; // phái nào có trong file cũ
let keptXinfa = 0;   // tâm pháp giữ được desc hoặc ring từ file cũ
let keptRings = 0;
// intro/note của phái: giữ bản sửa tay trong sects.js cũ nếu hợp lệ (intro là chuỗi không rỗng; note là null hoặc chuỗi không rỗng,
// null do người biên tập đặt chủ ý cũng được giữ); thiếu hoặc sai dạng thì lấy mặc định từ index.html (bảng SECTS ở trên).
const keepIntro = (old, dflt) => (old && typeof old.intro === "string" && old.intro.trim() !== "" ? old.intro : dflt);
const keepNote = (old, dflt) => (old && Object.prototype.hasOwnProperty.call(old, "note") && (old.note === null || (typeof old.note === "string" && old.note.trim() !== "")) ? old.note : dflt);
// story: tiểu sử ngắn của phái, giữ bản sửa tay trong sects.js cũ nếu là chuỗi không rỗng; thiếu hoặc sai dạng thì lấy mặc định ở bảng SECTS.
const keepStory = (old, dflt) => (old && typeof old.story === "string" && old.story.trim() !== "" ? old.story : dflt);
const sectsOut = SECTS.map((s) => {
  if (oldById.has(s.id)) keptNote.push(s.id);
  const sectOld = oldById.get(s.id);
  const xinfaOut = s.xinfa.map(([name, tag]) => {
    const id = slug(name);
    const old = sectOld ? oldXinfa(s.id, id) : null;
    const keepRing = !!old && keepableRing(old.ring);
    const keepDesc = !!old && typeof old.desc === "string" && old.desc.trim() !== "";
    if (keepRing || keepDesc) keptXinfa++;
    if (keepRing) keptRings++;
    return {
      id, name, tag,
      desc: keepDesc ? old.desc : null,
      ring: keepRing
        ? { draft: old.ring.draft,
            scores: old.ring.scores === null ? null : Object.fromEntries(AXIS_KEYS.map((a) => [a, old.ring.scores[a]])),
            why: old.ring.why === null ? null : Object.fromEntries(AXIS_KEYS.map((a) => [a, old.ring.why[a]])),
            summary: old.ring.summary }
        : defaultRing(),
    };
  });
  return {
    id: s.id, name: s.name, han: s.han,
    intro: keepIntro(sectOld, s.intro),
    note: keepNote(sectOld, s.note),
    story: keepStory(sectOld, s.story),
    xinfa: xinfaOut,
    video: keepVideo(sectOld && sectOld.video),
    skillVideo: keepVideo(sectOld && sectOld.skillVideo),
    keySkills: sectOld && Array.isArray(sectOld.keySkills) ? sectOld.keySkills : [],
  };
});
const videoSourceOut = oldVideoSource || DEFAULT_VIDEO_SOURCE;

/* ---------- Ghi file ---------- */
const stripPriv = (sk) => {
  const o = {};
  for (const k of ["id", "name", "poem", "sect", "set", "xinfa", "tang", "culy", "hao", "vukhi", "cast", "cooldown", "mota", "extra", "icon"]) o[k] = sk[k];
  return o;
};

const sectsJs = `/*
 * Dữ liệu 9 phái, 18 tâm pháp cho trang Võ công. FILE CÓ THỂ SINH bởi scripts/build-data.mjs (xem comment đầu file đó);
 * script giữ nguyên phần biên tập tay (intro, note, story, video, skillVideo, keySkills, JX_VIDEO_SOURCE; ở mỗi tâm pháp: desc, ring) khi chạy lại.
 *
 * Mỗi phái:
 *   id         Trùng hậu tố id panel trên landing (panel-<id>)
 *   name, han  Tên Việt và chữ Hán
 *   intro      Đoạn mô tả ngắn của phái (chuỗi không rỗng), hiện ở cột phải cạnh video/ảnh giới thiệu phái trên trang Võ công;
 *              chép nguyên văn từ <p class="panel__desc"> của panel phái trong index.html, sửa tay được ở đây
 *   note       Ghi chú ngắn kèm theo (vd "Chỉ dành cho nhân vật nữ."), chép từ <p class="panel__note"> trong index.html; null = không có
 *   story      Tiểu sử và cốt truyện ngắn của phái (chuỗi không rỗng, 120..900 ký tự), do biên tập viết lại bằng lời riêng từ tư liệu tham khảo;
 *              hiện dưới intro/note ở cột phải cạnh video giới thiệu phái trên trang Võ công, sửa tay được ở đây
 *   xinfa      2 tâm pháp, tâm pháp đầu là mặc định của trang Võ công (xem bên dưới)
 *   video      Video giới thiệu phái: { yt, title } — yt là mã YouTube hoặc null (ẩn); title là tiêu đề nguyên văn trên YouTube
 *   skillVideo Video "Học kỹ năng" của phái: cùng dạng { yt, title }; yt null = không hiện
 *   keySkills  Tối đa 3 chiêu tiêu biểu: { skill: "<id chiêu>", yt: mã YouTube | null }. Có thể để trống.
 *
 * Mỗi tâm pháp (phần tử của xinfa):
 *   id, name, tag  Tên và nhãn lấy nguyên văn từ trang landing
 *   desc           Văn bản giới thiệu lối chơi do chủ dự án tự viết; null = chưa có (trang không hiện gì)
 *   ring           Vòng chỉ số = ĐIỂM ĐÁNH GIÁ TỔNG QUAN của tâm pháp (KHÔNG đếm số chiêu). Hiện là ĐÁNH GIÁ TỰ ĐỘNG do một agent
 *                  đọc mô tả các chiêu rồi chấm, CHƯA được con người duyệt: chủ dự án sửa tay điểm ngay tại đây rồi đổi draft thành false.
 *                    draft    true = chưa duyệt (trang hiện chú thích "đang chờ duyệt"); false = đã duyệt
 *                    scores   null (chưa chấm: trang ẩn vòng) hoặc 6 khoá sat_thuong, khong_che, ho_tro, tri_lieu, phong_thu, co_dong,
 *                             mỗi khoá là số nguyên 3..10 (thấp nhất 3, không bao giờ về 0; thang tuyệt đối, không chuẩn hoá giữa các tâm pháp)
 *                    why      null hoặc 6 khoá như scores, mỗi khoá là một câu lý do (chuỗi không rỗng; bắt buộc khi scores khác null)
 *                    summary  null hoặc một câu nhận định tổng quan về tâm pháp
 */

/*
 * Nguồn của MỌI video (video, skillVideo): kênh YouTube chính thức của Võ Lâm Truyền Kỳ phiên bản 3D.
 * Chỉ ghi đúng những gì kênh tự nhận; giao diện hiển thị dòng "Nguồn: “<tiêu đề>” · kênh YouTube chính thức <channel>".
 */
window.JX_VIDEO_SOURCE = { channel: ${JSON.stringify(videoSourceOut.channel)}, handle: ${JSON.stringify(videoSourceOut.handle)}, url: ${JSON.stringify(videoSourceOut.url)}, about: ${JSON.stringify(videoSourceOut.about)} };

window.JX_SECTS = ${JSON.stringify(sectsOut, null, 2)};
`;

const skillsJs = `/*
 * Bộ và chiêu thức cho trang Võ công. FILE SINH TỰ ĐỘNG bởi scripts/build-data.mjs — đừng sửa tay.
 *
 * window.JX_SETS: các bộ chiêu, đã xếp theo thứ tự phái.
 *   id, name, sub (mô tả ngắn, vd "Vũ khí: Côn"), sect (id phái; mỗi bộ thuộc đúng 1 phái)
 *
 * window.JX_SKILLS: 270 chiêu, xếp theo phái -> bộ -> tầng tăng dần.
 *   id, name, poem (câu thơ)
 *   sect, set       id phái, id bộ
 *   xinfa           id tâm pháp (khớp JX_SECTS[].xinfa[].id) hoặc null = chiêu dùng chung của cả phái
 *   tang            Số tầng (nguyên, giữ nguyên 101, 102)
 *   culy            Tầm đánh, vd "20 thước", hoặc null (nguồn ghi "Không")
 *   hao             Hao tổn, vd "2% NL cơ bản (52 điểm)"
 *   vukhi           Vũ khí yêu cầu
 *   cast            "Nhanh" | "1.5 giây" | null  (thời gian thi triển)
 *   cooldown        "30 giây" | "2 phút" | null  (thời gian điều chỉnh/hồi chiêu)
 *   mota, extra     Mô tả và các dòng bổ sung (đã xoá số tuyệt đối của nhân vật mẫu)
 *   icon            "assets/skills/<id>.png" hoặc null (2 chiêu nguồn không có icon)
 */
window.JX_SETS = [
${sets.map((s) => "  " + JSON.stringify(s)).join(",\n")}
];

window.JX_SKILLS = [
${skills.map((s) => "  " + JSON.stringify(stripPriv(s))).join(",\n")}
];
`;

mkdirSync(join(ROOT, "data"), { recursive: true });
writeFileSync(join(ROOT, "data", "sects.js"), sectsJs, "utf8");
writeFileSync(join(ROOT, "data", "skills.js"), skillsJs, "utf8");

const iconDir = join(ROOT, "assets", "skills");
mkdirSync(iconDir, { recursive: true });
const keep = new Set();
let iconBytes = 0;
for (const s of skills) {
  if (!s._icon) continue;
  writeFileSync(join(iconDir, s.id + ".png"), s._icon.buf);
  keep.add(s.id + ".png");
  iconBytes += s._icon.buf.length;
}
for (const f of readdirSync(iconDir)) if (f.endsWith(".png") && !keep.has(f)) unlinkSync(join(iconDir, f)); // dọn icon mồ côi

/* ---------- Báo cáo ---------- */
console.log(`Bộ: ${sets.length} | Chiêu: ${skills.length} | Icon ghi: ${keep.size} | Thiếu icon: ${missingIcon.length} (${missingIcon.join(", ")})`);
console.log(`Chuỗi mota/extra bị làm sạch: ${cleanedCount} | Tổng byte icon: ${iconBytes}`);
if (RESET) console.log("Chế độ --reset: bỏ qua phần giữ, về mặc định (mất điểm ring đã nhập).");
else if (keepOld) console.log(`Giữ phần biên tập (video, skillVideo, keySkills, JX_VIDEO_SOURCE) cho ${keptNote.length}/${SECTS.length} phái; desc/ring giữ cho ${keptXinfa}/18 tâm pháp (ring dạng mới giữ nguyên: ${keptRings}/18), từ data/sects.js cũ.`);
else console.log("data/sects.js chưa có: dùng mặc định.");
console.log("Vòng chỉ số từng tâm pháp (dữ liệu biên tập, build không tính):");
for (const s of sectsOut) {
  for (const x of s.xinfa) {
    const sc = x.ring.scores;
    console.log(`  ${(s.id + "/" + x.id).padEnd(34)} ` + (sc ? AXIS_KEYS.map((a) => a.slice(0, 4) + "=" + sc[a]).join(" ") : "chưa chấm điểm") + ` draft=${x.ring.draft}`);
  }
}
