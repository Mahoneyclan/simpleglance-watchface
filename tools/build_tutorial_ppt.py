"""
Generates SimpleGlance_Tutorial.pptx — a code walkthrough of the watch face.
Run:  python3 tools/build_tutorial_ppt.py
"""
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.util import Inches, Pt
import copy

# ── Palette ───────────────────────────────────────────────────────────────────
BLACK   = RGBColor(0x00, 0x00, 0x00)
WHITE   = RGBColor(0xFF, 0xFF, 0xFF)
ORANGE  = RGBColor(0xFF, 0x80, 0x00)
DARK_BG = RGBColor(0x1A, 0x1A, 0x2E)
MID_BG  = RGBColor(0x16, 0x21, 0x3E)
ACCENT  = RGBColor(0xFF, 0x80, 0x00)   # orange
DIM     = RGBColor(0x88, 0x88, 0x88)
GREEN   = RGBColor(0x00, 0xAA, 0x00)
CODE_BG = RGBColor(0x0D, 0x1B, 0x2A)
CODE_FG = RGBColor(0xCE, 0xD4, 0xDB)
KW      = RGBColor(0x56, 0x9C, 0xD6)   # keyword blue
STR     = RGBColor(0xCE, 0x91, 0x78)   # string/number brown
CMT     = RGBColor(0x6A, 0x99, 0x55)   # comment green
FN      = RGBColor(0xDC, 0xDC, 0xAA)   # function yellow
# ──────────────────────────────────────────────────────────────────────────────

prs = Presentation()
prs.slide_width  = Inches(13.33)
prs.slide_height = Inches(7.5)

BLANK = prs.slide_layouts[6]  # completely blank

def add_slide():
    return prs.slides.add_slide(BLANK)

def bg(slide, color=DARK_BG):
    fill = slide.background.fill
    fill.solid()
    fill.fore_color.rgb = color

def box(slide, left, top, width, height, fill_color=None, line_color=None, line_width=Pt(0)):
    from pptx.util import Pt
    shape = slide.shapes.add_shape(
        1,  # MSO_SHAPE_TYPE.RECTANGLE
        Inches(left), Inches(top), Inches(width), Inches(height)
    )
    shape.fill.solid() if fill_color else shape.fill.background()
    if fill_color:
        shape.fill.fore_color.rgb = fill_color
    if line_color:
        shape.line.color.rgb = line_color
        shape.line.width = line_width
    else:
        shape.line.fill.background()
    return shape

def txt(slide, text, left, top, width, height,
        size=Pt(18), bold=False, color=WHITE, align=PP_ALIGN.LEFT,
        italic=False, wrap=True):
    txb = slide.shapes.add_textbox(
        Inches(left), Inches(top), Inches(width), Inches(height)
    )
    txb.word_wrap = wrap
    tf = txb.text_frame
    tf.word_wrap = wrap
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.size  = size
    run.font.bold  = bold
    run.font.color.rgb = color
    run.font.italic = italic
    return txb

def code_block(slide, lines, left, top, width, height, line_size=Pt(13)):
    """lines = list of (text, color) tuples."""
    bx = box(slide, left, top, width, height, fill_color=CODE_BG,
             line_color=ACCENT, line_width=Pt(1))
    txb = slide.shapes.add_textbox(
        Inches(left + 0.15), Inches(top + 0.12),
        Inches(width - 0.3), Inches(height - 0.24)
    )
    txb.word_wrap = False
    tf = txb.text_frame
    tf.word_wrap = False
    first = True
    for (text, color) in lines:
        if first:
            p = tf.paragraphs[0]
            first = False
        else:
            p = tf.add_paragraph()
        p.alignment = PP_ALIGN.LEFT
        run = p.add_run()
        run.text = text
        run.font.size = line_size
        run.font.color.rgb = color
        run.font.name = "Courier New"
    return txb

def accent_bar(slide, top=0.55, height=0.04):
    b = box(slide, 0, top, 13.33, height, fill_color=ACCENT)
    return b

# ════════════════════════════════════════════════════════════════════════════
# SLIDE 1 — Title
# ════════════════════════════════════════════════════════════════════════════
s = add_slide()
bg(s)
box(s, 0, 0, 13.33, 7.5, fill_color=DARK_BG)
# Decorative arc-like bar at top
box(s, 0, 0, 13.33, 0.55, fill_color=MID_BG)
accent_bar(s, top=0.51, height=0.08)

txt(s, "SimpleGlance", 1, 1.4, 11.33, 1.2,
    size=Pt(58), bold=True, color=ORANGE, align=PP_ALIGN.CENTER)
txt(s, "Watch Face — Code Tutorial", 1, 2.65, 11.33, 0.8,
    size=Pt(28), bold=False, color=WHITE, align=PP_ALIGN.CENTER)
txt(s, "A guided walkthrough of WatchFaceView.mc", 1, 3.55, 11.33, 0.55,
    size=Pt(18), color=DIM, align=PP_ALIGN.CENTER)

# Fake watch circle decoration
from pptx.util import Inches as I
oval = s.shapes.add_shape(9, I(5.4), I(4.5), I(2.5), I(2.5))
oval.fill.background()
oval.line.color.rgb = ORANGE
oval.line.width = Pt(5)

txt(s, "Garmin Fenix 6  •  MonkeyC  •  Connect IQ SDK", 1, 6.7, 11.33, 0.5,
    size=Pt(13), color=DIM, align=PP_ALIGN.CENTER)

