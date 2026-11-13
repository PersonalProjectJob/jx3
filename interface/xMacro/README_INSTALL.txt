xMacro GENERIC CORE 1.5 NAME TEST — BO THU MUC CAI DAT

CAI DAT
1. Thoat game. Sao luu ca thu muc Interface\xMacro cu ra cho an toan.
2. Giai nen ZIP sao cho duong dan la <Game>\Interface\xMacro\info.ini.
3. Dam bao file lua_0 la Interface\xMacro\Macro.lua; lua_1 la Interface\xMacro\functions.lua.
4. Khoi dong lai game; bat xMacro trong danh sach addon neu can.

KICH HOAT — DOC KY
README goc cua xMacro huong dan tao mot macro game co noi dung:
    /macro
hoac:
    /script macro()
Sau do bam macro game nay de chay macro xMacro da duoc thiet lap.
CHU Y: /skill, /xver, /buffnames la LENH NOI BO xMacro; go truc tiep vao khung chat game co the KHONG hoat dong.
Macro_Examples la cac mau text de nhap vao xMacro, KHONG tu nap khi chi chep .txt vao thu muc.

TEST
1. Xac minh macro khoi dong game '/macro' hay '/script macro()' hoat dong theo client.
2. Thu script xMacro ngan nhat: /xver; neu co phan hoi thi thu /buffnames.
3. Thu /skill TenKyNang (ten dung hien thi trong client, phai biet skill, co target hop le).
4. Neu khong chay, can log loi Lua/client va phuong thuc tao/chay macro, KHONG khang dinh Core da duoc xac nhan.

LOI CHUA XAC DINH
User da bao ca Core 1.1 va 1.5 khong hoat dong. Gói nay chuan hoa cau truc, CHUA the dam bao fix loi runtime.
Ten buff Than Binh, buff stack va target debuff trong mau That Tu VAN CHUA DUOC XAC THUC.
Van Hoa trong gói la reference Core1.1 chua chuyen thanh script Core1.5 hoan chinh.

KHONG CHAY 2 CORE
Khong copy them xMacro.lua cu vao folder nay tru khi can rollback. info.ini chi load Macro.lua.
