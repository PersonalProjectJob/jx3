"""
Trình chạy mô phỏng dòng thời gian chiến đấu (Continuous Combat Timeline Simulation)
Vạn Hoa (Hoa Gian Du) - Đổi vũ khí Quỷ Liễu Diệu Mặc (Buff 4761) & Thần Binh Cam Bích Lạc (CW Proc)

Cách chạy:
    python simulator/run_sim.py
"""

import sys
import os

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

if __name__ == "__main__" and __package__ is None:
    sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
    from simulator.engine import JX3Simulator
else:
    from .engine import JX3Simulator


def run_timeline_simulation(duration_sec=36, macro_text=None):
    print("=" * 85)
    print("       TRÌNH MÔ PHỎNG DÒNG THỜI GIAN CHIẾN ĐẤU VẠN HOA HOA GIAN DU (v80)")
    print("       Đổi vũ khí: Quỷ Liễu Diệu Mặc <-> Bích Lạc (CW) | Giữ buff 4761 | 3-DOT")
    print("=" * 85)

    sim = JX3Simulator()

    # Khởi tạo trang bị & túi đồ
    sim.set_current_weapon("Quỷ Liễu Diệu Mặc")
    sim.add_bag_item("Bích Lạc", bag=1, slot=0)

    # Đặt target là Boss
    sim.lua.execute("_mockTarget.bIsBoss = true")

    gcd_sec = 1.5
    frames_per_gcd = int(gcd_sec * 16)
    total_ticks = int(duration_sec / gcd_sec)

    print(f"{'Thời gian':<10} | {'Vũ khí':<18} | {'Chiêu thi triển':<22} | {'Vật phẩm':<10} | {'Trạng thái DOT & Buff'}")
    print("-" * 85)

    cast_stats = {}
    total_swaps = 0
    current_wp = sim.get_current_weapon()
    quy_lieu_stacks = 0

    for tick in range(total_ticks):
        time_sec = round(tick * gcd_sec, 1)

        # Giả lập sự kiện:
        # 1. Quỷ Liễu Diệu Mặc tích stack 4761 khi thi triển chiêu
        if sim.get_current_weapon() == "Quỷ Liễu Diệu Mặc":
            quy_lieu_stacks = min(10, quy_lieu_stacks + 1)
            # Giả lập thời gian buff sắp hết nếu đã đạt 10 stack
            dur = 1.5 if (quy_lieu_stacks >= 10 and tick % 4 == 0) else 10.0
            sim.add_player_buff(4761, name="4761", stack=quy_lieu_stacks, duration_sec=dur)

        # 2. Giả lập CW Bích Lạc kích hoạt proc hiệu ứng cam tại giây thứ 18.0
        if 18.0 <= time_sec < 18.0 + gcd_sec:
            print(f">>> [EVENT] THẦN BINH CAM BÍCH LẠC PROC HIỆU ỨNG ĐẶC BIỆT (BUFF 2495) <<<")
            sim.add_player_buff(2495, name="Bích Lạc", stack=1, duration_sec=6.0)

        # Thực hiện 1 nhịp Macro
        res = sim.execute_tick(macro_text)

        # Theo dõi đổi vũ khí
        new_wp = res["weapon"]
        if new_wp != current_wp:
            total_swaps += 1
            current_wp = new_wp

        # Chiêu thức xuất ra
        cast_name = "Chờ nhịp (None)"
        sk_id = None
        if res["casted"]:
            sk = res["casted"][0]
            cast_name = sk["name"]
            sk_id = sk["id"]
            cast_stats[cast_name] = cast_stats.get(cast_name, 0) + 1

        # Vật phẩm kích hoạt
        used_pendant_str = ""
        if res["used_items"]:
            for item in res["used_items"]:
                if item.get("pos") == 3:
                    used_pendant_str = "Bội (Pendant)"

        # Cập nhật trạng thái chiến đấu của Engine tương ứng với chiêu thức
        if sk_id == 180: # Thương Dương Chỉ
            sim.add_target_buff(666, name="Thương Dương Chỉ", stack=1, duration_sec=18.0)
            # Tăng Phệ Cốt trên quái
            cur_pc = 0
            for b in sim.lua.eval("_mockTarget.tBuffs").values():
                if b.dwID == 1902: cur_pc = b.nStackNum or 1
            sim.add_target_buff(1902, name="Phệ Cốt", stack=min(5, cur_pc + 1), duration_sec=18.0)

        elif sk_id == 189: # Chung Linh Dục Tú
            sim.add_target_buff(714, name="Chung Linh Dục Tú", stack=1, duration_sec=18.0)

        elif sk_id == 190: # Lan Thôi Ngọc Chiết
            sim.add_target_buff(711, name="Lan Thôi Ngọc Chiết", stack=1, duration_sec=18.0)

        elif sk_id == 182: # Ngọc Thạch Câu Phần
            # Nổ DOT: xóa DOT trên quái
            sim.remove_target_buff(666)
            sim.remove_target_buff(711)
            sim.remove_target_buff(714)
            # Nhận buff Tĩnh Minh
            cur_tm = 0
            for b in sim.lua.eval("_mockPlayer.tBuffs").values():
                if b.dwID == 4882: cur_tm = b.nStackNum or 1
            sim.add_player_buff(4882, name="Tĩnh Minh", stack=min(5, cur_tm + 1), duration_sec=60.0)
            sim.add_player_buff(4883, name="Tứ Du", stack=1, duration_sec=20.0)
            # Đặt CD Ngọc Thạch 15s (trừ khi proc CW Bích Lạc)
            has_cw = any(b.dwID == 2495 for b in sim.lua.eval("_mockPlayer.tBuffs").values())
            if not has_cw:
                sim.set_skill_cd(182, 15.0)

        elif sk_id == 136: # Thủy Nguyệt Vô Gian
            sim.add_player_buff(645, name="Thủy Nguyệt Vô Gian", stack=1, duration_sec=10.0)
            sim.set_skill_cd(136, 60.0)

        elif sk_id == 2645: # Loạn Tửu Thanh Hà
            sim.set_skill_cd(2645, 90.0)

        elif sk_id == 131: # Bích Thủy Thao Thiên
            sim.lua.execute("_mockPlayer.nCurrentMana = 10000")
            sim.set_skill_cd(131, 60.0)

        # Lấy tóm tắt Buff/Debuff hiển thị
        tar_dots = []
        for b in sim.lua.eval("_mockTarget.tBuffs").values():
            if b.dwID == 1902: tar_dots.append(f"PhệCốt({b.nStackNum})")
            elif b.dwID == 666: tar_dots.append("ThươngDương")
            elif b.dwID == 711: tar_dots.append("LanThôi")
            elif b.dwID == 714: tar_dots.append("ChungLinh")

        pl_buffs = []
        for b in sim.lua.eval("_mockPlayer.tBuffs").values():
            if b.dwID == 4761: pl_buffs.append(f"QL({b.nStackNum})")
            elif b.dwID == 4882: pl_buffs.append(f"TĩnhMinh({b.nStackNum})")
            elif b.dwID == 2495: pl_buffs.append("CW-BíchLạc")

        dots_str = ", ".join(tar_dots) if tar_dots else "Trống"
        buffs_str = ", ".join(pl_buffs) if pl_buffs else "Trống"
        status_str = f"Quái: [{dots_str}] | Bản thân: [{buffs_str}]"

        time_str = f"{time_sec:>4.1f}s"
        print(f"{time_str:<10} | {new_wp:<18} | {cast_name:<22} | {used_pendant_str:<10} | {status_str}")

        # Bước tiếp thời gian 1 GCD
        sim.advance_time(frames_per_gcd)

    print("-" * 85)
    print("                     TỔNG KẾT KẾT QUẢ MÔ PHỎNG")
    print("-" * 85)
    print(f"  * Tổng thời gian mô phỏng: {duration_sec} giây ({total_ticks} GCD)")
    print(f"  * Số lần đổi vũ khí tự động: {total_swaps}")
    print("  * Thống kê số lần xuất chiêu:")
    for name, cnt in sorted(cast_stats.items(), key=lambda x: -x[1]):
        bar = "■" * cnt
        print(f"     - {name:<22}: {cnt:>2} lần  {bar}")
    print("=" * 85 + "\n")


if __name__ == "__main__":
    run_timeline_simulation(duration_sec=36)