# ════════════════════════════════════════════════════════════════════════════
# SLIDE 2 — Agenda
# ════════════════════════════════════════════════════════════════════════════
s = add_slide()
bg(s)
accent_bar(s, top=0, height=0.55)
txt(s, "What We'll Cover", 0.4, 0.05, 12, 0.5,
    size=Pt(26), bold=True, color=BLACK, align=PP_ALIGN.LEFT)

items = [
    ("1", "Project structure & language basics"),
    ("2", "Class skeleton & lifecycle methods"),
    ("3", "Settings system"),
    ("4", "onUpdate() — the draw loop"),
    ("5", "Battery arc"),
    ("6", "Date & time rendering"),
    ("7", "Bottom activity bar"),
    ("8", "Side panels — HR & Notifications"),
    ("9", "Icon drawing primitives"),
]

col_gap = 6.5
for i, (num, label) in enumerate(items):
    col = i // 5
    row = i % 5
    lx = 0.5 + col * col_gap
    ly = 1.0 + row * 1.1
    oval2 = s.shapes.add_shape(9, I(lx), I(ly), I(0.55), I(0.55))
    oval2.fill.solid()
    oval2.fill.fore_color.rgb = ACCENT
    oval2.line.fill.background()
    txt(s, num, lx, ly, 0.55, 0.55,
        size=Pt(16), bold=True, color=BLACK, align=PP_ALIGN.CENTER)
    txt(s, label, lx + 0.65, ly + 0.04, col_gap - 0.8, 0.5,
        size=Pt(17), color=WHITE)

# ════════════════════════════════════════════════════════════════════════════
# SLIDE 3 — Project Structure
# ════════════════════════════════════════════════════════════════════════════
s = add_slide()
bg(s)
accent_bar(s, top=0, height=0.55)
txt(s, "1 · Project Structure", 0.4, 0.05, 12, 0.5,
    size=Pt(26), bold=True, color=BLACK)

tree = [
    ("simpleglance-watchface/",          WHITE),
    ("  source/",                         DIM),
    ("    WatchFaceView.mc    ← all drawing logic", ORANGE),
    ("    WatchFaceApp.mc     ← app entry point",   CODE_FG),
    ("  resources/",                      DIM),
    ("    settings/",                     DIM),
    ("      properties.xml   ← default values",     CODE_FG),
    ("      settings.xml     ← Garmin Connect UI",  CODE_FG),
    ("    strings/strings.xml",           CODE_FG),
    ("    fonts/              ← custom TimeFont",   CODE_FG),
    ("  manifest.xml          ← app metadata, version", CODE_FG),
    ("  bin/garminwatchface.iq ← compiled output",  GREEN),
]
code_block(s, tree, 0.5, 0.7, 6.3, 6.4, line_size=Pt(14))

# Right — language primer
box(s, 7.1, 0.7, 5.9, 6.4, fill_color=MID_BG,
    line_color=ACCENT, line_width=Pt(1))
txt(s, "MonkeyC Language Basics", 7.3, 0.82, 5.5, 0.4,
    size=Pt(16), bold=True, color=ACCENT)

primer = [
    ("• Garmin's proprietary scripting language", WHITE),
    ("• Java-like syntax, runs on watch hardware", WHITE),
    ("• Strongly typed with type annotations", WHITE),
    ("• Compiled to .iq bytecode by SDK", WHITE),
    ("• Classes extend Toybox framework", WHITE),
    ("", WHITE),
    ("Key Toybox modules used:", ORANGE),
    ("  Graphics   — dc (drawing context)", CODE_FG),
    ("  System     — clock, stats, settings", CODE_FG),
    ("  ActivityMonitor — steps, HR history", CODE_FG),
    ("  Activity   — live workout data", CODE_FG),
    ("  SensorHistory   — elevation, etc.", CODE_FG),
    ("  Application.Properties — user prefs", CODE_FG),
    ("  WatchUi    — base WatchFace class", CODE_FG),
]
y = 1.35
for (t, c) in primer:
    txt(s, t, 7.3, y, 5.5, 0.36, size=Pt(13), color=c)
    y += 0.34

# ════════════════════════════════════════════════════════════════════════════
# SLIDE 4 — Class Skeleton & Lifecycle
# ════════════════════════════════════════════════════════════════════════════
s = add_slide()
bg(s)
accent_bar(s, top=0, height=0.55)
txt(s, "2 · Class Skeleton & Lifecycle", 0.4, 0.05, 12, 0.5,
    size=Pt(26), bold=True, color=BLACK)

code_block(s, [
    ("class WatchFaceView extends WatchUi.WatchFace {",  KW),
    ("",                                                  CODE_FG),
    ("    // Private state — layout & cached settings",   CMT),
    ("    private var _screenWidth as Number = 260;",     CODE_FG),
    ("    private var _font  as FontReference or Null;",  CODE_FG),
    ("    private var _bgColor, _hourColor, _minColor …", CODE_FG),
    ("    private var _leftField, _rightField, _arcLabel…",CODE_FG),
    ("",                                                  CODE_FG),
    ("    function initialize()   { WatchFace.initialize(); }", FN),
    ("    function onLayout(dc)   { /* measure screen */ }",    FN),
    ("    function onShow()       { loadSettings(); }",         FN),
    ("    function onSettingsChanged() { loadSettings(); }",    FN),
    ("    function onUpdate(dc)   { /* MAIN DRAW LOOP */ }",    ORANGE),
    ("    function onHide()       { }",                         FN),
    ("}",                                                 KW),
], 0.5, 0.7, 7.4, 5.5)

