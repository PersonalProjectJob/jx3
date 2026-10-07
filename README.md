# jx3
Lưu trữ landingpage của Jx3

## Chạy trên máy

```bash
npm install
npm run dev
```

Mở `http://127.0.0.1:5178/`. Trang tự tải lại khi sửa file. Không mở trực tiếp `index.html` từ ổ đĩa (`file://`): video YouTube báo lỗi 153 và hiệu ứng WebGL bị tắt.

## Sửa nội dung

- Tin tức: `data/news.js` (tin hiện tại là tin mẫu, thay trước khi mở máy chủ)
- Bảng kỷ niệm "Còn nhớ không?": `data/memories.js` (ảnh trong `assets/memories/`)
- Màu, font, khoảng cách: `tokens.css`

## Deploy Vercel

Trang là HTML/CSS/JS tĩnh, không cần build. `vercel.json` đã tắt bước install/build và phục vụ thẳng thư mục gốc.
Import repo này trên Vercel, để mặc định các mục Framework / Build / Output (vercel.json sẽ áp dụng), rồi Deploy.

## Bản quyền

Máy chủ độc lập, không liên kết với VNG, Kingsoft hay Seasun. Hình ảnh nhân vật và ảnh chụp trong game thuộc bản quyền Kingsoft · Seasun.
