extends Node

export var rate=48000
export(String, MULTILINE) var tB=""
export(String, MULTILINE) var tM=""
export(String, MULTILINE) var tV1=""
export(String, MULTILINE) var tV2=""
export(String, MULTILINE) var tV3=""
export var SecPerWhole=5.9
var FrmPerWhole
var FrmPer64th

# std is 440, baroque is 415, concert sometimes 430
export var a4=440
# 12th root of 2
var tet12=1.0594630943592952645618252949463
var note_syms=["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
const digits=["0","1","2","3","4","5","6","7","8","9"]
var notes={}
var silence

var c={}
var playState=null

onready var home=get_node("..")
var audio=[]

func _ready():
	var tmp
	var ll
	FrmPer64th=int(60*SecPerWhole/64)
	FrmPerWhole=64*FrmPer64th
	print(FrmPer64th," physics frames per tick (whole=",FrmPerWhole,")")

	silence=AudioStreamSample.new()
	tmp=PoolByteArray()
	for wrd in range(4096):
		tmp.append(0)
		tmp.append(0)
	silence.data=tmp
	silence.format=AudioStreamSample.FORMAT_16_BITS
	silence.loop_mode=AudioStreamSample.LOOP_FORWARD
	silence.loop_begin=0
	silence.loop_end=4095
	silence.mix_rate=rate

	for chn in range(4):
		audio.append(get_node("../Channel "+str(1+chn)))

	var endV1
	var endV2
	var endV3
	
	tmp=tV1.c_escape()
	tmp=tmp.replace("\\n"," ")
	tmp=tmp.replace("\\r"," ")
	tmp=tmp.replace("\\t"," ")
	ll=tmp.length()
	tmp=tmp.replace("  "," ")
	while tmp.length()<ll:
		ll=tmp.length()
		tmp=tmp.replace("  "," ")
	endV1=tmp.strip_edges()
	
	tmp=tV2.c_escape()
	tmp=tmp.replace("\\n"," ")
	tmp=tmp.replace("\\r"," ")
	tmp=tmp.replace("\\t"," ")
	ll=tmp.length()
	tmp=tmp.replace("  "," ")
	while tmp.length()<ll:
		ll=tmp.length()
		tmp=tmp.replace("  "," ")
	endV2=tmp.strip_edges()
	
	tmp=tV3.c_escape()
	tmp=tmp.replace("\\n"," ")
	tmp=tmp.replace("\\r"," ")
	tmp=tmp.replace("\\t"," ")
	ll=tmp.length()
	tmp=tmp.replace("  "," ")
	while tmp.length()<ll:
		ll=tmp.length()
		tmp=tmp.replace("  "," ")
	endV3=tmp.strip_edges()
	
	tmp=tB.c_escape()
	tmp=tmp.replace("\\n"," ")
	tmp=tmp.replace("\\r"," ")
	tmp=tmp.replace("\\t"," ")
	ll=tmp.length()
	tmp=tmp.replace("  "," ")
	while tmp.length()<ll:
		ll=tmp.length()
		tmp=tmp.replace("  "," ")
	c[0]=tmp.strip_edges()
	
	tmp=tM.c_escape()
	tmp=tmp.replace("\\n"," ")
	tmp=tmp.replace("\\r"," ")
	tmp=tmp.replace("\\t"," ")
	ll=tmp.length()
	tmp=tmp.replace("  "," ")
	while tmp.length()<ll:
		ll=tmp.length()
		tmp=tmp.replace("  "," ")
	c[1]=("128R "+tmp+" "+endV1).strip_edges()
	c[2]=("256R "+tmp+" "+endV2).strip_edges()
	c[3]=("384R "+tmp+" "+endV3).strip_edges()
	for chn in range(4):
		c[chn]=c[chn].split(" ")
	
	var rc
	rc=make_note_table()
	while typeof(rc)!=TYPE_INT:
		print("Note ",notes.size(),"/96 (",num2note(notes.size()-1),")")
		yield(get_tree().create_timer(0.05),"timeout")
		rc=rc.resume()
	print("Done.")
	
	connect("frame",self,"update_rtc")
	connect("frame",self,"player")

signal frame
var frames=0
func _physics_process(delta):
	frames+=1
	emit_signal("frame")



signal rtc_second
signal rtc_minute
signal rtc_hour
signal rtc_day
var rtc_frm=0
var seconds=0
var minutes=0
var hours=0
var days=0
func update_rtc():
	var emits=[]
	rtc_frm+=1
	if rtc_frm>59:
		rtc_frm-=60
		seconds+=1
		emits.append("rtc_second")
	if seconds>59:
		seconds-=60
		minutes+=1
		emits.append("rtc_minute")
	if minutes>59:
		minutes-=60
		hours+=1
		emits.append("rtc_hour")
	if hours>23:
		hours-=24
		days+=1
		emits.append("rtc_day")
	for sgnl in emits:
		emit_signal(sgnl)



func num2note(num):
	var oct=int(num/12)
	var nte=num%12
	return note_syms[nte]+str(oct)

func note2num(nte_oct):
	var lhs=nte_oct.substr(0,2)
	var nolen=nte_oct.length()
	var rhs=""
	var nte=-1
	var oct=0
	if lhs[1]!="#":
		lhs=lhs[0]
		rhs=nte_oct.substr(1,nolen-1)
	else:
		rhs=nte_oct.substr(2,nolen-2)
	if rhs=="": return -1
	oct=rhs.to_int()
	lhs=lhs.to_upper()
	if lhs in note_syms:
		nte=note_syms.find(lhs)
		return (oct*12)+nte
	else:
		return -1



func make_note_table():
	var ref=note2num("A4")
	var note
	var cur=ref
	var hz=float(a4)
	print("Creating samples...")
	while cur >= 0:
		note=num2note(cur)
		notes[cur]={}
		notes[cur]["freq"]=hz
		notes[cur]["sam"]=make_sample(hz)
		# the floats are limited precision
		# so reset the hertz every A octaves
		# to reduce rounding error over
		# taking successive roots
		if (int(note) % 12)==9:
			var oct=int(note/12)-4
			var low=false
			if oct<0: low=true
			oct=pow(2,abs(oct))
			if low:
				hz=float(a4)/float(oct)
			else:
				hz=float(a4)*float(oct)
		else:
			hz=hz/tet12
		cur-=1
		yield()
	cur=ref
	hz=float(a4)
	while cur<95:
		cur+=1
		note=num2note(cur)
		# the floats are limited precision
		# so reset the hertz every A octaves
		# to reduce rounding error over
		# taking successive roots
		if (int(note) % 12)==9:
			var oct=int(note/12)-4
			var low=false
			if oct<0: low=true
			oct=pow(2,abs(oct))
			if low:
				hz=float(a4)/float(oct)
			else:
				hz=float(a4)*float(oct)
		else:
			hz=hz*tet12
		notes[cur]={}
		notes[cur]["freq"]=hz
		notes[cur]["sam"]=make_sample(hz)
		yield()
	return 1337

var ref_period=1.0/rate
func make_sample(freq):
	var phase
	var samples=0
	var period=1.0/freq
	var duration=0.0
	var cyc=int(freq)
	var i16
	var wvfm
	var lsb
	var msb
	var data=PoolByteArray()
	var sample=AudioStreamSample.new()
	var phT
	var wvSine=0.0
	var wvPulse=0.0
	var wvTooth=0.0
	var tDuty=0.0
	var mDuty=0.0
	var pDuty=0.0
	var lfo=1.0625
	while duration<(cyc*period):
		tDuty=(duration*lfo)/float(cyc*period)
		if tDuty>1.0: tDuty-=float(int(tDuty))
		mDuty=0.0
		if tDuty<.5:
			mDuty=tDuty*2.0
		if tDuty>=.5:
			mDuty=(0.5-min(tDuty-.5,.5))*2.0
		pDuty=1.0-mDuty
		phase=TAU*duration/period
		phT=float(int(phase/TAU))*TAU
		phT=phase-phT
		wvSine=sin(phase)/4.0					 	# sine
		wvTooth=((phT/PI)-1.0)/4.0				# sawtooth
		wvPulse=(-.25 if phT<=PI else .25) 	# square
		wvfm=pDuty*((wvPulse+wvTooth)/2.0)+mDuty*((wvSine+wvPulse)/2.0)
		if wvfm<0:
			i16=int(32768*wvfm)
		else:
			i16=int(32767*wvfm)
		if i16<0: i16+=65536
		lsb=int(i16%256)
		msb=int(i16/256)
		data.append(lsb)
		data.append(msb)
		duration+=ref_period
		samples+=1
	sample.data=data
	sample.format=AudioStreamSample.FORMAT_16_BITS
	sample.loop_mode=AudioStreamSample.LOOP_FORWARD
	sample.loop_begin=0
	sample.loop_end=int(48000*cyc*period)-1
	sample.mix_rate=rate
	sample.stereo=false
	return sample



func parseCmd(stmt):
	var rc={}
	var cmd=stmt
	var num=0
	while cmd[0] in digits:
		num=(10*num)+int(cmd[0])
		cmd=cmd.substr(1,cmd.length()-1)
	rc["num"]=num
	rc["cmd"]=cmd
	return rc

var frmMod
var tickCnt
var sentStop=false
var curs=Array()
signal row
func player():
	var chnSt
	var pair
	var cmd
	var num
	if playState==null:
		#print("init")
		frmMod=-1
		tickCnt=-1
		playState={}
		for chn in range(4):
			playState[chn]={}
			chnSt=playState[chn]
			chnSt["cmd"]=c[chn]
			chnSt["pos"]=0
			chnSt["rst"]=0
			chnSt["rpt"]=0
			chnSt["dur"]=0
			chnSt["run"]=true
			chnSt["vol"]=-12
			chnSt["pretty"]="==="
			chnSt["cur"]="#"
			curs.append("#")
	else:
		frmMod+=1
		while frmMod>=FrmPer64th:
			frmMod-=FrmPer64th
			tickCnt+=1
			for chn in range(4):
				chnSt=playState[chn]
				chnSt["pretty"]="---"
				if chnSt["run"]:
					chnSt["pretty"]="   "
					if chnSt["dur"]>0:
						chnSt["dur"]-=1
					else:
						if chnSt["pos"]>=chnSt["cmd"].size():
							curs[chn]="#"
							chnSt["run"]=false
							audio[chn].stop()
							audio[chn].stream=silence
							audio[chn].play()
							continue
						pair=parseCmd(chnSt["cmd"][chnSt["pos"]])
						cmd=pair["cmd"]
						num=pair["num"]
						if cmd=="[":
							chnSt["pos"]+=1
							chnSt["rst"]=chnSt["pos"]
							chnSt["rpt"]=0
							pair=parseCmd(chnSt["cmd"][chnSt["pos"]])
							cmd=pair["cmd"]
							num=pair["num"]
						if cmd=="]":
							if chnSt["rpt"]<(num-1):
								chnSt["rpt"]+=1
								chnSt["pos"]=chnSt["rst"]
								pair=parseCmd(chnSt["cmd"][chnSt["pos"]])
								cmd=pair["cmd"]
								num=pair["num"]
							else:
								chnSt["pos"]+=1
								if chnSt["pos"]>=chnSt["cmd"].size():
									chnSt["run"]=false
									audio[chn].stop()
									audio[chn].stream=silence
									audio[chn].play()
									chnSt["pretty"]="---"
									curs[chn]="#"
									continue
								else:
									pair=parseCmd(chnSt["cmd"][chnSt["pos"]])
									cmd=pair["cmd"]
									num=pair["num"]
						if not cmd in ["[","]"]:
							#print("ch",chn,": ",pair)
							chnSt["dur"]=num-1
							chnSt["pos"]+=1
							if cmd=="R":
								chnSt["pretty"]="==="
								audio[chn].stop()
								audio[chn].stream=silence
								audio[chn].play()
								curs[chn]="-"
							else:
								chnSt["pretty"]=cmd
								while len(chnSt["pretty"])<3:
									chnSt["pretty"]+=" "
								audio[chn].stop()
								audio[chn].volume_db=chnSt["vol"]
								audio[chn].stream=notes[note2num(cmd)]["sam"]
								audio[chn].play()
								curs[chn]=cmd
			var all_off=true
			for ch in range(4):
				if curs[ch]!="#":
					all_off=false
			if !all_off:
				emit_signal("row",tickCnt,curs)
			else:
				if !sentStop:
					sentStop=true
					emit_signal("row",tickCnt,curs)
