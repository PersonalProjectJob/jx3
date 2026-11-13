"""
Hệ thống tính toán Sát thương & Chỉ số Chiến đấu JX3 Patch 80 (Vạn Hoa Hoa Gian Du)
Bao gồm:
- Toàn bộ Kỹ năng Võ học & Bí kíp (Bí tịch)
- Hệ thống Trấn Phái (Talent Tree Hoa Gian 33/8)
- Hệ thống Kinh Mạch (Nhâm, Đốc, Xung, Đới)
- Tính toán Sát thương, Hội Kích (Crit), Hội Hiệu (Crit Multiplier), Phá Phòng
- Quản lý sát thương nổ DOT (Ngọc Thạch Câu Phần) và sát thương duy trì từng nhịp
- Tùy chọn 5 phút Vô hạn Mana (Bỏ qua điều kiện Mana)
"""

import math
import random

class CombatConfig:
    def __init__(self):
        # 1. Chỉ số cơ bản nhân vật (Vạn Hoa Hoa Gian v80 gear chuẩn)
        self.base_attack = 18500        # Nội công công kích Hỗn Nguyên
        self.base_crit_rate = 0.42      # Tỷ lệ hội kích (42%)
        self.base_crit_mult = 2.15      # Hội hiệu (215% sát thương crit)
        self.defense_break = 950        # Phá phòng
        self.boss_resistance = 0.20     # Giảm thương của Boss

        # 2. Hệ thống Bí Kíp (Secret Books)
        self.bikip = {
            # Dương Minh Chỉ (179)
            "dmc_cast_time1": True,     # Giảm 0.25s vận khí
            "dmc_cast_time2": True,     # Giảm 0.25s vận khí
            "dmc_damage1": True,        # Tăng 3% sát thương
            "dmc_damage2": True,        # Tăng 4% sát thương
            # Thương Dương Chỉ (180)
            "tdc_duration1": True,      # Tăng 3s duy trì (thêm 1 tick)
            "tdc_duration2": True,      # Tăng 3s duy trì (thêm 1 tick)
            "tdc_damage1": True,        # Tăng 3% sát thương
            "tdc_damage2": True,        # Tăng 4% sát thương
            # Chung Linh Dục Tú (189)
            "cldt_cast_time1": True,    # Giảm 0.25s vận khí
            "cldt_cast_time2": True,    # Giảm 0.25s vận khí
            "cldt_cast_time3": True,    # Giảm 0.25s vận khí
            "cldt_damage1": True,       # Tăng 4% sát thương
            # Lan Thôi Ngọc Chiết (190)
            "ltnc_cast_time1": True,    # Giảm 0.25s vận khí
            "ltnc_cast_time2": True,    # Giảm 0.25s vận khí
            "ltnc_damage1": True,       # Tăng 4% sát thương
            "ltnc_cd1": True,           # Giảm 1s CD
            # Ngọc Thạch Câu Phần (182)
            "ntcp_cd1": True,           # Giảm 1s CD (17s -> 16s)
            "ntcp_cd2": True,           # Giảm 1s CD (16s -> 15s)
            "ntcp_damage1": True,       # Tăng 4% sát thương nổ
            "ntcp_damage2": True,       # Tăng 5% sát thương nổ
            # Thủy Nguyệt Vô Gian (136)
            "tnvg_cd1": True,           # Giảm 5s hồi chiêu
            "tnvg_cd2": True,           # Giảm 5s hồi chiêu
        }

        # 3. Hệ thống Trấn Phái (Talent Tree Hoa Gian Du 33/8)
        self.tranphai = {
            "thanh_ca": True,           # Thanh Ca: +10% Hội kích Dương Minh Chỉ
            "doc_thao": True,           # Độc Thảo: +10% Sát thương các loại DOT
            "han_lang": True,           # Hàn Lăng: +10% Sát thương cơ bản Hỗn Nguyên
            "tinh_minh": True,          # Tĩnh Minh: Nổ Ngọc Thạch nhận buff Tĩnh Minh (+5% sát thương/tầng)
            "tu_du": True,              # Tứ Du: Sau nổ Ngọc Thạch giảm 20% thời gian vận khí
            "phe_cot": True,            # Phệ Cốt: Tích stack Phệ Cốt trên boss (+2% sát thương nhận/tầng, tối đa 5 tầng = +10%)
            "loan_tuu": True,           # Loạn Tửu Thanh Hà: Kỹ năng bạo phát (+100% nội công trong 10s)
        }

        # 4. Hệ thống Kinh Mạch (Meridians)
        self.kinhmach = {
            "nham_mach": True,          # Nhâm Mạch: +1,500 Nội Công, +150 Phá Phòng
            "doc_mach": True,           # Đốc Mạch: +8% Hội Kích, +15% Hội Hiệu
            "xung_mach": True,          # Xung Mạch: +120 Căn Cốt (+1,000 Nội Công, +3% Hội Kích)
            "doi_mach": True,           # Đới Mạch: Tăng hồi khí huyết & thần cơ
        }

        # 5. Cài đặt mô phỏng
        self.duration_sec = 300.0       # Mặc định 5 phút (300s)
        self.infinite_mana = True       # 5 phút vô hạn mana (bỏ qua điều kiện mana)
        self.weapon_main = "Bích Lạc"
        self.weapon_aux = "Quỷ Liễu Diệu Mặc"
        self.cw_proc_chance = 0.08      # 8% cơ hội kích hoạt CW Bích Lạc mỗi cast


