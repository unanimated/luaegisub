-- Manual: http://unanimated.hostfree.pw/ts/scripts-manuals.htm#shiftcut

script_name="ShiftCut"
script_description="Time Machine. finish sentences before they started. Travels back in time to"
script_author="unanimated"
script_version="3.1"
script_namespace="ua.ShiftCut"

re=require'aegisub.re'

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="3.1.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

function shiftcut(subs,sel,act)
	ADD=aegisub.dialog.display
	ak=aegisub.cancel
	alog=aegisub.log
	konfig(subs,sel,act)
	aegisub.set_undo_point(script_name)
	if res.slct=="Sel. + onward" then return sel2 end
	return sel
end

function konfig(subs,sel,act)
BIAS={"0","0.1","0.2","0.3","0.4","0.5","0.6","0.7","0.8","0.9","1"}
kf_snap_presets={"1,1,1,1","2,2,2,2","6,6,6,10","6,6,8,12","6,6,10,12","6,10,8,12","8,8,8,12","0,0,0,10","7,12,10,13"}
	style(subs,sel)
	GUI={
	{x=0,y=0,width=2,class="label",label="ShiftCut v"..script_version},
	{x=2,y=0,width=2,class="dropdown",name="slct",items={"Apply to selected","Apply to all lines","Sel. + onward"},value="Apply to selected"},
	
	{x=0,y=1,width=2,class="label",label="S&tyles to aply to:"},
	{x=2,y=1,width=2,class="dropdown",name="stail",items=styles,value="All Default",hint="limit what styles will be affected"},
	{x=4,y=1,width=3,class="edit",name="plustyle",value="",hint="Additional style"},
	
	{x=4,y=0,width=2,class="checkbox",name="info",label="I&nfo",hint="show info about linked/snapped lines"},
	{x=6,y=0,width=3,class="checkbox",name="mark",label="&Mark changed lines",hint="linking/snapping - mark changed lines in effect"},
	{x=9,y=0,class="checkbox",name="herp",label="&H.E.L.P.",hint="Use with anything not Cancel."},
	{x=9,y=1,class="checkbox",name="rem",label="&Remember last"},

	-- shift
	{x=0,y=2,class="label",label="SHIFT"},
	{x=1,y=2,class="dropdown",name="back",items={"backward","forward"},value="backward"},
	{x=2,y=2,width=2,class="floatedit",name="shifft",value=0},
	{x=4,y=2,class="label",label="ms /"},
	{x=5,y=2,class="checkbox",name="fshift",label="fr",hint="frames instead of ms"},
	{x=6,y=2,class="checkbox",name="endshit",label="by end ",hint="Shift sel. lines by end of active line\nto current video frame"},
	
	{x=0,y=3,width=2,class="checkbox",name="byframe",label="by frames per lines",hint="shift more each line\n(this disables the line above)"},
	{x=2,y=3,width=2,class="floatedit",name="frshift",value=1,min=1,hint="shift by __ frames..."},
	{x=4,y=3,width=3,class="floatedit",name="shiftlines",value=1,min=1,hint="...each __ lines"},


	-- add/cut
	{x=0,y=4,width=2,class="checkbox",name="IN",label="Add lead &in"},
	{x=2,y=4,width=2,class="floatedit",name="inn",value=0},
	{x=4,y=4,class="label",label="ms /"},
	{x=5,y=4,class="checkbox",name="fin",label="fr",hint="frames instead of ms"},
	{x=6,y=4,class="checkbox",name="cutin",label="Cut in",hint="cut (make shorter) lead in"},
	
	{x=0,y=5,width=2,class="checkbox",name="OUT",label="Add lead &out"},
	{x=2,y=5,width=2,class="floatedit",name="utt",value=0},
	{x=4,y=5,class="label",label="ms /"},
	{x=5,y=5,class="checkbox",name="fout",label="fr",hint="frames instead of ms"},
	{x=6,y=5,class="checkbox",name="cutout",label="Cut out",hint="cut (make shorter) lead out"},
	
	{x=0,y=6,width=3,class="checkbox",name="preventcut",label="prevent overlaps from adding leads   ",value=true},
	{x=3,y=6,width=4,class="checkbox",name="holdkf",label="don't add leads on KF"},

	-- linking
	{x=0,y=7,width=2,class="label",label="Line linking:  Max gap:"},
	{x=2,y=7,width=2,class="floatedit",name="link",value=400,min=0},
	{x=4,y=7,class="label",label="ms   "},
	{x=5,y=7,class="label",label="Bias: "},
	{x=6,y=7,class="dropdown",name="bias",items=BIAS,value="0.8",hint="higher number=closer to 2nd line"},

	-- overlaps
	{x=0,y=8,width=2,class="checkbox",name="over",label="&Fix overlaps up to:",
		hint="This is part of line linking.\nIf you want only overlaps, set linking gap to 0."},
	{x=2,y=8,width=2,class="floatedit",name="overlap",value=500,min=0 },
	{x=4,y=8,class="label",label="ms   "},
	{x=5,y=8,class="label",label="Bias: "},
	{x=6,y=8,class="dropdown",name="bios",items=BIAS,value="0.5",hint="higher number=closer to 2nd line"},

	-- keyframes
	{x=8,y=2,class="label",label="Keyframes"},
	{x=9,y=2,class="checkbox",name="prevent",label="Prevent overlaps",value=true},
	
	{x=8,y=3,class="label",label="Starts before:"},
	{x=8,y=4,class="label",label="Ends before:"},
	{x=8,y=5,class="label",label="Starts after:"},
	{x=8,y=6,class="label",label="Ends after:"},
	
	{x=9,y=3,class="floatedit",name="sb",value=0,min=0,max=250,hint="frames, not ms"},
	{x=9,y=4,class="floatedit",name="eb",value=0,min=0,max=250,hint="frames, not ms"},
	{x=9,y=5,class="floatedit",name="sa",value=0,min=0,max=250,hint="frames, not ms"},
	{x=9,y=6,class="floatedit",name="ea",value=0,min=0,max=250,hint="frames, not ms"},
	
	{x=8,y=7,class="checkbox",name="pres",label="&Preset:",value=true},
	{x=9,y=7,class="dropdown",name="preset",items=kf_snap_presets,value="6,10,8,12"},
	
	{x=8,y=8,class="label",label="Max CPS:"},
	{x=9,y=8,class="floatedit",name="cps",value=24,min=0,hint="don't snap if CPS would exceed the limit (0=disable)"},
	{x=7,y=2,class="label",label=" "},
	}
	loadconfig()
	if res and res.rem then
	  for key,val in ipairs(GUI) do
	    if val.name then val.value=res[val.name] end
	  end
	end
	P,res=ADD(GUI,{"Lea&d in/out","&Link lines","&Shift times","&Keyframe snap","&All","Save &config","Cancel"},{cancel='Cancel'})
	if P=="Cancel" then ak() end
	if res.herp then P=1 herpderp() end
	if res.slct=="Apply to all lines" then sel=selectall(subs,sel) end
	if res.slct=="Sel. + onward" then
		sel2={} for s=1,#sel do table.insert(sel2,sel[s]) end
		for s=sel[#sel]+1,#subs do table.insert(sel,s) end
	end
	keyframes=aegisub.keyframes()
	ms2fr=aegisub.frame_from_ms
	fr2ms=aegisub.ms_from_frame
	
	if P=="Lea&d in/out" or P=="&All" then 
	    if res.IN or res.cutin then cutin(subs,sel) end
	    if res.OUT or res.cutout then cutout(subs,sel) end
	end
	if P=="&Shift times" then if res.endshit then endshift(subs,sel,act) else shiift(subs,sel) end end
	if P=="&Link lines" or P=="&All" then linklines(subs,sel) end
	if P=="&Keyframe snap" or P=="&All" then keyframesnap(subs,sel) end
	
	if res.info then
	    if P=="&Link lines" or P=="&All" then alog("\n Linked lines: "..linx) end
	    if P=="&Link lines" and res.over or P=="&All" and res.over then alog("\n Overlaps fixed: "..overl) end
	    if P=="&Keyframe snap" or P=="&All" then alog("\n Lines snapped to keyframes: "..snapd) end
	end
	if P=="Save &config" then saveconfig() end
end

function style(subs,sel)
	styles={"All","All Default","Default+Alt","----------------"}
	stchk='/'
	for z,i in ipairs(sel) do
		st=subs[i].style
		if not stchk:match('/'..esc(st)..'/') then stchk=stchk..st..'/' table.insert(styles,st) end
	end
	return styles
end

function runcheck()
	run=0
	if res.stail=="All" then run=1 end
	if res.stail=="All Default" and line.style:match("Defa") then run=1 end
	if res.stail=="Default+Alt" and line.style:match("Defa") then run=1 end
	if res.stail=="Default+Alt" and line.style:match("Alt") then run=1 end
	if res.stail==line.style then run=1 end
	if line.style==res.plustyle then run=1 end
	return run
end

--	Lead in		--
function cutin(subs,sel)
	if res.fin then vfcheck() end
	for z,i in ipairs(sel) do
		line=subs[i]
		inn=round(res.inn)
		start=line.start_time
		endt=line.end_time
		prevline=subs[i-1]
		if prevline.class=="dialogue" then prevend=prevline.end_time else prevend=0 end
		run=runcheck()
		
		kfr=1
		if res.holdkf then
			startf=ms2fr(start)
			for k,kf in ipairs(keyframes) do
				if kf==startf then kfr=0 break end
			end
		end
	    
	    if run==1 and kfr==1 then
		if res.fin then start=ms2fr(start) endt=ms2fr(endt) prevend=ms2fr(prevend) end	-- by frames
		if res.cutin then	-- cut
			if (start+inn)<endt then start=(start+inn) else start=endt end
		else
			start=(start-inn)	-- add
			if res.preventcut and start<prevend then start=prevend end
		end
		if res.fin then start=fr2ms(start)
		else start=fr2ms(ms2fr(start)) or start end
		line.start_time=start
		subs[i]=line
	    end
	end
end

--	Lead out	--
function cutout(subs,sel)
	if res.fout then vfcheck() end
	for z,i in ipairs(sel) do
		line=subs[i]
		ut=round(res.utt)
		start=line.start_time
		endt=line.end_time
		if i<#subs then nextline=subs[i+1] nextart=nextline.start_time end
		run=runcheck()
		
		kfr=1
		if res.holdkf then
			endf=ms2fr(endt)
			for k,kf in ipairs(keyframes) do
				if kf==endf then kfr=0 break end
			end
		end
	    
	    if run==1 and kfr==1 then
		if res.fout then start=ms2fr(start) endt=ms2fr(endt) nextart=ms2fr(nextart) end	-- by frames
		if res.cutout then	-- cut
			if (endt-ut)>start then endt=(endt-ut) else endt=start end
		else
			endt=(endt+ut)	-- add
			if res.preventcut and i<#subs and endt>nextart and start<nextart then endt=nextart end
		end
		if res.fout then endt=fr2ms(endt)
		else endt=fr2ms(ms2fr(endt)) or endt end
		line.end_time=endt
		subs[i]=line
	    end
	end
end

--	Shifting	--
function shiift(subs,sel)
    if res.byframe or res.fshift then vfcheck() end
    for z,i in ipairs(sel) do
	line=subs[i]
	shift=res.shifft
	start=line.start_time
	endt=line.end_time
	run=runcheck()
	fram=math.floor(res.frshift+0.5)
	lin=math.floor(res.shiftlines+0.5)
	f=math.ceil(z/lin)
	
	if run==1 and not res.byframe then
		if res.fshift then start=ms2fr(start) endt=ms2fr(endt) end	-- by frames
		if res.back=="backward" then
			start=(start-shift)
			endt=(endt-shift)
		else
			start=(start+shift)
			endt=(endt+shift)
		end
		if res.fshift then
			start=fr2ms(start)
			endt=fr2ms(endt)
		else
			start=fr2ms(ms2fr(start)) or start
			endt=fr2ms(ms2fr(endt)) or endt
		end
		line.start_time=start
		line.end_time=endt
		subs[i]=line
	end
	-- by frames per lines
	if run==1 and res.byframe then
		SFr=(ms2fr(start))+fram*f
		EFr=(ms2fr(endt))+fram*f
		line.start_time=fr2ms(SFr)
		line.end_time=fr2ms(EFr)
		subs[i]=line
	end
    end
end

function endshift(subs,sel,act)
	vfcheck()
	FR=ms2fr(subs[act].end_time)
	dist=vframe-FR+1
	for z,i in ipairs(sel) do
		line=subs[i]
		SF=ms2fr(line.start_time)
		line.start_time=fr2ms(SF+dist)
		EF=ms2fr(line.end_time)
		line.end_time=fr2ms(EF+dist)
		subs[i]=line
	end
end

function vfcheck()
	if aegisub.project_properties==nil then
		t_error("Current frame unknown.\nProbably your Aegisub is too old.\nMinimum required: r8374.",true)
	end
	vframe=aegisub.project_properties().video_position
	if vframe==nil or fr2ms(1)==nil then t_error("Current frame unknown. Probably no video loaded.",true) end
end

--	Linking		--
function linklines(subs,sel)
	marker=0	linx=0	overl=0
	for z,i in ipairs(sel) do
	    line=subs[i]
		lnk=res.link
		start=line.start_time
		endt=line.end_time
		s1=fr2ms(ms2fr(start)) or start
		e1=fr2ms(ms2fr(endt)) or endt
		if i<#subs then nextline=subs[i+1] nextart=nextline.start_time nextf=ms2fr(nextart) end
		if marker==1 then start=start-diff2 end	-- link line 2
		if markover==1 then start=start+diffo end	-- overlap line 2
		marker=0
		markover=0
		run=runcheck()
	    if res.holdkf then
		endf=ms2fr(endt)
		for k,kf in ipairs(keyframes) do
		    if kf==endf or kf==nextf then run=0 break end
		end
	    end
	    
	    if run==1 then
		-- linking
		if lnk>0 and nextart>endt and nextart-endt<lnk and z~=#sel then
		 gap=nextart-endt
		 diff=gap*res.bias
		 endt=endt+diff
		 diff2=gap-diff
		 marker=1
		end
		
		-- overlaps
		if res.over and endt>nextart and endt-nextart<res.overlap and z~=#sel then
		lap=endt-nextart
		diffo=lap*res.bios
		endt=nextart+diffo
		markover=1
		end
		start=fr2ms(ms2fr(start)) or start
		endt=fr2ms(ms2fr(endt)) or endt
		line.start_time=start
		line.end_time=endt
		if res.mark then if line.start_time~=s1 or line.end_time~=e1 then line.effect=line.effect.."[linked]" end end
		if res.info and marker==1 then linx=linx+1 end
		if res.info and markover==1 then overl=overl+1 end
		subs[i]=line
	    end
	end
end

--	Snapping	--
function keyframesnap(subs,sel)
snapd=0
    if res.pres then kfsb,kfeb,kfsa,kfea=res.preset:match("(%d+),(%d+),(%d+),(%d+)")
	kfsb=tonumber(kfsb)
	kfeb=tonumber(kfeb)
	kfsa=tonumber(kfsa)
	kfea=tonumber(kfea)
    else
	kfsb=res.sb kfeb=res.eb kfsa=res.sa kfea=res.ea
    end
	for z,i in ipairs(sel) do aegisub.progress.title(string.format("Snapping Line %d/%d",z,#sel))
	    line=subs[i]
	    run=runcheck()
	    
	    if run==1 then
	    -- snapping to keyframes
	    
		start=line.start_time		-- start time
		endt=line.end_time		-- end time
		startemp=start
		endtemp=endt
		if z~=#sel then nextline=subs[i+1]
		nextart=nextline.start_time end
		if z~=1 then prevline=subs[i-1]
		prevend=prevline.end_time else prevend=0 end
		
		startf=ms2fr(start)		-- startframe
		endf=ms2fr(endt)		-- endframe
		fr1=endf-startf
		
		diff=250
		diffe=250
		startkf=keyframes[1]
		endkf=keyframes[#keyframes]
		
		-- check for nearby keyframes
		for k,kf in ipairs(keyframes) do
		
			-- startframe
			if kf>=startf-kfsa and kf<=startf+kfsb then
			tdiff=math.abs(startf-kf)
			if tdiff<=diff then diff=tdiff startkf=kf end
			startemp=fr2ms(startkf)
			
			stopstart=0
			if res.prevent and z~=1 and startemp<prevend and start>=prevend then stopstart=1 end
			if stopstart==0 then start=startemp end
			end
			
			-- endframe
			if kf>=endf-kfea and kf<=endf+kfeb then
			tdiff=math.abs(endf-kf)
			if tdiff<diffe then diffe=tdiff endkf=kf end
			endtemp=fr2ms(endkf)
			
			stopend=0
			if res.prevent and z~=#sel and endtemp>nextart and endkf-endf>kfsb then stopend=1 end
			if stopend==0 then endt=endtemp end
			end
		end
		
		-- CPS check
		startok=true
		endok=true
		if res.cps>0 then
			char=line.text:gsub("{[^}]-}",""):gsub("\\[Nn]","*"):gsub("%s?%*+%s?"," "):gsub("[%s%p]","")
			letrz=re.find(char,".")
			if letrz then linelen=#letrz else linelen=0 end
			startf2=ms2fr(start)
			endf2=ms2fr(endt)
			dura1=(line.end_time-start)/1000
			cps1=math.ceil(linelen/dura1)
			dura2=(endt-start)/1000
			if startf2-startf>3 and line.start_time>=prevend and cps1>res.cps then startok=false line.effect=line.effect.."[cps1]" dura2=(endt-line.start_time)/1000 end
			cps2=math.ceil(linelen/dura2)
			if endf-endf2>3 and cps2>res.cps then endok=false line.effect=line.effect.."[cps2]" end
		end
		
		if startok then line.start_time=start end
		if endok and endt-start>450 then line.end_time=endt end
		startf2=ms2fr(line.start_time)	    endf2=ms2fr(line.end_time)
		if res.mark then if startf2~=startf or endf2~=endf then line.effect=line.effect.."[snapped]" end end
		if res.info then if startf2~=startf or endf2~=endf then snapd=snapd+1 end end
		subs[i]=line
	    end
	end
end

function selectall(subs,sel)
	sel={}
	for i=1,#subs do
		if subs[i].class=="dialogue" then table.insert(sel,i) end
	end
	return sel
end

--	reanimatools	---------------------------------------------------------------------------
function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function round(n,dec) dec=dec or 0 n=math.floor(n*10^dec+0.5)/10^dec return n end
function logg(m) m=tf(m) or "nil" aegisub.log("\n "..m) end
function t_error(message,cancel) ADD({{class="label",label=message}},{"OK"},{close='OK'}) if cancel then ak() end end


HHH=[[
"Apply to selected / Apply to all lines" - This is obvious.
"Sel. + onward" - Apply to selection and onward.

"Styles to apply to"
"All Default" applies to all styles with "Defa" in the name.
"Default+Alt" applies to styles with "Defa" or "Alt" in the name, so stuff like "Default Flashback" or "Alternative".
Below that, the menu shows all styles in selected lines.
The box next to it lets you type an additional style you want to include. This may be useful if one of your dialogue styles has an odd naming pattern.

"Info (link/snap)" - For linking and keyframe snapping, this gives you information about how many lines were affected.
This can be useful when applying something to the whole script, unsure whether your settings are a good idea.
If you find no lines were changed, your settings were useless. If too many lines were changed, maybe you did something wrong, etc.

"Mark changed lines" - Same purpose as Info above, but this marks the lines in Effect so that you can check the changes.

"All" - This button applies "Lead in/out", "Link lines", and "Keyframe snap".

"Save config" - Saves your current configuration. This also lets you modify (add/remove) the keyframe presets.

There are 4 extra macros that can be hotkeyed:

"Shift End Link Forward" - Shifts end time by 3 frames forward, along with start time of the following line if linked.
"Shift End Link Backward" - Same but backward.
"Shift Start Link Forward" - Same but start time + end time of previous line.
"Shift Start Link Backward" - You get the idea...
These are equivalents of Ctrl+mouse drag. They can be useful for quick-adjusting the point of linking if for whatever reason you prefer the keyboard over the mouse. More useful for checking/correcting timing rather than timing itself.]]

LEADS=[[
Check lead in or out (or both), set values in milliseconds, go.
"fr" - Shift by frames instead of ms.
Cut in/out - Cut leads. (Line gets shorter.)
"Cut" overrides "Add", so it works even without Add checked.
You can also cut by using Add and negative values.
"Prevent overlaps from adding leads" - This makes sure that applying lead in/out won't create overlaps with adjacent lines.
"Don't add leads on keyframes" - This is useful when you're fixing a script that's already snapped to keyframes.
For example if your timer makes short lead outs, you can add 150ms lead out to all dialogue lines with these 2 checkboxes checked pretty safely (and then Link Lines).
]]

LNK=[[
"Max gap" - Maximum gap between lines to be linked. If the gap is longer, no linking.
"Bias" - Where the lines will be linked. 0.5 is in the midle of the gap. 0.8 means 80% of the gap goes to the first line, 20% to the second.
"Fix overlaps" - This allows you to fix what would be unwanted overlaps. If two consecutive lines overlap by less than this number, they will be made not to, based on the Bias, which works like the one for linking.
You can for example set this to only 50 if you want to just fix accidental 1-frame overlaps. (Assuming "normal" frame rates.)
If you want to only fix overlaps, set linking gap to 0.
]]

SHFT=[[
"Shift backward/forward" - Shift backward or forward by milliseconds.
"fr" - Shift by frames instead of milliseconds.
"by end" - Similar to Aegisub's "shift selection so that the active line starts at current frame", except the active line will end there.
"by frames per lines" - Shifts by a given amount of frames each line (or several lines). With 1/1 and lines with the same timecodes, each new line will be one frame further. With 3/1, each line will be 3 frames further. With 1/2, each two lines will be a frame further. (When this is on, the previous line in the GUI is ignored.)
]]

KFS=[[
This is really just like TPP, so there isn't much to explain.
Keyframe settings are in frames, not ms. Preset numbers are in the same order the GUI shows above it.
Preventing overlaps is something TPP doesn't have, afaik.
Overlaps would happen when lines are linked before a keyframe and your "Ends before" number is higher than "Starts before", for instance.
"Max CPS" - If snapping to a keyframe would result in a CPS higher than the given value, the line won't be snapped. "0" disables this. (Or you can just set a high number.) This setting will allow bleeds if the lines would otherwise be hard to read. However, it only applies if the bleed is over 3 frames because 1/2/3-frame bleeds are just never good and hardly make much difference for readability.]]
function herpderp()
	ADD=aegisub.dialog.display
	ak=aegisub.cancel
	herper={
	{x=0,y=0,width=24,class="label",label=" General Settings"},
	{x=24,y=0,width=18,class="label",label=" Lead In/Out"},
	{x=24,y=14,width=18,class="label",label=" Line Linking"},
	{x=42,y=0,width=20,class="label",label=" Shifting"},
	{x=42,y=11,width=20,class="label",label=" Keyframe Snapping"},
	{x=0,y=1,width=24,height=26,class="textbox",value=HHH},
	{x=24,y=1,width=18,height=13,class="textbox",value=LEADS},
	{x=24,y=15,width=18,height=12,class="textbox",value=LNK},
	{x=42,y=1,width=20,height=10,class="textbox",value=SHFT},
	{x=42,y=12,width=20,height=15,class="textbox",value=KFS},
	}
	Pr=ADD(herper,{"Herp","Derp","Cancer"},{close='Cancer'})
	ak()
end

--	Config Stuff	--
function saveconfig()
scconf="ShiftCut Config:\n\n"
  for k,v in ipairs(GUI) do
    if v.class=="floatedit" or v.class=="dropdown" then
      scconf=scconf..v.name..":"..res[v.name].."\n"
    end
    if v.class=="checkbox" and v.name~="save" then
      scconf=scconf..v.name..":"..tf(res[v.name]).."\n"
    end
    if v.name=="preset" then
	prsts="keyframe presets:"
	for w=1,#v.items do
	    prsts=prsts..v.items[w]..":"
	end
	scconf=scconf..prsts.."\n"
    end
  end
shiftkonfig=aegisub.decode_path("?user").."\\shiftcut.conf"
file=io.open(shiftkonfig,"w")
file:write(scconf)
file:close()
press,rez=ADD({{class="label",label="Config saved to:\n"..shiftkonfig}},{"OK","Add/Delete kf preset","Restore Defaults"},{close='OK'})
    if press=="Add/Delete kf preset" then
	ite=scconf:match("keyframe presets:(.-)\n")
	pressets=""
	for it in ite:gmatch("[^:]+") do
	pressets=pressets..it.."\n"
	end
	repeat
	if press=="Reset" then pressets="1,1,1,1\n2,2,2,2\n6,6,6,10\n6,6,8,12\n6,6,10,12\n6,10,8,12\n8,8,8,12\n0,0,0,10\n7,12,10,13" end
	press,rez=ADD({{class="textbox",x=0,y=0,width=12,height=12,name="addpres",value=pressets}},
	{"Save","Reset"},{ok='Save'})
	until press~="Reset"
	newpres=rez.addpres.."\n"
	newpres=newpres:gsub("\n",":") :gsub("::",":")
	scconf=scconf:gsub(ite,newpres)
	file=io.open(shiftkonfig,"w")
	file:write(scconf)
	file:close()
	ADD({{class="label",label="Saved"}},{"OK"},{close='OK'})
    end
    if press=="Restore Defaults" then
	file=io.open(shiftkonfig,"w")
	file:write("")
	file:close()
	ADD({{class="label",label="Defaults restored"}},{"OK"},{close='OK'})
    end
end

function loadconfig()
sconfig=aegisub.decode_path("?user").."\\shiftcut.conf"
file=io.open(sconfig)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	for k,v in ipairs(GUI) do
	    if v.class=="floatedit" or v.class=="checkbox" or v.class=="dropdown" then
	      if konf:match(v.name) then v.value=detf(konf:match(v.name..":(.-)\n")) end
	    end
	    if v.name=="preset" then ite=konf:match("keyframe presets:(.-)\n")
	      if ite~=nil then
	        v.items={}
	        for it in ite:gmatch("[^:]+") do table.insert(v.items,it) end
	      end
	    end
	end
    end
end

function tf(val)
	if val==true then ret="true"
	elseif val==false then ret="false"
	else ret=val end
	return ret
end

function detf(txt)
	if txt=="true" then ret=true
	elseif txt=="false" then ret=false
	else ret=txt end
	return ret
end


function shiftEF(subs,sel)	SL=3	shiftlink(subs,sel)	end
function shiftEB(subs,sel)	SL=-3	shiftlink(subs,sel)	end

function shiftlink(subs,sel)
ak=aegisub.cancel
ms2fr=aegisub.frame_from_ms
fr2ms=aegisub.ms_from_frame
    for z,i in ipairs(sel) do
	line=subs[i]
	endt=line.end_time
	EF=ms2fr(endt)
	if i<#subs then
		line2=subs[i+1]
		start2=line2.start_time
		SF=ms2fr(start2)
	end
	if SF and SF==EF then SF=SF+SL line2.start_time=fr2ms(SF) subs[i+1]=line2 end
	EF=EF+SL
	line.end_time=fr2ms(EF)
	subs[i]=line
	SF=nil
    end
end

function shiftSF(subs,sel)	SS=3	shiftstart(subs,sel)	end
function shiftSB(subs,sel)	SS=-3	shiftstart(subs,sel)	end

function shiftstart(subs,sel)
ak=aegisub.cancel
ms2fr=aegisub.frame_from_ms
fr2ms=aegisub.ms_from_frame
    for z,i in ipairs(sel) do
	line=subs[i]
	start=line.start_time
	SF=ms2fr(start)
	if subs[i-1].class=="dialogue" then
		line0=subs[i-1]
		end0=line0.end_time
		EF=ms2fr(end0)
	end
	if EF and SF==EF then EF=EF+SS line0.end_time=fr2ms(EF) subs[i-1]=line0 end
	SF=SF+SS
	line.start_time=fr2ms(SF)
	subs[i]=line
	EF=nil
    end
end

if haveDepCtrl then
  depRec:registerMacros({
	{"ShiftCut",script_description,shiftcut},
	{": Non-GUI macros :/ShiftCut: Shift End Link Forward","Shift end linking by 3 frames right",shiftEF},
	{": Non-GUI macros :/ShiftCut: Shift End Link Backward","Shift end linking by 3 frames left",shiftEB},
	{": Non-GUI macros :/ShiftCut: Shift Start Link Forward","Shift start linking by 3 frames right",shiftSF},
	{": Non-GUI macros :/ShiftCut: Shift Start Link Backward","Shift start linking by 3 frames left",shiftSB},
	{": HELP : / ShiftCut","ShiftCut",herpderp},
  },false)
else
	aegisub.register_macro("ShiftCut",script_description,shiftcut)
	aegisub.register_macro(": Non-GUI macros :/ShiftCut: Shift End Link Forward","Shift end linking by 3 frames right",shiftEF)
	aegisub.register_macro(": Non-GUI macros :/ShiftCut: Shift End Link Backward","Shift end linking by 3 frames left",shiftEB)
	aegisub.register_macro(": Non-GUI macros :/ShiftCut: Shift Start Link Forward","Shift start linking by 3 frames right",shiftSF)
	aegisub.register_macro(": Non-GUI macros :/ShiftCut: Shift Start Link Backward","Shift start linking by 3 frames left",shiftSB)
	aegisub.register_macro(": HELP : / ShiftCut","ShiftCut",herpderp)
end