# Lifecycle diagram on right
box(s, 8.2, 0.7, 4.8, 5.5, fill_color=MID_BG,
    line_color=ACCENT, line_width=Pt(1))
txt(s, "Lifecycle Flow", 8.4, 0.82, 4.4, 0.35,
    size=Pt(15), bold=True, color=ACCENT)

steps = [
    ("initialize()",      "Called once at startup"),
    ("onLayout(dc)",      "Screen dimensions available"),
    ("onShow()",          "Face is visible → load settings"),
    ("onUpdate(dc)",      "Every second (or on demand)"),
    ("onSettingsChanged()","User changed prefs in app"),
    ("onHide()",          "Face hidden / switched away"),
]
sy = 1.35
for fn_name, note in steps:
    b = s.shapes.add_shape(1, I(8.3), I(sy), I(2.0), I(0.38))
    b.fill.solid(); b.fill.fore_color.rgb = RGBColor(0x2A,0x2A,0x4A)
    b.line.color.rgb = ORANGE; b.line.width = Pt(1)
    txt(s, fn_name, 8.33, sy+0.04, 1.95, 0.32,
        size=Pt(12), bold=True, color=ORANGE, align=PP_ALIGN.CENTER)
    txt(s, note, 10.45, sy+0.06, 2.5, 0.32,
        size=Pt(11), color=CODE_FG)
    if sy < 2.9:
        arr = s.shapes.add_shape(1, I(9.2), I(sy+0.38), I(0.3), I(0.15))
        arr.fill.solid(); arr.fill.fore_color.rgb = ACCENT
        arr.line.fill.background()
    sy += 0.62

txt(s, "↑ repeats every second", 8.3, sy + 0.05, 4.5, 0.3,
    size=Pt(11), color=DIM)

# ════════════════════════════════════════════════════════════════════════════
# SLIDE 5 — Settings System
# ════════════════════════════════════════════════════════════════════════════
s = add_slide()
bg(s)
accent_bar(s, top=0, height=0.55)
txt(s, "3 · Settings System", 0.4, 0.05, 12, 0.5,
    size=Pt(26), bold=True, color=BLACK)

txt(s, "properties.xml — default values", 0.5, 0.65, 5.8, 0.35,
    size=Pt(14), bold=True, color=ORANGE)
code_block(s, [
    ('<property id="BgColor"    type="number">0x000000</property>', CODE_FG),
    ('<property id="HourColor"  type="number">0xFFFFFF</property>', CODE_FG),
    ('<property id="MinColor"   type="number">0xFF8000</property>', CODE_FG),
    ('<property id="LeftField"  type="number">1</property>',        CODE_FG),
    ('<property id="RightField" type="number">4</property>',        CODE_FG),
    ('<property id="Use24h"     type="boolean">false</property>',   CODE_FG),
    ('<property id="ArcLabel"   type="number">0</property>',        CODE_FG),
], 0.5, 1.05, 5.8, 2.35, line_size=Pt(12))

txt(s, "loadSettings() — cache into instance vars", 0.5, 3.5, 5.8, 0.35,
    size=Pt(14), bold=True, color=ORANGE)
code_block(s, [
    ("private function loadSettings() as Void {",    KW),
    ("  _bgColor   = Properties.getValue(\"BgColor\");",    CODE_FG),
    ("  _hourColor = Properties.getValue(\"HourColor\");",  CODE_FG),
    ("  _leftField = Properties.getValue(\"LeftField\");",  CODE_FG),
    ("  _use24h    = Properties.getValue(\"Use24h\");",     CODE_FG),
    ("  // derive fg/dim from bg luminance:",               CMT),
    ("  var dark = isDark(_bgColor);",                      CODE_FG),
    ("  _fgColor  = dark ? COLOR_WHITE : COLOR_BLACK;",     CODE_FG),
    ("  _dimColor = dark ? COLOR_DK_GRAY : COLOR_LT_GRAY;", CODE_FG),
    ("}",                                                    KW),
], 0.5, 3.9, 5.8, 3.25, line_size=Pt(12))

# Right column
txt(s, "settings.xml — Garmin Connect Mobile UI", 6.7, 0.65, 6.3, 0.35,
    size=Pt(14), bold=True, color=ORANGE)
code_block(s, [
    ('<setting propertyKey="@Properties.BgColor"',  CODE_FG),
    ('         title="@Strings.SettingBgColor">',   CODE_FG),
    ('  <settingConfig type="list">',               KW),
    ('    <listEntry value="0x000000">Black</…>',   STR),
    ('    <listEntry value="0xFFFFFF">White</…>',   STR),
    ('  </settingConfig>',                          KW),
    ('</setting>',                                  CODE_FG),
    ("",                                            CODE_FG),
    ('<setting propertyKey="@Properties.Use24h"',   CODE_FG),
    ('         title="@Strings.SettingUse24h">',    CODE_FG),
    ('  <settingConfig type="boolean" />',          KW),
    ('</setting>',                                  CODE_FG),
], 6.7, 1.05, 6.3, 3.5, line_size=Pt(12))

box(s, 6.7, 4.7, 6.3, 2.4, fill_color=MID_BG,
    line_color=DIM, line_width=Pt(1))
txt(s, "isDark() — adaptive foreground color", 6.9, 4.82, 6.0, 0.35,
    size=Pt(13), bold=True, color=ORANGE)
