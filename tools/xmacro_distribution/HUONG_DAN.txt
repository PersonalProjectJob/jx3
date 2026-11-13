XMACRO 0.9.7 - HUONG DAN CAI DAT / CHIA SE

1. Giai nen TOAN BO ZIP vao mot thu muc, roi chay CAI_DAT.bat.
   Chon thu muc co jx3client.exe hoac game.exe. Khong can Python.
   Nen thoat game va dong cua so KeySpam truoc khi cai/cap nhat.
   Installer sao luu addon cu vao xMacro-backups trong thu muc game,
   chep de cac file phat hanh va giu nguyen du lieu *.jx3dat cua ban.
   Neu can phuc hoi: dong game/tool, lay thu muc xMacro trong ban sao luu
   chep lai vao Interface. Installer khong tu dung game/tool.

2. Cach cai thu cong: chep thu muc Interface vao thu muc game.
   Neu da co xMacro, tu sao luu Interface/xMacro truoc khi chep de.
   Chay Interface/xMacro/start_xmacro.bat mot lan de mo helper Windows.
   Giu cua so helper mo; Ctrl+C hoac dong cua so de thoat.
   Sau do vao lai game/tai lai addon. Helper phai hien ONLINE.

3. Chon 1-4 phim khac nhau trong bang Key Spam, bam BAT DAU / DUNG.
   Moi chu ky 50 ms nhan tat ca phim da chon. O trong duoc bo qua.
   ESC -> Thiet lap phim tat -> xMacro - Key Spam BAT/TAT:
   gan MOT phim de bat/dung. Khong gan trung voi phim dang spam.
   Nut -/+ thu nho/mo bang; keo thanh tieu de de doi vi tri.

4. De chay Van Hoa: tao vi-lenh co noi dung /script macro("VH")
   neu client cho phep tao vi-lenh Lua. Gan phim cho vi-lenh do, roi nhap
   phim ay vao Key Spam. Toggle chi bat/dung spam phim; no khong tu tao
   vi-lenh hay tu gan phim. Khong can dung lenh slash /macro.
   Client hien bo qua posted keys khi Alt+Tab. Ve game de tiep tuc;
   chua xac nhan spam chay khi game khong duoc focus.

LENH GOI THEO PHAI / NHANH
/script macro("VH")   : Van Hoa - Hoa Gian (da co combo)
/script macro("7T")   : That Tu (cho bo sung combo)
/script macro("TS")   : Thien Sach (cho bo sung combo)
/script macro("TK")   : Tang Kiem (cho bo sung combo)
/script macro("DMKV") : Duong Mon - Kinh Vu (cho bo sung combo)
/script macro("DMTL") : Duong Mon - Thien La (cho bo sung combo)
Ma phai can dat trong dau nhay; chap nhan chu thuong va khoang trang hai dau.
Khong dung macro(TS): TS chua duoc dinh nghia la bien Lua.
Ma chua co combo/ma sai se dung, khong chay nham combo Van Hoa.
macro() va macro("auto") van chay cau hinh mac dinh trong Config.lua.
Goi ma rieng khong doi cau hinh mac dinh hay phim Key Spam da luu.

HIEN HO TRO
Chi profile VanHoa / HoaGian da duoc kiem tra bang bo test.
Chua thay the cho kiem thu rotation thuc te trong game.
ThatTu la tai lieu tham khao chua xac minh, khong tu dong ho tro.
Mac dinh Config.lua: xMacro.Config = {school='VanHoa', profile='HoaGian'}.
Muon them school/profile can module da xac minh va dang ky vao
Schools/Registry.lua qua xMacro.Schools.Register, them vao danh sach build
Runtime va build lai truoc khi reload. Game nap cac file Native/XM00..XM07 theo thu tu lua_n;
cac thu muc Core/Schools/Features van la ma nguon de bao tri theo phai.
Xem docs/EXTENDING.txt trong ma nguon. Ban ZIP da build san cac file Native va Runtime.lua.

CHIA SE
Gui goi ZIP do tools/build_xmacro_package.py tao. Khong zip nguyen
thu muc xMacro dang dung: co the lo du lieu/trang thai ca nhan.
SHA256.json ghi ma bam tung file phat hanh. KeySpam.exe Windows x64
la ban standalone tu Tools/KeySpam/engine.py, khong can cai Python.
Nguoi dung ma nguon co the chay Python 3 qua start_xmacro.bat neu thieu exe.
Khong copy venv, scratch, log, *.jx3dat hay file backup cho nguoi khac.

CHAN DOAN
start_xmacro.bat --check chi liet ke game hop le va doc cau hinh;
khong gui phim, khong tao file trang thai. OFFLINE: mo helper va xem loi.
CHO GAME: dua dung cua so game len truoc mot lan. LOI: DUNG, kiem tra
quyen game/tool, roi BAT DAU lai. DANG SPAM chi bao da post message,
khong chung minh client da xu ly phim. Tool chi gui vao client trong
thu muc game nay; khong lay focus va khong gui SendInput.

BAO TRI MA NGUON TRONG GOI ZIP 0.9.7
Sau khi sua nguon, mo terminal tai thu muc da giai nen goi va chay:
python BUILD_NATIVE.py --addon Interface/xMacro
Chi sau khi build thanh cong moi reload addon/vao lai game.
Lenh nay danh cho nguoi bao tri co Python 3; nguoi cai ZIP khong can chay.
Neu dung repository: python tools/build_xmacro_native.py --addon interface/xMacro

CHAN DOAN KHOI DONG 0.9.7
Sau khi cai, thoat han game roi mo lai de nap info.ini va cac file Native moi.
Khi chat san sang, thong bao khoi dong la [xMacro 0.9.7] Loading native modules va MODULES_READY.
LOAD_ERROR <module>: <loi> chi ro module khong khoi tao duoc.
Mot module loi khong chan nap cac module tiep theo, gom bang Key Spam.
NOT_READY: combo bi khoa de tranh dung Core cu hoac khoi tao do dang.
UI_ERROR chi ro loi tao bang Key Spam. Macro runtime error la loi khi goi combo.
Neu khong co dong Loading native modules: kiem tra dung thu muc client dang chay,
addon dang bat va da thoat han/mo lai game. Gui lai nguyen dong loi de chan doan.
Ban0.9.7 bo sung chong dung nap im lang; chua xac nhan nguyen nhan tren may khac.

LUU Y VE VERSION TRONG INFO.INI
version=0.8 duoc giu theo khai bao native cua ban addon da hoat dong.
Khong doi truong nay theo so phat hanh goi ZIP. Ban phat hanh hien tai
nam o release=0.9.7, ten xMacro 0.9.7 va xMacro.Runtime.version.
Builder se tu choi goi neu version native khac0.8.

MA HOA LUA 0.9.7
Cac file sinh Native va Runtime dung UTF-8 BOM. Khong bo BOM khi luu lai.
BOM giup native loader bo qua chuyen ANSI he thong sang UTF-8.
