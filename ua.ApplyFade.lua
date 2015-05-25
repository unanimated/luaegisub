--[[ INSTRUCTIONS
For regular fade, type only 'fade in' / 'fade out' values.
Checking alpha will use alpha transform instead, with the fade in/out values and accel.
Checking colours will do colour transforms (with accel). If only one checked, the other will be alpha transform.
Checking blur will do a blur transform with given start and end blur (and accel), using the current blur as the middle value.
In case of user stupidity, ie. blur missing, 0.6 is used as default.
For letter by letter, the dropdown is for each letter, while fade in/out are for the overall fades.
Letter by letter using \ko - uses {\ko#} tags instead of transforms for fade in.
  if the value is under 40, it's used as \ko[value]; if it's 40+, it's considered to be the overall fade, ie. when the last letter appears.
\ko by word fades in by word instead of by letter.
(Inline tags are supported, but if you fade by word and have tags in the middle of a word, it won't work as you want it to.)
Fade across multiple lines will create a set of alpha transforms across lines.
  Nukes all present alpha tags; supports shadow alpha.
  "Global time" will use times relative to video, rather than of each individual line.
Fade in to current frame - sets fade in to current video frame.
Fade out from current frame - sets fade out to current video frame.
Extra functions:
Fade between 0 and 1 gives you that fraction of the line's duration, so fade in 0.2 with 1 second is \fad(200,0).
Negative fade gives you the inverse with respect to duration, so if dur=3000 and fade in is -500, you get \fad(2500,0), or to 500 from end.

Manual: http://unanimated.xtreemhost.com/ts/scripts-manuals.htm#fade   ]]

script_name="Apply Fade"
script_description="Applies fade to selected lines"
script_author="unanimated"
script_version="3.92"
script_namespace="ua.ApplyFade"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="3.9.2"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

re=require'aegisub.re'

function def()
if fadin<=1 and fadin>0 then fadin=round(dur*fadin) end
if fadout<=1 and fadout>0 then fadout=round(dur*fadout) end
if fadin<0 then fadin=dur+fadin end
if fadout<0 then fadout=dur+fadout end
if fadin<0 then fadin=0 end
if fadout<0 then fadout=0 end
end

function fade(subs,sel)
    for z,i in ipairs(sel) do
	progress("Processing line: "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	dur=line.end_time-line.start_time
	def()

	-- remove existing fade
	text=text:gsub("\\fad%([%d%.%,]-%)","")

	-- standard fade
	if P=="Apply Fade" then
	text="{\\fad("..fadin..","..fadout..")}"..text
	text=text:gsub("%)}{\\",")\\") :gsub("{}","")
	end

	-- letter by letter
	if P=="Letter by Letter" then

		-- delete old letter-by-letter if present
		if text:match("\\t%([%d,]+\\alpha[^%(%)]+%)}%S$") then
		 text=text:gsub("\\t%([^%(%)]-%)","") :gsub("\\alpha&H%x+&","") :gsub("{}","")
		end

	    if not res.del then

		-- fail if letter fade is larger than total fade
		lf=tonumber(res.letterfade)
		if fadin>0 and fadin<=lf or fadout>0 and fadout<=lf then ADD({{class="label",
		  label="The fade for each letter must be smaller than overall fade."}},{"Fuck! Sorry, I'm stupid. Won't happen again."})
		ak() end
		
		-- mode: in, out, both
		if fadout==0 then mode=1 elseif fadin==0 then mode=2 else mode=3 end

		-- save initial tags; remove other tags/comments
		tags=text:match("^({\\[^}]*})") or ""
		orig=text:gsub("^({\\[^}]*})","") :gsub("{[^\\}]-}","")
		text=text:gsub("%b{}","") :gsub("%s*$","") :gsub("\\N","*")

		-- letter-by-letter fade happens here
		outfade=dur-fadout
		count=0
		text3=""
		al=tags:match("^{[^}]-\\alpha&H(%x%x)&") or "00"

		matches=re.find(text,"[\\w[:punct:]][\\s\\\\*]*")
		length=#matches
		ftime1=((fadin-lf)/(length-1))
		ftime2=((fadout-lf)/(length-1))
		for _,match in ipairs(matches) do
		  ch=match.str
		  if res.rtl then fin1=math.floor(ftime1*(#matches-count-1)) else fin1=math.floor(ftime1*count) end
		  fin2=fin1+lf
		  if res.rtl then fout1=math.floor(ftime2*(#matches-count-1)+outfade) else fout1=math.floor(ftime2*count+outfade) end
		  fout2=fout1+lf
		  if mode==1 then text2m="{\\alpha&HFF&\\t("..fin1..","..fin2..",\\alpha&H"..al.."&)}"..ch end
		  if mode==2 then text2m="{\\alpha&H"..al.."&\\t("..fout1..","..fout2..",\\alpha&HFF&)}"..ch end
		  if mode==3 then 
		  text2m="{\\alpha&HFF&\\t("..fin1..","..fin2..",\\alpha&H"..al.."&)\\t("..fout1..","..fout2..",\\alpha&HFF&)}"..ch end
		  text3=text3..text2m
		  count=count+1
		end

		-- join saved tags + new text with transforms
		text=tags..text3
		text=text:gsub("}{","") :gsub("%*","\\N")
		if orig:match("{\\") then text=textmod(orig) end
	    end
	end

	text=text:gsub("\\fad%(0,0%)","") :gsub("{}","")
	line.text=text
	subs[i]=line
    end
end

function fadalpha(subs,sel)
if res.clr or res.crl then res.alf=true end
blin="\\blur"..res.bli	blout="\\blur"..res.blu
if res.vin or res.vout then vfcheck() vt=math.floor((fr2ms(vframe+1)+fr2ms(vframe))/2) end
    for z,i in ipairs(sel) do
	progress("Processing line: "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	ortext=text
	sr=stylechk(subs,line.style)
	st,et,dur=times()
	def()
	if res.vin then fadin=vt-st end
	if res.vout then fadout=et-vt end

	if not text:match("^{\\[^}]-}") then text="{\\arfa}"..text end

	col1=res.c1:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
	col2=res.c2:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")

	text=text:gsub("\\1c","\\c")
	notra=text:gsub("\\t%b()","")
	primary=notra:match("^{[^}]-\\c(&H%x+&)") or sr.color1:gsub("H%x%x","H")
	outline=notra:match("^{[^}]-\\3c(&H%x+&)") or sr.color3:gsub("H%x%x","H")
	shadcol=notra:match("^{[^}]-\\4c(&H%x+&)") or sr.color4:gsub("H%x%x","H")
	primary2=text:match("^{[^}]*\\c(&H%x+&)[^}]-}") or sr.color1:gsub("H%x%x","H")
	outline2=text:match("^{[^}]*\\3c(&H%x+&)[^}]-}") or sr.color3:gsub("H%x%x","H")
	shadcol2=text:match("^{[^}]*\\4c(&H%x+&)[^}]-}") or sr.color4:gsub("H%x%x","H")
	border=tonumber(text:match("^{[^}]-\\bord([%d%.]+)")) or sr.outline
	shadow=tonumber(text:match("^{[^}]-\\shad([%d%.]+)")) or sr.shadow

	kolora1="\\c"..col1	kolora3="\\3c"..col1	kolora4="\\4c"..col1	kolora,see1,see3,see4="","","",""
	kolorb1="\\c"..col2	kolorb3="\\3c"..col2	kolorb4="\\4c"..col2	kolorb=""
	if col1~=primary then kolora=kolora..kolora1 see1="\\c"..primary end
	if col1~=outline then kolora=kolora..kolora3 see3="\\3c"..outline end
	if col1~=shadcol then kolora=kolora..kolora4 see4="\\4c"..shadcol end
	if col2~=primary2 then kolorb=kolorb..kolorb1 end
	if col2~=outline2 then kolorb=kolorb..kolorb3 end
	if col2~=shadcol2 then kolorb=kolorb..kolorb4 end
	a00="\\alpha&H00&"	aff="\\alpha&HFF&"	lb=""

	-- blur w/o alpha
	if res.blur then lineblur=text:match("^{[^}]-(\\blur[%d%.]+)")
	    if lineblur==nil then lineblur="\\blur0.6" end
	    text=text:gsub("^({[^}]-)\\blur[%d%.]+","%1")
	    text=text:gsub("^{}","{\\arfa}")
	    if not text:match("^{\\") then text="{\\notarealtag}"..text end
	    if fadin==0 then lb=lineblur else lb="" end
	    if not res.alf then
	    if fadin~=0 then text=text:gsub("^({\\[^}]-)}","%1"..blin.."\\t(0,"..fadin..","..res.inn..","..lineblur..")}") end
	    if fadout~=0 then text=text:gsub("^({\\[^}]-)}","%1"..lb.."\\t("..dur-fadout..",0,"..res.utt..","..blout..")}") end
	    text=text:gsub("\\notarealtag","")
	    end
	end
	if not res.blur then lineblur="" blin="" blout="" end

	if res.alf then
	  if fadin~=0 then
	  -- fade from colour
	    if res.crl then
		if kolora~="" then
		  text=text:gsub("^{\\[^}]-}",function(a)
		    if a:match("\\t") then
		    nt=""
		    for n,t in a:gmatch("(.-)(\\t%b())") do nt=nt..n:gsub("\\[34]?c&H%x+&","")..t end
		    nt=nt..a:match(".*\\t%b()(.-)$"):gsub("\\[34]?c&H%x+&","")
		    return nt
		    else return a:gsub("\\[34]?c&H%x+&","") end end)
		  text=text:gsub("^{}","{\\arfa}")
		  tfc=kolora..blin.."\\t(0,"..fadin..","..res.inn..","..see1..see3..see4..lineblur..")"
		  text=text:gsub("^({\\[^}]-)}",function(a)
		    if a:match("\\t") then
		    return a:gsub("^(.-)(\\t.*)","%1"..tfc.."%2}")
		    else return a..tfc.."}" end end)
		end
		-- inline colour tags
		for t in text:gmatch(".({\\[^}]-})") do
		  det=t:gsub("\\t%b()","")
		  if det:match("\\[13]?c") then
		    col1=det:match("(\\c&H%x+&)") or ""	if col1==kolora1 then col1="" end
		    col3=det:match("(\\3c&H%x+&)") or ""	if col3==kolora3 then col3="" end
		    col4=det:match("(\\4c&H%x+&)") or ""	if col4==kolora4 then col4="" end
		    if (col1..col3..col4):len()>0 then
		      tfic="\\t(0,"..fadin..","..res.inn..","..col1..col3..col4..")"
		      if t:match("\\t") then
			t2=""
			for n,tf in t:gmatch("(.-)(\\t%b())") do
			  t2=t2..n:gsub("\\c&H%x+&",kolora1):gsub("\\3c&H%x+&",kolora3):gsub("\\4c&H%x+&",kolora4)..tf end
			t2=t2..t:match(".*\\t%b()(.-)$"):gsub("\\c&H%x+&",kolora1):gsub("\\3c&H%x+&",kolora3):gsub("\\4c&H%x+&",kolora4)
			t2=t2:gsub("^(.-)(\\t.*)","%1"..tfic.."%2")
		      else
			t2=t:gsub("\\c&H%x+&",kolora1):gsub("\\3c&H%x+&",kolora3):gsub("\\4c&H%x+&",kolora4)
			t2=t2:gsub("({[^}]-)}","%1"..tfic.."}")
		      end
		      text=text:gsub(esc(t),t2)
		    end
		  end
		end
	    else
	    -- fade from alpha
		subalf=false
		st_alf=notra:match("^{[^}]-(\\alpha&H%x%x&)")
		st_a1=notra:match("^{[^}]-(\\1a&H%x%x&)")
		st_a3=notra:match("^{[^}]-(\\3a&H%x%x&)")
		st_a4=notra:match("^{[^}]-(\\4a&H%x%x&)")
		if st_alf==nil then toalf=a00 else toalf=st_alf end
		tosub=toalf:match("&H%x%x&")
		if st_a1==nil then toa1="\\1a"..tosub else subalf=true toa1=st_a1 end
		if st_a3==nil then toa3="\\3a"..tosub else subalf=true toa3=st_a3 end
		if st_a4==nil then toa4="\\4a"..tosub else subalf=true toa4=st_a4 end
		if subalf then toalf=toa1..toa3..toa4 else toalf=toalf end
		fromalf=toalf:gsub("&H%x%x&","&HFF&")
		text=text:gsub("^{\\[^}]-}",function(a)
		    if a:match("\\t") then
		    nt=""
		    for n,t in a:gmatch("(.-)(\\t%b())") do nt=nt..n:gsub("\\%w+a&H%x+&","")..t end
		    nt=nt..a:match(".*\\t%b()(.-)$"):gsub("\\%w+a&H%x+&","")
		    return nt
		    else return a:gsub("\\%w+a&H%x+&","") end end)
		tfa=blin..fromalf.."\\t(0,"..fadin..","..res.inn..","..lineblur..toalf..")"
		text=text:gsub("^({\\[^}]-)}",function(a)
		    if a:match("\\t") then
		    return a:gsub("^(.-)(\\t.*)","%1"..tfa.."%2}")
		    else return a..tfa.."}" end end)
		-- inline alpha tags
		for t in text:gmatch(".({\\[^}]-})") do
		    det=t:gsub("\\t%b()","")
		    arfa=det:match("(\\alpha&H%x+&)") or ""
		    arf1=det:match("(\\1a&H%x+&)") or ""
		    arf3=det:match("(\\3a&H%x+&)") or ""
		    arf4=det:match("(\\4a&H%x+&)") or ""
		    toarfa=arfa..arf1..arf3..arf4
		    if toarfa~="" then
		      fromarfa=toarfa:gsub("&H%x%x&","&HFF&")
		      tfia=fromarfa.."\\t(0,"..fadin..","..res.inn..","..toarfa..")"
		      if t:match("\\t") then
			t2=""
			for n,tf in t:gmatch("(.-)(\\t%b())") do
			  t2=t2..n:gsub("\\alpha&H%x+&","") :gsub("\\[134]a&H%x+&","")..tf end
			t2=t2..t:match(".*\\t%b()(.-)$"):gsub("\\alpha&H%x+&","") :gsub("\\[134]a&H%x+&","")
			t2=t2:gsub("^(.-)(\\t.*)","%1"..tfia.."%2")
		      else
			t2=t:gsub("\\alpha&H%x+&","") :gsub("\\[134]a&H%x+&","")
			t2=t2:gsub("({[^}]-)}","%1"..tfia.."}")
		      end
		      text=text:gsub(esc(t),t2)
		    end
		end
	    end
	  end

	  if fadout~=0 then
	  -- fade to colour
	    if res.clr then
		if kolorb~="" then
		  text=text:gsub("^({\\[^}]-)}","%1"..lb.."\\t("..dur-fadout..",0,"..res.utt..","..kolorb..blout..")}")
		end
		-- inline colour tags
		for t in text:gmatch(".({\\[^}]-})") do
		  if t:match("\\[13]?c") or t:match("\\alpha") then
		    k_out=""
		    if t:match("\\c&H%x+&")~=kolorb1 and t:match("\\c&H%x+&")~=nil then k_out=k_out..kolorb1 end
		    if t:match("\\3c&H%x+&")~=kolorb3 and t:match("\\3c&H%x+&")~=nil then k_out=k_out..kolorb3 end
		    if t:match("\\4c&H%x+&")~=kolorb4 and t:match("\\4c&H%x+&")~=nil then k_out=k_out..kolorb4 end
		    t2=t:gsub("({\\[^}]-)}","%1\\t("..dur-fadout..",0,"..res.utt..","..k_out..")}")
		    text=text:gsub(esc(t),t2)
		  end
		end
	    -- fade to alpha
	    else
		if text:match("^{[^}]-(\\[134]a&H%x%x&)") then toarf="\\1a&HFF&".."\\3a&HFF&".."\\4a&HFF&" else toarf=aff end
		text=text:gsub("^({\\[^}]-)}","%1"..lb.."\\t("..dur-fadout..",0,"..res.utt..","..blout..toarf..")}")
		-- inline alpha tags
		for t in text:gmatch(".({\\[^}]-})") do
		    toarf=""
		    if t:match("\\alpha") then toarf=toarf..aff end
		    if t:match("\\1a") then toarf=toarf.."\\1a&HFF&" end
		    if t:match("\\3a") then toarf=toarf.."\\3a&HFF&" end
		    if t:match("\\4a") then toarf=toarf.."\\4a&HFF&" end
		    if toarf~="" then
		      t2=t:gsub("({\\[^}]-)}","%1\\t("..dur-fadout..",0,"..res.utt..","..toarf..")}")
		      text=text:gsub(esc(t),t2)
		    end
		end
	    end
	  end
	  if border==0 then  text=text:gsub("\\3c&H%x+&","") end
	  if shadow==0 then  text=text:gsub("\\4c&H%x+&","") end
	  if not text:match("\\fad%(0,0%)") then text=text:gsub("\\fad%(%d+,%d+%)","") end	-- nuke fade
	  if res.keepthefade then
	    if res.crl then f1=fadin else f1=0 end
	    if res.clr then f2=fadout else f2=0 end
	    if f1+f2>0 then text=text:gsub("^{\\","{\\fad("..f1..","..f2..")\\") end
	  end
	  text=text:gsub("\\t%([^\\]+%)","")
	end
	text=text:gsub("\\arfa","")
	line.text=text
	subs[i]=line
    end
end

function koko_da(subs,sel)
    if fadin<1 then t_error("Fade in must be at least 1",true) end
    for x,i in ipairs(sel) do
	progress("Processing line: "..x.."/"..#sel)
        line=subs[i]
        text=line.text
	text=text:gsub("\\ko%d+","") :gsub("{}","")

	-- save initial tags; remove other tags/comments
	tags=text:match("^{\\[^}]-}") or ""
	orig=text:gsub("^({\\[^}]*})","")
	text=text:gsub("{[^}]*}","") :gsub("%s*$","") :gsub("\\N","*")

	--letter
	if not res.word then
	    matches=re.find(text,"[\\w[:punct:]][\\s\\\\*]*")
	    len=#matches
	    if fadin>=40 then ko=round(fadin/(len-1))/10 else ko=fadin end
	    text=re.sub(text,"([\\w[:punct:]])","{\\\\ko"..ko.."}\\1")
	else
	--word
	    matches=re.find(text,"[\\w[:punct:]]+[\\s\\\\*]*")
	    len=#matches
	    if fadin>=40 then ko=round(fadin/(len-1)/10) else ko=fadin end
	    text=re.sub(text,"([\\w[:punct:]]+)","{\\\\ko"..ko.."}\\1")
	end

	-- join saved tags + new text with transforms
	text=tags..text
	if not text:match("\\2a&HFF&") then text=text:gsub("^{","{\\2a&HFF&") end
	text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") :gsub("%*","\\N")
	if orig:match("{\\") then text=textmod(orig) end
	line.text=text
        subs[i]=line
    end
end

function fadeacross(subs,sel)
	if fadin<0 then fadin=0 end
	if fadout<0 then fadout=0 end
	full=0	war=0
	S=subs[sel[1]].start_time
	E=subs[sel[#sel]].end_time
	-- get total duration
	for z,i in ipairs(sel) do
	    line=subs[i]
	    dur=line.end_time-line.start_time
	    full=full+dur
	    if line.start_time<S then S=line.start_time war=1 end
	    if line.end_time>E then E=line.end_time war=1 end
	end
	-- Error if fades too long
	if res.time and fadin+fadout>E-S or not res.time and fadin+fadout>full then
		t_error("Error. Fades are longer than the duration of lines",true)
	end
	-- Warning if not sorted by time
	if war==1 then t_error("Not sorted by time. \nDeal with the consequences.") end
	-- Fade
	full2=E-S
	if res.time then full=full2 end
	durs=0 durs1=0
	for z,i in ipairs(sel) do
	progress("Processing line: "..z.."/"..#sel)
	    line=subs[i]
	    text=line.text
	    start,endt,dur=times()
	    startf=ms2fr(start)
	    endf=ms2fr(endt)
	    if endf-startf==1 then oneframe=true else oneframe=false end
	    -- check shadow alpha
	    sr=stylechk(subs,line.style)
	    shad=sr.color4:match("H(%x%x)")
	    if text:match("\\4a") then shad=text:match("\\4a&H(%x%x)") end
	    if shad~="00" then shade=1-(tonumber(shad,16)/256) end
	    kill=1
	    -- fade in
	    if durs<fadin then
		killpha()
		durs1=durs1+dur		durs2=endt-S
		if res.time then durs=durs2 else durs=durs1 end
		if durs>fadin then in_end=dur-(durs-fadin) tim="0,"..in_end.."," kill=0 else tim="" end
		alfin_s=tohex(255-(round((durs-dur)/fadin*255)))
		alfin_e=tohex(255-(round(durs/fadin*255)))
		alfin_1=tohex(255-(round((durs-dur/2)/fadin*255)))
		if shad~="00" then
		    shin_s=tohex(255-round((255-tonumber(alfin_s,16))*shade))
		    shin_e=tohex(255-round((255-tonumber(alfin_e,16))*shade))
		    shin_1=tohex(255-round((255-tonumber(alfin_1,16))*shade))
		    instart="\\1a&H"..alfin_s.."&\\3a&H"..alfin_s.."&\\4a&H"..shin_s.."&"
		    inend="\\1a&H"..alfin_e.."&\\3a&H"..alfin_e.."&\\4a&H"..shin_e.."&"
		    onefadin="\\1a&H"..alfin_1.."&\\3a&H"..alfin_1.."&\\4a&H"..shin_1.."&"
		else
		    instart="\\alpha&H"..alfin_s.."&" inend="\\alpha&H"..alfin_e.."&"
		    onefadin="\\alpha&H"..alfin_1.."&"
		end
		if alfin_s~=alfin_e then
		    if oneframe then text=text:gsub("^({\\[^}]-)}","%1"..onefadin.."}")
		    else text=text:gsub("^({\\[^}]-)}","%1"..instart.."\\t("..tim..inend..")}")
		    end
		end
	    elseif fadin>start-S and z>1 and start==subs[i-1].start_time then killpha()
		text=text:gsub("^({\\[^}]-)}","%1\\alpha&H"..alfin_s.."&\\t("..tim.."\\alpha&H"..alfin_e.."&)}")
	    end
	    -- fade out
	    dure1=full
	    dure2=E-start
	    if res.time then dure=dure2 full=dure2-dur else dure=dure1 full=full-dur end
	    if full<fadout then
		if kill==1 then killpha() end
		if dure>fadout then out_start=dure-fadout tim=out_start..","..dur.."," else tim="" end
		alfout_s=tohex(255-(round(dure/fadout*255)))
		alfout_e=tohex(255-(round(full/fadout*255)))
		alfout_1=tohex(255-(round((dure+full)/2/fadout*255)))
		if shad~="00" then 
		    shout_s=tohex(255-round((255-tonumber(alfout_s,16))*shade))
		    shout_e=tohex(255-round((255-tonumber(alfout_e,16))*shade))
		    shout_1=tohex(255-round((255-tonumber(alfout_1,16))*shade))
		    outstart="\\1a&H"..alfout_s.."&\\3a&H"..alfout_s.."&\\4a&H"..shout_s.."&"
		    outend="\\1a&H"..alfout_e.."&\\3a&H"..alfout_e.."&\\4a&H"..shout_e.."&"
		    onefadeout="\\1a&H"..alfout_1.."&\\3a&H"..alfout_1.."&\\4a&H"..shout_1.."&"
		else
		    outstart="\\alpha&H"..alfout_s.."&" outend="\\alpha&H"..alfout_e.."&"
		    onefadeout="\\alpha&H"..alfout_1.."&"
		end
		if kill==1 then autstart=outstart else autstart="" end
		if alfout_s~=alfout_e then
		    if oneframe then text=text:gsub("^({\\[^}]-)}","%1"..onefadeout.."}")
		    else text=text:gsub("^({\\[^}]-)}","%1"..autstart.."\\t("..tim..outend..")}")
		    end
		end
	    end
	    text=text:gsub("\\fake","") :gsub("{}","")
   	    line.text=text
	    subs[i]=line
	end
end

function vfade(subs,sel)
    vfcheck()
    for z,i in ipairs(sel) do
	line=subs[i]
	text=line.text
	st,et=times()
	vt=math.floor((fr2ms(vframe+1)+fr2ms(vframe))/2)
	vfin=vt-st
	vfut=et-vt
	if not text:match("\\fad%(") then text="{\\fad(0,0)}"..text text=text:gsub("{\\fad%(0,0%)}{\\","{\\fad(0,0)\\") end
	if res.vin and vfin>0 then text=text:gsub("\\fad%(%d+,(%d+)%)","\\fad("..vfin..",%1)") end
	if res.vout and vfut>0 then text=text:gsub("\\fad%((%d+),%d+%)","\\fad(%1,"..vfut..")") end
	text=text:gsub("\\fad%(0,0%)","") :gsub("{}","")
   	line.text=text
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

function textmod(orig)
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	repeat text,r=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") until r==0
	vis=text:gsub("%b{}","")
	ltrmatches=re.find(vis,".")
	  for l=1,#ltrmatches do
	    table.insert(tk,ltrmatches[l].str)
	  end
	stags=text:match("^{(\\[^}]-)}") or ""
	text=text:gsub("^{\\[^}]-}",""):gsub("{[^\\}]-}","")
	count=0
	for seq in orig:gmatch("[^{]-{%*?\\[^}]-}") do
	    chars,as,tak=seq:match("([^{]-){(%*?)(\\[^}]-)}")
	    pos=re.find(chars,".")
	    if pos==nil then ps=0+count else ps=#pos+count end
	    tgl={p=ps,t=tak,a=as}
	    table.insert(tg,tgl)
	    count=ps
	end
	count=0
	for seq in text:gmatch("[^{]-{%*?\\[^}]-}") do
	    chars,as,tak=seq:match("([^{]-){(%*?)(\\[^}]-)}")
	    pos=re.find(chars,".")
	    if pos==nil then ps=0+count else ps=#pos+count end
	    tgl={p=ps,t=tak,a=as}
	    table.insert(tg,tgl)
	    count=ps
	end
    newline=""
    for i=1,#tk do
	newline=newline..tk[i]
	newt=""
	for n,t in ipairs(tg) do
	    if t.p==i then newt=newt..t.a..t.t end
	end
	if newt~="" then newline=newline.."{"..as..newt.."}" end
    end
    newtext="{"..stags.."}"..newline
    text=newtext:gsub("{}","")
    return text
end

function killpha()
	if shad~="00" then text=text:gsub("\\[1234]a&H%x%x&","") end
	text=text:gsub("\\fad%([%d%.%,]-%)",""):gsub("\\alpha&H%x%x&",""):gsub("\\t%([^\\%)]-%)",""):gsub("{}","")
	if not text:match("^{\\") then text="{\\fake}"..text end
end

function times()
	st=line.start_time
	et=line.end_time
	dur=et-st
	return st,et,dur
end

function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
end

function round(n,dec) dec=dec or 0 n=math.floor(n*10^dec+0.5)/10^dec return n end

function tohex(num)
n1=math.floor(num/16)
n2=num%16
num=tohex1(n1)..tohex1(n2)
return num
end

function tohex1(num)
HEX={"1","2","3","4","5","6","7","8","9","A","B","C","D","E"}
if num<1 then num="0" elseif num>14 then num="F" else num=HEX[num] end
return num
end

function stylechk(subs,sn)
  for i=1,#subs do
    if subs[i].class=="style" then
      local st=subs[i]
      if sn==st.name then sr=st break end
    end
  end
  if sr==nil then t_error("Style '"..sn.."' doesn't exist.",1) end
  return sr
end

function logg(m) m=tf(m) or "nil" aegisub.log("\n "..m) end

--	Config		--
function saveconfig()
fadconf="Fade config\n\n"
  for key,val in ipairs(GUI) do
    if val.class=="floatedit" or val.class=="dropdown" then
      fadconf=fadconf..val.name..":"..res[val.name].."\n"
    end
    if val.class=="checkbox" and val.name~="save" and val.name~="del" then
      fadconf=fadconf..val.name..":"..tf(res[val.name]).."\n"
    end
  end
fadconfig=ADP("?user").."\\apply_fade.conf"
file=io.open(fadconfig,"w")
file:write(fadconf)
file:close()
ADD({{class="label",label="Config saved to:\n"..fadconfig}},{"OK"},{close='OK'})
end

function loadconfig()
fconfig=ADP("?user").."\\apply_fade.conf"
file=io.open(fconfig)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	  for key,val in ipairs(GUI) do
	    if val.class=="floatedit" or val.class=="checkbox" or val.class=="dropdown" then
	      if konf:match(val.name) then val.value=detf(konf:match(val.name..":(.-)\n")) end
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

function fadeconfig(subs,sel)
	GUI={
	{x=0,y=0,width=4,class="label",label="fade  /  alpha/c/blur transform"},
	{x=0,y=1,class="label",label="Fade in:"},
	{x=0,y=2,class="label",label="Fade out:"},
	{x=1,y=1,width=3,class="floatedit",name="fadein",value=0},
	{x=1,y=2,width=3,class="floatedit",name="fadeout",value=0},
	{x=4,y=0,class="checkbox",name="alf",label="alpha"},
	{x=5,y=0,class="checkbox",name="blur",label="blur"},
	{x=4,y=1,class="checkbox",name="crl",label="from:"},
	{x=4,y=2,class="checkbox",name="clr",label="to:"},
	{x=5,y=1,class="color",name="c1"},
	{x=5,y=2,class="color",name="c2"},
	{x=0,y=3,class="label",label="accel:"},
	{x=1,y=3,width=3,class="floatedit",name="inn",value=1,min=0,hint="accel in - <1 starts fast, >1 starts slow"},
	{x=4,y=3,width=2,class="floatedit",name="utt",value=1,min=0,hint="accel out - <1 starts fast, >1 starts slow"},
	{x=0,y=4,class="label",label="blur:",},
	{x=1,y=4,width=3,class="floatedit",name="bli",value=3,min=0,hint="start blur"},
	{x=4,y=4,width=2,class="floatedit",name="blu",value=3,min=0,hint="end blur"},

	{x=0,y=5,class="label",label="By letter:"},
	{x=1,y=5,class="dropdown",name="letterfade",
		items={"40","80","120","160","200","250","300","350","400","450","500","1000"},value="120"},
	{x=2,y=5,width=2,class="label",label="ms/letter"},
	{x=4,y=5,class="checkbox",name="rtl",label="rtl",hint="right to left"},
	{x=5,y=5,class="checkbox",name="del",label="Delete",hint="delete letter-by-letter"},

	{x=0,y=6,width=6,class="checkbox",name="keepthefade",label="Keep fade along with colour transforms"},

	{x=0,y=7,width=4,class="checkbox",name="ko",label="Letter by letter using \\ko"},
	{x=4,y=7,width=2,class="checkbox",name="word",label="\\ko by word"},

	{x=0,y=8,width=4,class="checkbox",name="mult",label="Fade across multiple lines"},
	{x=4,y=8,width=2,class="checkbox",name="time",label="Global time"},

	{x=0,y=10,width=3,class="checkbox",name="vin",label="Fade in to current frame"},
	{x=3,y=10,width=3,class="checkbox",name="vout",label="out from current frame"},

	{x=4,y=9,width=2,class="checkbox",name="save",label="[Save config]"},
	{x=0,y=9,width=4,class="checkbox",name="rem",label="Remember last settings"},
	}
	loadconfig()
	if faded and res.rem then
	  for key,val in ipairs(GUI) do
	    if val.class=="checkbox" or val.class=="dropdown" or val.class=="floatedit" then val.value=res[val.name] end
	  end
	end
	P,res=ADD(GUI,{"Apply Fade","Letter by Letter","Cancel"},{ok='Apply Fade',cancel='Cancel'})
	fr2ms=aegisub.ms_from_frame
	ms2fr=aegisub.frame_from_ms
	fadin=res.fadein
	fadout=res.fadeout
	faded=true
	if P=="Apply Fade" then
	  if res.save then saveconfig()
	  elseif res.alf or res.blur or res.clr or res.crl then fadalpha(subs,sel)
	  elseif res.mult then fadeacross(subs,sel)
	  elseif res.vin or res.vout then vfade(subs,sel)
	  else fade(subs,sel) end
	end
	if P=="Letter by Letter" then if res.ko or res.word then koko_da(subs,sel) else fade(subs,sel) end
	end
end

function apply_fade(subs,sel)
    ADD=aegisub.dialog.display
    ADP=aegisub.decode_path
    ak=aegisub.cancel
    fadeconfig(subs,sel)
    aegisub.set_undo_point(script_name)
    return sel
end

if haveDepCtrl then depRec:registerMacro(apply_fade) else aegisub.register_macro(script_name,script_description,apply_fade) end