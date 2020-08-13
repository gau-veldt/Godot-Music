extends Node2D

onready var player := get_node("../Player")
onready var cam := get_node("Camera2D")

var whtBG=StyleBoxFlat.new()
var blkBG=StyleBoxFlat.new()
var chBG=[
	StyleBoxFlat.new(),
	StyleBoxFlat.new(),
	StyleBoxFlat.new(),
	StyleBoxFlat.new()
]

var keyboard=Array()
func _ready():
	whtBG.bg_color=Color("#ffffff")
	blkBG.bg_color=Color("#000000")
	chBG[0].bg_color=Color("#ff00ff")
	chBG[1].bg_color=Color("#00ffff")
	chBG[2].bg_color=Color("#0080ff")
	chBG[3].bg_color=Color("#0000ff")
	var blk_skips=[1,2,1,1,2]
	
	var px=5
	var pxB=11
	var pxB_i=0
	var py=7
	# generate white key visuals
	for key in range(96):
		var kn=player.num2note(key)
		if kn[1]!="#":
			var kc=Label.new()
			var knv=""
			kc.name=kn
			if len(kn)<3:
				kn=kn[0]+"  "+kn[1]
			for ch in kn:
				knv+=ch
				knv+="\n"
			knv=knv.strip_edges()
			kc.text=knv
			kc.rect_scale=Vector2(.6,.6)
			kc.rect_min_size=Vector2(15,77)
			kc.align=Label.ALIGN_CENTER
			kc.set_position(Vector2(px,py))
			px+=10
			self.add_child(kc)
			keyboard.append(kc)
		else:
			keyboard.append(null)
	# generate black key visuals
	for key in range(96):
		var kn=player.num2note(key)
		if kn[1]=="#":
			var kc=Label.new()
			var knv=""
			kc.name=kn
			if len(kn)<3:
				kn=kn[0]+"  "+kn[1]
			for ch in kn:
				knv+=ch
				knv+="\n"
			knv=knv.strip_edges()
			kc.text=knv
			kc.rect_scale=Vector2(.6,.6)
			kc.set_position(Vector2(pxB,py))
			pxB+=10*blk_skips[pxB_i]
			pxB_i+=1 if pxB_i<4 else -4
			self.add_child(kc)
			keyboard[key]=kc
	reset_key_colors()
	player.connect("row",self,"on_row")

func reset_key_colors():
	var kc : Label
	var kn
	var bW:bool
	for ky in range(96):
		bW=true
		kc=keyboard[ky]
		kn=player.num2note(ky)
		if kn[1]=="#": bW=false
		if bW:
			kc.set("custom_colors/font_color",Color("#000000"))
			kc.set("custom_styles/normal",whtBG)
		else:
			kc.set("custom_colors/font_color",Color("#ffffff"))
			kc.set("custom_styles/normal",blkBG)

func on_row(frame,state):
	var measure
	var beat
	var slice
	var st
	var kn
	measure=1+(frame/64)
	slice=frame % 64
	beat=1+(slice/16)
	reset_key_colors()
	#print(frame,",",state)
	var stop=true
	for ch in range(4):
		st=state[ch]
		if st!="#": stop=false
		if len(st)>1:
			kn=player.note2num(st)
			keyboard[kn].set("custom_colors/font_color",Color("#000000"))
			keyboard[kn].set("custom_styles/normal",chBG[ch])
	if stop:
		get_tree().quit()
