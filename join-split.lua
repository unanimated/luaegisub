-- JOIN
-- joins ACTIVE line with the next one. it's a combination of "Join (concatenate)" and "Join (keep first)"
-- if the text (without tags) is the same on both lines, then it's "keep first"
-- if text is different, it's "concatenate", but it nukes some redundant tags from the 2nd line
-- if a bigger selection has the same visible text on all lines, works as "Join (keep first)" for the whole selection
-- set a simple hotkey to use when timing

-- SPLIT
-- splits a line at linebreak (use together with Line Breaker with simple hotkeys under Subtitle Grid)
-- it's similar to "Split at cursor (estimate times)", but uses \N as "cursor"
-- compared to the inbuilt tool, the times estimation works better, you keep tags for both resulting lines, and it snaps to keyframes (6-frame range)

script_name="Join / Split"
script_description="Joins / splits lines"
script_author="unanimated"
script_version="1.0"

function join(subs,sel,act)
    go=0
    if #sel>1 then
	go=1	st=10000000  et=0
	for x,i in ipairs(sel) do
	  l=subs[i]	  t=l.text	ct=t:gsub("{[^}]-}","")
	  stm=l.start_time etm=l.end_time
	  if stm<st then st=stm end
	  if etm>et then et=etm end
	  if x>1 and ct~=ref then go=0 end
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
	if act==#subs then aegisub.log("Nothing to join with.") aegisub.cancel() end
        l=subs[act]		t=l.text	ct=t:gsub("{[^}]-}","")
	l2=subs[act+1]		t2=l2.text	ct2=t2:gsub("{[^}]-}","")	ct3=t2:gsub("^{[^}]-}","")    :gsub("^%- ","")

	if ct~=ct2 then 
	  t=t:gsub("{[Jj][Oo][Ii][Nn]}%s*$","")
	  tt=t:match("^{\\[^}]-}")
	  tt2=t2:match("^{\\[^}]-}")
	  if tt~=nil and tt2~=nil then 
	    tt=tt:gsub("\\pos%b()","")
	    tt2=tt2:gsub("\\pos%b()","")
	    if tt==tt2 then t=t.." "..ct3 else
	    tt2=tt2:gsub("\\an%d","")
	    :gsub("\\pos%b()","")
	    :gsub("\\move%b()","")
	    :gsub("\\fade?%b()","")
	    :gsub("\\org%b()","")
	    :gsub("\\i?clip%b()","")
	    :gsub("\\q%d","")
	    :gsub("{}","")
	    t=t.." "..tt2..ct3 end
	  elseif tt2~=nil then
	    t=t.." "..tt2..ct3
	  else
	    t=t.." "..ct3
	  end
	  t=t:gsub("%.%.%. %.%.%."," ") :gsub("(%a%-) (%a)","%1%2")
	end
	if l2.end_time>l.end_time then l.end_time=l2.end_time end
	subs.delete(act+1)
	l.text=t
        subs[act]=l
    end
    aegisub.set_undo_point(script_name)
    return sel
end

function split(subs,sel)
	for i=#sel,1,-1 do
	  line=subs[sel[i]]
	  text=subs[sel[i]].text
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
	    end
	    
	    if not text:match("\\N") and not text:match(" ") then text=text.."\\N"..text end
	    
	    if text:match("\\N") then
	    text=text:gsub("^%- (.-\\N)%- ","%1")
	    line2=line
		start=line.start_time		-- start time
		endt=line.end_time		-- end time
		dur=endt-start
		ms2fr=aegisub.frame_from_ms
		fr2ms=aegisub.ms_from_frame
		
		keyframes=aegisub.keyframes()	-- keyframes table
		startf=ms2fr(start)		-- startframe
		endf=ms2fr(endt)		-- endframe
		
		diff=250
		diffe=250
		startkf=keyframes[1]
		endkf=keyframes[#keyframes]
		
		txt=text:gsub("{[^}]-}","")
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
		line2.text=aftern
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
		text=text:gsub("^(.-)%s?\\N(.*)","%1")
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

aegisub.register_macro("Join","Joins lines",join)
aegisub.register_macro("Split","Splits Lines",split)