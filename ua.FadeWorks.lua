script_name="FadeWorkS"
script_description="Makes pictograph overlays fade in and out of existence"
script_author="unanimated"
script_version="5.0"
script_namespace="ua.Fadeworks"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="5.0.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

re=require'aegisub.re'

function fadeconfig(subs,sel)
	for i=1,#subs do
		if subs[i].class=="dialogue" then line0=i-1 break end
	end
	GUI={
	{x=0,y=0,width=4,class="label",label=script_name.." v"..script_version},
	{x=0,y=1,class="label",label="Fade in:"},
	{x=0,y=2,class="label",label="Fade out:"},
	{x=1,y=1,width=3,class="floatedit",name="fadein",value=0},
	{x=1,y=2,width=3,class="floatedit",name="fadeout",value=0},
	{x=1,y=3,width=3,class="floatedit",name="inn",value=1,min=0,hint="accel in - <1 starts fast, >1 starts slow"},
	{x=4,y=3,width=2,class="floatedit",name="utt",value=1,min=0,hint="accel out - <1 starts fast, >1 starts slow"},
	{x=4,y=0,width=2,class="checkbox",name="alf",label="Alpha/&Colour"},
	{x=4,y=1,class="checkbox",name="crl",label="&From:"},
	{x=4,y=2,class="checkbox",name="clr",label="&To:"},
	{x=5,y=1,class="color",name="c1"},
	{x=5,y=2,class="color",name="c2"},
	{x=0,y=3,class="label",label="Accel:"},
	{x=0,y=4,width=5,class="checkbox",name="keepthefade",label="&Keep fade along with colour transforms"},
	{x=0,y=5,width=4,class="checkbox",name="mult",label="Fade &across multiple lines"},
	{x=4,y=5,width=2,class="checkbox",name="time",label="&Global time"},
	{x=6,y=5,class="checkbox",name="ex",label="Clip &+",hint='Expand clip 3px in each direction'},

	{x=0,y=6,width=7,class="label",label="\nFades from/to tags will be applied if valid tags && fade in or out are present",},
	{x=0,y=7,class="label",label="Tags:",},
	{x=1,y=7,width=5,class="edit",name="tags",value="\\blur3",
	hint="(transformable) tags to be faded from/to\n(bord, shad, xbord, ybord, xshad, yshad, blur, be,\nfs, fscx, fscy, fsp, frz, frx, fry, fax, fay)"},
	{x=6,y=7,class="label",label="e.g. \\blur3\\fs10"},
	{x=0,y=8,class="label",label="In/out:",},
	{x=1,y=8,width=3,class="floatedit",name="tgin",value=0,min=0,hint="fade in for tags"},
	{x=4,y=8,width=2,class="floatedit",name="tgout",value=0,min=0,hint="fade out for tags"},
	{x=6,y=8,class="label",label="times like for \\fad"},
	{x=0,y=9,class="label",label="Accel:",},
	{x=1,y=9,width=3,class="floatedit",name="tai",value=1,min=0,hint="accel for tags in"},
	{x=4,y=9,width=2,class="floatedit",name="tao",value=1,min=0,hint="accel for tags out"},
	{x=6,y=9,class="label",label="acc<1 slows down"},
	{x=6,y=10,class="label",label="acc>1 speeds up"},

	{x=0,y=10,class="label",label="By letter:"},
	{x=1,y=10,class="dropdown",name="letterfade",items={"40","80","120","160","200","250","300","350","400","450","500","750","1000","1250","1500"},value="120"},
	{x=2,y=10,width=2,class="label",label="ms/letter"},
	{x=4,y=10,class="checkbox",name="rtl",label="&RTL",hint="right to left"},
	{x=5,y=10,class="checkbox",name="del",label="&Delete",hint="delete letter-by-letter"},

	{x=0,y=11,width=4,class="checkbox",name="ko",label="Letter by letter using \\&ko"},
	{x=4,y=11,width=2,class="checkbox",name="word",label="\\ko b&y word"},
	{x=6,y=11,class="checkbox",name="mir",label="&Mirror tags",hint="fade out to negative value (0-x)\nfor frz, fry, fax, xshad"},

	{x=0,y=12,width=3,class="checkbox",name="vin",label="Fade &in to current frame"},
	{x=4,y=12,width=3,class="checkbox",name="vout",label="Fade &out from current frame"},

	{x=6,y=0,class="checkbox",name="hlp",label="[&Help]",hint="Apply Help"},
	{x=6,y=1,class="checkbox",name="rem",label="Remember &last"},
	{x=6,y=2,class="checkbox",name="rep",label="Re&peat last"},
	{x=6,y=3,class="checkbox",name="save",label="[&Save config]"},
	}
	loadconfig()
	if faded and res.rem then
	  for key,val in ipairs(GUI) do
	    if val.class=="checkbox" or val.class=="dropdown" or val.class:match"edit" or val.class=="color" then val.value=res[val.name] end
	    if val.name=='hlp' then val.value=false end
	  end
	end
	P,res=ADD(GUI,{"Apply Fade","By L&etter","&By Clip","Fade&works","Fade Away"},{ok='Apply Fade',cancel='Fade Away'})
	fr2ms=aegisub.ms_from_frame
	ms2fr=aegisub.frame_from_ms
	if rep and res.rep then res=rep end
	if res.rep and not rep then t_error("Nothing to repeat",1) end
	tagcheck()
	fadin=res.fadein
	fadout=res.fadeout
	faded=true
	if TAGS and fadin>0 or TAGS and fadout>0 then res.alf=true end
	if res.hlp then P="Apply Fade" end
	if P=="Apply Fade" then
		if res.hlp then fadehelp(subs,sel)
		elseif res.save then saveconfig()
		elseif res.alf or TAGS or res.clr or res.crl then fadalpha(subs,sel)
		elseif res.mult then fadeacross(subs,sel)
		elseif res.vin or res.vout then vfade(subs,sel)
		else fade(subs,sel) end
	end
	if P=="By L&etter" then if res.ko or res.word then koko_da(subs,sel) else fade(subs,sel) end end
	if P=="Fade&works" then sel=fadeworks(subs,sel) end
	if P=="&By Clip" then clipfade(subs,sel) end
	rep=res
	return sel
end

function tagcheck()
	TAGS=nil
	ttags=res.tags
	if ttags:len()>3 and ttags:match"^\\" then TAGS=1 end
	if res.tgin==0 and res.tgout==0 then TAGS=nil end
	reftags={"bord","shad","fs","fscx","fscy","fsp","blur","be","frz","frx","fry","fax","fay","xshad","yshad","xbord","ybord"}
	checktags="|bord|shad|fs|fscx|fscy|fsp|blur|be|frz|frx|fry|fax|fay|xshad|yshad|xbord|ybord|"
	if TAGS then
		for tg in ttags:gmatch("\\[^\\]+") do
			tg1,tgval=tg:match("\\(%a+)(.*)")
			rem=nil
			if not checktags:match("|"..tg1.."|") then ttags=ttags:gsub(esc(tg),"") t_error("Wrong tag: "..tg) rem=1 end
			if not rem and not tgval:match("^%-?%d+%.?%d*$") then ttags=ttags:gsub(esc(tg),"") t_error("Missing value: "..tg) end
		end
		if not ttags:match"^\\" then TAGS=nil end
	end
end

