-- This is a quick snap-to-keyframe script for timers who would like to have this hotkeyed for whatever reason. Works on selected lines.

script_name="Snap"
script_description="Snaps to nearby keyframes"
script_author="unanimated"
script_version="1.2"

-- SETTINGS

kfsb=6		-- starts before
kfeb=10		-- ends before
kfsa=8		-- starts after
kfea=15		-- ends after

-- END OF SETTINGS

function keyframesnap(subs,sel)
    keyframes=aegisub.keyframes()
    ms2fr=aegisub.frame_from_ms
    fr2ms=aegisub.ms_from_frame
    
    if subs[sel[1]].effect=="gui" then
	gui={
	{x=0,y=0,width=1,height=1,class="label",label="Starts before "},
	{x=0,y=1,width=1,height=1,class="label",label="Ends before "},
	{x=0,y=2,width=1,height=1,class="label",label="Starts after "},
	{x=0,y=3,width=1,height=1,class="label",label="Ends after "},
	{x=1,y=0,width=1,height=1,class="floatedit",name="sb",value=6},
	{x=1,y=1,width=1,height=1,class="floatedit",name="eb",value=10},
	{x=1,y=2,width=1,height=1,class="floatedit",name="sa",value=8},
	{x=1,y=3,width=1,height=1,class="floatedit",name="ea",value=15},
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
	diff=250
	diffe=250
	startkf=keyframes[1]
	endkf=keyframes[#keyframes]
	
	-- snap to keyframes
	for k,kf in ipairs(keyframes) do
	    if kf>=startf-kfsa and kf<=startf+kfsb then
		sdiff=math.abs(startf-kf)
		if sdiff<=diff then diff=sdiff startkf=kf startn=fr2ms(startkf) end
	    end
	    if kf>=endf-kfea and kf<=endf+kfeb then
		ediff=math.abs(endf-kf)
		if ediff<diffe then diffe=ediff endkf=kf endtn=fr2ms(endkf) end
	    end
	end
	
	-- snap to adjacent lines
	if startn==nil or startn==start then
	  if subs[i-1].class=="dialogue" then
	    prevend=subs[i-1].end_time
	    pref=ms2fr(prevend)
	    sdiff=startf-pref
	    if sdiff<=kfsa and sdiff>0 or sdiff<0 and sdiff<=kfsb then startn=prevend end
	 end
	end
	if endtn==nil or endtn==endt then
	  if subs[i+1] then
	    nextart=subs[i+1].start_time
	    nesf=ms2fr(nextart)
	    ediff=nesf-endf
	    if ediff<=kfea and ediff>0 or ediff<0 and ediff<=kfeb then endtn=nextart end
	  end
	end
	
	if startn==nil then startn=start end
	if endtn==nil then endtn=endt end
	line.start_time=startn
	line.end_time=endtn
	subs[i]=line
    end
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, keyframesnap)