-- Times a sign with {TS 3:24} to 3:24-3:25. Can convert and use a few other formats, like {3:24}, {TS,3:24}, {3,24} etc.
-- supported timecodes: {TS 1:23}; {TS 1:23 words}; {TS words 1:23}; {TS,1:23}; {1:23}; {1;23}; {1,23}; {1.23}; [1:23] and variations

script_name="Time signs from timecodes"
script_description="Rough-times signs from TS timecodes"
script_author="unanimated"
script_version="2.61"

function signtime(subs, sel)
    for i=#sel,1,-1 do
	line=subs[sel[i]]
	text=line.text
	-- format timecodes
	text=text
	:gsub("(%d+):(%d%d):(%d%d)",
		function(a,b,c) return a*60+b..":"..c end)	-- hours
	:gsub("^(%d%d%d%d)%s%s*","{TS %1}")			-- ^1234  text
	:gsub("(%d%d)ish","%1")				-- 1:23ish
	:gsub("^([%d%s:,%-]+)","{%1}")				-- ^1:23, 2:34, 4:56
	:gsub("^(%d+:%d%d)%s%-%s","{TS %1}")			-- ^12?:34 -
	:gsub("^(%d+:%d%d%s*)","{TS %1}")			-- ^12?:34
	:gsub("^{(%d+:%d%d)","{TS %1")				-- ^{12?:34
	:gsub("^%[(%d+:%d%d)%]:?%s*","{TS %1}")		-- ^[12?:34]:?
	:gsub("{TS[%s%p]+(%d)","{TS %1")			-- {TS ~12:34
	:gsub("({[^}]-)(%d+)[%;%.,]?(%d%d)([^:%d][^}]-})","%1%2:%3%4")	-- {1;23 / 1.23 / 1,23 123}
	:gsub("{TS%s([^%d\\}]+)%s(%d+:%d%d)","{TS %2 %1")	-- {TS comment 12:34}
	:gsub(":%s?}","}")					-- {TS 12:34: }
	:gsub("|","\\N")
	tc=text:match("^{[^}]-}") or ""
	tc=tc:gsub("(%d+)(%d%d)([^:])","%1:%2%3")
	text=text:gsub("^{[^}]-}%s*",tc)
	line.text=text

	tstags=text:match("{TS[^}]-}") or ""

	times={}	-- collect times if there are more
	for tag in tstags:gmatch("%d+:%d+") do table.insert(times,tag) end

	for t=#times,1,-1 do
	    tim=times[t]
	    -- convert to start time
	    tstid1,tstid2=tim:match("(%d+):(%d%d)")
	    if tstid1 then tid=(tstid1*60000+tstid2*1000-500) end
		-- shifting times
	    if tid then
		if res.shift then tid=tid+res.secs*1000 end
		-- set start and end time [500ms before and after the timecode]
		line.start_time=tid line.end_time=(tid+1000)
	    end

	    -- snapping to keyframes
	    if res.snap then
		start=line.start_time
		endt=line.end_time
		startf=ms2fr(start)
		endf=ms2fr(endt)
		diff=250
		diffe=250
		startkf=keyframes[1]
		endkf=keyframes[#keyframes]

		-- check for nearby keyframes
		for k,kf in ipairs(keyframes) do
			-- startframe snap up to 24 frames back [scroll down to change default] and 5 frames forward
			if kf>=startf-res.kfs and kf<startf+5 then
			tdiff=math.abs(startf-kf)
			if tdiff<=diff then diff=tdiff startkf=kf end
			start=fr2ms(startkf)
			line.start_time=start
			end
			-- endframe snap up to 24 frames forward [scroll down to change default] and 10 frames back
			if kf>=endf-10 and kf<=endf+res.kfe then
			tdiff=math.abs(endf-kf)
			if tdiff<diffe then diffe=tdiff endkf=kf end
			endt=fr2ms(endkf)
			line.end_time=endt
			end
		end
	    end
	    line.text=line.text:gsub("{TS[^}]-}","{TS "..tim.."}")
	    subs.insert(sel[i]+1,line)
	    if t>1 then table.insert(sel,sel[#sel]+1) end
	end
	if #times>0 then subs.delete(sel[i]) end
    end
    if res.copy then taim=0 tame=0
	for z,i in ipairs(sel) do
	    l=subs[i]
	    if l.start_time==0 then l.start_time=taim l.end_time=tame end
	    taim=l.start_time
	    tame=l.end_time
	    subs[i]=l
	end
    end
    return sel
end

function timesigns(subs, sel)
dialog_config=
{
    {x=0,y=0,width=4,class="label",label="Check this if all your timecodes are too late or early:", },
    {x=0,y=1,width=1,class="checkbox",name="shift",label="Shift timecodes by ",value=false },
    {x=1,y=1,width=2,class="intedit",name="secs",value=-10,hint="Negative=backward / positive=forward" },
    {x=3,y=1,width=1,class="label",label=" sec.", },
    {x=0,y=2,width=4,class="checkbox",name="copy",label="For lines without timecodes, copy from the previous line",value=false},
    {x=0,y=3,width=2,class="checkbox",name="snap",label="Snapping to keyframes:",value=true },
    {x=0,y=4,width=2,class="label",label="Frames to search back:", },
    {x=0,y=5,width=2,class="label",label="Frames to search forward:", },
    {x=2,y=4,width=2,class="intedit",name="kfs",value="24",step=1,min=1,max=250 },	-- default search back [24]
    {x=2,y=5,width=2,class="intedit",name="kfe",value="24",step=1,min=1,max=250 },	-- default search forward [24]
}
    buttons={"No more suffering with SHAFT signs!","Exit"}
    P,res=aegisub.dialog.display(dialog_config,buttons,{ok='No more suffering with SHAFT signs!',cancel='Exit'})
    if P=="Exit" then aegisub.cancel() end
	ms2fr=aegisub.frame_from_ms
	fr2ms=aegisub.ms_from_frame
	keyframes=aegisub.keyframes()
    if P=="No more suffering with SHAFT signs!" then sel=signtime(subs,sel) end
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, timesigns)