txt(s,
    "Converts 0xRRGGBB → perceived luminance using the\n"
    "ITU-R BT.601 formula:  Y = 0.299R + 0.587G + 0.114B\n"
    "If Y < 128 the background is dark → use white text.\n"
    "This auto-adjusts labels & borders for any bg colour.",
    6.9, 5.22, 6.1, 1.75, size=Pt(12), color=CODE_FG)

# ════════════════════════════════════════════════════════════════════════════
# SLIDE 6 — onUpdate Draw Loop
# ════════════════════════════════════════════════════════════════════════════
s = add_slide()
bg(s)
accent_bar(s, top=0, height=0.55)
txt(s, "4 · onUpdate() — The Draw Loop", 0.4, 0.05, 12, 0.5,
    size=Pt(26), bold=True, color=BLACK)

code_block(s, [
    ("function onUpdate(dc as Dc) as Void {", KW),
    ("    dc.setColor(_bgColor, _bgColor);",  CODE_FG),
    ("    dc.clear();                      // wipe display", CMT),
    ("",                                   CODE_FG),
    ("    drawBatteryArc(dc);              // arc at top",   ORANGE),
    ("    drawDate(dc);                    // SAT 20 MAY",   FN),
    ("    drawTime(dc);                    // HH:MM + panels", FN),
    ("    drawBottomBar(dc);               // steps • floors", FN),
    ("}",                                  KW),
], 0.5, 0.7, 7.0, 3.8)

# Visual layout map
box(s, 7.8, 0.65, 5.1, 6.6, fill_color=MID_BG,
    line_color=ACCENT, line_width=Pt(1))
txt(s, "Screen Layout (260×260 px)", 7.95, 0.75, 4.8, 0.35,
    size=Pt(13), bold=True, color=ACCENT)

# fake screen
watch = s.shapes.add_shape(9, I(8.7), I(1.2), I(3.3), I(3.3))
watch.fill.solid(); watch.fill.fore_color.rgb = BLACK
watch.line.color.rgb = DIM; watch.line.width = Pt(2)

# Labels on fake screen
regions = [
    (9.9, 1.3,  "Battery Arc",   ORANGE),
    (9.9, 1.75, "Date",          CODE_FG),
    (9.9, 2.15, "  HH : MM",     WHITE),
    (8.85,2.15, "HR",            GREEN),
    (11.05,2.15,"Notif",         GREEN),
    (9.9, 2.85, "Steps • Floors",CODE_FG),
]
for lx, ly, lb, lc in regions:
    txt(s, lb, lx, ly, 1.4, 0.3, size=Pt(10), color=lc, align=PP_ALIGN.CENTER)

# Call-order list
notes = [
    ("1", "clear() — fill entire face with background color"),
    ("2", "drawBatteryArc() — renders first (behind everything)"),
    ("3", "drawDate() — small text at top"),
    ("4", "drawTime() — large digits + side panels"),
    ("5", "drawBottomBar() — activity stats at bottom"),
]
ny = 4.75
for num, note in notes:
    dot = s.shapes.add_shape(9, I(7.9), I(ny), I(0.32), I(0.32))
    dot.fill.solid(); dot.fill.fore_color.rgb = ACCENT
    dot.line.fill.background()
    txt(s, num, 7.9, ny, 0.32, 0.32,
        size=Pt(10), bold=True, color=BLACK, align=PP_ALIGN.CENTER)
    txt(s, note, 8.3, ny + 0.02, 4.4, 0.3, size=Pt(12), color=CODE_FG)
    ny += 0.42

# ════════════════════════════════════════════════════════════════════════════
# SLIDE 7 — Battery Arc
# ════════════════════════════════════════════════════════════════════════════
s = add_slide()
bg(s)
accent_bar(s, top=0, height=0.55)
txt(s, "5 · Battery Arc", 0.4, 0.05, 12, 0.5,
    size=Pt(26), bold=True, color=BLACK)

code_block(s, [
    ("private function drawBatteryArc(dc) {",             KW),
    ("  var stats   = System.getSystemStats();",          CODE_FG),
    ("  var battPct = stats.battery.toNumber(); // 0-100",CODE_FG),
    ("  var r       = (_screenWidth / 2) - 7;  // 123px", CODE_FG),
    ("",                                                   CODE_FG),
    ("  // 1. Draw dim track (full 150°→30° span)",        CMT),
    ("  dc.setPenWidth(8);",                              CODE_FG),
    ("  dc.setColor(_dimColor, TRANSPARENT);",            CODE_FG),
    ("  dc.drawArc(cx, cy, r, ARC_CCW, 30, 150);",        FN),
    ("",                                                   CODE_FG),
    ("  // 2. Draw coloured fill proportional to charge",  CMT),
    ("  var battCol = battPct > 50  ? COLOR_GREEN",        CODE_FG),
    ("             : battPct >= 25 ? COLOR_ORANGE",        CODE_FG),
    ("             :                 COLOR_RED;",          CODE_FG),
    ("  var endAngle = 30 + battPct * 120 / 100;",         ORANGE),
    ("  dc.drawArc(cx, cy, r, ARC_CCW, 30, endAngle);",    FN),
    ("",                                                   CODE_FG),
    ("  // 3. Optional label (%, days)",                   CMT),
    ("  if (_arcLabel != ARCLABEL_NONE) { … }",           CODE_FG),
    ("}",                                                  KW),
], 0.5, 0.68, 7.1, 6.5, line_size=Pt(12))

