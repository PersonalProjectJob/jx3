/*
 * Bảng kỷ niệm ("Còn nhớ không?").
 * Lưới ô: một nửa ô hiện ảnh, nửa còn lại hiện câu hoài niệm.
 * Cứ mỗi nhịp, một ảnh ở lâu nhất đổi thành chữ và một ô chữ đổi thành ảnh mới (hiệu ứng lấp lánh).
 * `interval` là thời gian một ảnh ở lại (mili-giây). `perRound` là số ảnh tối đa cùng lúc trên desktop.
 *
 * photos: { src, alt, caption }  ·  notes: câu hoài niệm cho các ô chữ.
 * Ảnh chụp trong game 剑网3, bản quyền thuộc Kingsoft · Seasun; nguồn: diễn đàn xoyo, 52pk, 17173, 3dmgame, zhihu, yesky.
 */
window.JX_MEMORIES = {
  perRound: 4,
  interval: 5000,
  photos: [
    { src: "assets/memories/dem-trang-pho-ban.webp", alt: "Người chơi đứng trước cổng phó bản dưới trăng tròn", caption: "Đêm trăng trước cổng phó bản" },
    { src: "assets/memories/chia-tay-ban-80.webp", alt: "Rất đông người chơi đứng chụp ảnh tập thể", caption: "Ảnh tập thể chia tay bản 80" },
    { src: "assets/memories/mai-ngoi-truong-an.webp", alt: "Mái ngói cung điện Trường An dưới nắng", caption: "Mái ngói Trường An dưới nắng" },
    { src: "assets/memories/hoa-son-thac-may.webp", alt: "Vách núi, thác nước và mây ở Hoa Sơn", caption: "Vách núi Hoa Sơn, thác đổ trong mây" },
    { src: "assets/memories/dao-huong-thon-ao.webp", alt: "Bờ ao lau sậy ở Đạo Hương Thôn", caption: "Bờ ao Đạo Hương Thôn" },
    { src: "assets/memories/van-hoa-coc.webp", alt: "Cánh đồng hoa tím ở Vạn Hoa Cốc", caption: "Biển hoa tím Vạn Hoa Cốc" },
    { src: "assets/memories/ky-binh-vuot-song.webp", alt: "Đoàn kỵ binh phi ngựa vượt sông", caption: "Kỵ binh vượt sông ra trận" },
    { src: "assets/memories/giap-tran-bai-bien.webp", alt: "Hai đạo quân giáp trận trên bãi biển", caption: "Hạo Khí, Ác Nhân giáp trận" },
    { src: "assets/memories/that-tu-hoa-dao.webp", alt: "Hai nữ hiệp Thất Tú múa kiếm dưới hoa đào", caption: "Hai nàng Thất Tú dưới hoa đào" },
    { src: "assets/memories/khinh-cong-hoa-dao.webp", alt: "Nhân vật khinh công trên mái đình giữa hoa đào", caption: "Khinh công giữa trời hoa đào" },
    { src: "assets/memories/ca-bang-bac-da.webp", alt: "Cả bang đứng xếp hàng trên bậc đá", caption: "Cả bang xếp hàng trên bậc đá" },
    { src: "assets/memories/cho-boss-the-gioi.webp", alt: "Rất đông người chơi vây quanh boss thế giới", caption: "Cả server vây boss thế giới" },
    { src: "assets/memories/mui-thuyen.webp", alt: "Nhân vật ngồi trên mui thuyền giữa sông núi", caption: "Ngồi mui thuyền ngắm non nước" },
    { src: "assets/memories/tay-ho-hoang-hon.webp", alt: "Hồ nước lúc hoàng hôn, hoa đào nở hai bên", caption: "Hồ nước hoàng hôn, đào nở" },
    { src: "assets/memories/dao-huong-thon.webp", alt: "Phong cảnh Đạo Hương Thôn", caption: "Đạo Hương Thôn ngày đầu nhập môn" },
    { src: "assets/memories/rung-truc-hoa-dao.webp", alt: "Lối nhỏ qua rừng trúc, hoa đào nở bên suối", caption: "Lối nhỏ qua rừng trúc" },
    { src: "assets/memories/chuc-long-dien.webp", alt: "Đội hình đánh boss trong phó bản Chúc Long Điện", caption: "Phó bản Chúc Long Điện" },
    { src: "assets/memories/dau-truong.webp", alt: "Một trận đấu trường giữa hai đội", caption: "Một trận Danh Kiếm Đại Hội" },
    { src: "assets/memories/quang-truong.webp", alt: "Quảng trường thành đông người chơi", caption: "Quảng trường đông người" }
  ],
  notes: [
    "Đêm trăng ngồi trước cổng phó bản, đợi cho đủ người.",
    "Cả server vây boss thế giới, giật không nổi một món đồ.",
    "Tấm ảnh cuối cùng trước khi bản 80 khép lại.",
    "Lần đầu khinh công qua mái ngói Trường An.",
    "Đứng trên vách Hoa Sơn, nhìn thác đổ vào mây.",
    "Ngày đầu nhập môn ở Đạo Hương Thôn.",
    "Rong ruổi Vạn Hoa Cốc chỉ để ngắm hoa.",
    "Chiến trường phe phái kéo dài tới tận sáng.",
    "Thua năm trận Danh Kiếm liền vẫn xếp hàng đánh tiếp.",
    "Cả bang xếp hàng trên bậc đá chụp ảnh.",
    "Rao bán đồ trên kênh thế giới đến khàn cả giọng.",
    "Người sư phụ đầu tiên dẫn đi làm nhiệm vụ.",
    "Nghe nhạc nền Đạo Hương Thôn mà nhớ cả một thời."
  ]
};
