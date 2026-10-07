/*
 * Tin tức hiển thị trên trang. Tin đầu tiên là tin lớn, các tin sau hiện dạng mục lục.
 *
 * Mỗi tin:
 *   date      "2026-10-20" hoặc "" (hiện là "—")
 *   category  Chuyên mục, ví dụ "Thông báo"
 *   title     Tiêu đề
 *   summary   Tóm tắt 1–2 câu (chỉ hiện ở tin lớn)
 *   url       Link bài viết; để "" nếu chưa có (tiêu đề sẽ không bấm được)
 *   mock      true = tin mẫu (chỉ để bạn nhớ, KHÔNG hiện trên trang). Đổi thành false (hoặc xoá) khi là tin thật.
 *
 * Toàn bộ tin dưới đây là MOCK DATA. Trang không còn gắn nhãn "Tin mẫu",
 * nên người xem sẽ tưởng là tin thật: BẮT BUỘC thay bằng tin thật trước khi mở máy chủ.
 */
window.JX_NEWS = [
  {
    date: "",
    category: "Thông báo",
    title: "Lịch mở máy chủ phiên bản lv80",
    summary: "Thời gian mở máy chủ chính thức sẽ được cập nhật tại đây.",
    url: "",
    mock: true
  },
  {
    date: "",
    category: "Hướng dẫn",
    title: "Cài đặt client PC từng bước",
    summary: "",
    url: "",
    mock: true
  },
  {
    date: "",
    category: "Sự kiện",
    title: "Quà tân thủ cho người chơi cũ trở lại",
    summary: "",
    url: "",
    mock: true
  },
  {
    date: "",
    category: "Bảo trì",
    title: "Lịch bảo trì định kỳ hàng tuần",
    summary: "",
    url: "",
    mock: true
  }
];
