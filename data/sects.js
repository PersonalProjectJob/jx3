/*
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
window.JX_VIDEO_SOURCE = { channel: "VÕ LÂM TRUYỀN KỲ 3", handle: "@VLTKPhienBan3D", url: "https://www.youtube.com/@VLTKPhienBan3D", about: "Kênh video chính thức của Võ Lâm Truyền Kỳ phiên bản 3D" };

window.JX_SECTS = [
  {
    "id": "thien-sach",
    "name": "Thiên Sách",
    "han": "天策",
    "intro": "Kỵ binh Đại Đường dưới trướng Lý thị. Thương dài, xung trận đi đầu.",
    "note": null,
    "story": "Thiên Sách Phủ đặt ở Lạc Dương, khởi từ phủ tướng của Lý Thế Dân thuở còn là Tần Vương và về sau là lực lượng thân cận của hoàng tộc họ Lý. Đệ tử không theo tôn giáo nào, chỉ một lòng trung với nhà Đường, giỏi trường thương và chiến đấu trên lưng ngựa. Khi loạn An Sử nổ ra, phủ bị quân Lang Nha vây hãm, cầm cự để Huyền Tông kịp rời Trường An, rồi cùng quân Thương Vân giành lại phủ. Chính Thiên Sách đứng ra kết nối các phái, mở đường cho Hạo Khí Minh.",
    "xinfa": [
      {
        "id": "ngao-huyet-chien-y",
        "name": "Ngạo Huyết Chiến Ý",
        "tag": "Ngoại công",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 8,
            "khong_che": 7,
            "ho_tro": 4,
            "tri_lieu": 3,
            "phong_thu": 6,
            "co_dong": 7
          },
          "why": {
            "sat_thuong": "Tịch Lịch 200% vũ khí +3050 hai mục tiêu; Long Nha, Long Ngâm bùng nổ",
            "khong_che": "Băng choáng 5s, Đoạn Hồn Thích choáng, Xuyên giảm tốc nhóm, Thương Nguyệt đánh lui",
            "ho_tro": "Hám Như Lôi tăng công/khí huyết đội 30 phút; Tịch Lịch giảm trị thương 50%",
            "tri_lieu": "Chỉ tự hồi: Từ Như Lâm 5%/giây khi chí mạng, có xác suất",
            "phong_thu": "Thủ Như Sơn −80% 8s (hồi 5p30), Ngự chặn đòn, Gầm Như Hổ chống trọng thương",
            "co_dong": "Đột, Đoạn Hồn Thích lao 8–25 thước; Tật xung thích; lên ngựa trong chiến đấu"
          },
          "summary": "DPS ngoại công cận chiến: sát thương đơn mục tiêu lớn qua Trí Tàn, khống chế đa dạng, lao tới nhanh, có chiêu giảm sát thương."
        }
      },
      {
        "id": "thiet-lao-luat",
        "name": "Thiết Lao Luật",
        "tag": "Phòng thủ · Ngoại công",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 6,
            "khong_che": 7,
            "ho_tro": 4,
            "tri_lieu": 3,
            "phong_thu": 9,
            "co_dong": 8
          },
          "why": {
            "sat_thuong": "Dùng chung Long Nha, Long Ngâm, Diệt; thiếu Tịch Lịch, vai trò chính là chịu đòn",
            "khong_che": "Băng choáng 5s, Đoạn Hồn Thích choáng, Xuyên giảm tốc nhóm, Thương Nguyệt đánh lui",
            "ho_tro": "Hám Như Lôi buff đội; Lược Như Hỏa nâng cấp cho đồng đội không uy hiếp",
            "tri_lieu": "Ngang Như Nhạc hồi 30% khí huyết tối đa bản thân, hồi 3 phút",
            "phong_thu": "Ngang Như Nhạc +30% khí huyết, Uyên chịu thay 3 đòn, Thủ Như Sơn −80%",
            "co_dong": "Uyên giải hạn chế di chuyển, lao 6–20 thước tới đồng đội; thêm Đột, Tật"
          },
          "summary": "Tank Thiên Sách: Định Quân, Phá Phong giữ mục tiêu; nhiều chiêu giảm và chịu thay sát thương; giữ khống chế, lao tới của phái."
        }
      }
    ],
    "video": {
      "yt": "T5O_uZ23NNE",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Thiên Sách phái"
    },
    "skillVideo": {
      "yt": "ajDLrbYvFfc",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Học kỹ năng Thiên Sách Phái"
    },
    "keySkills": []
  },
  {
    "id": "thuan-duong",
    "name": "Thuần Dương",
    "han": "纯阳",
    "intro": "Đạo môn trên Hoa Sơn. Kiếm khí và trận pháp, khống chế cả một vùng.",
    "note": null,
    "story": "Thuần Dương Cung là đạo quán trên núi Hoa Sơn, do đạo sĩ Lữ Thuần Dương dựng nên và hưng thịnh dưới triều Đường Huyền Tông. Đệ tử luyện nội công trước rồi mới học kiếm, chia hai nhánh: khí tông theo Tử Hà Công, kiếm tông theo Thái Hư Kiếm Ý, lấy tĩnh chế động, ít màng danh lợi. Sau khi Lữ Thuần Dương quy ẩn, Lý Vong Sinh nối ngôi chưởng môn; đại đệ tử Tạ Vân Lưu vì vướng vào biến cố triều đình mà rời sư môn.",
    "xinfa": [
      {
        "id": "tu-ha-cong",
        "name": "Tử Hà Công",
        "tag": "Nội công · Hỗn nguyên",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 4,
            "khong_che": 3,
            "ho_tro": 9,
            "tri_lieu": 3,
            "phong_thu": 7,
            "co_dong": 3
          },
          "why": {
            "sat_thuong": "Không có đòn sát thương; chỉ Tử Khí Đông Lai +25% công, chí mạng",
            "khong_che": "Sinh Thái Cực giảm tốc 40% trong khí trường; Thổ Cố Nạp Tân 15% trói chân",
            "ho_tro": "Trấn Sơn Hà: đội miễn sát thương 8s; khí trường giảm sát thương, tăng chí mạng",
            "tri_lieu": "Không có chiêu hồi khí huyết nào trong bộ chiêu",
            "phong_thu": "Tọa Vọng hộ thuẫn hồi 30s; Trấn Sơn Hà miễn sát thương 8s",
            "co_dong": "Chỉ Thế Vân Tung nhảy cao; không có lao tới hay dịch chuyển"
          },
          "summary": "Nội công Thuần Dương thiên hỗ trợ đội bằng khí trường, Trấn Sơn Hà; dữ liệu thiếu đòn sát thương nên chấm sát thương thận trọng."
        }
      },
      {
        "id": "thai-hu-kiem-y",
        "name": "Thái Hư Kiếm Ý",
        "tag": "Ngoại công",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 8,
            "khong_che": 9,
            "ho_tro": 7,
            "tri_lieu": 3,
            "phong_thu": 6,
            "co_dong": 3
          },
          "why": {
            "sat_thuong": "Vô Ngã Vô Kiếm 200% vũ khí +3107; Vạn Kiếm Quy Tông 6 mục tiêu",
            "khong_che": "Đại Đạo định thân 6s, Nhân Kiếm định 5 mục tiêu, Kiếm Xung choáng 3s",
            "ho_tro": "Khí trường giảm sát thương ngoại, tăng công, giải bất lợi đội; Vạn Kiếm giảm phòng",
            "tri_lieu": "Chỉ nâng cấp Nhân Kiếm Hợp Nhất hồi 1% khí huyết mỗi khí trường",
            "phong_thu": "Chuyển Càn Khôn −60% 8s (hồi 2 phút), hộ thuẫn Tọa Vọng, Lăng Thái Hư",
            "co_dong": "Chỉ Thế Vân Tung nhảy cao; không có lao tới hay dịch chuyển"
          },
          "summary": "DPS ngoại công cận chiến Thuần Dương: sát thương theo ô khí, định thân/choáng dày, khí trường vừa buff đội vừa chặn khinh công địch; cơ động kém."
        }
      }
    ],
    "video": {
      "yt": "RdpC6lWrqIk",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Thuần Dương phái"
    },
    "skillVideo": {
      "yt": "lz-Ax_Mffhk",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Học kỹ năng Thuần Dương Phái"
    },
    "keySkills": []
  },
  {
    "id": "van-hoa",
    "name": "Vạn Hoa",
    "han": "万花",
    "intro": "Cốc ẩn giữa trăm hoa. Ngòi bút vừa điểm huyệt vừa cứu người.",
    "note": null,
    "story": "Vạn Hoa Cốc ẩn trong một sơn cốc kín, chỉ vào được qua đường hầm bí mật, được ví như cõi Đào Nguyên. Cốc do Đông Phương Vũ Hiên cùng các bậc văn nhân tài tử dựng nên, nơi tụ hội những người tinh thông cầm, kỳ, thư, họa và y thuật. Đệ tử dùng bút để điểm huyệt tiệt mạch và chữa bệnh cứu người, giữ lập trường trung lập, ít can dự vào tranh chấp giang hồ. Cốc còn cất giữ bộ bí kíp Vạn Hoa, trong đó nổi tiếng nhất là võ kinh và y kinh.",
    "xinfa": [
      {
        "id": "hoa-gian-du",
        "name": "Hoa Gian Du",
        "tag": "Nội công · Hỗn nguyên",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 9,
            "khong_che": 7,
            "ho_tro": 6,
            "tri_lieu": 3,
            "phong_thu": 5,
            "co_dong": 3
          },
          "why": {
            "sat_thuong": "Khoái Tuyết Thời Tinh 6 mục tiêu mỗi giây; Loạn Sái +40% công; nhiều DoT",
            "khong_che": "Phù Dung định 4s, Bàng Hoa định 6s, Quyết Âm cấm nội công",
            "ho_tro": "Xuân Nê hộ thuẫn, Bích Thủy hồi nội lực, giải bất lợi; Chung Linh giảm công",
            "tri_lieu": "Hào Châm hồi 867 khi bị đánh ×5; Hoa Ngữ Tố Tâm tự hồi 4%/giây",
            "phong_thu": "Tinh Lâu Nguyệt Ảnh miễn khống chế 4s, Xuân Nê −40%, Hoa Ngữ tự hồi",
            "co_dong": "Thái Âm Chỉ lùi về sau (hồi 25s); Tinh Lâu xóa hạn chế di chuyển"
          },
          "summary": "DPS nội công tầm xa Vạn Hoa: DoT và Khoái Tuyết diện rộng mạnh, nhiều định thân, cấm vận công, kèm hỗ trợ chung của phái."
        }
      },
      {
        "id": "ly-kinh-dich-dao",
        "name": "Ly Kinh Dịch Đạo",
        "tag": "Trị liệu · Hỗn nguyên",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 4,
            "khong_che": 4,
            "ho_tro": 8,
            "tri_lieu": 9,
            "phong_thu": 6,
            "co_dong": 3
          },
          "why": {
            "sat_thuong": "Chỉ chiêu chung: Dương Minh Chỉ, Thương Dương Chỉ, Ngọc Thạch; không đòn riêng",
            "khong_che": "Chỉ chiêu chung: Quyết Âm cấm nội công, Thiếu Dương giảm tốc 60%",
            "ho_tro": "Lợi Châm giải bất lợi 10 đồng đội; Đại Châm cấp 40% nội lực",
            "tri_lieu": "Bỉ Châm hồi nhóm (hồi 8s), Trường Châm 1485+ (+2522), Ác Châm HoT, Tính Phong +20%",
            "phong_thu": "Xuân Nê −40% cho đồng đội, Lợi Châm giải bất lợi diện rộng",
            "co_dong": "Chỉ chiêu chung: Thái Âm Chỉ lùi về sau, Tinh Lâu xóa hạn chế di chuyển"
          },
          "summary": "Healer Vạn Hoa: hồi đơn lớn, hồi nhóm và HoT, giải bất lợi, cấp nội lực, hộ thuẫn đồng đội; sát thương chỉ từ chiêu chung."
        }
      }
    ],
    "video": {
      "yt": "Yhit1xNYKGM",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Vạn Hoa phái"
    },
    "skillVideo": {
      "yt": "X14nSnU9saE",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Học kỹ năng Vạn Hoa Phái"
    },
    "keySkills": []
  },
  {
    "id": "that-tu",
    "name": "Thất Tú",
    "han": "七秀",
    "intro": "Song kiếm hoà cùng vũ điệu, đẹp mà sát.",
    "note": "Chỉ dành cho nhân vật nữ.",
    "story": "Thất Tú Phường nằm ven hồ ở Dương Châu, được xếp vào những nơi phong nhã bậc nhất Đại Đường cùng Vạn Hoa Cốc và Trường Ca Môn. Nơi đây khởi từ Ức Doanh Lâu của Công Tôn Đại Nương, nhận nuôi cô nhi và dạy múa nhạc, về sau mới đổi tên thành Thất Tú Phường. Đệ tử phần lớn là nữ, chia ngoại phường biểu diễn và nội phường là cấm địa luyện võ; sở trường song kiếm hoà cùng vũ điệu, với hai tâm pháp Băng Tâm Quyết và Vân Thường Tâm Kinh.",
    "xinfa": [
      {
        "id": "bang-tam-quyet",
        "name": "Băng Tâm Quyết",
        "tag": "Nội công · Âm tính",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 7,
            "khong_che": 9,
            "ho_tro": 5,
            "tri_lieu": 3,
            "phong_thu": 5,
            "co_dong": 6
          },
          "why": {
            "sat_thuong": "Kiếm Khí Trường Giang 513-533, Kiếm Thần Vô Ngã 10 mục tiêu; hệ số thấp",
            "khong_che": "Lôi Đình khống 10s, Đế Tham định 5 mục tiêu, Kiếm Phá cấm chiêu",
            "ho_tro": "Bà La Môn buff đội, Vũ Lâm Linh +10% trị thương, Nguyệt Hoa chuyển nội lực",
            "tri_lieu": "Không có chiêu hồi máu; chỉ Tâm Cổ Huyền cứu người trọng thương",
            "phong_thu": "Thiên Địa Đê Ngang hóa giải 40% 10s; Thước Đạp Chi né tránh, miễn khống chế",
            "co_dong": "Điệp Lộng Túc +55% tốc độ 15s, giải hạn chế; Lân Lý Khúc đặt lại hồi"
          },
          "summary": "DPS nội công âm tính Thất Tú: sát thương theo Kiếm Vũ, khống chế rất dày (Lôi Đình, định thân diện rộng, cấm chiêu), tự tăng tốc tốt."
        }
      },
      {
        "id": "van-thuong-tam-kinh",
        "name": "Vân Thường Tâm Kinh",
        "tag": "Trị liệu · Âm tính",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 4,
            "khong_che": 6,
            "ho_tro": 6,
            "tri_lieu": 9,
            "phong_thu": 5,
            "co_dong": 6
          },
          "why": {
            "sat_thuong": "Linh Lung Không Hầu chế độ sát thương 693-766 mỗi 0.5s; cùng Đại Huyền, Giang Hải",
            "khong_che": "Chiêu chung: Lôi Đình khống 10s, Đế Tham định 5 mục tiêu",
            "ho_tro": "Bà La Môn, Vũ Lâm Linh, Khiêu Châu giải bất lợi, Tâm Cổ Huyền cứu người",
            "tri_lieu": "Vương Mẫu 1541-1703, Tả Hoàn hồi nhóm 10 thước, nhiều HoT, Phong Tụ hồi tức thì",
            "phong_thu": "Chỉ chiêu chung: Thiên Địa Đê Ngang hóa giải 40%, Thước Đạp Chi miễn khống chế",
            "co_dong": "Điệp Lộng Túc +55% tốc độ, giải hạn chế di chuyển; Lân Lý Khúc đặt lại"
          },
          "summary": "Healer Thất Tú dựa trên Kiếm Vũ: hồi đơn lớn, HoT, hồi nhóm kênh, giải bất lợi, cứu người trong chiến đấu; giữ khống chế chung."
        }
      }
    ],
    "video": {
      "yt": "_bi50yQ9ZNQ",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Thất Tú phái"
    },
    "skillVideo": {
      "yt": "r7HrjT8ig0w",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Học kỹ năng Thất Tú Phái"
    },
    "keySkills": []
  },
  {
    "id": "thieu-lam",
    "name": "Thiếu Lâm",
    "han": "少林",
    "intro": "Thiền trượng và quyền cước. Bất động như núi giữa vòng vây.",
    "note": "Chỉ dành cho nhân vật nam.",
    "story": "Thiếu Lâm Tự dưới chân núi Thiếu Thất, Tung Sơn, là tổ đình Thiền tông từ khi Bồ Đề Đạt Ma đến truyền đạo. Đầu nhà Đường, tăng binh của chùa từng giúp Lý Thế Dân dẹp loạn nên được triều đình trọng vọng. Chùa chỉ nhận đệ tử nam, lấy côn pháp làm gốc, nội công Dịch Cân Kinh và Tẩy Tủy Kinh đi cùng Phật pháp. Trong giang hồ, Thiếu Lâm đứng cùng Thiên Sách trong vụ Đại Quang Minh Tự, và phải đối đầu những thế lực ngoại bang nhòm ngó Dịch Cân Kinh như Nhất Đao Lưu và Bồ Đề Hội.",
    "xinfa": [
      {
        "id": "dich-can-kinh",
        "name": "Dịch Cân Kinh",
        "tag": "Nội công · Dương tính",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 9,
            "khong_che": 8,
            "ho_tro": 5,
            "tri_lieu": 3,
            "phong_thu": 6,
            "co_dong": 3
          },
          "why": {
            "sat_thuong": "Đảo Hư Thức (+6074), Nã Vân Thức kết liễu (+6166), Vi Đà Hiến Chử (+4111)",
            "khong_che": "Thiên Cân Trụy choáng 10 mục tiêu, Ngũ Uẩn choáng 5s, Tróc Ảnh kéo",
            "ho_tro": "Kim Cương Nộ Mục +15% công nội cả đội; Bát Nhã Quyết tăng phòng đồng đội",
            "tri_lieu": "Luân Hồi Quyết tự hồi sinh 30% (hồi 5 phút); không trị liệu đồng đội",
            "phong_thu": "Vô Tướng Quyết −50% 10s, Luân Hồi tự hồi sinh, La Hán phản đòn 40%",
            "co_dong": "Không có lao tới; Kim Cương Quyết miễn giảm tốc, Đoàn Cốt giải khống chế"
          },
          "summary": "DPS nội công Thiếu Lâm: hệ số sát thương rất cao theo điểm thiền định, khống chế cận chiến mạnh, sinh tồn khá, cơ động thấp."
        }
      },
      {
        "id": "tay-tuy-kinh",
        "name": "Tẩy Tủy Kinh",
        "tag": "Phòng thủ · Dương tính",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 6,
            "khong_che": 9,
            "ho_tro": 4,
            "tri_lieu": 3,
            "phong_thu": 9,
            "co_dong": 3
          },
          "why": {
            "sat_thuong": "Chung Vi Đà Hiến Chử, Hoành Tảo Lục Hợp; riêng Tam Thế Chư Phật",
            "khong_che": "Đại Sư Tử Hống choáng 5 mục tiêu 5s; thêm Thiên Cân Trụy",
            "ho_tro": "Bát Nhã Quyết tăng phòng đồng đội; Lập Địa giảm phòng nội 5 địch",
            "tri_lieu": "Linh Sơn Thi Vũ hồi 0.1%/tầng/giây; Luân Hồi Quyết tự hồi sinh 30%",
            "phong_thu": "Tụ Nạp Càn Khôn −25% nội, +24% phòng ngoại (hồi 30s); Vô Tướng −50%; ép đánh",
            "co_dong": "Không có lao tới; chỉ Kim Cương Quyết miễn giảm tốc, Đoàn Cốt giải khống chế"
          },
          "summary": "Tank Thiếu Lâm: giảm sát thương và phản đòn theo điểm thiền định, nhiều chiêu ép đánh, choáng diện rộng mạnh, tự hồi sinh; cơ động thấp."
        }
      }
    ],
    "video": {
      "yt": "5ODx_TwSwUo",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D]  Thiếu Lâm phái"
    },
    "skillVideo": {
      "yt": "ru3u0fb1dmg",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Học kỹ năng Thiếu Lâm Phái"
    },
    "keySkills": []
  },
  {
    "id": "tang-kiem",
    "name": "Tàng Kiếm",
    "han": "藏剑",
    "intro": "Diệp gia bên Tây Hồ. Khinh kiếm, trọng kiếm luân phiên, sát thương dồn dập.",
    "note": null,
    "story": "Tàng Kiếm Sơn Trang nằm bên Tây Hồ, Hàng Châu, vốn là thế gia rèn kiếm Giang Nam của họ Diệp. Diệp Mạnh Thu bỏ con đường khoa cử để theo kiếm đạo và dựng sơn trang; đại trang chủ đời hai là Diệp Anh. Mười năm một lần, sơn trang mở Danh Kiếm Đại Hội, trao thanh kiếm tôi luyện suốt mười năm cho người mạnh nhất. Môn phái dùng cả khinh kiếm lẫn trọng kiếm, theo Nho gia và đề cao hiệp nghĩa; họ Diệp được xếp vào tứ đại thế gia thời Thiên Bảo cùng Đường gia, Liễu gia và Dương gia.",
    "xinfa": [
      {
        "id": "van-thuy-quyet",
        "name": "Vấn Thủy Quyết",
        "tag": "Ngoại công · Khinh kiếm",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 7,
            "khong_che": 6,
            "ho_tro": 3,
            "tri_lieu": 3,
            "phong_thu": 5,
            "co_dong": 9
          },
          "why": {
            "sat_thuong": "Cửu Khê Di Yên 10 mục tiêu, Đạp Tuyết diện rộng; hệ số vừa",
            "khong_che": "Túy Nguyệt choáng 4s, Trích Tinh choáng 3s, Kinh Đào giảm tốc 50%",
            "ho_tro": "Mai Ẩn Hương +20% phá phòng ngoại đồng đội; Thám Mai chuyển uy hiếp",
            "tri_lieu": "Không có chiêu hồi khí huyết nào",
            "phong_thu": "Tuyền Ngưng Nguyệt hộ thuẫn, Vân Tê Tùng né tránh 20s, Mộng Tuyền nâng cấp −66%",
            "co_dong": "Ngọc Tuyền xông 3 lần, Ngọc Hồng lao 24 thước, Bình Hồ xuyên mục tiêu"
          },
          "summary": "DPS ngoại công khinh kiếm Tàng Kiếm: cực cơ động với nhiều chiêu xông, sát thương nhóm và tích kiếm khí, khống chế chung choáng/giảm tốc."
        }
      },
      {
        "id": "son-cu-kiem-y",
        "name": "Sơn Cư Kiếm Ý",
        "tag": "Ngoại công · Trọng kiếm",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 8,
            "khong_che": 7,
            "ho_tro": 3,
            "tri_lieu": 3,
            "phong_thu": 5,
            "co_dong": 5
          },
          "why": {
            "sat_thuong": "Vân Phi Ngọc Hoàng 200%+200% vũ khí, Hà Lưu Bảo Thạch 10 mục tiêu",
            "khong_che": "Hạc Quy Cô Sơn choáng 10 mục tiêu, Phong Tháp đánh lui 15 thước",
            "ho_tro": "Mai Ẩn Hương +20% phá phòng ngoại đồng đội; Hà Lưu giải khí kình địch",
            "tri_lieu": "Không có chiêu hồi khí huyết nào",
            "phong_thu": "Khiếu Nhật miễn khống chế 12s; Tuyền Ngưng Nguyệt hộ thuẫn; Vân Tê Tùng",
            "co_dong": "Hạc Quy Cô Sơn nhảy 15 thước (hồi 20s); Thám Mai lướt tới đồng đội"
          },
          "summary": "DPS ngoại công trọng kiếm Tàng Kiếm: tiêu kiếm khí cho đòn lớn và diện rộng, choáng nhóm bằng Hạc Quy Cô Sơn, cơ động ở mức vừa."
        }
      }
    ],
    "video": {
      "yt": "tmPxK_zi8gs",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Tàng Kiếm phái"
    },
    "skillVideo": {
      "yt": "G8cUO2AQaNk",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Học kỹ năng Tàng Kiếm Phái"
    },
    "keySkills": []
  },
  {
    "id": "ngu-doc",
    "name": "Ngũ Độc",
    "han": "五毒",
    "intro": "Miêu Cương cổ độc. Tiếng sáo gọi trùng, độc ngấm dần không thoát.",
    "note": null,
    "story": "Ngũ Độc Giáo, giáo đồ tự gọi là Ngũ Tiên Giáo và không thích bị gọi là Ngũ Độc, đặt tổng đàn sâu trong làng người Miêu ở Tây Nam, sau Vô Tâm Lĩnh. Giáo có lai lịch cổ xưa mà chính giáo đồ cũng không rõ, thờ Xi Vưu và nhận mình là hậu duệ Cửu Lê. Võ học là cổ thuật và độc thuật, điều khiển bọ cạp, thiềm thừ, rắn, rết, nhện; tiếng sáo gọi trùng là vũ khí đặc trưng. Giáo chủ hiện nay là Khúc Vân; thời Thiên Bảo giáo từng chia rẽ khi tả trưởng lão Ô Mông Quý nổi loạn rồi lập Thiên Nhất Giáo.",
    "xinfa": [
      {
        "id": "doc-kinh",
        "name": "Độc Kinh",
        "tag": "Nội công · Độc tính",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 8,
            "khong_che": 8,
            "ho_tro": 5,
            "tri_lieu": 3,
            "phong_thu": 6,
            "co_dong": 4
          },
          "why": {
            "sat_thuong": "Thiềm Khiếu DoT 9 mục tiêu, Bách Túc diện rộng, Xà Ảnh DoT",
            "khong_che": "Huyễn Cổ định 5s, Miên Cổ ngủ, Mê Tâm Cổ kích hoạt choáng/trói chân/cấm nội công",
            "ho_tro": "Huyền Thủy Cổ tăng căn cốt đội, Phượng Hoàng Cổ hồi sinh trước",
            "tri_lieu": "Khô Tàn Cổ với Thiềm Khiếu hút khí huyết; không trị liệu đồng đội",
            "phong_thu": "Hiến Tế −40% hoặc miễn khống chế (hồi 35s); Cuồng Bạo pet chịu thay 50%",
            "co_dong": "Cổ Trùng Cuồng Bạo +40% tốc độ, giải khống chế; Hóa Điệp khinh công"
          },
          "summary": "DPS nội công độc tính Ngũ Độc: DoT nhiều mục tiêu, ba loại cổ cường hóa chiêu thành khống chế, pet và Hiến Tế giúp sinh tồn."
        }
      },
      {
        "id": "bo-thien-quyet",
        "name": "Bổ Thiên Quyết",
        "tag": "Trị liệu · Độc tính",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 3,
            "khong_che": 4,
            "ho_tro": 7,
            "tri_lieu": 10,
            "phong_thu": 6,
            "co_dong": 3
          },
          "why": {
            "sat_thuong": "Chỉ chiêu chung Thiên Ti, Hạt Tâm, Khô Tàn Cổ; không có đòn riêng",
            "khong_che": "Thiên Ti giảm tốc 50%, Hiến Tế Thiên Thù trói chân 6 kẻ địch, pet trói/kéo",
            "ho_tro": "Đỉnh Cổ hồi 20% nội lực đội, Huyền Thủy Cổ, Phượng Hoàng Cổ hồi sinh 60%",
            "tri_lieu": "Thiên Điệp Thổ Thụy hồi 0.5s/lần suốt 8s, Túy Vũ 6 người, Nữ Oa +50%",
            "phong_thu": "Thánh Thủ −40% cho đồng đội; Nữ Oa nâng cấp −50%; Hiến Tế hồi đầy",
            "co_dong": "Chỉ Hóa Điệp và giải hạn chế bằng Hiến Tế; Nữ Oa giảm tốc bản thân"
          },
          "summary": "Healer Ngũ Độc mạnh nhất về hồi máu: hồi nhóm kênh dày, vùng hồi 6 người, Nữ Oa +50% trị thương, cấp nội lực."
        }
      }
    ],
    "video": {
      "yt": "ATqRAyvsta8",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Ngũ Độc phái"
    },
    "skillVideo": {
      "yt": "D0mQgL4t1BY",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Học kỹ năng Ngũ Độc Phái"
    },
    "keySkills": []
  },
  {
    "id": "duong-mon",
    "name": "Đường Môn",
    "han": "唐门",
    "intro": "Ám khí và cơ quan đất Thục. Ẩn mình, bắn từ xa, không ai thấy người.",
    "note": null,
    "story": "Đường Môn khởi từ những gia tộc sát thủ vùng Ba Thục, sau mở rộng sang buôn bán muối, binh khí, tơ lụa mà trở thành một trong tứ đại thế gia. Đường Gia Bảo tường cao ngói đen, cơ quan dày đặc, là cấm địa; người ngoài chỉ được đến chợ và bến sông Đường Gia Tập. Đệ tử sở trường ám khí, nỏ, cơ quan và độc, dùng Thiên Cơ Hạp, không theo tôn giáo mà chỉ trung thành với gia tộc. Môn chủ hiện nay là Đường Ngạo Thiên, người quyết khôi phục danh tiếng của Đường Môn.",
    "xinfa": [
      {
        "id": "kinh-vu-quyet",
        "name": "Kinh Vũ Quyết",
        "tag": "Ngoại công",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 9,
            "khong_che": 8,
            "ho_tro": 4,
            "tri_lieu": 3,
            "phong_thu": 5,
            "co_dong": 8
          },
          "why": {
            "sat_thuong": "Truy Mệnh Tiễn 300% vũ khí (+8294), Liệt Thạch Nỏ 10 mục tiêu",
            "khong_che": "Lôi Chấn Tử 4s, Mê Thần Đinh 6s, Toàn Tâm trói 3s, đẩy lùi",
            "ho_tro": "Tử Mẫu Phi Trảo cứu đồng đội; Xuyên Tâm Nỏ giảm trị thương 50%",
            "tri_lieu": "Chỉ nâng cấp Kinh Hồng Du Long hồi 6% khi né, tối đa 3 lần",
            "phong_thu": "Kinh Hồng Du Long né +45%, −45% nội 10s; Phù Quang ngụy trang 60s",
            "co_dong": "Phi Tinh Độn Ảnh về cơ quan 35 thước, Tử Mẫu-Mẫu tới đồng đội, nhảy kép"
          },
          "summary": "DPS ngoại công tầm xa Đường Môn: đòn nỏ hệ số cao nhất dữ liệu, khống chế tầm 25 thước, nhiều công cụ thoát thân và ngụy trang."
        }
      },
      {
        "id": "thien-la-nguy-dao",
        "name": "Thiên La Ngụy Đạo",
        "tag": "Nội công · Độc tính",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 7,
            "khong_che": 8,
            "ho_tro": 4,
            "tri_lieu": 3,
            "phong_thu": 5,
            "co_dong": 8
          },
          "why": {
            "sat_thuong": "Bẫy và Thiên Nữ Tản Hoa 10 mục tiêu, Thiên Cơ Nỏ; hệ số cộng thấp",
            "khong_che": "Côn Bằng Thiết Trảo hút 5 mục tiêu; Lôi Chấn, Mê Thần Đinh",
            "ho_tro": "Thiên Cơ Biến nâng cấp +20% tấn công đội; Đoạn Hồn Sa hút nội lực",
            "tri_lieu": "Chỉ nâng cấp Kinh Hồng Du Long hồi 6% khi né",
            "phong_thu": "Kinh Hồng Du Long −45% nội 10s; Quỉ Phủ nâng cấp −30%; Phù Quang ngụy trang",
            "co_dong": "Phi Tinh Độn Ảnh về cơ quan 35 thước, Tử Mẫu-Mẫu tới đồng đội, nhảy kép"
          },
          "summary": "DPS nội công độc Đường Môn: bẫy, nỏ máy, cơ quan diện rộng, khống chế vùng mạnh, cơ động tốt; số liệu sát thương chưa đầy đủ."
        }
      }
    ],
    "video": {
      "yt": "NdUtZB-6Xb0",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Đường Môn phái"
    },
    "skillVideo": {
      "yt": "UZgDHE4V560",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Học kỹ năng Đường Môn Phái"
    },
    "keySkills": []
  },
  {
    "id": "minh-giao",
    "name": "Minh Giáo",
    "han": "明教",
    "intro": "Song loan đao từ Tây Vực. Ẩn thân giữa ánh sáng và bóng tối.",
    "note": null,
    "story": "Minh Giáo do Lục Nguy Lâu lập ra, có gốc từ Hỏa giáo của Ba Tư; ông là người Hán lớn lên nơi đất Ba Tư rồi mang giáo về Trung Nguyên. Giáo thờ Minh Tôn, lấy Thánh Hỏa Điển làm điển tịch, dùng loan đao, nổi tiếng ẩn tung và vũ đạo dị vực. Trong vụ Đại Quang Minh Tự, Thiên Sách phối hợp Thiếu Lâm và các phái đánh vào, phần lớn cao tầng của giáo thiệt mạng; Lục Nguy Lâu thoát được, về sau giáo chia hai nhánh và ông đưa người về Thánh Mộ Sơn nơi sa mạc Tây Vực.",
    "xinfa": [
      {
        "id": "phan-anh-thanh-quyet",
        "name": "Phần Ảnh Thánh Quyết",
        "tag": "Nội công · Âm dương",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 8,
            "khong_che": 8,
            "ho_tro": 3,
            "tri_lieu": 3,
            "phong_thu": 6,
            "co_dong": 9
          },
          "why": {
            "sat_thuong": "Tịnh Thế Phá Ma Kích 8 mục tiêu, Xích Nhật Luân, Sinh Diệt đặt lại",
            "khong_che": "Vô Minh Hồn Tỏa 8s, Sinh Tử Kiếp choáng 4s, Cực Lạc Dẫn kéo 6 địch",
            "ho_tro": "Hầu như không: chỉ Sinh Tử Kiếp-Nguyệt giảm 50% trị thương mục tiêu",
            "tri_lieu": "Thánh Minh Hựu-Nhật tự hồi 10% cộng 1%/giây; không trị liệu đồng đội",
            "phong_thu": "Tham Ma Thể −80% 5s (hồi 57s), Ám Trần miễn khống chế",
            "co_dong": "Ảo Quang Bộ dịch chuyển 20 thước, Lưu Quang Tù Ảnh nhảy sau lưng"
          },
          "summary": "DPS nội công Minh Giáo: sát thương liên đoạn, diện rộng, ngụy trang tập kích, dịch chuyển linh hoạt, khống chế đa dạng, ít hỗ trợ."
        }
      },
      {
        "id": "minh-ton-luu-ly-the",
        "name": "Minh Tôn Lưu Ly Thể",
        "tag": "Phòng thủ · Âm dương",
        "desc": null,
        "ring": {
          "draft": true,
          "scores": {
            "sat_thuong": 6,
            "khong_che": 6,
            "ho_tro": 7,
            "tri_lieu": 4,
            "phong_thu": 9,
            "co_dong": 6
          },
          "why": {
            "sat_thuong": "Dùng chung bộ Nhật/Nguyệt đầy đủ; riêng chỉ Giới Hỏa Trảm 234-258 kèm uy hiếp",
            "khong_che": "Sinh Tử Kiếp choáng 4s, Cực Lạc Dẫn kéo 6; Quy Tịch giảm tốc",
            "ho_tro": "Triều Thánh Ngôn +30% công đội; Lực Độ Ách hộ thuẫn 10 đồng đội",
            "tri_lieu": "Triều Thánh Ngôn hồi 5%/giây cho đồng đội 8s nhưng hồi 5 phút",
            "phong_thu": "Tham Ma Thể −80% (hồi 57s), Triều Thánh −60%, Tính Mệnh Hải +50% khí huyết",
            "co_dong": "Ảo Quang Bộ dịch chuyển 20 thước, Thánh Minh Hựu-Nguyệt +40% tốc độ, Như Ý Pháp"
          },
          "summary": "Tank Minh Giáo: ép đánh diện rộng, nhiều tầng giảm sát thương, tăng khí huyết, hộ thuẫn và buff đội; giữ sát thương, dịch chuyển của phái."
        }
      }
    ],
    "video": {
      "yt": "egcS35t5mP8",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D]  Minh Giáo phái"
    },
    "skillVideo": {
      "yt": "6OqZU3UhEaY",
      "title": "[Võ Lâm Truyền Kỳ phiên bản 3D] Học kỹ năng Minh Giáo Phái"
    },
    "keySkills": []
  }
];