function def(fadin,fadout)
if fadin<=1 and fadin>0 then fadin=round(dur*fadin) end
if fadout<=1 and fadout>0 then fadout=round(dur*fadout) end
if fadin<0 then fadin=dur+fadin end
if fadout<0 then fadout=dur+fadout end
if fadin<0 then fadin=0 end
if fadout<0 then fadout=0 end
return fadin,fadout
end

function fade(subs,sel)
    for z,i in ipairs(sel) do
	progress("Processing line #"..i-line0.." ["..z.."/"..#sel.."]")
	line=subs[i]
	text=line.text
	dur=line.end_time-line.start_time
	fadin,fadout=def(fadin,fadout)

	-- remove existing fade
	text=text:gsub("\\fad%b()","")

	-- standard fade
	if P=="Apply Fade" then
	text="{\\fad("..fadin..","..fadout..")}"..text
	text=text:gsub("%)}{\\",")\\") :gsub("{}","")
	end

	-- letter by letter
	if P=="By L&etter" then

		-- delete old letter-by-letter if present
		if text:match("\\t%([%d,]+\\alpha[^%(%)]+%)}%S$") then
		 text=text:gsub("\\t%([%d,]*\\alpha[^%(%)]+%)","") :gsub("\\alpha&H%x+&","") :gsub("{}","")
		end

		re_check=0
		if text:match "{[^}]*{" or text:match "}[^{]*}" or text:match "^[^{]*}" or text:match "{[^}]*$" then brackets=true end
		local tback=text
		visible=text:gsub("%b{}",""):gsub("^ *(.-) *$","%1"):gsub(" *\\N *"," "):gsub("^ +$","")
		if not res.del and visible~="" and not brackets and not text:match '\\p1' then repeat text=tback
	
			-- fail if letter fade is larger than total fade
			lf=tonumber(res.letterfade)
			if fadin>0 and fadin<=lf or fadout>0 and fadout<=lf then ADD({{class="label",
			  label="The fade for each letter must be smaller than overall fade."}},{"Fuck! Sorry, I'm stupid. Won't happen again."})
			ak() end
			
			-- mode: in, out, both
			if fadout==0 then mode=1 elseif fadin==0 then mode=2 else mode=3 end
			
			-- save linebreak patterns
			breaks={}
			for br in text:gmatch(" ?\\N") do
				table.insert(breaks,br)
			end
			
			-- save initial tags; remove other tags/comments
			tags=text:match("^({\\[^}]*})") or ""
			orig=text:gsub("^({\\[^}]*})","") :gsub("{[^\\}]-}","") :gsub("\\N","{\\N}")
			text=text:gsub("%b{}","") :gsub("%s*$","") :gsub("\\N","")

			-- letter-by-letter fade happens here
			outfade=dur-fadout
			count=0
			text3=""
			al=tags:match("^{[^}]-\\alpha&H(%x%x)&") or "00"

			matches=re.find(text,"\\S\\s*")
			length=#matches
			ftime1=((fadin-lf)/(length-1))
			ftime2=((fadout-lf)/(length-1))
			for _,match in ipairs(matches) do
			  ch=match.str
			  -- aegisub.log(ch)
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
			if orig:match("{\\") then text=textmod(orig,text) end
			
			-- fix linebreaks
			repeat text,c=text:gsub("{\\N","\\N{") until c==0
			text=text:gsub("{([^}]-)\\N([^}]-)}","\\N{%1%2}"):gsub("{%**}",""):gsub("(%S)\\N","%1 \\N")
			local b=0
			text=text:gsub(" \\N",function() b=b+1 return breaks[b] end)
		
			visible2=text:gsub("%b{}",""):gsub(" *\\N *"," ")
			if visible~=visible2 then re_check=re_check+1 end
			
			until visible==visible2 or re_check==256
			
			if visible~=visible2 then
				logg("Line #"..i-line0..": It appears that characters have been lost or added. \n If the problem isn't obvious from the two lines below, it's probably a failure of the re module.\n Undo (Ctrl+Z) and try again (Repeat Last might work). If the problem persists, rescan Autoload Dir.\n>> "..visible.."\n--> "..visible2.."\n")
			end
		end
		if brackets then logg("Line #"..i-line0..": Messed up curly brackets. Skipping.\n    ->   "..text..'\n') end
	end

	text=text:gsub("\\fad%(0,0%)","") :gsub("{}","")
	if line.text~=text and not brackets then
		line.text=text
		subs[i]=line
	end
	brackets=nil
    end
end


--	ALPHA / COLOURS / TAGS		--	############################################
function fadalpha(subs,sel)
if res.clr or res.crl then res.alf=true end
if res.vin or res.vout then vfcheck() vt=math.floor((fr2ms(vframe+1)+fr2ms(vframe))/2) end
mirrors="|frz|fry|fax|xshad|"
    for z,i in ipairs(sel) do
	progress("Processing line: "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	ortext=text
	sr=stylechk(subs,line.style)
	st,et,dur=times()
	fadin,fadout=def(fadin,fadout)
	if res.vin then fadin=vt-st end
	if res.vout then fadout=et-vt end

	if not text:match("^{\\[^}]-}") then text="{\\arfa}"..text end

	col1=res.c1:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
	col2=res.c2:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
	SC1=sr.color1:gsub("H%x%x","H")
	SC3=sr.color3:gsub("H%x%x","H")
	SC4=sr.color4:gsub("H%x%x","H")

	text=text:gsub("\\1c","\\c")
	notra=text:gsub("\\t%b()","")
	primary=notra:match("^{[^}]-\\c(&H%x+&)") or SC1
	outline=notra:match("^{[^}]-\\3c(&H%x+&)") or SC3
	shadcol=notra:match("^{[^}]-\\4c(&H%x+&)") or SC4
	primary2=text:match("^{[^}]*\\c(&H%x+&)[^}]-}") or SC1
	outline2=text:match("^{[^}]*\\3c(&H%x+&)[^}]-}") or SC3
	shadcol2=text:match("^{[^}]*\\4c(&H%x+&)[^}]-}") or SC4
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
		  tfc=kolora.."\\t(0,"..fadin..","..res.inn..","..see1..see3..see4..")"
		  text=text:gsub("^({\\[^}]-)}",function(a)
		    if a:match("\\t") then
		    return a:gsub("^(.-)(\\t.*)","%1"..tfc.."%2}")
		    else return a..tfc.."}" end end)
		  if col1==primary and col1~=SC1 then text=addtag3(kolora1,text) end
		  if col1==outline and col1~=SC3 then text=addtag3(kolora3,text) end
		  if col1==shadcol and col1~=SC4 then text=addtag3(kolora4,text) end
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
		tfa=fromalf.."\\t(0,"..fadin..","..res.inn..","..toalf..")"
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
		  text=text:gsub("^({\\[^}]-)}","%1"..lb.."\\t("..dur-fadout..",0,"..res.utt..","..kolorb..")}")
		end
		-- inline colour tags
		for t in text:gmatch(".({\\[^}]-})") do
		  if t:match("\\[13]?c") or t:match("\\alpha") then
		    k_out=""
		    if t:match(".*(\\c&H%x+&)")~=kolorb1 and t:match("\\c&H%x+&") then k_out=k_out..kolorb1 end
		    if t:match(".*(\\3c&H%x+&)")~=kolorb3 and t:match("\\3c&H%x+&") then k_out=k_out..kolorb3 end
		    if t:match(".*(\\4c&H%x+&)")~=kolorb4 and t:match("\\4c&H%x+&") then k_out=k_out..kolorb4 end
		    t2=t:gsub("({\\[^}]-)}","%1\\t("..dur-fadout..",0,"..res.utt..","..k_out..")}")
		    text=text:gsub(esc(t),t2)
		  end
		end
	    -- fade to alpha
	    else
		if text:match("^{[^}]-(\\[134]a&H%x%x&)") then toarf="\\1a&HFF&".."\\3a&HFF&".."\\4a&HFF&" else toarf=aff end
		text=text:gsub("^({\\[^}]-)}","%1"..lb.."\\t("..dur-fadout..",0,"..res.utt..","..toarf..")}")
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
	
	-- TAGS #######################################################################################################
	if TAGS then
		tgin,tgout=def(res.tgin,res.tgout)
		origtags=""
		tftagsIN=""
		tftagsOUT=""
		for tg in ttags:gmatch("\\[^\\]+") do
			tag,tgval=tg:match("\\(%a+)(.*)")
			midval=0
			STAG=text:match("^{\\[^}]-}") or ""
			midval=getvalue(tag)
			tftagsIN=tftagsIN.."\\"..tag..tgval
			if res.mir and mirrors:match("|"..tag.."|") then tgval=0-tgval end
			tftagsOUT=tftagsOUT.."\\"..tag..tgval
			origtags=origtags.."\\"..tag..midval
			STAG=STAG:gsub("\\"..tag.."[^})\\]*","")
		end
		if not STAG:match("^{\\") then STAG="{\\notarealtag}"..STAG end
		if tgin~=0 then intra=tftagsIN.."\\t(0,"..tgin..","..res.tai..","..origtags..")" else intra=origtags end
		if tgout~=0 then transfinal=intra.."\\t("..dur-tgout..",0,"..res.tao..","..tftagsOUT..")" else transfinal=intra end
		STAG=STAG:gsub("}",transfinal.."}"):gsub("\\notarealtag","")
		STAG=duplikill(STAG)
		text=text:gsub("^{\\[^}]-}",STAG)
	end
	
	text=text:gsub("\\arfa","")
	line.text=text
	subs[i]=line
    end
end

function getvalue(tag)
	V=STAG:match("\\"..tag.."(%-?%d+%.?%d*)")
	if not V then
		if tag=="bord" then V=sr.outline end
		if tag=="shad" then V=sr.shadow end
		if tag=="fs" then V=sr.fontsize end
		if tag=="fsp" then V=sr.spacing end
		if tag=="fscx" then V=sr.scale_x end
		if tag=="fscy" then V=sr.scale_y end
		if tag=="frz" then V=sr.angle end
		V=V or "0"
	end
	return V
end

function koko_da(subs,sel)
    if fadin<1 then t_error("Fade in must be at least 1",true) end
    for x,i in ipairs(sel) do
	progress("Processing line: "..x.."/"..#sel)
        line=subs[i]
        text=line.text
	text=text:gsub("\\ko%d+","") :gsub("{}","")

	-- save initial tags; remove other tags/comments
	tags=text:match(STAG) or ""
	orig=text:gsub("^({\\[^}]*})","")
	text=text:gsub("{[^}]*}","") :gsub("%s*$","") :gsub("\\N","*")

	--letter
	if not res.word then
		matches=re.find(text,"[\\w[:punct:]][\\s\\\\*]*")
		len=#matches
		if fadin>=40 then ko=round(fadin/(len-1))/10 else ko=fadin end
		text=re.sub(text,"([\\w[:punct:]])","{\\\\ko"..ko.."}\\1")
	else	--word
		matches=re.find(text,"[\\w[:punct:]]+[\\s\\\\*]*")
		len=#matches
		if fadin>=40 then ko=round(fadin/(len-1)/10) else ko=fadin end
		text=re.sub(text,"([\\w[:punct:]]+)","{\\\\ko"..ko.."}\\1")
	end

	-- join saved tags + new text with transforms
	text=tags..text
	if not text:match("\\2a&HFF&") then text=text:gsub("^({.-)}","%1\\2a&HFF&}") end
	text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") :gsub("%*","\\N")
	if orig:match("{\\") then text=textmod(orig,text) end
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
	if aegisub.project_properties==nil then t_error("Current frame unknown.\nProbably your Aegisub is too old.\nMinimum required: r8374.",true) end
	vframe=aegisub.project_properties().video_position
	if vframe==nil or fr2ms(1)==nil then t_error("Current frame unknown. Probably no video loaded.",true) end
end


-- Fade with Clip	--
function clipfade(subs,sel)
	for z,i in ipairs(sel) do
		line=subs[i]
		text=line.text
		dur=line.end_time-line.start_time
		tags=text:match(STAG) or ""
		vis=nobra(text)

		_,poses=text:gsub("\\N","") poses=poses+1
		sr=stylechk(subs,line.style)
		notra=detra(tags)
		if not text:match'\\pos%b()' and not text:match'\\move%b()' then text=getpos(subs,text) end
		posX,posY=text:match("\\pos%(([%d.-]+),([%d.-]+)%)")
		m1,m2,m3,m4=text:match("\\move%(([%d.-]+),([%d.-]+),([%d.-]+),([%d.-]+)")
		if m1 and not posY then posX=m1 posY=m2 end
		scx=notra:match("\\fscx([%d%.]+)")
		scy=notra:match("\\fscy([%d%.]+)")
		fsp=notra:match("\\fsp([%d%.]+)")
		fsize=notra:match("\\fs([%d%.]+)")
		phont=notra:match("\\fn([^\\}]+)")
		bord=notra:match("\\bord([%d%.]+)") or sr.outline
		shad=notra:match("\\shad([%d%.]+)") or sr.shadow
		xshad=notra:match("\\xshad([%d%.]+)") or shad
		yshad=notra:match("\\yshad([%d%.]+)") or shad
		bold=notra:match("\\b([01])")
		if scx then sr.scale_x=tonumber(scx) end
		if scy then sr.scale_y=tonumber(scy) end
		if fsp then sr.spacing=tonumber(fsp) end
		if fsize then sr.fontsize=tonumber(fsize) end
		if phont then sr.fontname=phont end
		if bold=='1' then sr.bold=true end
		if bold=='0' then sr.bold=false end

		w,h,d,el=aegisub.text_extents(sr,vis)
		if poses>1 then
			vis2=vis:gsub(" *\\N *","\n")
			w=0
			for vt in vis2:gmatch('[^\n]+') do
				w1=aegisub.text_extents(sr,vt)
				if w1>w then w=w1 end
			end
			h=h*poses
		end

		align=text:match("\\an(%d)") or tostring(sr.align)
		x_left=posX
		if align:match("[258]") then x_left=round(posX-w/2,1) end
		if align:match("[369]") then x_left=round(posX-w,1) end
		y_top=posY
		if align:match("[456]") then y_top=round(posY-h/2,1) end
		if align:match("[123]") then y_top=round(posY-h,1) end
		x_right=round(x_left+w,1)
		y_bottom=round(y_top+h,1)
		ex=0
		if res.ex then ex=3 end
		x_left=x_left-bord-ex
		y_top=y_top-bord-ex
		x_right=x_right+bord+xshad+ex
		y_bottom=y_bottom+bord+yshad+ex

		klip='\\clip'..par({x_left,y_top,x_right,y_bottom})
		klip_s='\\clip'..par({x_left,y_top,x_left+2,y_bottom})
		klip_e='\\clip'..par({x_right-2,y_top,x_right,y_bottom})
		text=text:gsub('\\i?clip%b()','')
		if fadin==0 then klip_f=klip else klip_f=klip_s..'\\t(0,'..fadin..','..res.inn..','..klip..')' end
		if fadout~=0 then klip_f=klip_f..'\\t('..dur-fadout..','..dur..','..res.utt..','..klip_e..')' end
		text=addtag1(klip_f,text)

		line.text=text
		subs[i]=line
	end
end



--	FADEWORKS	###############################################################################################
function fadeworks(subs,sel)
	nsel={} for z,i in ipairs(sel) do table.insert(nsel,i) end
	fadegui={
	{x=1,y=0,class="label",label="Lines before start time"},
	{x=2,y=0,class="label",label="Lines after end time"},
	{x=0,y=1,class="label",label="Lines to create:"},
	{x=1,y=1,class="intedit",name="LF",value=5,min=0},
	{x=2,y=1,class="intedit",name="RF",value=5,min=0},
	{x=0,y=2,class="label",label="Frames per line:"},
	{x=1,y=2,class="intedit",name="LFram",value=1,min=1},
	{x=2,y=2,class="intedit",name="RFram",value=1,min=1},
	{x=0,y=3,class="label",label="Shift each line by:"},
	{x=1,y=3,class="intedit",name="LFshift",value=1,min=1,hint="Should be same/lower than # of frames"},
	{x=2,y=3,class="intedit",name="RFshift",value=1,min=1,hint="Should be same/lower than # of frames"},
	{x=0,y=4,class="label",label="X distance:"},
	{x=1,y=4,class="floatedit",name="LFX",value=0},
	{x=2,y=4,class="floatedit",name="RFX",value=0},
	{x=0,y=5,class="label",label="Y distance:"},
	{x=1,y=5,class="floatedit",name="LFY"},
	{x=2,y=5,class="floatedit",name="RFY"},
	{x=0,y=6,class="label",label="X acceleration:"},
	{x=1,y=6,class="floatedit",name="LFacx",value=1,min=0},
	{x=2,y=6,class="floatedit",name="RFacx",value=1,min=0},
	{x=0,y=7,class="label",label="Y acceleration:"},
	{x=1,y=7,class="floatedit",name="LFacy",value=1,min=0},
	{x=2,y=7,class="floatedit",name="RFacy",value=1,min=0},
	{x=0,y=8,class="label",label="fbf transform*:"},
	{x=1,y=8,class="edit",name="Lfbf",value="\\",hint="tags to transform FROM"},
	{x=2,y=8,class="edit",name="Rfbf",value="\\",hint="tags to transform TO"},
	{x=0,y=9,class="label",label="fbf alpha tf:"},
	{x=1,y=9,class="edit",name="Lalf",hint="start alpha in hexadecimal"},
	{x=2,y=9,class="edit",name="Ralf",hint="end alpha in hexadecimal"},
	{x=0,y=10,class="label",label="\\t acceleration:"},
	{x=1,y=10,class="floatedit",name="LFact",value=1,min=0},
	{x=2,y=10,class="floatedit",name="RFact",value=1,min=0},
	
	{x=0,y=11,class="label",label="Flickering:"},
	{x=1,y=11,class="checkbox",name="LFad",label="Fade in"},
	{x=2,y=11,class="checkbox",name="RFad",label="Fade out"},
	
	{x=0,y=12,class="label",label="  * get colours:"},
	{x=1,y=12,class="color",name="col"},
	{x=2,y=12,class="edit",name="kol",hint="Paste the result to 'fbf transform'\n(modify the \\c type)"},
	
	{x=0,y=13,class="label",label="Fade mode:"},
	{x=1,y=13,width=2,class="checkbox",name="Fade",label="Use existing \\fad for line length and start/end point",hint="experimental feature intended to make overlapping lines"},
	{x=0,y=14,class="label",label="   add transform:"},
	{x=1,y=14,class="edit",name="LFtra",value="\\",hint="tags to transform FROM"},
	{x=2,y=14,class="edit",name="RFtra",value="\\",hint="tags to transform TO"},
	
	{x=3,y=3,class="label",label="frames"},
	{x=3,y=4,class="label",label="pixels"},
	{x=3,y=5,class="label",label="pixels"},
	}
	if resfade then
		for k,v in ipairs(fadegui) do
			if v.name then v.value=rez[v.name] end
		end
	end
	pres=nil
	
	repeat
	if pres=="Save/Load" then
		fwsafe()
		if Pf=="Inhume" then
			for k,v in ipairs(fadegui) do
				if v.name then v.value=rez[v.name] end
			end
		end
	end
	if pres=="Get colour tag" then
		K=rez.col:gsub("#(%x%x)(%x%x)(%x%x)","\\c&H%3%2%1&")
		for k,v in ipairs(fadegui) do
			if v.name=="kol" then v.value=K else v.value=rez[v.name] end
		end
	end
	pres,rez=ADD(fadegui,{"OK","Save/Load","Get colour tag","Cancel"},{ok='OK',close='Cancel'})
	until pres=="OK" or pres=="Cancel"
	
	resfade=rez
	if pres=="Cancel" then ak() end
	if rez.Fade then rez.LFad=false rez.RFad=false end
	
	-- fadeworks lines --
	for z=#sel,1,-1 do
		i=sel[z]
		line=subs[i]
		text=line.text
		startf=ms2fr(line.start_time)
		endf=ms2fr(line.end_time)
		styleref=stylechk(subs,line.style)
		if not text:match("\\pos%(") then text=getpos(subs,text) end
		pX,pY=text:match("\\pos%(([^,]-),([^,]-)%)")
		if rez.Lfbf:match 'fs[cp]' or rez.Rfbf:match 'fs[cp]' then text=text:gsub("^{\\","{\\q2\\") end
		if rez.Fade then
			f1,f2=text:match("\\fad%(([^,]-),([^,]-)%)")
			if not f1 then t_error("Abort: No \\fad tag on line #"..i-line0,1) end
			rez.LFram=ms2fr(f1)
			rez.RFram=ms2fr(f2)
		else
			if rez.LFad then f1=fr2ms(rez.LFram) else f1=0 end
			if rez.RFad then f2=fr2ms(rez.RFram) else f2=0 end
		end
		redshift=0
		blushift=0
		if not rez.Fade then
			redshift=rez.LFram-rez.LFshift
			blushift=rez.RFram-rez.RFshift
		end
	
	-- replicating OUT
	if rez.RF>0 then
	  for r=rez.RF,1,-1 do
		l2=line
		posx=numgrad(pX,pX+rez.RFX,rez.RF+1,r+1,rez.RFacx)
		posy=numgrad(pY,pY+rez.RFY,rez.RF+1,r+1,rez.RFacy)
		text2=text:gsub("\\pos%b()","\\pos("..posx..","..posy..")"):gsub("\\t%b()","")
		stags=text:match("^%b{}") or ""
		-- save tags from transforms for OUT lines
		tratags=""
		for tra in stags:gmatch("\\t%b()") do
			tTags=tra:match("\\t%(.-(\\.*)%)")
			tratags=tratags..tTags
		end
		nontra=text2:gsub("\\t%b()","")
		if rez.Fade and rez.RFtra:len()>1 then
			text2=text2:gsub("^({\\[^}]-)}","%1\\t("..rez.RFtra..")}")
		end
		if rez.RFad then text2=text2:gsub("\\fad%b()",""):gsub("^{","{\\fad(0,"..f2..")") end
		-- tags from orig. line's transforms to text2
		for tag in tratags:gmatch("\\[^\\]+") do text2=addtag3(tag,text2) end
		-- tags transforming line by line
		if rez.Rfbf:len()>1 then
			for tag in rez.Rfbf:gmatch("\\[^\\]+") do
			  tg,val=tag:match("(\\%d?%a+)([%d&%-][^\\}]*)")
			  -- from \t or from not \t or from style
			  endval=tratags:match(tg.."([%d&%-][^\\}]*)") or nontra:match(tg.."([%d&%-][^\\}]*)") or styleval(tg)
			  if tg=="\\c" or tg:match"%d" then
			    nval=acgrad(val,endval,rez.RF+1,rez.RF-r+1,1/rez.RFact)
			  else
			    nval=numgrad(val,endval,rez.RF+1,rez.RF-r+1,1/rez.RFact)
			  end
			  text2=addtag3(tg..nval,text2)
			end
		end
		if rez.Ralf:len()>1 then
			ralf=rez.Ralf:match("%x%x")
			if ralf then
				endval=nontra:match("alpha&H(%x%x)&") or "00"
				nval=acgrad(ralf,endval,rez.RF+1,rez.RF-r+1,1/rez.RFact)
				text2=addtag3("\\alpha"..nval,text2)
			end
		end
		startf2=endf+rez.RFshift*(r-1)
		endf2=startf2+rez.RFram
		if rez.Fade then
			text2=text2:gsub("\\fad%(([^,]+),([^,]+)%)","\\fad(0,%2)")
			startf2=startf2-rez.RFram+rez.RFshift endf2=endf2-rez.RFram+rez.RFshift
		end
		l2.start_time=fr2ms(startf2-blushift)
		l2.end_time=fr2ms(endf2-blushift)
		l2.text=text2
		subs.insert(i+1,l2)
		nsel=shiftsel2(nsel,i,1)
	    end
	end
	
	-- main line
	line.start_time=fr2ms(startf)
	line.end_time=fr2ms(endf)
	if rez.LFad or rez.RFad then text=text:gsub("\\fad%b()",""):gsub("^{","{\\fad("..f1..","..f2..")") end
	line.text=text
	subs.insert(i+1,line)
	
	-- replicating IN
	if rez.LF>0 then
	    for r=1,rez.LF do
		l2=line
		posx=numgrad(pX,pX+rez.LFX,rez.LF+1,r+1,rez.LFacx)
		posy=numgrad(pY,pY+rez.LFY,rez.LF+1,r+1,rez.LFacy)
		text2=text:gsub("\\pos%b()","\\pos("..posx..","..posy..")"):gsub("\\t%b()","")
		nontra=text2:gsub("\\t%b()","")
		if rez.Fade and rez.LFtra:len()>1 then
			Ltra="{}"
			for tag in rez.LFtra:gmatch("\\[^\\]+") do
			  tg=tag:match("(\\%d?%a+)[%d&%-]")
			  if nontra:match(tg.."[%d&%-]") then
			    Ltra=Ltra:gsub("{","{"..nontra:match(tg.."[%d&%-][^\\}]*"))
			  else Ltra=fill_in(Ltra,tg) end
			  text2=addtag3(tag,text2)
			end
			  Ltra=Ltra:gsub("[{}]","")
			text2=text2:gsub("^({\\[^}]-)}","%1\\t("..Ltra..")}")
		end
		if rez.LFad then text2=text2:gsub("\\fad%b()",""):gsub("^{","{\\fad("..f1..",0)") end
		if rez.Lfbf:len()>1 then
			for tag in rez.Lfbf:gmatch("\\[^\\]+") do
			  tg,val=tag:match("(\\%d?%a+)([%d&%-][^\\}]*)")
			  endval=nontra:match(tg.."([%d&%-][^\\}]*)") or styleval(tg)
			  endval=tostring(endval)
			  if tg=="\\c" or tg:match"%d" then
			    nval=acgrad(val,endval,rez.LF+1,rez.LF-r+1,1/rez.LFact)
			  else
			    nval=numgrad(val,endval,rez.LF+1,rez.LF-r+1,1/rez.LFact)
			  end
			  text2=addtag3(tg..nval,text2)
			end
		end
		if rez.Lalf:len()>1 then
			lalf=rez.Lalf:match("%x%x")
			if lalf then
				endval=nontra:match("alpha&H(%x%x)&") or "00"
				nval=acgrad(lalf,endval,rez.LF+1,rez.LF-r+1,1/rez.LFact)
				text2=addtag3("\\alpha"..nval,text2)
			end
		end
		
		endf2=startf-rez.LFshift*(r-1)
		startf2=endf2-rez.LFram
		if rez.Fade then
			text2=text2:gsub("\\fad%(([^,]+),([^,]+)%)","\\fad(%1,0)")
			startf2=startf2+rez.LFram-rez.LFshift endf2=endf2+rez.LFram-rez.LFshift
		end
		l2.start_time=fr2ms(startf2+redshift)
		l2.end_time=fr2ms(endf2+redshift)
		l2.text=text2
		subs.insert(i+1,l2)
		nsel=shiftsel2(nsel,i,1)
	    end
	end
	
	subs.delete(i)
	sel=nsel
	end
	return sel
end

--	reanimatools	----------------------------------------
function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function round(n,dec) dec=dec or 0 n=math.floor(n*10^dec+0.5)/10^dec return n end
function wrap(str) return "{"..str.."}" end
function par(tab) return '('..table.concat(tab,',')..')' end
function detra(t) return t:gsub("\\t%b()","") end
function nobra(t) return t:gsub("%b{}","") end
function nobrea(t) return t:gsub("%b{}",""):gsub("\\[Nh]","") end
function nobrea1(t) return t:gsub("%b{}",""):gsub(" *\\[Nh] *"," ") end
function tagmerge(t) repeat t,r=t:gsub("({\\[^}]-)}{(\\[^}]-})","%1%2") until r==0 return t end
function logg(m) m=tf(m) or "nil" aegisub.log("\n "..m) end
function loggtab(m) m=tf(m) or "nil" aegisub.log("\n {"..table.concat(m,';').."}") end
function progress(msg) if aegisub.progress.is_cancelled() then ak() end aegisub.progress.title(msg) end
function t_error(message,cancel) ADD({{class="label",label=message}},{"OK"},{close='OK'}) if cancel then ak() end end

function retextmod(orig,text)
	local v1,v2,c,t2
	v1=nobrea(orig)
	c=0
	repeat
		t2=textmod(orig,text)
		v2=nobrea(text)
		c=c+1
	until v1==v2 or c==666
	if v1~=v2 then logg("Something went wrong with the text...") logg(v1) logg(v2) end
	return t2
end

function textmod(orig,text)
if text=="" then return orig end
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	text=tagmerge(text)
	vis=nobra(text)
	ltrmatches=re.find(vis,".")
	if not ltrmatches then logg("text: "..text..'\nvisible: '..vis)
		logg("If you're seeing this, something really weird is happening with the re module.\nTry this again or rescan Autoload.")
	end
	  for l=1,#ltrmatches do
	    table.insert(tk,ltrmatches[l].str)
	  end
	stags=text:match(STAG) or ""
	text=text:gsub(STAG,"") :gsub("{[^\\}]-}","")
	orig=orig:gsub("{([^\\}]+)}",function(c) return wrap("\\\\"..c.."|||") end)
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
    newtext=stags..newline:gsub("(|||)(\\\\)","%1}{%2"):gsub("({[^}]-)\\\\([^\\}]-)|||","{%2}%1")
    text=newtext:gsub("{}","")
    return text
end

function addtag1(tg,txt) 
	if not txt:match("^{\\") then txt="{"..tg.."}"..txt
	elseif txt:match("^{[^}]-\\t") then txt=txt:gsub("^({[^}]-)\\t","%1"..tg.."\\t")
	else txt=txt:gsub("^({\\[^}]-)}","%1"..tg.."}") end
	return txt
end

function addtag3(tg,txt)
	no_tf=txt:gsub("\\t%b()","")
	tgt=tg:match("(\\%d?%a+)[%d%-&]") val="[%d%-&]"
	if not tgt then tgt=tg:match("(\\%d?%a+)%b()") val="%b()" end
	if not tgt then tgt=tg:match("\\fn") val="" end
	if not tgt then t_error("adding tag '"..tg.."' failed.") end
	if tgt:match("clip") then txt,r=txt:gsub("^({[^}]-)\\i?clip%b()","%1"..tg)
		if r==0 then txt=txt:gsub("^({\\[^}]-)}","%1"..tg.."}") end
	elseif no_tf:match("^({[^}]-)"..tgt..val) then txt=txt:gsub("^({[^}]-)"..tgt..val.."[^\\}]*","%1"..tg)
	elseif not txt:match("^{\\") then txt="{"..tg.."}"..txt
	elseif txt:match("^{[^}]-\\t") then txt=txt:gsub("^({[^}]-)\\t","%1"..tg.."\\t")
	else txt=txt:gsub("^({\\[^}]-)}","%1"..tg.."}") end
return txt
end

function styleval(tag)
	if tag=="\\bord" then s_val=styleref.outline
	elseif tag=="\\shad" then s_val=styleref.shadow
	elseif tag=="\\fscx" then s_val=styleref.scale_x
	elseif tag=="\\fscy" then s_val=styleref.scale_y
	elseif tag=="\\fs" then s_val=styleref.fontsize
	elseif tag=="\\fsp" then s_val=styleref.spacing
	elseif tag=="\\alpha" then s_val="&H00&"
	elseif tag=="\\1a" then s_val="&"..styleref.color1:match("H%x%x").."&"
	elseif tag=="\\2a" then s_val="&"..styleref.color2:match("H%x%x").."&"
	elseif tag=="\\3a" then s_val="&"..styleref.color3:match("H%x%x").."&"
	elseif tag=="\\4a" then s_val="&"..styleref.color4:match("H%x%x").."&"
	elseif tag=="\\c" then s_val=styleref.color1:gsub("H%x%x","H")
	elseif tag=="\\2c" then s_val=styleref.color2:gsub("H%x%x","H")
	elseif tag=="\\3c" then s_val=styleref.color3:gsub("H%x%x","H")
	elseif tag=="\\4c" then s_val=styleref.color4:gsub("H%x%x","H")
	else s_val="0"
	end
	return s_val
end

function duplikill(tagz)
	local tags1={"blur","be","bord","shad","xbord","xshad","ybord","yshad","fs","fsp","fscx","fscy","frz","frx","fry","fax","fay"}
	local tags2={"c","2c","3c","4c","1a","2a","3a","4a","alpha"}
	tagz=tagz:gsub("\\t%b()",function(t) return t:gsub("\\","|") end)
	for i=1,#tags1 do
	    tag=tags1[i]
	    repeat tagz,c=tagz:gsub("|"..tag.."[%d%.%-]+([^}]-)(\\"..tag.."[%d%.%-]+)","%1%2") until c==0
	    repeat tagz,c=tagz:gsub("\\"..tag.."[%d%.%-]+([^}]-)(\\"..tag.."[%d%.%-]+)","%2%1") until c==0
	end
	tagz=tagz:gsub("\\1c&","\\c&")
	for i=1,#tags2 do
	    tag=tags2[i]
	    repeat tagz,c=tagz:gsub("|"..tag.."&H%x+&([^}]-)(\\"..tag.."&H%x+&)","%1%2") until c==0
	    repeat tagz,c=tagz:gsub("\\"..tag.."&H%x+&([^}]-)(\\"..tag.."&H%x+&)","%2%1") until c==0
	end
	repeat tagz,c=tagz:gsub("\\fn[^\\}]+([^}]-)(\\fn[^\\}]+)","%2%1") until c==0
	repeat tagz,c=tagz:gsub("(\\[ibusq])%d(.-)(%1%d)","%2%3") until c==0
	repeat tagz,c=tagz:gsub("(\\an)%d(.-)(%1%d)","%3%2") until c==0
	tagz=tagz:gsub("(|i?clip%(%A-%))(.-)(\\i?clip%(%A-%))","%2%3")
	:gsub("(\\i?clip%b())(.-)(\\i?clip%b())",function(a,b,c)
	    if a:match("m") and c:match("m") or not a:match("m") and not c:match("m") then return b..c else return a..b..c end end)
	tagz=tagz:gsub("|","\\"):gsub("\\t%([^\\%)]-%)","")
	return tagz
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

function tohex(num)
	n1=math.floor(num/16)
	n2=math.floor(num%16)
	num=tohex1(n1)..tohex1(n2)
	return num
end

function tohex1(num)
	HEX={"1","2","3","4","5","6","7","8","9","A","B","C","D","E"}
	if num<1 then num="0" elseif num>14 then num="F" else num=HEX[num] end
	return num
end

function numgrad(V1,V2,total,l,acc)
	acc=acc or 1
	acc_fac=(l-1)^acc/(total-1)^acc
	VC=round(acc_fac*(V2-V1)+V1,2)
return VC
end

function acgrad(C1,C2,total,l,acc)
	acc=acc or 1
	acc_fac=(l-1)^acc/(total-1)^acc
	B1,G1,R1=C1:match("(%x%x)(%x%x)(%x%x)")
	B2,G2,R2=C2:match("(%x%x)(%x%x)(%x%x)")
	A1=C1:match("(%x%x)") R1=R1 or A1
	A2=C2:match("(%x%x)") R2=R2 or A2
	nR1=(tonumber(R1,16))  nR2=(tonumber(R2,16))
	R=acc_fac*(nR2-nR1)+nR1
	R=tohex(round(R))
	CC="&H"..R.."&"
	if B1 then
	nG1=(tonumber(G1,16))  nG2=(tonumber(G2,16))
	nB1=(tonumber(B1,16))  nB2=(tonumber(B2,16))
	G=acc_fac*(nG2-nG1)+nG1
	B=acc_fac*(nB2-nB1)+nB1
	G=tohex(round(G))
	B=tohex(round(B))
	CC="&H"..B..G..R.."&"
	end
return CC
end

function getpos(subs,text)
    st=nil defst=nil
    for g=1,#subs do
        if subs[g].class=="info" then
		local k=subs[g].key
		local v=subs[g].value
		if k=="PlayResX" then resx=v end
		if k=="PlayResY" then resy=v end
        end
	if resx==nil then resx=0 end
	if resy==nil then resy=0 end
        if subs[g].class=="style" then
		local s=subs[g]
		if s.name==line.style then st=s break end
		if s.name=="Default" then defst=s end
        end
	if subs[g].class=="dialogue" then
		if defst then st=defst else t_error("Style '"..line.style.."' not found.\nStyle 'Default' not found. ",1) end
		break
	end
    end
    if st then
	acleft=st.margin_l	if line.margin_l>0 then acleft=line.margin_l end
	acright=st.margin_r	if line.margin_r>0 then acright=line.margin_r end
	acvert=st.margin_t	if line.margin_t>0 then acvert=line.margin_t end
	acalign=st.align	if text:match("\\an%d") then acalign=text:match("\\an(%d)") end
	aligntop="789" alignbot="123" aligncent="456"
	alignleft="147" alignright="369" alignmid="258"
	if alignleft:match(acalign) then horz=acleft
	elseif alignright:match(acalign) then horz=resx-acright
	elseif alignmid:match(acalign) then horz=resx/2 end
	if aligntop:match(acalign) then vert=acvert
	elseif alignbot:match(acalign) then vert=resy-acvert
	elseif aligncent:match(acalign) then vert=resy/2 end
    end
    if horz>0 and vert>0 then 
	if not text:match("^{\\") then text="{\\rel}"..text end
	text=text:gsub("^({\\[^}]-)}","%1\\pos("..horz..","..vert..")}") :gsub("\\rel","")
    end
    return text
end

function fill_in(tags,tag)
	if tag=="\\bord" then tags=tags:gsub("^{","{"..tag..styleref.outline)
	elseif tag=="\\shad" then tags=tags:gsub("^{","{"..tag..styleref.shadow)
	elseif tag=="\\fscx" then tags=tags:gsub("^{","{"..tag..styleref.scale_x)
	elseif tag=="\\fscy" then tags=tags:gsub("^{","{"..tag..styleref.scale_y)
	elseif tag=="\\fs" or tag=="\\fsize" then tags=tags:gsub("^{","{"..tag..styleref.fontsize)
	elseif tag=="\\fsp" then tags=tags:gsub("^{","{"..tag..styleref.spacing)
	elseif tag=="\\alpha" then tags=tags:gsub("^{","{"..tag.."&H00&")
	elseif tag=="\\1a" then tags=tags:gsub("^{","{"..tag.."&"..styleref.color1:match("H%x%x").."&")
	elseif tag=="\\2a" then tags=tags:gsub("^{","{"..tag.."&"..styleref.color2:match("H%x%x").."&")
	elseif tag=="\\3a" then tags=tags:gsub("^{","{"..tag.."&"..styleref.color3:match("H%x%x").."&")
	elseif tag=="\\4a" then tags=tags:gsub("^{","{"..tag.."&"..styleref.color4:match("H%x%x").."&")
	elseif tag=="\\c" then tags=tags:gsub("^{","{"..tag..styleref.color1:gsub("H%x%x","H"))
	elseif tag=="\\2c" then tags=tags:gsub("^{","{"..tag..styleref.color2:gsub("H%x%x","H"))
	elseif tag=="\\3c" then tags=tags:gsub("^{","{"..tag..styleref.color3:gsub("H%x%x","H"))
	elseif tag=="\\4c" then tags=tags:gsub("^{","{"..tag..styleref.color4:gsub("H%x%x","H"))
	else tags=tags:gsub("^{","{"..tag.."0")
	end
	return tags
end

function shiftsel2(sel,i,mode)
	if i<sel[#sel] then
	for s=1,#sel do if sel[s]>i then sel[s]=sel[s]+1 end end
	end
	if mode==1 then table.insert(sel,i+1) end
	table.sort(sel)
return sel
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

herpderp=[[
Regular Fade: type only 'Fade in' / 'Fade out' values.

Checking 'Alpha/Colour' will use alpha transform instead, with the 'Fade in/out' values and 'accel'.
Checking 'From/To' colours will do colour transforms (with accel). If only one checked, the other will be alpha transform.
'Keep fade along with colour transforms' - when using colour transforms, the \fad tag will be kept as well.

'Fade across multiple lines' will create a set of alpha transforms across lines.
This can be used if you want to fade out a whole part of a conversation. Like people walking away and talking, sound gets quieter...
This nukes all present alpha tags. It supports shadow alpha (\4a).

'Global time' will use times relative to video, rather the combined times of lines. This makes a difference with gaps between lines.


By Letter

This fades each letter separately, in a sequence.
The dropdown menu is the fading time for each letter, while Fade in/out are for the overall fades.
So if you have 10 characters and use 120ms/letter and 1200ms Fade in, the fades will follow perfectly one after another.
If the Fade in is 1000 ms, they will overlap a little. If 500ms, you'll have about 3 letters fading at a time.

'RTL' fades right to left.

'Delete' removes a letter-by-letter fade (by removing all transforms and alphas).

'Letter by letter using \ko' uses {\ko#} tags instead of transforms for fade in.
If the Fade in is under 40, it's used as \ko[value]; if it's 40+, it's considered to be the overall fade, i.e. when the last letter appears.
'\ko by word' fades in by word instead of by letter.
(Inline tags are supported, but if you fade by word and have tags in the middle of a word, it won't work as you want it to.
Also, \ko actually works with decimal values, like \ko4.6.)

'Fade in to current frame' - sets fade in to current video frame.
'Fade out from current frame' - sets fade out from current video frame.
These are for setting fades very easily without requiring any numbers.
The current frame will be the first/last fully visible, so for Fade in, set to the first frame after the fade, not the last frame of the fade.


By Clip

This is a simple clip transform, making text appear from the left and disappear to the right, based on fade in/out values.
As a bonus, when the fades are both 0, it will just create a clip around the text. This supports font name, size, spacing, scaling, border, shadow, and weight, but not italics, rotations, fax & fay, and not inline tags. It can handle linebreaks. With \move, it's somewhat applicable, but it only considers the starting position, so not very useful in most cases.
This is dealing with fonts, and fonts are a clusterfuck of uncertainty, so things aren't always 100% accurate. As a dirty workaround to make sure the clip isn't just a bit too small, you can check 'Clip +' to expand the clip by 3 pixels in each direction.
The fades in and out may overlap, but the second transform is calculated from the ongoing first transform, so things get a bit unpredictable there. (Not like you would reasonably ever need this, though.)
Only fade in/out and accel apply here from the other options.


Tags

This is for transforms from and to given tags. The difference from just using HYDRA for transforms is that this allows you to do it in a "fade" approach for the times, which is convenient mainly for the end transforms. Plus you can combine this with alpha/colour transforms with different settings in one run. (This was previously implemented for blur only, in a different manner.)

You must input valid transformable tags, with values. Example: "\blur5\fs10\fsp4\fax0.2"

Tags are used for both In and Out (if those values aren't "0"), but if you check 'Mirror tags', the values for Fade out will be mirrored for frz, fry, fax, and xshad, meaning they will be the opposite of Fade in. This allows for keeping some symmetry.
But you can always run it once for Fade in and once for Fade out, if you want different tags.

This is activated by the Apply Fade button and can run along with alpha/colour transforms. What determines what runs and what doesn't is whether the in/out times are both zero or not.


'[Help]' - shows Help, which you're currently reading.

'Remember last settings' - the GUI will remember your last used values (until automation reload).

'Repeat last' - runs with values used last time.

'[Save config]' - saves your current settings as defaults.


Extra functionality:
Fade between 0 and 1 gives you that fraction of the line's duration, so Fade in 0.2 with 1 second is \fad(200,0).
Fade value of 1 is the duration of the whole line.
Negative fade gives you the inverse with respect to duration, so if dur=3000 & fade in is -500, you get \fad(2500,0), i.e. 500 from end.



>Fadeworks<

This was created for various fbf fade effects that focus more on replicating lines than alpha fade. The idea was to add lines before start time and after end time and do things you can't do with transforms. The main part is shifting position, including using acceleration, so you can create linear movement with accel or all kinds of other moves.

Each side of the GUI is separate; left for 'fade in', right for 'fade out'.

'Lines to create' is how many lines will be created before and after the current line. If set to '0', the effect for that side is disabled.

'Frames per line' is the duration of each created line.

'Shift each line by' is the timing difference between the lines.
This is generally best to leave the same as the setting above it. With values of '1', you get regular fbf lines. Values of '2' would make consecutive 2-frame lines. If the duration is larger than this setting, lines will overlap (which may be used as a special effect). If this setting is larger than the duration, there will be time gaps between the lines (which probably isn't too useful).

'X/Y distance' is where the starting/ending point will be relative to current \pos.
If X is -100 and 100 respectively, the line will start 100 pixels to the left of where it is now and end 100 to the right, no matter how many lines you put in between.

'Acceleration' is separate for each element, as that allows for more effects.
In fact, the accel on the X/Y movement is one of the main points of this.
Due to how this is written, using the same accel on the left and right kind of mirrors it in the result, which is what you'll usually want.
(If left starts slow, right ends slow.)

'fbf transform' - you can type some tags, like \bord10, and border will be 10 on the outer lines (first of fade in, last of fade out) and transform frame by frame to whatever value you have on the main line. The main line should always remain unchanged.

'fbf alpha tf' is just an extra field to enter alpha values for the above (in hexadecimal, like "FF") to avoid having to type the whole thing.
The fbf transform field can actually handle even colours, but you have to type them. You can use the 'get colours' tool.
Set a colour, click on 'Get colour tag', and you'll get the tag in the field next to the colour picker. Copypaste from there.
Change \c to whichever colour type you need.
This has its own accel.

'Fade mode' is pretty weird and hard to explain, but it should be used on lines that have fades. The replicated lines will use those fades, and the idea is to create fading lines that overlap with one another in different positions.
This mode disables 'Frames per line'.
You can 'add transforms' to this, but just like the fades, these will reset on each line, and the effect is kind of bizarre and requires some experimentation to get something useful out of it.
It does work combined with the fbf transforms, but the results may be a bit unpredictable and bad, and they will look different for fade in and fade out.

If you find an effect you want to keep for later, there's a mini GUI for saving the settings.
You can Save, Load, and Delete presets.]]

function fadehelp(subs,sel)
	Pr=aegisub.dialog.display({{width=50,height=20,class="textbox",value=herpderp}},{"OK","Back"},{close='OK'})
	if Pr=="Back" then fadeconfig(subs,sel) end
end

--	FW SAFE		--
function fwsafe()
	FWS={}
	fwconf=ADP("?user").."\\fadeworksafe.conf"
	file=io.open(fwconf)
	-- read saved
	if file~=nil then
		FWsaved=file:read("*all")
		file:close()
		for f in FWsaved:gmatch("FWS: ([^\n]+)") do table.insert(FWS,f) end
	end
	vault={
	{x=0,y=0,class="label",label="Save as:"},
	{x=1,y=0,class="edit",name="fwsave"},
	{x=0,y=1,class="label",label="Load/Delete:"},
	{x=1,y=1,class="dropdown",name="fwload",items=FWS,value=FWS[1]},
	{x=0,y=2,width=2,class="label",label="This is a GUI within a GUI within a GUI............................"},
	}
	
	repeat
	-- DELETE
	if Pf=="Expunge" and rs.fwload~="" then
		delName=rs.fwload
		file=io.open(fwconf)
		FWsaved=file:read("*all")
		file:close()
		-- del from text
		Wmod=FWsaved:gsub("FWS: "..esc(delName)..".-"..esc(delName).." END\n\n","")
		-- resave file
		file=io.open(fwconf,"w")
		file:write(Wmod)
		file:close()
		-- remove from list
		for i=1,#FWS do
			if FWS[i]==delName then table.remove(FWS,i) break end
		end
		for key,val in ipairs(vault) do
			if val.name=="fwload" then val.value=FWS[1] end
		end
		t_error("'"..delName.."' deleted.")
	end
	if Pf=="Expunge" and rs.fwload=="" then t_error("Nothing to delete") end
	Pf,rs=ADD(vault,{"Inhume","Exhume","Expunge","Vanish"},{close='Vanish'})
	until Pf~="Expunge"
	
	-- SAVE
	if Pf=="Inhume" then
		FWN=rs.fwsave
		saveOK=1
		-- name check
		if FWN=='' then t_error("No name given") saveOK=nil end
		for i=1,#FWS do
			if FWN==FWS[i] then t_error("Name '"..FWN.."' already exists") saveOK=nil break end
		end
		-- save
		if saveOK then 	
			WorkS='FWS: '..FWN..'\n'
			for key,val in ipairs(fadegui) do
				if val.class~="label" then WorkS=WorkS..val.name..":"..tf(rez[val.name]).."\n" end
			end
			WorkS=WorkS..FWN..' END\n\n'
			if file==nil then file=io.open(fwconf,"w") else file=io.open(fwconf,"a") end
			file:write(WorkS)
			file:close()
			t_error("Saved as '"..FWN.."'")
		end
	end
	-- LOAD
	if Pf=="Exhume" then
		toload=rs.fwload
		if file==nil then t_error("Nothing to load")
		elseif toload=='' then t_error("No name given")
		else
			fwloaded=FWsaved:match("FWS: "..esc(toload).."\n(.-\n)"..esc(toload).." END")
			for key,val in ipairs(fadegui) do
			    if val.class~="label" then
			      if fwloaded:match(val.name) then val.value=detf(fwloaded:match(val.name..":(.-)\n")) end
			    end
			end
		end
	end
end

--	Config		--
function saveconfig()
fadconf="Fade config\n\n"
  for key,val in ipairs(GUI) do
    if val.class:match"edit" or val.class=="dropdown" then
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
	    if val.class:match"edit" or val.class=="checkbox" or val.class=="dropdown" then
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

function apply_fade(subs,sel)
	ADD=aegisub.dialog.display
	ADP=aegisub.decode_path
	ak=aegisub.cancel
	STAG="^{\\[^}]-}"
	sel=fadeconfig(subs,sel)
	aegisub.set_undo_point(script_name)
	return sel
end

if haveDepCtrl then
  depRec:registerMacros({
	{script_name,script_description,apply_fade},
	{": HELP : / FadeWorkS","FadeWorkS",fadehelp},
  },false)
else
	aegisub.register_macro(script_name,script_description,apply_fade)
	aegisub.register_macro(": HELP : / FadeWorkS","FadeWorkS",fadehelp)
end