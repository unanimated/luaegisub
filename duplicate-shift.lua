script_name="Duplicate and Shift"
script_description="old Aegisub's Ctrl+D function"
script_author="unanimated"
script_version="1.1"

all_at_the_end=true	-- if true, all new lines go after the end time of the last line. if false, each new line goes right after its original.

function duplishift(subs, sel)
    last=subs[sel[#sel]]
    endtime=last.end_time
    ms2fr=aegisub.frame_from_ms
    fr2ms=aegisub.ms_from_frame
    shiftframe=ms2fr(endtime)
    newsel={}
    for i=#sel,1,-1 do
        line=subs[sel[i]]
	l2=line
	startfr=ms2fr(l2.start_time)
	endfr=ms2fr(l2.end_time)
	if all_at_the_end then
	  if line.end_time==endtime then line.end_time=fr2ms(shiftframe) subs[sel[i]]=line end
	  l2.start_time=fr2ms(shiftframe)
	  l2.end_time=fr2ms(shiftframe+1)
	else
	  line.start_time=fr2ms(startfr)
	  line.end_time=fr2ms(endfr) subs[sel[i]]=line
	  l2.start_time=fr2ms(endfr)
	  l2.end_time=fr2ms(endfr+1)
	end
	subs.insert(sel[#sel]+1,l2)
	table.insert(newsel,sel[#sel]+i)
    end
    return newsel
end

aegisub.register_macro(script_name, script_description, duplishift)