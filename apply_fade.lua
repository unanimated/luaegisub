--[[ INSTRUCTIONS
For regular fade, type only 'fade in' / 'fade out' values.
Checking alpha will use alpha transform instead, with the fade in/out values and accel.
Checking colours will do colour transforms (with accel). If only one checked, the other will be alpha transform.
Checking blur will do a blur transform with given start and end blur (and accel), using the current blur as the middle value.
In case of user stupidity, ie. blur missing, 0.6 is used as default.
For letter by letter, the dropdown is for each letter, while fade in/out are for the overall fades.
Letter by letter using \ko - uses {\ko#} tags instead of transforms for fade in
  if the value is under 40, it's used as \ko[value]; if it's 40+, it's considered to be the overall fade, ie. when the last letter appears.
\ko by word fades in by word instead of by letter.
(Inline tags are supported, but if you fade by word and have tags in the middle of a word, it won't work as you want it to.)
Fade across multiple lines will create a set of alpha transforms across lines. 
  Nukes all present alpha tags; supports shadow alpha.
  "Global time" will use times relative to video, rather than of each individual line.
Fade in to current frame - sets fade in to current video frame
Fade out from current frame - sets fade out to current video frame
Extra functions:
Fade between 0 and 1 gives you that fraction of the line's duration, so fade in 0.2 with 1 second is \fad(200,0).
Negative fade gives you the inverse with respect to duration, so if dur=3000 and fade in is -500, you get \fad(2500,0), or to 500 from end. ]]

script_name="Apply fade"
script_description="Applies fade to selected lines"
script_author="unanimated"
script_version="3.7"

re=require'aegisub.re'

function fade(subs,sel)
    for z, i in ipairs(sel) do
	line=subs[i]
	text=line.text
	fadein=res.fadein 
	fadeout=res.fadeout 
	dur=line.end_time-line.start_time
	if fadein<=1 and fadein>0 then fadein=round(dur*fadein) end
	if fadeout<=1 and fadeout>0 then fadeout=round(dur*fadeout) end
	if fadein<0 then fadein=dur+fadein end
	if fadeout<0 then fadeout=dur+fadeout end
	if fadein<0 then fadein=0 end
	if fadeout<0 then fadeout=0 end
	    -- remove existing fade
	    text=text:gsub("\\fad%([%d%.%,]-%)","")

		-- standard fade
		if pressed=="Apply Fade" then
		text="{\\fad("..fadein..","..fadeout..")}"..text
		text=text:gsub("%)}{\\",")\\")
		text=text:gsub("{}","")
		end

	    -- letter by letter
	    if pressed=="Letter by Letter" then

	    -- delete old letter-by-letter if present
		if text:match("\\t%([%d,]+\\alpha[^%(%)]+%)}[%w%p]$") then
		    text=text:gsub("\\t%([^%(%)]-%)","")
		    text=text:gsub("\\alpha&H%x+&","")
		    text=text:gsub("{}","")
		end

	    if not res.del then

		-- fail if letter fade is larger than total fade
		lf=tonumber(res.letterfade)
		if fadein>0 and fadein<=lf or fadeout>0 and fadeout<=lf then aegisub.dialog.display({{class="label",
		    label="The fade for each letter must be smaller than overall fade.",x=0,y=0,width=1,height=2}},
			{"Fuck! Sorry, I'm stupid. Won't happen again."}) 
		aegisub.cancel() end
		-- mode: in, out, both
		if fadeout==0 then mode=1 
		elseif fadein==0 then mode=2
		else mode=3 end

		-- save initial tags; remove other tags/comments
		tags=""
		if text:match("^{\\[^}]*}") then tags=text:match("^({\\[^}]*})") end
		orig=text:gsub("^({\\[^}]*})","")
		text=text:gsub("{[^}]*}","")
		text=text:gsub("%s*$","")
		text=text:gsub("\\N","*")

		-- define variables
		outfade=dur-fadeout

		    -- letter-by-letter fade happens here
		    count=0
		    text3=""
		    al=tags:match("^{[^}]-\\alpha&H(%x%x)&")
		    if al==nil then al="00" end

		    matches=re.find(text,"[\\w[:punct:]][\\s\\\\*]*")
		    length=#matches
		    ftime1=((fadein-lf)/(length-1))
		    ftime2=((fadeout-lf)/(length-1))

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
		text=text:gsub("}{","")
		text=text:gsub("%*","\\N")
		if orig:match("{\\") then text=textmod(orig) end
		end

	    end -- not del

	text=text:gsub("\\fad%(0,0%)","") :gsub("{}","")
	line.text=text
	subs[i]=line
    end
end

function textmod(orig)
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	repeat text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	    until not text:match("{(\\[^}]-)}{(\\[^}]-)}")
	vis=text:gsub("{[^}]-}","")
	ltrmatches=re.find(vis,".")
	  for l=1,#ltrmatches do
	    table.insert(tk,ltrmatches[l].str)
	  end
	stags=text:match("^{(\\[^}]-)}")
	if stags==nil then stags="" end
	text=text:gsub("^{\\[^}]-}","") :gsub("{[^\\}]-}","")
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
	for n, t in ipairs(tg) do
	    if t.p==i then newt=newt..t.a..t.t end
	end
	if newt~="" then newline=newline.."{"..as..newt.."}" end
    end
    newtext="{"..stags.."}"..newline
    text=newtext
    return text
end

function fadalpha(subs,sel)
	if res.clr or res.crl then res.alf=true end
	fadin=res.fadein	fadout=res.fadeout
	blin="\\blur"..res.bli	blout="\\blur"..res.blu
	if res.vin or res.vout then vfcheck() vt=math.floor((fr2ms(vframe+1)+fr2ms(vframe))/2) end
	for z, i in ipairs(sel) do
	    line=subs[i]
	    text=subs[i].text
	    ortext=text
	    styleref=stylechk(subs,line.style)
	    st=line.start_time
	    et=line.end_time
	    if res.vin then fadin=vt-st end
	    if res.vout then fadout=et-vt end
	    dur=et-st
	    if fadin<=1 and fadin>0 then fadin=round(dur*fadin) end
	    if fadout<=1 and fadout>0 then fadout=round(dur*fadout) end
	    if fadin<0 then fadin=dur+fadin end
	    if fadout<0 then fadout=dur+fadout end
	    if fadin<0 then fadin=0 end
	    if fadout<0 then fadout=0 end
	    
	    if not text:match("^{\\[^}]-}") then text="{\\arfa}"..text end

	    col1=res.c1:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
	    col2=res.c2:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")

		text=text:gsub("\\1c","\\c")
		primary=styleref.color1:gsub("H%x%x","H")
		pri=text:match("^{[^}]-\\c(&H%x+&)")		if pri~=nil then primary=pri end
		outline=styleref.color3:gsub("H%x%x","H")
		out=text:match("^{[^}]-\\3c(&H%x+&)")		if out~=nil then outline=out end
		shadcol=styleref.color4:gsub("H%x%x","H")
		sha=text:match("^{[^}]-\\4c(&H%x+&)")		if sha~=nil then shadcol=sha end
		border=styleref.outline
		bord=text:match("^{[^}]-\\bord([%d%.]+)")	if bord~=nil then border=tonumber(bord) end
		shadow=styleref.shadow
		shad=text:match("^{[^}]-\\shad([%d%.]+)")	if shad~=nil then shadow=tonumber(shad) end

		kolora1="\\c"..col1	kolora3="\\3c"..col1	kolora4="\\4c"..col1
		kolorb1="\\c"..col2	kolorb3="\\3c"..col2	kolorb4="\\4c"..col2
		kolora=kolora1..kolora3..kolora4	kolorb=kolorb1..kolorb3..kolorb4
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
			text=text:gsub("^{\\[^}]-}",function(a) return a:gsub("\\[34]?c&H%x+&","") end)
			text=text:gsub("^{}","{\\arfa}")
			text=text:gsub("^({\\[^}]-)}",
			"%1"..kolora..blin.."\\t(0,"..fadin..","..res.inn..",\\c"..primary.."\\3c"..outline.."\\4c"..shadcol..lineblur..")}")
			-- inline colour tags
			for t in text:gmatch(".({\\[^}]-})") do
			    if t:match("\\[13]?c") then
			      col1="" col3="" col4=""
			      if t:match("\\c&") then col1=t:match("(\\c&H%x+&)") end
			      if t:match("\\3c") then col3=t:match("(\\3c&H%x+&)") end
			      if t:match("\\4c") then col4=t:match("(\\4c&H%x+&)") end
			      t2=t
			      :gsub("\\c&H%x+&",kolora1)
			      :gsub("\\3c&H%x+&",kolora3)
			      :gsub("\\4c&H%x+&",kolora4)
			      :gsub("({[^}]-)}","%1\\t(0,"..fadin..","..res.inn..","..col1..col3..col4..")}")
			      t=esc(t)
			      text=text:gsub(t,t2)
			    end
			end
		    else
		-- fade from alpha
			subalf=false
			st_alf=text:match("^{[^}]-(\\alpha&H%x%x&)")
			st_a1=text:match("^{[^}]-(\\1a&H%x%x&)")
			st_a3=text:match("^{[^}]-(\\3a&H%x%x&)")
			st_a4=text:match("^{[^}]-(\\4a&H%x%x&)")
			if st_alf==nil then toalf=a00 else toalf=st_alf end
			tosub=toalf:match("&H%x%x&")
			if st_a1==nil then toa1="\\1a"..tosub else subalf=true toa1=st_a1 end
			if st_a3==nil then toa3="\\3a"..tosub else subalf=true toa3=st_a3 end
			if st_a4==nil then toa4="\\4a"..tosub else subalf=true toa4=st_a4 end
			if subalf then toalf=toa1..toa3..toa4 else toalf=toalf end
			fromalf=toalf:gsub("&H%x%x&","&HFF&")
			text=text:gsub("^({[^}]-)\\alpha&H%x%x&","%1")
			:gsub("^{\\[^}]-}",function(a) return a:gsub("\\[134]a&H%x+&","") end)
			:gsub("^{(\\[^}]-)}","{%1"..blin..fromalf.."\\t(0,"..fadin..","..res.inn..","..lineblur..toalf..")}")
			-- inline alpha tags
			for t in text:gmatch(".({\\[^}]-})") do
			    arfa=t:match("(\\alpha&H%x+&)") if arfa==nil then arfa="" end
			    arf1=t:match("(\\1a&H%x+&)") if arf1==nil then arf1="" end
			    arf3=t:match("(\\3a&H%x+&)") if arf3==nil then arf3="" end
			    arf4=t:match("(\\4a&H%x+&)") if arf4==nil then arf4="" end
			    toarfa=arfa..arf1..arf3..arf4
			    if toarfa~="" then
			      fromarfa=toarfa:gsub("&H%x%x&","&HFF&")
			      t2=t:gsub("\\alpha&H%x+&","") :gsub("\\[134]a&H%x+&","")
			      t2=t2:gsub("({[^}]-)}","%1"..fromarfa.."\\t(0,"..fadin..","..res.inn..","..toarfa..")}")
			      t=esc(t)
			      text=text:gsub(t,t2)
			    end
			end
		    end
		end

		if fadout~=0 then
		-- fade to colour
		    if res.clr then
			text=text:gsub("^({\\[^}]-)}","%1"..lb.."\\t("..dur-fadout..",0,"..res.utt..","..kolorb..blout..")}")
			-- inline colour tags
			for t in text:gmatch(".({\\[^}]-})") do
			    if t:match("\\[13]?c") or t:match("\\alpha") then
			      t2=t:gsub("({\\[^}]-)}","%1\\t("..dur-fadout..",0,"..res.utt..","..kolorb..")}")
			      if not t:match("\\c&") and not t:match("\\alpha") then t2=t2:gsub("\\c&H%x+&","") end
			      if not t:match("\\3c") and not t:match("\\alpha") then t2=t2:gsub("\\3c&H%x+&","") end
			      if not t:match("\\4c") and not t:match("\\alpha") then t2=t2:gsub("\\4c&H%x+&","") end
			      t=esc(t)
			      text=text:gsub(t,t2)
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
			      t=esc(t)
			      text=text:gsub(t,t2)
			    end
			end
		    end
		end
		if border==0 then  text=text:gsub("\\3c&H%x+&","") end
		if shadow==0 then  text=text:gsub("\\4c&H%x+&","") end
		if not text:match("\\fad%(0,0%)") then text=text:gsub("\\fad%(%d+,%d+%)","") end	-- nuke fade
		text=text:gsub("\\\\","\\")
	    end
	    text=text:gsub("\\arfa","")
	    line.text=text
	    subs[i]=line
	end
end

function koko_da(subs,sel)
    finn=res.fadein
    if finn<1 then aegisub.dialog.display({{class="label",label="Fade in must be at least 1"}},{"OK"},{close='OK'}) aegisub.cancel() end
    for x, i in ipairs(sel) do
        line=subs[i]
        text=line.text
	text=text:gsub("\\ko%d+","") :gsub("{}","")
	
	-- save initial tags; remove other tags/comments
	tags=text:match("^{\\[^}]-}") if tags==nil then tags="" end
	orig=text:gsub("^({\\[^}]*})","")
	text=text:gsub("{[^}]*}","")	:gsub("%s*$","")	:gsub("\\N","*")
	
	--letter
	if not res.word then
	    matches=re.find(text,"[\\w[:punct:]][\\s\\\\*]*")
	    len=#matches
	    if finn>=40 then ko=round(finn/(len-1))/10 else ko=finn end
	    text=re.sub(text,"([\\w[:punct:]])","{\\\\ko"..ko.."}\\1")
	else
	--word
	    matches=re.find(text,"[\\w[:punct:]]+[\\s\\\\*]*")
	    len=#matches
	    if finn>=40 then ko=round(finn/(len-1)/10) else ko=finn end
	    text=re.sub(text,"([\\w[:punct:]]+)","{\\\\ko"..ko.."}\\1")
	end
	
	-- join saved tags + new text with transforms
	text=tags..text
	if not text:match("\\2a&HFF&") then text=text:gsub("^{","{\\2a&HFF&") end
	text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	text=text:gsub("%*","\\N")
	if orig:match("{\\") then text=textmod(orig) end
	line.text=text
        subs[i]=line
    end
end

function fadeacross(subs,sel)
	fadin=res.fadein	fadout=res.fadeout
	if fadin<0 then fadin=0 end
	if fadout<0 then fadout=0 end
	full=0	war=0
	S=subs[sel[1]].start_time
	E=subs[sel[#sel]].end_time
	-- get total duration
	for x,i in ipairs(sel) do
	    line=subs[i]
	    dur=line.end_time-line.start_time
	    full=full+dur
	    if line.start_time<S then S=line.start_time war=1 end
	    if line.end_time>E then E=line.end_time war=1 end
	end
	-- Error if fades too long
	if res.time and fadin+fadout>E-S or not res.time and fadin+fadout>full then 
	aegisub.dialog.display({{class="label",label="Error. Fades are longer than the duration of lines"}},{"OK"},{close='OK'})
	aegisub.cancel() 
	end
	-- Warning if not sorted by time
	if war==1 then 
	  aegisub.dialog.display({{class="label",label="Not sorted by time. \nDeal with the consequences."}},{"OK"},{cancel='OK'}) end
	-- Fade
	full2=E-S
	if res.time then full=full2 end
	durs=0 durs1=0
	for x,i in ipairs(sel) do
	    line=subs[i]
	    text=line.text
	    dur=line.end_time-line.start_time
	    start=line.start_time
	    endt=line.end_time
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
		    onefadein="\\1a&H"..alfin_1.."&\\3a&H"..alfin_1.."&\\4a&H"..shin_1.."&"
		else
		    instart="\\alpha&H"..alfin_s.."&" inend="\\alpha&H"..alfin_e.."&"
		    onefadein="\\alpha&H"..alfin_1.."&"
		end
		if alfin_s~=alfin_e then
		    if oneframe then text=text:gsub("^({\\[^}]-)}","%1"..onefadein.."}")
		    else text=text:gsub("^({\\[^}]-)}","%1"..instart.."\\t("..tim..inend..")}")
		    end
		end
	    elseif fadin>start-S and x>1 and start==subs[i-1].start_time then killpha()
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

function vfcheck()
    if aegisub.project_properties==nil then
	aegisub.dialog.display({{class="label",label="Current frame unknown.\nProbably your Aegisub is too old.\nMinimum required: r8374."}},
	{"OK"},{close='OK'}) aegisub.cancel()
    end
    vframe=aegisub.project_properties().video_position
    if vframe==nil or fr2ms(1)==nil then
	aegisub.dialog.display({{class="label",label="Current frame unknown. Probably no video loaded."}},
	{"OK"},{close='OK'}) aegisub.cancel()
    end
end

function vfade(subs,sel)
    vfcheck()
    for z, i in ipairs(sel) do
	line=subs[i]
	text=line.text
	st=line.start_time
	et=line.end_time
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

function killpha()
	if shad~="00" then text=text:gsub("\\[1234]a&H%x%x&","") end
	text=text:gsub("\\fad%([%d%.%,]-%)","") :gsub("\\alpha&H%x%x&","") :gsub("\\t%([^\\%)]-%)","") :gsub("{}","")
	if not text:match("^{\\") then text="{\\fake}"..text end
end

function esc(str)
str=str
:gsub("%%","%%%%")
:gsub("%(","%%%(")
:gsub("%)","%%%)")
:gsub("%[","%%%[")
:gsub("%]","%%%]")
:gsub("%.","%%%.")
:gsub("%*","%%%*")
:gsub("%-","%%%-")
:gsub("%+","%%%+")
:gsub("%?","%%%?")
return str
end

function round(num) num=math.floor(num+0.5) return num end

function tohex(num)
    n1=math.floor(num/16)
    n2=num%16
    if n1<0 then n2=0 end
    num=tohex1(n1)..tohex1(n2)
return num
end

function tohex1(num)
    if num<1 then num="0"
    elseif num>14 then num="F"
    elseif num==10 then num="A"
    elseif num==11 then num="B"
    elseif num==12 then num="C"
    elseif num==13 then num="D"
    elseif num==14 then num="E" end
return num
end

function stylechk(subs,stylename)
  for i=1, #subs do
    if subs[i].class=="style" then
      local st=subs[i]
      if stylename==st.name then styleref=st break end
    end
  end
  return styleref
end

--	Config		--
function saveconfig()
fadconf="Fade config\n\n"
  for key,val in ipairs(fade_config) do
    if val.class=="floatedit" or val.class=="dropdown" then
      fadconf=fadconf..val.name..":"..res[val.name].."\n"
    end
    if val.class=="checkbox" and val.name~="save" and val.name~="del" then
      fadconf=fadconf..val.name..":"..tf(res[val.name]).."\n"
    end
  end
fadconfig=aegisub.decode_path("?user").."\\apply_fade.conf"
file=io.open(fadconfig,"w")
file:write(fadconf)
file:close()
aegisub.dialog.display({{class="label",label="Config Saved to:\n"..fadconfig}},{"OK"},{close='OK'})
end

function loadconfig()
fconfig=aegisub.decode_path("?user").."\\apply_fade.conf"
file=io.open(fconfig)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	  for key,val in ipairs(fade_config) do
	    if val.class=="floatedit" or val.class=="checkbox" or val.class=="dropdown" then
	      if konf:match(val.name) then val.value=detf(konf:match(val.name..":(.-)\n")) end
	    end
	  end
    end
end

function tf(val)
    if val==true then ret="true" else ret="false" end
    return ret
end

function detf(txt)
    if txt=="true" then ret=true
    elseif txt=="false" then ret=false
    else ret=txt end
    return ret
end

function fadeconfig(subs,sel)
	fade_config=
	{
	  {x=0,y=0,width=4,height=1,class="label",label="fade  /  alpha/c/blur transform", },
	  {x=0,y=1,width=1,height=1,class="label",label="Fade in:"},
	  {x=0,y=2,width=1,height=1,class="label",label="Fade out:"},
	  {x=1,y=1,width=3,height=1,class="floatedit",name="fadein",value=0},
	  {x=1,y=2,width=3,height=1,class="floatedit",name="fadeout",value=0},
	  {x=4,y=0,width=1,height=1,class="checkbox",name="alf",label="alpha",value=false},
	  {x=5,y=0,width=1,height=1,class="checkbox",name="blur",label="blur",value=false},
	  {x=4,y=1,width=1,height=1,class="checkbox",name="crl",label="from:",value=false},
	  {x=4,y=2,width=1,height=1,class="checkbox",name="clr",label="to:",value=false},
	  {x=5,y=1,width=1,height=1,class="color",name="c1"},
	  {x=5,y=2,width=1,height=1,class="color",name="c2"},
	  {x=0,y=3,width=1,height=1,class="label",label="accel:",},
	  {x=1,y=3,width=3,height=1,class="floatedit",name="inn",value=1,min=0,hint="accel in - <1 starts fast, >1 starts slow"},
	  {x=4,y=3,width=2,height=1,class="floatedit",name="utt",value=1,min=0,hint="accel out - <1 starts fast, >1 starts slow"},
	  {x=0,y=4,width=1,height=1,class="label",label="blur:",},
	  {x=1,y=4,width=3,height=1,class="floatedit",name="bli",value=3,min=0,hint="start blur"},
	  {x=4,y=4,width=2,height=1,class="floatedit",name="blu",value=3,min=0,hint="end blur"},
	  
	  {x=0,y=5,width=1,height=1,class="label",label="By letter:"},
	  {x=1,y=5,width=1,height=1,class="dropdown",name="letterfade",
		items={"40","80","120","160","200","250","300","350","400","450","500","1000"},value="120"},
	  {x=2,y=5,width=2,height=1,class="label",label="ms/letter", },
	  {x=4,y=5,width=1,height=1,class="checkbox",name="rtl",label="rtl",value=false,hint="right to left"},
	  {x=5,y=5,width=1,height=1,class="checkbox",name="del",label="Delete",value=false,hint="delete letter-by-letter"},
	  
	  {x=0,y=6,width=4,height=1,class="checkbox",name="ko",label="Letter by letter using \\ko",value=false},
	  {x=4,y=6,width=2,height=1,class="checkbox",name="word",label="\\ko by word",value=false},
	  
	  {x=0,y=7,width=4,height=1,class="checkbox",name="mult",label="Fade across multiple lines",value=false},
	  {x=4,y=7,width=2,height=1,class="checkbox",name="time",label="Global time",value=false},
	  
	  {x=0,y=9,width=3,height=1,class="checkbox",name="vin",label="Fade in to current frame",value=false},
	  {x=3,y=9,width=3,height=1,class="checkbox",name="vout",label="out from current frame",value=false},
	  
	  {x=4,y=8,width=2,height=1,class="checkbox",name="save",label="[Save config]",value=false},
	  {x=0,y=8,width=4,height=1,class="checkbox",name="rem",label="Remember last settings",value=false},
	}
	loadconfig()
	if faded and res.rem then
	  for key,val in ipairs(fade_config) do
	    if val.class=="checkbox" or val.class=="dropdown" or val.class=="floatedit" then val.value=res[val.name] end
	  end
	end
	pressed, res=aegisub.dialog.display(fade_config,{"Apply Fade", "Letter by Letter","Cancel"},{ok='Apply Fade',cancel='Cancel'})
	fr2ms=aegisub.ms_from_frame
	ms2fr=aegisub.frame_from_ms
	faded=true
	if pressed=="Apply Fade" then
	    if res.save then saveconfig()
	    elseif res.alf or res.blur or res.clr or res.crl then fadalpha(subs,sel)
	    elseif res.mult then fadeacross(subs,sel)
	    elseif res.vin or res.vout then vfade(subs,sel)
	    else fade(subs,sel) end
	end
	if pressed=="Letter by Letter" then if res.ko or res.word then koko_da(subs,sel) else fade(subs,sel) end end
end

function apply_fade(subs,sel)
    fadeconfig(subs,sel)
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, apply_fade)