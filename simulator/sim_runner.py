"""
Bộ điều phối Mô phỏng Chiến đấu Toàn diện (Full Combat Simulation Runner)
Kết nối:
- Lua Macro Engine (xMacro core v1.5)
- Combat Damage & Attributes System (combat_system.py)
- Thu thập dữ liệu DPS theo thời gian thực (DPS Graph, Breakdown, Logs)
"""

import sys
import os
import math

if __name__ == "__main__" and __package__ is None:
    sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
    from simulator.engine import JX3Simulator
    from simulator.combat_system import CombatConfig, CombatSimulator
else:
    from .engine import JX3Simulator
    from .combat_system import CombatConfig, CombatSimulator


def run_full_simulation(config=None, macro_text=None):
    if config is None:
        config = CombatConfig()

    combat_sim = CombatSimulator(config)
    engine = JX3Simulator()

    # Khởi tạo vũ khí ban đầu
    engine.set_current_weapon(config.weapon_aux) # Bắt đầu với Quỷ Liễu
    engine.add_bag_item(config.weapon_main, bag=1, slot=0) # Main CW trong túi
    engine.lua.execute("_mockTarget.bIsBoss = true")

    total_duration = float(config.duration_sec)
    cur_time = 0.0

    timeline = []
    dps_curve = []
    skill_stats = {}
    total_damage = 0

    # Quản lý DOT ticks (Thương Dương: 666, Lan Thôi: 711, Chung Linh: 714)
    # Lưu thời điểm tick kế tiếp của từng DOT
    dot_next_tick = {666: None, 711: None, 714: None}
    dot_durations = {666: 18.0, 711: 18.0, 714: 18.0}
    if config.bikip.get("tdc_duration1"): dot_durations[666] += 3.0
    if config.bikip.get("tdc_duration2"): dot_durations[666] += 3.0

    current_weapon = engine.get_current_weapon()
    total_swaps = 0
    quy_lieu_stacks = 0

    max_steps = int(total_duration * 10) + 100
    step_count = 0

    # Giả lập lặp qua các nhịp thi triển
    while cur_time < total_duration and step_count < max_steps:
        step_count += 1
        time_sec = round(cur_time, 2)

        # 1. Bỏ qua điều kiện Mana nếu bật tùy chọn vô hạn mana
        if config.infinite_mana:
            engine.lua.execute("_mockPlayer.nCurrentMana = 10000; _mockPlayer.nMaxMana = 10000")

        # 2. Xử lý các nhịp DOT tick sát thương ngầm đã đến giờ
        for dot_id in [666, 711, 714]:
            if dot_next_tick[dot_id] is not None and cur_time >= dot_next_tick[dot_id]:
                # Kiểm tra xem boss còn buff DOT này không
                has_dot = False
                for b in engine.lua.eval("_mockTarget.tBuffs").values():
                    if b.dwID == dot_id: has_dot = True; break
                if has_dot:
                    # Tính sát thương 1 nhịp DOT
                    dot_names = {666: "Thương Dương Chỉ (DOT)", 711: "Lan Thôi Ngọc Chiết (DOT)", 714: "Chung Linh Dục Tú (DOT)"}
                    name = dot_names[dot_id]
                    # Sát thương tick
                    atk = combat_sim.effective_attack
                    base_tick = 850 + (0.42 * atk)
                    if config.tranphai.get("doc_thao"): base_tick *= 1.10
                    is_crit = combat_sim.roll_crit()
                    final_tick = base_tick * (combat_sim.effective_crit_mult if is_crit else 1.0)
                    tick_dmg = int(round(final_tick))

                    total_damage += tick_dmg
                    if name not in skill_stats:
                        skill_stats[name] = {"count": 0, "total_dmg": 0, "crit_count": 0, "max_dmg": 0}
                    skill_stats[name]["count"] += 1
                    skill_stats[name]["total_dmg"] += tick_dmg
                    if is_crit: skill_stats[name]["crit_count"] += 1
                    skill_stats[name]["max_dmg"] = max(skill_stats[name]["max_dmg"], tick_dmg)

                    # Lên lịch tick tiếp theo sau 3 giây
                    dot_next_tick[dot_id] = cur_time + 3.0
                else:
                    dot_next_tick[dot_id] = None

        # 3. Quản lý trạng thái Quỷ Liễu Diệu Mặc
        if engine.get_current_weapon() == "Quỷ Liễu Diệu Mặc":
            quy_lieu_stacks = min(10, quy_lieu_stacks + 1)
            # Nếu đã 10 tầng, giả lập thời gian còn lại dao động để macro xử lý xả buff
            dur = 1.6 if (quy_lieu_stacks >= 10 and int(cur_time) % 6 == 0) else 10.0
            engine.add_player_buff(4761, name="4761", stack=quy_lieu_stacks, duration_sec=dur)

        # 4. Giả lập cơ hội Thần Binh Cam Bích Lạc kích hoạt hiệu ứng Cam
        if engine.get_current_weapon() == "Bích Lạc" and combat_sim.rng.random() < config.cw_proc_chance:
            engine.add_player_buff(2495, name="Bích Lạc", stack=1, duration_sec=6.0)
            timeline.append({
                "time": time_sec,
                "type": "PROC",
                "name": "Bích Lạc (CW Proc)",
                "detail": "Kích hoạt hiệu ứng Thần Binh Cam Bích Lạc (Reset CD Ngọc Thạch trong 6s)"
            })

        # 5. Thực thi 1 nhịp Macro thông qua xMacro Engine
        res = engine.execute_tick(macro_text)

        # Theo dõi đổi vũ khí
        new_wp = res["weapon"]
        if new_wp != current_weapon:
            total_swaps += 1
            timeline.append({
                "time": time_sec,
                "type": "SWAP",
                "name": f"Đổi vũ khí: {new_wp}",
                "detail": f"Chuyển từ {current_weapon} -> {new_wp}"
            })
            current_weapon = new_wp

        # Vật phẩm kích hoạt
        used_pendant = False
        if res["used_items"]:
            for it in res["used_items"]:
                if it.get("pos") == 3:
                    used_pendant = True
                    timeline.append({
                        "time": time_sec,
                        "type": "ITEM",
                        "name": "Bội (Pendant)",
                        "detail": "Kích hoạt hiệu ứng Dây Chuyền Bội khi proc Cam"
                    })

        # Kiểm tra chiêu thức được Macro chọn
        casted_skill = res["casted"][0] if res["casted"] else None

        # Trạng thái Buff của Player hiện tại
        has_tudu = any(b.dwID == 4883 for b in engine.lua.eval("_mockPlayer.tBuffs").values())
        has_thuy_nguyet = any(b.dwID == 645 for b in engine.lua.eval("_mockPlayer.tBuffs").values())
        has_loan_tuu = any(b.dwID == 2719 for b in engine.lua.eval("_mockPlayer.tBuffs").values())
        tinh_minh_stacks = 0
        for b in engine.lua.eval("_mockPlayer.tBuffs").values():
            if b.dwID == 4882: tinh_minh_stacks = b.nStackNum or 1

        # Trạng thái Debuff trên Boss
        phe_cot_stacks = 0
        for b in engine.lua.eval("_mockTarget.tBuffs").values():
            if b.dwID == 1902: phe_cot_stacks = b.nStackNum or 1

        cast_duration = 1.5 # Mặc định 1 GCD

        if casted_skill:
            sk_id = casted_skill["id"]
            sk_name = casted_skill["name"]

            # Tính thời gian vận khí thực tế dựa trên Bí kíp & Trấn phái
            cast_duration = combat_sim.calculate_skill_cast_time(sk_id, has_tudu, has_thuy_nguyet)

            # Đếm số nhịp DOT còn lại nếu là chiêu nổ Ngọc Thạch
            dot_ticks_left = {}
            if sk_id == 182:
                for did in [666, 711, 714]:
                    for b in engine.lua.eval("_mockTarget.tBuffs").values():
                        if b.dwID == did:
                            end_f = b.nEndFrame or 0
                            cur_f = engine.get_frame()
                            sec_left = max(0, (end_f - cur_f) / 16.0)
                            ticks = int(math.ceil(sec_left / 3.0))
                            dot_ticks_left[did] = ticks

            # Tính toán sát thương
            dmg_res = combat_sim.calculate_damage(
                sk_name, sk_id,
                phe_cot_stacks=phe_cot_stacks,
                tinh_minh_stacks=tinh_minh_stacks,
                has_loan_tuu=has_loan_tuu,
                dot_ticks_remaining=dot_ticks_left
            )

            dmg = dmg_res["damage"]
            total_damage += dmg

            if sk_name not in skill_stats:
                skill_stats[sk_name] = {"count": 0, "total_dmg": 0, "crit_count": 0, "max_dmg": 0}
            skill_stats[sk_name]["count"] += 1
            skill_stats[sk_name]["total_dmg"] += dmg
            if dmg_res["is_crit"]: skill_stats[sk_name]["crit_count"] += 1
            skill_stats[sk_name]["max_dmg"] = max(skill_stats[sk_name]["max_dmg"], dmg)

            # Cập nhật trạng thái sau khi xuất chiêu
            if sk_id == 180: # Thương Dương Chỉ
                dur = dot_durations[666]
                engine.add_target_buff(666, name="Thương Dương Chỉ", stack=1, duration_sec=dur)
                dot_next_tick[666] = cur_time + 3.0
                # Tăng stack Phệ Cốt
                cur_pc = min(5, phe_cot_stacks + 1)
                engine.add_target_buff(1902, name="Phệ Cốt", stack=cur_pc, duration_sec=18.0)

            elif sk_id == 189: # Chung Linh Dục Tú
                dur = dot_durations[714]
                engine.add_target_buff(714, name="Chung Linh Dục Tú", stack=1, duration_sec=dur)
                dot_next_tick[714] = cur_time + 3.0

            elif sk_id == 190: # Lan Thôi Ngọc Chiết
                dur = dot_durations[711]
                engine.add_target_buff(711, name="Lan Thôi Ngọc Chiết", stack=1, duration_sec=dur)
                dot_next_tick[711] = cur_time + 3.0
                # CD Lan Thôi (nếu có bí kíp)
                ltnc_cd = 0.0
                if not config.bikip.get("ltnc_cd1"): ltnc_cd = 1.0
                if ltnc_cd > 0: engine.set_skill_cd(190, ltnc_cd)

            elif sk_id == 182: # Ngọc Thạch Câu Phần (Nổ DOTs)
                engine.remove_target_buff(666); dot_next_tick[666] = None
                engine.remove_target_buff(711); dot_next_tick[711] = None
                engine.remove_target_buff(714); dot_next_tick[714] = None
                # Nhận buff Tĩnh Minh & Tứ Du
                new_tm = min(5, tinh_minh_stacks + 1)
                engine.add_player_buff(4882, name="Tĩnh Minh", stack=new_tm, duration_sec=60.0)
                engine.add_player_buff(4883, name="Tứ Du", stack=1, duration_sec=20.0)

                # CD Ngọc Thạch: 17s - Bí kíp
                nt_cd = 17.0
                if config.bikip.get("ntcp_cd1"): nt_cd -= 1.0
                if config.bikip.get("ntcp_cd2"): nt_cd -= 1.0

                has_cw = any(b.dwID == 2495 for b in engine.lua.eval("_mockPlayer.tBuffs").values())
                if not has_cw:
                    engine.set_skill_cd(182, nt_cd)

            elif sk_id == 136: # Thủy Nguyệt Vô Gian
                engine.add_player_buff(645, name="Thủy Nguyệt Vô Gian", stack=1, duration_sec=10.0)
                tn_cd = 60.0
                if config.bikip.get("tnvg_cd1"): tn_cd -= 5.0
                if config.bikip.get("tnvg_cd2"): tn_cd -= 5.0
                engine.set_skill_cd(136, tn_cd)

            elif sk_id == 2645: # Loạn Tửu Thanh Hà
                engine.add_player_buff(2719, name="Loạn Tửu Thanh Hà", stack=1, duration_sec=10.0)
                engine.set_skill_cd(2645, 90.0)

            elif sk_id == 131: # Bích Thủy Thao Thiên
                engine.set_skill_cd(131, 60.0)

            # Tiêu thụ buff Thủy Nguyệt Vô Gian khi đã vận khí tức thời
            if has_thuy_nguyet and sk_id in [179, 189, 190]:
                engine.remove_player_buff(645)

            # Ghi nhận sự kiện xuất chiêu vào timeline
            timeline.append({
                "time": time_sec,
                "type": "SKILL",
                "name": sk_name,
                "damage": dmg,
                "is_crit": dmg_res["is_crit"],
                "cast_time": cast_duration,
                "weapon": current_weapon,
                "detail": f"{'Bạo kích! ' if dmg_res['is_crit'] else ''}Sát thương: {dmg:,} (x{dmg_res['dmg_mult']})"
            })

        # Ghi nhận điểm đồ thị DPS mỗi nhịp
        current_dps = int(round(total_damage / max(1.0, cur_time)))
        dps_curve.append({"time": time_sec, "dps": current_dps, "total_dmg": total_damage})

        # Bước tiếp thời gian theo thời gian thi triển chiêu (GCD), tối thiểu 0.5s để tránh loop vô hạn
        step_duration = max(0.5, cast_duration)
        frames_to_advance = max(8, int(step_duration * 16))
        engine.advance_time(frames_to_advance)
        cur_time += step_duration

    # Tính toán tổng hợp kết quả
    final_dps = int(round(total_damage / max(1.0, total_duration)))

    # Tính tỷ lệ đóng góp của từng chiêu
    breakdown = []
    total_crits = 0
    total_hits = 0
    for name, st in sorted(skill_stats.items(), key=lambda x: -x[1]["total_dmg"]):
        pct = round((st["total_dmg"] / max(1, total_damage)) * 100, 1)
        crit_pct = round((st["crit_count"] / max(1, st["count"])) * 100, 1)
        total_crits += st["crit_count"]
        total_hits += st["count"]
        breakdown.append({
            "name": name,
            "count": st["count"],
            "total_dmg": st["total_dmg"],
            "dps": int(round(st["total_dmg"] / max(1.0, total_duration))),
            "percent": pct,
            "crit_rate": crit_pct,
            "max_dmg": st["max_dmg"]
        })

    overall_crit_pct = round((total_crits / max(1, total_hits)) * 100, 1)

    return {
        "summary": {
            "total_time": total_duration,
            "total_damage": total_damage,
            "dps": final_dps,
            "total_casts": total_hits,
            "total_swaps": total_swaps,
            "crit_rate": overall_crit_pct,
            "infinite_mana": config.infinite_mana
        },
        "breakdown": breakdown,
        "timeline": timeline,
        "dps_curve": dps_curve
    }