class CombatSimulator:
    def __init__(self, config=None):
        self.cfg = config or CombatConfig()
        self.rng = random.Random(42)    # Cố định seed cho kết quả so sánh khách quan

        # Tính toán chỉ số sau buff Nội Tại từ Kinh Mạch & Trấn Phái
        self.effective_attack = self.cfg.base_attack
        self.effective_crit = self.cfg.base_crit_rate
        self.effective_crit_mult = self.cfg.base_crit_mult
        self.effective_armor_pen = self.cfg.defense_break

        if self.cfg.kinhmach.get("nham_mach"):
            self.effective_attack += 1500
            self.effective_armor_pen += 150
        if self.cfg.kinhmach.get("doc_mach"):
            self.effective_crit += 0.08
            self.effective_crit_mult += 0.15
        if self.cfg.kinhmach.get("xung_mach"):
            self.effective_attack += 1000
            self.effective_crit += 0.03
        if self.cfg.tranphai.get("han_lang"):
            self.effective_attack *= 1.10

    def calculate_skill_cast_time(self, skill_id, has_tudu=False, has_thuy_nguyet=False):
        """Tính toán thời gian vận khí (giây) của kỹ năng sau khi áp dụng Bí kíp & Trấn phái"""
        if skill_id == 136:
            return 0.25  # Thủy Nguyệt Vô Gian: Off-GCD animation delay

        if has_thuy_nguyet and skill_id in [179, 189, 190]:
            return 1.5  # Thủy Nguyệt làm chiêu thành tức thời, tốn 1 GCD

        base_time = 0.0
        if skill_id == 179: # Dương Minh Chỉ
            base_time = 1.75
            if self.cfg.bikip.get("dmc_cast_time1"): base_time -= 0.25
            if self.cfg.bikip.get("dmc_cast_time2"): base_time -= 0.25
        elif skill_id == 189: # Chung Linh Dục Tú
            base_time = 1.75
            if self.cfg.bikip.get("cldt_cast_time1"): base_time -= 0.25
            if self.cfg.bikip.get("cldt_cast_time2"): base_time -= 0.25
            if self.cfg.bikip.get("cldt_cast_time3"): base_time -= 0.25
        elif skill_id == 190: # Lan Thôi Ngọc Chiết
            base_time = 1.75
            if self.cfg.bikip.get("ltnc_cast_time1"): base_time -= 0.25
            if self.cfg.bikip.get("ltnc_cast_time2"): base_time -= 0.25
        else:
            base_time = 1.5 # Thương Dương Chỉ, Ngọc Thạch Câu Phần: Instant nhưng chiếm 1 GCD

        if has_tudu and base_time > 0:
            base_time = max(1.0, base_time * 0.8) # Tứ Du giảm 20% vận khí

        # GCD tối thiểu theo engine game là 1.0s
        return max(1.0, round(base_time, 2))

    def roll_crit(self, bonus_crit=0.0):
        rate = min(1.0, self.effective_crit + bonus_crit)
        return self.rng.random() < rate

    def calculate_damage(self, skill_name, skill_id, phe_cot_stacks=0, tinh_minh_stacks=0, has_loan_tuu=False, dot_ticks_remaining=None):
        """
        Tính toán sát thương chính xác cho từng chiêu thức
        """
        atk = self.effective_attack
        if has_loan_tuu:
            atk *= 2.0 # Loạn Tửu Thanh Hà +100% nội công

        # Multiplier tăng sát thương chung
        dmg_mult = 1.0

        # Phệ Cốt: +2% mỗi tầng (tối đa 5 tầng = +10%)
        if self.cfg.tranphai.get("phe_cot"):
            dmg_mult *= (1.0 + min(5, phe_cot_stacks) * 0.02)

        # Tĩnh Minh: +5% mỗi tầng (tối đa 5 tầng = +25%)
        if self.cfg.tranphai.get("tinh_minh"):
            dmg_mult *= (1.0 + min(5, tinh_minh_stacks) * 0.05)

        # Phá phòng & Giáp boss
        armor_factor = max(0.65, 1.0 - self.cfg.boss_resistance + (self.effective_armor_pen / 5000.0))

        bonus_crit = 0.0
        base_dmg = 0
        is_crit = False

        if skill_id == 179: # Dương Minh Chỉ
            base_dmg = self.rng.randint(1450, 1620) + (1.25 * atk)
            # Bí kíp DMC
            bk_mult = 1.0
            if self.cfg.bikip.get("dmc_damage1"): bk_mult += 0.03
            if self.cfg.bikip.get("dmc_damage2"): bk_mult += 0.04
            base_dmg *= bk_mult
            # Trấn phái Thanh Ca
            if self.cfg.tranphai.get("thanh_ca"): bonus_crit += 0.10

        elif skill_id == 180: # Thương Dương Chỉ (Direct cast hit)
            base_dmg = self.rng.randint(600, 750) + (0.35 * atk)
            bk_mult = 1.0
            if self.cfg.bikip.get("tdc_damage1"): bk_mult += 0.03
            if self.cfg.bikip.get("tdc_damage2"): bk_mult += 0.04
            base_dmg *= bk_mult

        elif skill_id == 189: # Chung Linh Dục Tú
            base_dmg = self.rng.randint(650, 800) + (0.40 * atk)
            if self.cfg.bikip.get("cldt_damage1"): base_dmg *= 1.04

        elif skill_id == 190: # Lan Thôi Ngọc Chiết
            base_dmg = self.rng.randint(750, 920) + (0.45 * atk)
            if self.cfg.bikip.get("ltnc_damage1"): base_dmg *= 1.04

        elif skill_id == 182: # Ngọc Thạch Câu Phần (Nổ sát thương gốc + toan bo DOTs con lai)
            raw_explosion = self.rng.randint(1800, 2200) + (0.85 * atk)
            bk_mult = 1.0
            if self.cfg.bikip.get("ntcp_damage1"): bk_mult += 0.04
            if self.cfg.bikip.get("ntcp_damage2"): bk_mult += 0.05
            raw_explosion *= bk_mult

            # Sát thương từ các nhịp DOT còn lại được kích nổ
            dot_bonus = 0
            if dot_ticks_remaining:
                for dot_id, ticks in dot_ticks_remaining.items():
                    tick_dmg = 0
                    if dot_id == 666: # Thương Dương
                        tick_dmg = (self.rng.randint(700, 850) + 0.38 * atk)
                    elif dot_id == 714: # Chung Linh
                        tick_dmg = (self.rng.randint(800, 950) + 0.42 * atk)
                    elif dot_id == 711: # Lan Thôi
                        tick_dmg = (self.rng.randint(900, 1100) + 0.48 * atk)
                    if self.cfg.tranphai.get("doc_thao"):
                        tick_dmg *= 1.10
                    dot_bonus += tick_dmg * ticks

            base_dmg = raw_explosion + dot_bonus

        elif skill_id in [131, 132, 136, 2645]:
            base_dmg = 0 # Buff / Utility chiêu không gây trực tiếp dame

        # Tính toán Hội kích
        is_crit = self.roll_crit(bonus_crit)
        final_dmg = base_dmg * dmg_mult * armor_factor
        if is_crit:
            final_dmg *= self.effective_crit_mult

        return {
            "skill_name": skill_name,
            "skill_id": skill_id,
            "damage": int(round(final_dmg)),
            "is_crit": is_crit,
            "base_dmg": int(round(base_dmg)),
            "dmg_mult": round(dmg_mult, 3)
        }