box(s, 7.9, 0.68, 5.1, 6.5, fill_color=MID_BG,
    line_color=ACCENT, line_width=Pt(1))
txt(s, "Arc Geometry", 8.05, 0.80, 4.8, 0.35,
    size=Pt(15), bold=True, color=ACCENT)

notes2 = [
    ("Coordinate system",
     "Garmin uses degrees: 0°=right, 90°=top,\n"
     "180°=left, 270°=bottom (counter-clockwise)."),
    ("Track spans 10 o'clock→2 o'clock",
     "150° (top-left) to 30° (top-right).\n"
     "Total arc = 120°."),
    ("Fill anchored at 30° (empty side)",
     "endAngle = 30 + battPct × 120 / 100\n"
     "Full charge → endAngle = 150°."),
    ("Colour thresholds",
     "> 50% → Green\n"
     "25–50% → Orange\n"
     "< 25% → Red"),
    ("Optional label",
     "Drawn at the top of the arc.\n"
     "ARCLABEL_PCT → \"72%\"\n"
     "ARCLABEL_DAYS → \"9d\" (batteryInDays)"),
]
ny = 1.3
for title, body in notes2:
    txt(s, title, 8.05, ny, 4.8, 0.3,
        size=Pt(13), bold=True, color=ORANGE)
    txt(s, body, 8.05, ny + 0.3, 4.8, 0.62,
        size=Pt(12), color=CODE_FG)
    ny += 1.08

# ════════════════════════════════════════════════════════════════════════════
# SLIDE 8 — Date & Time
# ════════════════════════════════════════════════════════════════════════════
s = add_slide()
bg(s)
accent_bar(s, top=0, height=0.55)
txt(s, "6 · Date & Time Rendering", 0.4, 0.05, 12, 0.5,
    size=Pt(26), bold=True, color=BLACK)

txt(s, "drawDate()", 0.5, 0.65, 5.8, 0.33,
    size=Pt(14), bold=True, color=ORANGE)
code_block(s, [
    ("var now = Gregorian.info(Time.now(), FORMAT_SHORT);",CODE_FG),
    ("var days   = [\"SUN\",\"MON\",\"TUE\"…];",         CODE_FG),
    ("var months = [\"JAN\",\"FEB\",\"MAR\"…];",         CODE_FG),
    ("var dateStr = format(\"$1$ $2$ $3$\", [",          CODE_FG),
    ("    days[now.day_of_week - 1],   // \"WED\"",      CMT),
    ("    now.day.format(\"%d\"),       // \"04\"",       CMT),
    ("    months[now.month - 1]]);     // \"JUN\"",       CMT),
    ("dc.drawText(cx, 43, FONT_MEDIUM, dateStr, CENTER);",FN),
], 0.5, 1.0, 6.0, 2.8, line_size=Pt(12))

txt(s, "drawTime() — two-tone digits", 0.5, 3.95, 5.8, 0.33,
    size=Pt(14), bold=True, color=ORANGE)
code_block(s, [
    ("// Compute text widths to centre the pair",         CMT),
    ("var hrW  = dc.getTextDimensions(hrStr, font)[0];",  CODE_FG),
    ("var minW = dc.getTextDimensions(minStr, font)[0];", CODE_FG),
    ("var totalW = hrW + colonGap + minW;",               CODE_FG),
    ("var hrX    = cx - totalW / 2;",                     ORANGE),
    ("",                                                   CODE_FG),
    ("dc.setColor(_hourColor, TRANSPARENT);",             CODE_FG),
    ("dc.drawText(hrX, y, font, hrStr, LEFT);",           FN),
    ("dc.setColor(_minColor, TRANSPARENT);",              CODE_FG),
    ("dc.drawText(minX, y, font, minStr, LEFT);",         FN),
    ("// Two filled circles for the colon",               CMT),
    ("dc.fillCircle(colonX, y - 20, 7);",                 CODE_FG),
    ("dc.fillCircle(colonX, y + 20, 7);",                 CODE_FG),
], 0.5, 4.3, 6.0, 3.05, line_size=Pt(12))

# Right panel
box(s, 6.85, 0.68, 6.1, 6.6, fill_color=MID_BG,
    line_color=ACCENT, line_width=Pt(1))
txt(s, "Centering Two-Color Text", 7.0, 0.80, 5.8, 0.35,
    size=Pt(15), bold=True, color=ACCENT)
txt(s,
    "Because the hour and minute digits are different colours,\n"
    "they can't be drawn as a single string. We must:\n\n"
    "  1. Measure both strings individually with\n"
    "     getTextDimensions().\n\n"
    "  2. Compute the combined width including colon gap.\n\n"
    "  3. Calculate hrX = centerX − totalWidth / 2  so the\n"
    "     whole block is horizontally centred.\n\n"
    "  4. Draw hours at hrX, minutes at hrX + hrW + gap.\n\n"
    "The colon is two filled circles drawn at the midpoint\n"
    "between the two digit groups — hardware-efficient.",
    7.0, 1.25, 5.8, 4.5, size=Pt(13), color=CODE_FG)

txt(s, "Custom font loaded once in onLayout():", 7.0, 5.85, 5.8, 0.3,
    size=Pt(12), bold=True, color=ORANGE)
txt(s, "_font = WatchUi.loadResource(Rez.Fonts.TimeFont);",
    7.0, 6.2, 5.8, 0.3, size=Pt(12), color=CODE_FG)

