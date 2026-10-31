"""Test the panel: the REAL PANEL section of fast_farm.lua built in luau.exe
with stand-in Roblox objects (panel_stubs.lua) and the REAL config table,
then pressed (panel_cases.lua):

- it builds; 30 pages; Home fits its body without a scroll bar;
- one mode at a time and the panel says which: the Modes list shows exactly
  one On; PvP and the Leviathan sit on top (off = the mode underneath
  again); the circuit has no off; a mode's switch says what On turns off;
  the Mirage's job picked on its page, kept while off; Start names the mode;
  with PvP on, Home's button is PvP's Stop;
- Back walks the pages you came through (a shared page reached by a link);
- every mode page: its own switch is its first, How it works / Details last;
- CENSUS: every control fired once. Every CFG key the OLD panel (build
  2026-10-11.2, before the reorganization) could change is still changed
  (OLD_KEYS below, frozen with --census), each from ONE page (the mode keys
  excepted - one at a time is that rule), and nothing new but MirageJob
  and the per-attacker dodge sliders (2026-10-12);
- every page within 3 taps of Home.

usage: python tools/panel_test.py [path-to-luau.exe]
       python tools/panel_test.py --census path/to/fast_farm.lua   (print the keys a panel changes)
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"
args = sys.argv[1:]
census = None
src_override = None
if args and args[0] == "--census":
    census = args[1]
    args = args[2:]
if args and args[0] == "--src":         # a mutated copy (mutation checks)
    src_override = args[1]
    args = args[2:]
if args:
    LUAU = args[0]

# The keys the panel before the reorganization (975a637) could change.
OLD_KEYS = [k for k in """
AimHidden
AimSkills
AutoAttack
AutoBuso
AutoKen
AutoKeys.C
AutoKeys.V
AutoKeys.X
AutoKeys.Z
AutoTeam
BeastHeight
BerryWant.Blue Icicle Berry
BerryWant.Green Toad Berry
BerryWant.Orange Berry
BerryWant.Pink Pig Berry
BerryWant.Purple Jelly Berry
BerryWant.Red Cherry Berry
BerryWant.White Cloud Berry
BerryWant.Yellow Star Berry
BoatLift
BoneMax
BoneMin
BossFirst
CastWait
Debug
DodgeRadius
DodgeSpeed
DodgeTime
DodgeUp
EggStay
EliteLook
EliteQuest
EmberStopAt
EmberTreeMax
EquipWait
EscapeBelow
FishHeight
FleeTo
FlowerGiveUp
FruitMinPrice
FruitPlayerDrops
GolemCage
GolemLift
GolemWeapon
GrabMax
GrabRadius
GunFast
GunFastEvery
GunHold
HeightFixed
HeightMelee
HeightMode
HeightSafe
HitRange
HopOrder
HopRevisit
Hunt
HuntHop
HuntKind
InstantHop
InvSwap
KenEvery
LearnLeash
LeviFight
LeviHeight
LeviShare
LootStay
M1Between
M1Every
M1Method
M1Weapon
Magnet
MasteryStop
MasteryWeapon
MaxPull
MeleeDistance
MirageNeed
OthersRadius
PileSpread
PressureMax
PullAll
PullOthers
PutBackAfter
Pvp
PvpAim
PvpClean
PvpDash
PvpDashX
PvpFace
PvpFaceRange
PvpKenBack
PvpLead
PvpNoShake
PvpRange
PvpSpeed
PvpSpeedTo
PvpVision
RaidChip
RaidFruitMax
RaidLoop
RaidMode
RaidRadius
RaidReach
RaidStuckSecs
RandomMode
RandomRadius
RecipeWant.Bright Yellow
RecipeWant.Pure Red
RecipeWant.Snow White
RecipeWant.Winter Sky
RelicMin
RespawnHome
RespawnMax
ReturnAt
SeaDodge
SeaEvFight.Piranha
SeaEvFight.Rumbling Waters
SeaEvFight.Sea Beast
SeaEvFight.Shark
SeaEvFight.Terrorshark
SeaEvForm
SeaEvGoal
SeaEvKeys.C
SeaEvKeys.F
SeaEvKeys.V
SeaEvKeys.X
SeaEvKeys.Z
SeaEvStopAtGoal
SeaEvTrial
SeaEvWeapons.Blox Fruit
SeaEvWeapons.Gun
SeaEvWeapons.Melee
SeaEvWeapons.Sword
SeaLeg2
SeaMagnet
SeaSearchMinutes
SeaSearchTo
SeaSpeed
SeaSteer
SeaStudsPerM
SeaTurnBack
SeaTurnEvery
SeaTurnMax
SeaTurnRate
SideFixed
SilentAim
StartWith
StayHigh
SwordWant.Oroshi
SwordWant.Saishi
SwordWant.Shizu
Team
TravelSpeed
VentDistance
VentGuitar
VentKeys.C
VentKeys.V
VentKeys.X
VentKeys.Z
VentM1Every
Volcano
VolcanoAfter
VolcanoLoot
Weapons.*.C
Weapons.*.F
Weapons.*.M1
Weapons.*.V
Weapons.*.X
Weapons.*.Z
Weapons.*.hold
Weapons.*.use
""".splitlines() if k.strip()]
# Gone on purpose since: SeaEvDanger (2026-10-12 - the sea events boat always
# travels, no patrol circle; user: "it doesn't matter 6 or 7").


def read(name):
    with open(os.path.join(HERE, name), encoding="utf-8") as f:
        return f.read()


src_path = census or src_override or os.path.join(HERE, "..", "fast_farm.lua")
with open(src_path, encoding="utf-8") as f:
    src = f.read()

a = src.index("local CFG = {")
cfg = src[a:src.index("\n}\n", a) + 3]
p = src.index("-- PANEL\n")
panel = src[p:src.index("-- API\n", p)]

stubs = read("panel_stubs.lua")
cut = stubs.index("-- @@CFG@@")
cut_end = stubs.index("\n", cut) + 1
lua = (stubs[:cut] + cfg + "local CFG_REAL = CFG\nCFG = proxy(CFG_REAL, \"\")\n" + stubs[cut_end:]
       + panel
       + "\nlocal RUN = " + ('"census"' if census else '"full"') + "\n"
       + "local OLD_KEYS = {" + ", ".join('"%s"' % k for k in OLD_KEYS) + "}\n"
       + read("panel_cases.lua"))

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(lua)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
if census:
    sys.exit(0)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
