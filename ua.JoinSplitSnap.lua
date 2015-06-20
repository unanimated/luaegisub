-- Manual: http://unanimated.xtreemhost.com/ts/scripts-manuals.htm#join

-- JOIN
-- joins selected lines or one selected line with the following line. it's a combination of "Join (concatenate)" and "Join (keep first)"
-- if the text (without tags) is the same on all lines, then it's "keep first"
-- if different, it's "concatenate" for 2 lines, but it nukes some redundant tags from the 2nd line
-- if it's more than 2 lines with different text, you get to choose to join them with only tags from the first one, or from all
-- when keeping tags, it nukes ones that should only be once in a line plus some others detected as redundant (not very sophisticated)
-- set a simple hotkey to use when timing

-- SPLIT
-- splits a line at linebreak (use together with Line Breaker with simple hotkeys under Subtitle Grid)
-- it's similar to "Split at cursor (estimate times)", but uses \N as "cursor"
-- compared to the inbuilt tool, the times estimation works better, you keep tags for both resulting lines, and it snaps to keyframes (6-frame range)

-- SNAP
-- snaps to keyframes or adjacent lines based on the settings below


-- KF SNAPPING SETTINGS

kfsb=6		-- starts before
kfeb=10		-- ends before
kfsa=8		-- starts after
kfea=15		-- ends after

-- END OF SETTINGS

script_name="Join / Split / Snap"
script_description="Joins lines / splits lines / snaps to keyframes"
script_author="unanimated"
script_version="1.2"
script_namespace="ua.JoinSplitSnap"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="1.2.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