# ════════════════════════════════════════════════════════════════════════════
# SLIDE 9 — Bottom Bar / fieldValue
# ════════════════════════════════════════════════════════════════════════════
s = add_slide()
bg(s)
accent_bar(s, top=0, height=0.55)
txt(s, "7 · Bottom Activity Bar", 0.4, 0.05, 12, 0.5,
    size=Pt(26), bold=True, color=BLACK)

code_block(s, [
    ("private function drawBottomBar(dc) {",               KW),
    ("  var actInfo = ActivityMonitor.getInfo();",         CODE_FG),
    ("  var l = fieldValue(_leftField,  actInfo);",        CODE_FG),
    ("  var r = fieldValue(_rightField, actInfo);",        CODE_FG),
    ("  var text = (l.length()>0 && r.length()>0)",        CODE_FG),
    ("           ? l + \" • \" + r",                      ORANGE),
    ("           : (l.length()>0 ? l : r);",              CODE_FG),
    ("  dc.drawText(cx, 228, FONT_SMALL, text, CENTER);",  FN),
    ("}",                                                   KW),
], 0.5, 0.68, 5.9, 3.2)

txt(s, "fieldValue() — what each FIELD_* returns", 0.5, 4.0, 5.9, 0.35,
    size=Pt(14), bold=True, color=ORANGE)

fields = [
    ("FIELD_STEPS",      "1", "actInfo.steps",             "\"4.2k stp\" or \"850 stp\""),
    ("FIELD_CALORIES",   "2", "actInfo.calories",          "\"1840 cal\""),
    ("FIELD_DISTANCE",   "3", "actInfo.distance / 100000", "\"8.4 km\""),
    ("FIELD_FLOORS",     "4", "actInfo.floorsClimbed",     "\"3 fl\""),
    ("FIELD_ACTIVE_MIN", "5", "actInfo.activeMinutesDay",  "\"42 min\""),
    ("FIELD_ELEVATION",  "7", "SensorHistory.getElevation","\"328 m\""),
]
box(s, 0.5, 4.42, 5.9, 2.85, fill_color=CODE_BG,
    line_color=ACCENT, line_width=Pt(1))
txt(s, "Const     Val  Source                    Example",
    0.6, 4.52, 5.7, 0.3, size=Pt(10), bold=True, color=ORANGE)
for i, (const, val, src, ex) in enumerate(fields):
    fy = 4.9 + i * 0.38
    row_c = RGBColor(0x12,0x28,0x40) if i % 2 == 0 else CODE_BG
    box(s, 0.5, fy, 5.9, 0.36, fill_color=row_c)
    txt(s, const, 0.6,  fy+0.04, 1.4, 0.3, size=Pt(10), color=FN)
    txt(s, val,   2.05, fy+0.04, 0.3, 0.3, size=Pt(10), color=STR)
    txt(s, src,   2.4,  fy+0.04, 2.1, 0.3, size=Pt(10), color=CODE_FG)
    txt(s, ex,    4.55, fy+0.04, 1.7, 0.3, size=Pt(10), color=GREEN)

# Right panel
box(s, 6.7, 0.68, 6.3, 6.6, fill_color=MID_BG,
    line_color=ACCENT, line_width=Pt(1))
txt(s, "Data Sources", 6.85, 0.80, 6.0, 0.35,
    size=Pt(15), bold=True, color=ACCENT)
notes3 = [
    ("ActivityMonitor.getInfo()",
     "Returns a snapshot of the user's daily activity.\n"
     "Refreshed every minute by the OS. Null-safe fields."),
    ("FIELD_ELEVATION special case",
     "Uses SensorHistory, not ActivityMonitor.\n"
     "Must check hasattr before calling — API not present\n"
     "on all devices / firmware versions."),
    ("Formatting logic",
     "Steps ≥ 1000 → compact \"4.2k stp\" form.\n"
     "Distance: raw value is centimetres → ÷ 100 000 = km.\n"
     "All values fall back to \"--\" if null."),
    ("Two-field layout",
     "Left and right fields joined with \" • \" separator.\n"
     "If one is FIELD_NONE it is omitted — the remaining\n"
     "field centres itself automatically."),
]
ny = 1.3
for title, body in notes3:
    txt(s, title, 6.85, ny, 6.0, 0.3,
        size=Pt(13), bold=True, color=ORANGE)
    txt(s, body, 6.85, ny + 0.3, 6.0, 0.72,
        size=Pt(12), color=CODE_FG)
    ny += 1.2

# ════════════════════════════════════════════════════════════════════════════
# SLIDE 10 — Side Panels (HR + Notif)
# ════════════════════════════════════════════════════════════════════════════
s = add_slide()
bg(s)
accent_bar(s, top=0, height=0.55)
txt(s, "8 · Side Panels — HR & Notifications", 0.4, 0.05, 12, 0.5,
    size=Pt(26), bold=True, color=BLACK)

