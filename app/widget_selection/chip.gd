@tool extends PanelContainer

@export var color: Color
var text: String:
	set(v):
		text = v
		%Chip.text = v
		color = pastel_color_from_text(v)
		var style_box = get_theme_stylebox("panel").duplicate()
		style_box.bg_color = color
		add_theme_stylebox_override("panel", style_box)

func pastel_color_from_text(new_text: String) -> Color:
	var s := new_text
	var h: int = 0x811C9DC5 # FNV-1a offset basis (32-bit)

	for i in s.length():
		var code: int = s.unicode_at(i)
		h = (h ^ code) & 0xFFFFFFFF
		h = int((int(h) * 0x01000193) & 0xFFFFFFFF)

	var hue: int = h % 360
	var sat: float = 55.0
	var light: float = 45.0

	return hsl_to_color(hue, sat, light)


func hsl_to_color(h: int, s: float, l: float) -> Color:
	var hf: float = float(h) / 60.0
	var sf: float = s / 100.0
	var lf: float = l / 100.0

	var c: float = (1.0 - abs(2.0 * lf - 1.0)) * sf

	var q: float = floor(hf / 2.0)
	var rem: float = hf - q * 2.0
	var x: float = c * (1.0 - abs(rem - 1.0))

	var m: float = lf - c / 2.0

	var r1: float = 0.0
	var g1: float = 0.0
	var b1: float = 0.0

	var sector: int = int(floor(hf)) % 6
	match sector:
		0: r1 = c;  g1 = x;  b1 = 0.0
		1: r1 = x;  g1 = c;  b1 = 0.0
		2: r1 = 0.0; g1 = c;  b1 = x
		3: r1 = 0.0; g1 = x;  b1 = c
		4: r1 = x;  g1 = 0.0; b1 = c
		5: r1 = c;  g1 = 0.0; b1 = x

	return Color(r1 + m, g1 + m, b1 + m, 1.0)