function join(subs,sel)
    go=0
    morethan2=nil
    if #sel>1 then
	go=1	st=10000000   et=0
	for z,i in ipairs(sel) do
	  l=subs[i]	 t=l.text	ct=t:gsub("%b{}","")
	  stm=l.start_time etm=l.end_time
	  if stm<st then st=stm end
	  if etm>et then et=etm end
	  if z>1 and ct~=ref then go=0 end
	  ref=ct
	end
    end
    if go==1 then
	l=subs[sel[1]]
	l.start_time=st	l.end_time=et
	subs[sel[1]]=l
	for i=#sel,2,-1 do subs.delete(sel[i]) end
	sel={sel[1]}
    else
	if sel[1]==#subs then aegisub.log("Nothing to join with.") aegisub.cancel() end
	if #sel==1 then table.insert(sel,sel[1]+1) end
	if #sel>2 then morethan2=true
		dialog={{class="label",label="Join "..#sel.." lines with different text?\n\nOption 1: join, keeping only tags from first line\n\nOption 2: join and try to preserve relevant tags"}}
		buttons={"Join, no tags","Join, with tags","Cancel"}
		press=aegisub.dialog.display(dialog,buttons,{close='Cancel'})
		if press=="Join, no tags" then nt="" et=0
		  for i=2,#sel do
		    l=subs[sel[i]] t=l.text:gsub("%b{}",""):gsub(" *\\N *"," ") nt=nt.." "..t
		    if l.end_time>et then et=l.end_time end
		  end
		  l=subs[sel[1]] l.text=l.text:gsub(" *\\N *"," ")..nt l.end_time=et subs[sel[1]]=l
		  for i=#sel,2,-1 do subs.delete(sel[i]) table.remove(sel,i) end
		end
		if press=="Join, with tags" then
		  repeat join2(subs,sel) until #sel==1
		end
	else
	join2(subs,sel)
	end
    end
    aegisub.set_undo_point(script_name)
    return sel
end

function join2(subs,sel)
        l=subs[sel[1]]		t=l.text	ct=t:gsub("%b{}","")
	l2=subs[sel[2]]		t2=l2.text	ct2=t2:gsub("%b{}","")	ct3=t2:gsub("^{[^}]-}",""):gsub("^%- ","")
	if ct~=ct2 or morethan2 then
	  t=t:gsub("{[Jj][Oo][Ii][Nn]}%s*$","")
	  tt=t:match("^{\\[^}]-}") or ""
	  tt2=t2:match("^{\\[^}]-}") or ""
	  tt1=tt:gsub("\\an?%d",""):gsub("\\%a%a+%b()",""):gsub("\\q%d",""):gsub("\\t%([^\\]*%)",""):gsub("{}","")
	  tt2=tt2:gsub("\\an?%d",""):gsub("\\%a%a+%b()",""):gsub("\\q%d",""):gsub("\\t%([^\\]*%)",""):gsub("{}","")
	  if tt==tt2 then t=t.." "..ct3
	  elseif not tt1:match("\\t") and not tt2:match("\\t") then
	    for tag in tt1:gmatch("\\[^\\}]+") do
		tt2=tt2:gsub(esc(tag),"")
	    end
	    t=t.." "..tt2..ct3
	  else
	    t=t.." "..tt2..ct3
	  end
	  t=t:gsub("%.%.%. %.%.%."," "):gsub("(%a%-) (%a)","%1%2"):gsub("\" \""," "):gsub(" *\\N *"," ")
	  :gsub("(\\i1.-)\\i(%d)",function(i,n) if n=="1" then return i else return i..n end end)
	  :gsub("{}","")
	end
	if l2.end_time>l.end_time then l.end_time=l2.end_time end
	subs.delete(sel[2])
	l.text=t
        subs[sel[1]]=l
	if #sel>1 then table.remove(sel,2)
	  if #sel>1 then for s=2,#sel do sel[s]=sel[s]-1 end end
	end
	return subs[sel[1]]
end

function split(subs,sel)
	for i=#sel,1,-1 do
	line=subs[sel[i]]
	text=line.text
	c=0

	    if not text:match("\\N") and sel[i]<#subs then
		nextline=subs[sel[i]+1]
		if text:match(" that$") then text=text:gsub(" that$","") nextline.text="that "..nextline.text c=1 end
		if text:match(" and$") then text=text:gsub(" and$","") nextline.text="and "..nextline.text c=1 end
		if text:match(" but$") then text=text:gsub(" but$","") nextline.text="but "..nextline.text c=1 end
		if text:match(" so$") then text=text:gsub(" so$","") nextline.text="so "..nextline.text c=1 end
		if text:match(" to$") then text=text:gsub(" to$","") nextline.text="to "..nextline.text c=1 end
		if text:match(" when$") then text=text:gsub(" when$","") nextline.text="when "..nextline.text c=1 end
		if text:match(" with$") then text=text:gsub(" with$","") nextline.text="with "..nextline.text c=1 end
		if text:match(" the$") then text=text:gsub(" the$","") nextline.text="the "..nextline.text c=1 end
		subs[sel[i]+1]=nextline
	    end

	    if c==0 then
		text=text:gsub("{SPLIT}","{split}")
		if not text:match("\\N") and text:match("{split}") then text=text:gsub("{split}","\\N") end
		if not text:match("\\N") and text:match("%- ") then text=text:gsub("(.)%- (.-)$","%1\\N- %2") end
		if not text:match("\\N") and text:match("%. [{\\\"]?%w") then
			text=text
			:gsub("([MD][rs]s?)%. ","%1## ")
			:gsub("^(.-)%. ","%1. \\N")
			:gsub("## ",". ") end
		if not text:match("\\N") and text:match("[%?!] {?%w") then text=text:gsub("^(.-)([%?!]) ","%1%2 \\N") end
		if not text:match("\\N") and text:match(", {?%w") then text=text:gsub("^(.-), ","%1, \\N") end
		if text:match("\\N") and text:match("{split}") then text=text:gsub("\\N","/N"):gsub("{split}","\\N") end
	    end

	    if not text:match("\\N") and not text:match(" ") then text=text.."\\N"..text end

	    if text:match("\\N") then
		text=text:gsub("^%- (.-\\N)%- ","%1"):gsub("^({\\i1})%- (.-\\N)%- ","%1%2"):gsub("({\\i1})%- ","%1"):gsub("{add}","")
		line2=line
		start=line.start_time
		endt=line.end_time
		dur=endt-start
		ms2fr=aegisub.frame_from_ms
		fr2ms=aegisub.ms_from_frame
		keyframes=aegisub.keyframes()
		startf=ms2fr(start)
		endf=ms2fr(endt)
		diff=250
		diffe=250
		startkf=keyframes[1]
		endkf=keyframes[#keyframes]
		txt=text:gsub("%b{}","")
		one,two=txt:match("^(.-)\\N(.*)")
		c1=one:len()
		c2=two:len()
		f=c1/(c1+c2)
		if dur<3200 then f=(f+0.5)/2 end
		if dur<2000 then f=0.5 end
		if f<0.2 then f=0.2 end
		if f>0.8 then f=0.8 end

		-- line 2
		aftern=text:match("\\N%s*(.*)")
		tags=text:match("^{\\[^}]-}") if tags and not aftern:match("^{\\[^}]-}") then aftern=tags..aftern end
		line2.text=aftern:gsub("/N","\\N")
		line2.start_time=start+dur*f
		start2f=ms2fr(line2.start_time)
		for k,kf in ipairs(keyframes) do
			if kf>=start2f-6 and kf<=start2f+6 then
			tdiff=math.abs(start2f-kf)
			if tdiff<=diff then diff=tdiff startkf=kf end
			start2=fr2ms(startkf)
			line2.start_time=start2
			end
		end
		subs.insert(sel[i]+1,line2)

		-- line 1
		text=text:gsub("^(.-)%s?\\N(.*)","%1"):gsub("/N","\\N")
		line.start_time=start
		line.end_time=start+dur*f
		end1f=ms2fr(line.end_time)
		for k,kf in ipairs(keyframes) do
			if kf>=end1f-12 and kf<=end1f+6 then
			tdiff=math.abs(end1f-kf)
			if tdiff<diffe then diffe=tdiff endkf=kf end
			endt=fr2ms(endkf)
			if endt-start>500 then line.end_time=endt end
			end
		end
	    end

	line.text=text
	subs[sel[i]]=line
	end
	for s=#sel,1,-1 do sel[s]=sel[s]+s-1 end
	aegisub.set_undo_point(script_name)
	return sel
end

function keyframesnap(subs,sel)
    keyframes=aegisub.keyframes()
    ms2fr=aegisub.frame_from_ms
    fr2ms=aegisub.ms_from_frame
    if subs[sel[1]].effect=="gui" then
	gui={
	{x=0,y=0,class="label",label="Starts before "},
	{x=0,y=1,class="label",label="Ends before "},
	{x=0,y=2,class="label",label="Starts after "},
	{x=0,y=3,class="label",label="Ends after "},
	{x=1,y=0,class="floatedit",name="sb",value=6},
	{x=1,y=1,class="floatedit",name="eb",value=10},
	{x=1,y=2,class="floatedit",name="sa",value=8},
	{x=1,y=3,class="floatedit",name="ea",value=15}
	}
	buttons={"OK","Cancel"}
	pressed,res=aegisub.dialog.display(gui,buttons,{ok='OK',close='Cancel'})
	if pressed=="Cancel" then aegisub.cancel() end
	kfsb=res.sb
	kfeb=res.eb
	kfsa=res.sa
	kfea=res.ea
    end

    for z,i in ipairs(sel) do
	line=subs[i]
	start=line.start_time
	endt=line.end_time
	startn=start
	endtn=endt
	startf=ms2fr(start)
	endf=ms2fr(endt)
	diff=250	diffe=250
	KS=0		KE=0
	startkf=keyframes[1]
	endkf=keyframes[#keyframes]
	
	-- snap to keyframes
	for k,kf in ipairs(keyframes) do
	    if kf>=startf-kfsa and kf<=startf+kfsb then
		sdiff=math.abs(startf-kf)
		if sdiff<=diff then diff=sdiff startkf=kf startn=fr2ms(startkf) KS=1 end
	    end
	    if kf>=endf-kfea and kf<=endf+kfeb then
		ediff=math.abs(endf-kf)
		if ediff<diffe then diffe=ediff endkf=kf endtn=fr2ms(endkf) KE=1 end
	    end
	end
	
	-- snap to adjacent lines
	if KS==0 then
	  if subs[i-1].class=="dialogue" then
	    l2=subs[i-1]
	    prevend=l2.end_time
	    pref=ms2fr(prevend)
	    sdiff=startf-pref
	    if sdiff<=kfsa and sdiff>0 or sdiff<0 and sdiff<=kfsb then
		startn=prevend
		l2.end_time=fr2ms(ms2fr(prevend))
		subs[i-1]=l2
	    end
	 end
	end
	if KE==0 then
	  if subs[i+1] then
	    l2=subs[i+1]
	    nextart=l2.start_time
	    nesf=ms2fr(nextart)
	    ediff=nesf-endf
	    if ediff<=kfea and ediff>0 or ediff<0 and ediff<=kfeb then
		endtn=nextart
		l2.start_time=fr2ms(ms2fr(nextart))
		subs[i+1]=l2
	    end
	  end
	end
	
	if startn==nil then startn=start end
	if endtn==nil then endtn=endt end
	if startn~=line.start_time then startn=fr2ms(ms2fr(startn)) end
	if endtn~=line.end_time then endtn=fr2ms(ms2fr(endtn)) end
	line.start_time=startn
	line.end_time=endtn
	subs[i]=line
    end
    aegisub.set_undo_point(script_name)
    return sel
end

function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function logg(m) m=m or "nil" aegisub.log("\n "..m) end

if haveDepCtrl then
  depRec:registerMacros({
	{"Join-Split-Snap/Join","Joins lines",join},
	{"Join-Split-Snap/Split","Splits Lines",split},
	{"Join-Split-Snap/Snap to keyframes","Snaps to nearby keyframes",keyframesnap},
  },false)
else
	aegisub.register_macro("Join-Split-Snap/Join","Joins lines",join)
	aegisub.register_macro("Join-Split-Snap/Split","Splits Lines",split)
	aegisub.register_macro("Join-Split-Snap/Snap to keyframes","Snaps to nearby keyframes",keyframesnap)
end