code_block(s, [
    ("// HR panel: open on left (no left border)",          CMT),
    ("private function drawHRPanel(dc, cx, cy) {",          KW),
    ("  // 1. Blank out area behind panel",                  CMT),
    ("  dc.fillRectangle(x, y, boxW, boxH);",               CODE_FG),
    ("  // 2. Draw 3-sided rounded border",                  CMT),
    ("  dc.drawLine(top_edge); dc.drawArc(top_right_corner);",CODE_FG),
    ("  dc.drawLine(right_edge); dc.drawArc(bottom_right);", CODE_FG),
    ("  dc.drawLine(bottom_edge);",                          CODE_FG),
    ("  // 3. Draw heart icon straddling top border",        CMT),
    ("  drawMiniHeart(dc, cx, y);",                          FN),
    ("  // 4. Read HR — live workout first, then history",   CMT),
    ("  var actInfo = Activity.getActivityInfo();",          CODE_FG),
    ("  if (actInfo != null && actInfo.currentHeartRate != null) {", CODE_FG),
    ("      hrStr = actInfo.currentHeartRate.toString();",   CODE_FG),
    ("  } else if (ActivityMonitor has :getHeartRateHistory) {", CODE_FG),
    ("      var sample = getHeartRateHistory(1, true).next();", CODE_FG),
    ("      if (sample.heartRate != INVALID_HR_SAMPLE) {",   CODE_FG),
    ("          hrStr = sample.heartRate.toString();",       CODE_FG),
    ("  } }",                                                KW),
    ("  dc.drawText(cx, midY, FONT_SMALL, hrStr, CENTER);",  FN),
    ("}",                                                    KW),
], 0.5, 0.68, 7.3, 6.55, line_size=Pt(11.5))

box(s, 8.1, 0.68, 4.9, 6.55, fill_color=MID_BG,
    line_color=ACCENT, line_width=Pt(1))
txt(s, "Design Notes", 8.25, 0.80, 4.5, 0.35,
    size=Pt(15), bold=True, color=ACCENT)
notes4 = [
    ("Panel shape",
     "Both boxes are 34×52 px. Each is 3-sided:\n"
     "HR panel opens LEFT (time digits bleed in).\n"
     "Notif panel opens RIGHT."),
    ("fillRectangle() first",
     "Erases whatever the time digits drew behind\n"
     "the panel area — order matters."),
    ("HR priority",
     "Activity (live) > ActivityMonitor history.\n"
     "This mirrors the crystal-face pattern and\n"
     "works at rest and during workouts."),
    ("INVALID_HR_SAMPLE guard",
     "0xFFFF (65535) is the sentinel for 'no reading'.\n"
     "Must skip these to find the last valid BPM."),
    ("Notification count",
     "System.getDeviceSettings().notificationCount\n"
     "Returns an Integer — drawn as-is (no icon)."),
]
ny = 1.3
for title, body in notes4:
    txt(s, title, 8.25, ny, 4.6, 0.3,
        size=Pt(13), bold=True, color=ORANGE)
    txt(s, body, 8.25, ny + 0.3, 4.6, 0.72,
        size=Pt(12), color=CODE_FG)
    ny += 1.16

# ════════════════════════════════════════════════════════════════════════════
# SLIDE 11 — Icon Drawing Primitives
# ════════════════════════════════════════════════════════════════════════════
s = add_slide()
bg(s)
accent_bar(s, top=0, height=0.55)
txt(s, "9 · Icon Drawing Primitives", 0.4, 0.05, 12, 0.5,
    size=Pt(26), bold=True, color=BLACK)

txt(s, "drawMiniHeart()", 0.5, 0.65, 5.8, 0.35,
    size=Pt(14), bold=True, color=ORANGE)
code_block(s, [
    ("dc.fillCircle(cx-3, cy-4, 3);   // left lobe",  CODE_FG),
    ("dc.fillCircle(cx+3, cy-4, 3);   // right lobe", CODE_FG),
    ("dc.fillRectangle(cx-5,cy-2,11,2);// bridge",    CODE_FG),
    ("dc.fillRectangle(cx-4,cy,  9,2);",              CODE_FG),
    ("dc.fillRectangle(cx-3,cy+2, 7,2);",             CODE_FG),
    ("dc.fillRectangle(cx-2,cy+4, 5,2);",             CODE_FG),
    ("dc.fillRectangle(cx-1,cy+6, 3,1);",             CODE_FG),
    ("dc.fillCircle(cx,  cy+7, 1);     // tip",       CODE_FG),
], 0.5, 1.05, 5.8, 2.85, line_size=Pt(13))

txt(s, "drawMiniBell()", 0.5, 4.05, 5.8, 0.35,
    size=Pt(14), bold=True, color=ORANGE)
code_block(s, [
    ("// Bell dome",                                     CMT),
    ("dc.fillCircle(cx, cy-2, 5);",                     CODE_FG),
    ("// Erase lower half of dome (flat bottom edge)",  CMT),
    ("dc.setColor(_bgColor, TRANSPARENT);",             CODE_FG),
    ("dc.fillRectangle(cx-6, cy-2, 12, 6);",            CODE_FG),
    ("// Redraw body & rim",                            CMT),
    ("dc.setColor(_fgColor, TRANSPARENT);",             CODE_FG),
    ("dc.fillRectangle(cx-5, cy-2, 10, 5);  // body",  CODE_FG),
    ("dc.fillRectangle(cx-6, cy+3, 12, 2);  // rim",   CODE_FG),
    ("dc.fillCircle(cx, cy+7, 2);            // clapper",CODE_FG),
], 0.5, 4.45, 5.8, 3.25, line_size=Pt(13))

# Right panel
box(s, 6.7, 0.68, 6.3, 6.6, fill_color=MID_BG,
    line_color=ACCENT, line_width=Pt(1))
txt(s, "Why Pixel Art, Not Vector?", 6.85, 0.80, 6.0, 0.35,
    size=Pt(15), bold=True, color=ACCENT)
txt(s,
    "Garmin watch faces can't load PNG icons directly — the\n"
    "Graphics API only provides primitive draw calls:\n\n"
    "  fillCircle(x, y, radius)\n"
    "  fillRectangle(x, y, w, h)\n"
    "  drawArc(x, y, r, dir, startAngle, endAngle)\n"
    "  drawLine(x1, y1, x2, y2)\n\n"
    "Icons are built by compositing these primitives at\n"
    "pixel scale (~16 px tall). The technique is:\n\n"
    "  1. Draw the filled positive shape in _fgColor.\n"
    "  2. Punch holes by painting _bgColor over parts\n"
    "     of the shape (erase-by-overpainting).\n"
    "  3. Redraw foreground on top to restore detail.\n\n"
    "The bell uses this erase trick to flatten its dome.\n\n"
    "Icons straddle the panel top border (cy = border y)\n"
    "so they visually 'sit on' the box edge.",
    6.85, 1.25, 6.0, 5.85, size=Pt(13), color=CODE_FG)

# ════════════════════════════════════════════════════════════════════════════
# SLIDE 12 — Summary / Cheat Sheet
# ════════════════════════════════════════════════════════════════════════════
s = add_slide()
bg(s)
accent_bar(s, top=0, height=0.55)
txt(s, "Summary — Quick Reference", 0.4, 0.05, 12, 0.5,
    size=Pt(26), bold=True, color=BLACK)

# Two-column table
headers = ["Function", "Role", "Key API"]
rows = [
    ("onLayout(dc)",      "Screen size, load font",       "dc.getWidth(), loadResource()"),
    ("onShow()",          "Cache settings on appear",     "Application.Properties.getValue()"),
    ("onUpdate(dc)",      "Full redraw every second",     "dc.clear(), drawXxx(dc)"),
    ("loadSettings()",    "Pull prefs → instance vars",   "Properties.getValue(), isDark()"),
    ("drawBatteryArc()",  "Top arc, colour by charge",    "System.getSystemStats(), drawArc()"),
    ("drawDate()",        "SAT 04 JUN header",            "Gregorian.info(), drawText()"),
    ("drawTime()",        "Two-tone HH:MM + colon dots",  "getTextDimensions(), fillCircle()"),
    ("drawBottomBar()",   "Activity stats row",           "ActivityMonitor.getInfo()"),
    ("drawHRPanel()",     "Left panel, HR value",         "Activity + ActivityMonitor"),
    ("drawNotifPanel()",  "Right panel, notif count",     "System.getDeviceSettings()"),
    ("fieldValue()",      "Format any FIELD_* constant",  "SensorHistory, ActivityMonitor"),
    ("drawMiniHeart()",   "Pixel heart icon",             "fillCircle(), fillRectangle()"),
    ("drawMiniBell()",    "Pixel bell icon",              "fillCircle(), fillRectangle()"),
    ("isDark(color)",     "Adaptive text color",          "ITU-R BT.601 luminance formula"),
]

col_widths = [2.2, 2.55, 4.5]
col_starts = [0.25, 2.5, 5.1]
row_h = 0.38
header_y = 0.68

# Header row
for ci, (cw, cx, hdr) in enumerate(zip(col_widths, col_starts, headers)):
    box(s, cx, header_y, cw, row_h, fill_color=ACCENT)
    txt(s, hdr, cx+0.05, header_y+0.05, cw-0.1, row_h-0.1,
        size=Pt(12), bold=True, color=BLACK)

for ri, (fn_name, role, api) in enumerate(rows):
    ry = header_y + row_h + ri * row_h
    row_c = RGBColor(0x12,0x28,0x40) if ri % 2 == 0 else MID_BG
    for ci, (cw, cx) in enumerate(zip(col_widths, col_starts)):
        box(s, cx, ry, cw, row_h, fill_color=row_c)
    vals = [fn_name, role, api]
    colors2 = [FN, CODE_FG, DIM]
    for ci, (cw, cx, val, vc) in enumerate(zip(col_widths, col_starts, vals, colors2)):
        txt(s, val, cx+0.05, ry+0.06, cw-0.1, row_h-0.1,
            size=Pt(10), color=vc)

# Right column: build / deploy note
box(s, 9.85, 0.68, 3.25, 6.6, fill_color=MID_BG,
    line_color=ACCENT, line_width=Pt(1))
txt(s, "Build & Deploy", 10.0, 0.80, 3.0, 0.35,
    size=Pt(14), bold=True, color=ACCENT)
txt(s,
    "Compile:\n"
    "  monkeyc -o bin/watch.iq\n"
    "    -f monkey.jungle\n"
    "    -y developer_key.der\n"
    "    -d fenix6\n\n"
    "Deploy:\n"
    "  Copy .iq to watch via\n"
    "  USB → GARMIN/Apps/\n\n"
    "After any version bump:\n"
    "  • Edit manifest.xml\n"
    "  • Rebuild .iq\n"
    "  • Keep both in sync!\n\n"
    "Settings live in:\n"
    "  Garmin Connect Mobile\n"
    "  → My Device\n"
    "  → Watch Faces\n"
    "  → SimpleGlance → ⚙",
    10.0, 1.25, 3.0, 5.9, size=Pt(12), color=CODE_FG)

# ── Save ─────────────────────────────────────────────────────────────────────
out = "/Volumes/GDrive/Github/simpleglance-watchface/SimpleGlance_Tutorial.pptx"
prs.save(out)
print(f"Saved → {out}")
