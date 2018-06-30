-- Manual: http://unanimated.hostfree.pw/ts/scripts-manuals.htm#linebreak

script_name="Line Breaker"
script_description="Breaks lines"
script_author="unanimated"
script_version="2.4"
script_namespace="ua.LineBreaker"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="2.4.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

re=require'aegisub.re'

function setupcheck()
	file=io.open(breaksetup)
	if file==nil then setup() end
end

nnngui={
	{x=0,y=0,width=2,class="label",label="---------------- Line Breaker Setup ----------------"},
	{x=0,y=1,class="label",label="min. characters:"},
	{x=1,y=1,class="intedit",name="minchar",value=0},
	{x=0,y=2,class="label",label="min. words:"},
	{x=1,y=2,class="intedit",name="minword",value=3},
	{x=0,y=3,width=2,class="checkbox",name="middle",label="linebreak in the middle if all else fails",value=true},
	{x=0,y=4,class="label",label="^ min. characters:"},
	{x=1,y=4,class="intedit",name="midminchar",value=0},
	{x=0,y=5,width=3,class="checkbox",name="forcemiddle",label="force breaks in the middle",hint="rather than after commas etc."},
	{x=0,y=6,width=3,class="checkbox",name="disabledialog",label="disable dialog for making manual breaks"},
	{x=0,y=7,width=3,class="checkbox",name="allowtwo",label="allow a break if there are only two words",value=true},
	{x=0,y=8,width=3,class="checkbox",name="balance",label="enable balance checks",value=true,hint="check ratio between top and bottom line"},
	{x=0,y=9,class="label",label="^ max. ratio:"},
	{x=1,y=9,class="floatedit",name="maxratio",value=2.2},
	{x=0,y=10,width=3,class="checkbox",name="nobreak1",label="don't break 1-liners",hint="disables manual breaking && break between 2"}
}

function setup()
file=io.open(breaksetup)
	if file~=nil then
		konf=file:read("*all")
		io.close(file)
		for k,v in ipairs(nnngui) do
			if v.class=="checkbox" or v.class:match"edit" then
				if konf:match(v.name) then v.value=detf(konf:match(v.name..":(.-)\n")) end
			end
		end
	end
	P,res=ADD(nnngui,{"Save","Cancel"},{ok='Save',close='Cancel'})
	if P=="Cancel" then ak() end
	nnncf="Line Breaker Settings\n\n"
	for k,v in ipairs(nnngui) do
		if v.class=="checkbox" then nnncf=nnncf..v.name..":"..tf(res[v.name]).."\n" end
		if v.class:match"edit" then nnncf=nnncf..v.name..":"..res[v.name].."\n" end
	end
   
	file=io.open(breaksetup,"w")
	file:write(nnncf)
	file:close()
	ADD({{class="label",label="Config Saved to:\n"..breaksetup}},{"OK"},{close='OK'})
	ak()
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
	else ret=tonumber(txt) end
	return ret
end

function readconfig()
file=io.open(breaksetup)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	min_characters=detf(konf:match("minchar:(.-)\n"))
	min_words=detf(konf:match("minword:(.-)\n"))
	put_break_in_the_middle=detf(konf:match("middle:(.-)\n"))
	middle_min_char=detf(konf:match("midminchar:(.-)\n"))
	force_middle=detf(konf:match("forcemiddle:(.-)\n"))
	disable_dialog=detf(konf:match("disabledialog:(.-)\n"))
	allow_two=detf(konf:match("allowtwo:(.-)\n"))
	balance_checks=detf(konf:match("balance:(.-)\n"))
	max_ratio=detf(konf:match("maxratio:(.-)\n"))
	do_not_break_1liners=detf(konf:match("nobreak1:(.-)\n"))
    end
end

function cuts()
	ADD=aegisub.dialog.display
	ADP=aegisub.decode_path
	ak=aegisub.cancel
	STAG="^{>?\\[^}]-}"
	breaksetup=ADP("?user").."\\lbreak.conf"
end

function nnn(subs,sel)
	cuts()
	setupcheck()
	readconfig()
	for i=1,#subs do
		if subs[i].class=="style" then
			local st=subs[i]
			if st.name=="Default" then defaref=st defleft=st.margin_l defright=st.margin_r end
		end
		if subs[i].class=="info" then
			local k=subs[i].key
			local v=subs[i].value
			if k=="PlayResX" then resx=v end
			if k=="PlayResY" then resy=v end
		end
		if subs[i].class=="dialogue" then break end
	end

	for z,i in ipairs(sel) do
		line=subs[i]
		text=line.text
		if line.effect=="setup" then setup() end
		if aegisub.progress.is_cancelled() then ak() end
		aegisub.progress.title("Processing line: "..z.."/"..#sel)
		if line.style=="Default" then styleref=defaref else styleref=stylechk(subs,line.style) end
		
		if text:match("\\N") then
			text=text:gsub(" *{\\i0}\\N{\\i1} *"," "):gsub("\\N","\n"):gsub(" *\n+ *"," "):gsub("(%w)— (%w)","%1—%2")
		else
			text=line_breaker(text)
		end
		line.text=text
		subs[i]=line
	end
	ALLSP=nil
end

function line_breaker(text)
	text=text:gsub("([%.,%?!]) $","%1")
	nocom=text:gsub("%b{}","")	nocomlength=nocom:len()
	tags=text:match(STAG) or ""
	stekst=text:gsub(STAG,"")
	repeat stekst,r=stekst:gsub("{[^\\}]-}$","") until r==0
	tekst=stekst
	-- fill spaces in comments
	tekst=tekst:gsub("{[^\\}]-}",function(c) return c:gsub(" ","__") end)

	-- get max width of a line in pixels
	width,height,descent,ext_lead=aegisub.text_extents(styleref,nocom)
	xres,yres,ar,artype=aegisub.video_size()
	if xres==nil then xres=resx yres=resy end
	realx=xres/yres*resy
	wf=realx/resx
	if line.style=="Default" then vidth=realx-(defleft*wf)-(defright*wf)
	else vidth=realx-(styleref.margin_l*wf)-(styleref.margin_r*wf) end

	-- count words
	wrd=0	for word in nocom:gmatch("%S+") do wrd=wrd+1 end

	-- put breaks after . , ? ! — that are not at the end
	tekst=tekst:gsub("([^%.])%. ","%1. \\N")
	:gsub("([^%.])%.({\\[^}]-}) ","%1.%2 \\N")
	:gsub("([,!%?:;]) ","%1 \\N")
	:gsub("([,!%?:;])({\\[^}]-}) ","%1%2 \\N")
	:gsub("([%.,])\" ","%1\" \\N")
	:gsub("(%w+)—(%w+)","%1—\\N%2")
	:gsub("%.%.%. ","... \\N")
	:gsub("([DM][rs]s?%.) \\N","%1 ")

	-- remove comma breaks if . or ? or !
	if tekst:match("[%.%?!] \\N") and tekst:match(", \\N") then tekst=tekst:gsub(", \\N",", ") end

	tekst=reduce(tekst)	-- remove breaks if there are more than one; leave the one closer to the centre
	tekst=balance(tekst)	-- balance of lines - ratio check 1

	-- if breaks removed and there's a comma
	if not tekst:match("\\N") then
		tekst=tekst:gsub(", ",", \\N"):gsub(",({\\[^}]-}) ",",%1 \\N")
		:gsub("^([%w']+, )\\N","%1"):gsub(", \\N(%S+)$",", %1")
	end
	tekst=reduce(tekst)

	-- balance of lines - ratio check 2
	ratio=nil	tekst=balance(tekst)	backup1=nil
	if tekst:match("[^.,] \\N") and ratio~=nil and ratio>=2 and max_ratio>ratio then backup1=tekst ratio1=ratio tekst=db(tekst) end

	if wrd>5 then testxt=tekst:gsub("^[%w%p]+ [%w%p]+(.-)[%w%p]+ [%w%p]+$","%1") else testxt=tekst end

	-- if no linebreak in line, put breaks before selected words, in 3 rounds
	words1={" but "," and "," if "," when "," because "," 'cause "," yet "," unless "," with "," without "," whether "," where "," why "," as well as "}
	words2={" or "," nor "," for "," from "," before "," after "," at "," that "," since "," until "," while "," behind "," beyond "," than "," over "," above "," via "}
	words3={" about "," into "," to "," how "," is "," isn't "," was "," wasn't "," has "," hasn't "," are "," aren't "," were "," weren't "," won't "," the "," a "," an "}
	tekst=words(words1)
	tekst=words(words2)
	tekst=words(words3)

	-- insert break in the middle of the line
	if force_middle then tekst=db(tekst) end
	if put_break_in_the_middle and nocomlength>=middle_min_char and not tekst:match("\\N") then
		tekst="\\N"..tekst
		diff=250
		stop=0
		while stop==0 do
			last=tekst
			repeat tekst,r1=tekst:gsub("\\N(%b{})","%1\\N") tekst,r2=tekst:gsub("\\N([^%s{}]+)","%1\\N") until r1==0 and r2==0
			tekst=tekst:gsub("\\N "," \\N")
			btxt=tekst:gsub("%b{}","")
			beforespace=btxt:match("^(.-)\\N")	beforelength=beforespace:len()
			afterspace=btxt:match("\\N(.-)$")	afterlength=afterspace:len()
			tdiff=math.abs(beforelength-afterlength)
			if tdiff<diff then diff=tdiff else stop=1 tekst=last end
		end
	end

	-- shift breaks to better places
	backup2=tekst
	tekst=re.sub(tekst," (a|a[sn]|by|I|I'm|I'd|I've|I'll|the|for|that|o[nfr]|i[nf]|who|to) \\\\N([\\w\\-']+) "," \\\\N\\1 \\2 ")
	tekst=re.sub(tekst," \\\\N([oi]n) (because|and|but|when) "," \\1 \\\\N\\2 ")
	tekst=tekst
	:gsub(" (lots?) \\Nof "," %1 of \\N")
	:gsub(" (very) \\N(%S+) "," \\N%1 %2 ")
	:gsub(" \\Nme "," me \\N")
	:gsub("^ ","")
	tekstb=balance(tekst)
	if tekstb~=tekst then tekst=backup2 end

	double={"so that","no one","ought to","now that","it was","he was","she was","will be","there is","there are","there was","there were","get to","sort of","kind of","put it","each other","each other's","have to","has to","had to","having to","want to","wanted to","used to","able to","going to","supposed to","allowed to","tend to","due to","forward to","thanks to","not to","has been","have been","had been","filled with","full of","out of","into the","onto the","part with","more than","less than","make sure","give up","would be","wipe out","wiped out","real life","no matter","based on","bring up","think of","thought of","even if","even when","even though","grow up","grew up","grown up","other than","rather than","just because","write down","all kinds","so much","no more","ever since","someone else","one of","such a","such as","hope for","hopes for","hoped for","come about","came about"}
	for d=1,#double do
		dbl=double[d]
		d1,d2=dbl:match("([%a']+) ([%a']+)")
		btxt=tekst:gsub("%b{}","")
		if tekst:match(" "..d1.." \\N"..d2.." ") then
			bd=btxt:match("^(.-)"..d1.." \\N"..d2)	bd=bd:gsub("%b{}","")	blgth=bd:len()
			ad=btxt:match(d1.." \\N"..d2.."(.-)$")	ad=ad:gsub("%b{}","")	algth=ad:len()
			if blgth>algth then tekst=tekst:gsub(" "..d1.." \\N"..d2.." "," \\N"..d1.." "..d2.." ")
			else tekst=tekst:gsub(" "..d1.." \\N"..d2.." "," "..d1.." "..d2.." \\N") end
		end
	end
	nobreak={"sort of","kind of","full of","out of","based on","think of","thought of","one of","even if","even when","such a","such as"}
	nb=0
	for b=1,#nobreak do
		if tekst:match(nobreak[b].." \\N") then nb=1 end
	end
	if nb==0 then tekst=re.sub(tekst," (a|a[sn]|by|I|I'm|I'd|I've|I'll|the|for|o[nfr]|i[nf]|who) \\\\N([\\w\\-']+) "," \\\\N\\1 \\2 ") end
	if tekst:match(" by %a+ing \\N") then
		beforethat=tekst:match("^(.-)by %a+ing \\N")	beforethat=beforethat:gsub("%b{}","")	befrlgth=beforethat:len()
		afterthat=tekst:match("by %a+ing \\N(.-)$")	afterthat=afterthat:gsub("%b{}","")	afterlgth=afterthat:len()
		if befrlgth>afterlgth then tekst=tekst:gsub(" (by %a+ing) \\N"," \\N%1 ") end
	end

	if not tekst:match("\\N") and backup1~=nil then tekst=backup1 end
	if tekst:match("\\N") and backup1~=nil and ratio>=ratio1 then tekst=backup1 end

	-- character/word restrictions
	if nocomlength<min_characters or wrd<min_words then tekst=db(tekst) end

	-- break if there are only 2 words in the line
	if wrd==2 and allow_two then tekst=tekst:gsub("(%w+%p?) (%w+%p?) ?","%1 \\N%2") end
	
	-- don't break 1-liners if in settings
	if do_not_break_1liners and vidth>=width then tekst=db(tekst) end

	-- apply changes
	tekst=tekst:gsub("__"," ")
	tekst=tekst:gsub("%%","%%%%")
	text=text:gsub(esc(stekst),tekst)

	-- GUI for manual breaking
	if disable_dialog==false and not do_not_break_1liners and not text:match("\\N") or line.effect=="n" then
		after=text:gsub(STAG,""):gsub(" *\\[Nn] *"," ")
		if not ALLSP then
			dialog={{x=0,y=0,width=2,height=5,class="textbox",name="txt",value=after},
			{x=0,y=5,class="label",label="Use 'Enter' to make linebreaks  "},
			{x=1,y=5,class="checkbox",name="allspaces",label="'All spaces' for all lines       "}}
			Pr,res=ADD(dialog,{"OK","All spaces","Skip","Cancel"},{close='Cancel'})
		end
		if Pr=="Cancel" then ak() end
		if Pr=="Skip" then text=line.text end
		if Pr=="OK" then
			res.txt=res.txt:gsub("\n","\\N") :gsub("\\N "," \\N")
			text=tags..res.txt
		end
		if Pr=="All spaces" then if res.allspaces then ALLSP=true end
			after=after:gsub(" +"," \\N") :gsub("\\N\\N","\\N") text=tags..after
		end
		if line.effect=="n" then line.effect="" end
	end
	return text
end

function balance(tekst)
	if balance_checks and tekst:match("\\N") and not tekst:match("\\N%-") and wrd>4 then
		beforespace=tekst:match("^(.-) *\\N")	beforespace=beforespace:gsub("%b{}","")	beforelength=beforespace:len()
		afterspace=tekst:match("\\N(.-)$")	afterspace=afterspace:gsub("%b{}","")	afterlength=afterspace:len()
		if beforelength>afterlength then ratio=beforelength/afterlength else ratio=afterlength/beforelength end
		difflength=math.abs(beforelength-afterlength)
		wb=aegisub.text_extents(styleref,beforespace)
		wa=aegisub.text_extents(styleref,afterspace)
		if wb>wa then ratiop=wb/wa else ratiop=wa/wb end
		if ratio>max_ratio then tekst=db(tekst) end
		if nocomlength>50 and ratio>(max_ratio*0.95) or ratiop>(max_ratio*0.95) then tekst=db(tekst) end
		if nocomlength>70 and ratio>(max_ratio*0.9) or ratiop>(max_ratio*0.9) then tekst=db(tekst) end
			-- logg(tekst.."\n ratio: "..ratio.."     length: "..nocomlength)    logg("ratiop: "..ratiop)
		-- prevent 3-liners
		if wb>=vidth or wa>=vidth then tekst=db(tekst) end
	end
	return tekst
end

function reduce(tekst)
	if tekst:match("\\N.*\\N") then repeat
		beforespace,afterspace=tekst:match("^(.-)\\N.*\\N(.-)$")
		beforespace=beforespace:gsub("%b{}","")	beforelength=beforespace:len()
		afterspace=afterspace:gsub("%b{}","")	afterlength=afterspace:len()
		if beforelength>afterlength then tekst=tekst:gsub("^(.*)\\N(.-)$","%1%2") else tekst=tekst:gsub("^(.-)\\N","%1") end
	until not tekst:match("\\N.*\\N")
	end
	return tekst
end

function words(tab)
	if not tekst:match("\\N") and wrd>4 then
		for w=1,#tab do ord=tab[w]
			tekst=tekst:gsub(ord," \\N"..ord):gsub("\\N ","\\N")
		end
		tekst=reduce(tekst)
		tekst=balance(tekst)
	end
	return tekst
end

function db(t) t=t:gsub("\\N","") return t end
function logg(m) m=tf(m) or "nil" aegisub.log("\n "..m) end
function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function t_error(message,cancel) ADD({{class="label",label=message}},{"OK"},{close='OK'}) if cancel then ak() end end

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

function nshift(subs,sel)
    for z,i in ipairs(sel) do
        line=subs[i]
        text=line.text
	text=text:gsub("([%a%p])\\N([%a%p])","%1 \\N%2") 
		if not text:match("\\N") then text="\\N"..text end
		text=text:gsub("\\N([^%s{}]+ ?)$","%1")	-- end
		text=text:gsub("\\N([^%s{}]+ ?%b{} ?)$","%1") 	-- end
		text=text:gsub("\\N "," \\N")
		repeat text,r1=text:gsub("\\N(%b{})","%1\\N") text,r2=text:gsub("\\N([^%s{}]+)","%1\\N") until r1==0 and r2==0
		text=text:gsub("\\N "," \\N")
		text=text:gsub("\\N$","")
	line.text=text
	subs[i]=line
    end
end

function backshift(subs,sel)
    for z,i in ipairs(sel) do
        line=subs[i]
        text=line.text
	text=text:gsub("([%a%p])\\N([%a%p])","%1 \\N%2") 
		if not text:match("\\N") then text=text.."\\N" end
		text=text:gsub("^(%b{} ?[^%s{}]+ ?)\\N","%1")	-- start
		text=text:gsub("^([^%s{}]+ ?)\\N","%1")	-- start
		text=text:gsub(" \\N","\\N ")
		repeat text,r1=text:gsub("(%b{})\\N","\\N%1") text,r2=text:gsub("([^%s{}]+)\\N","\\N%1") until r1==0 and r2==0
		text=text:gsub("^\\N","")
	line.text=text
	subs[i]=line
    end
end

function shutup(subs) cuts() setup() end

if haveDepCtrl then
  depRec:registerMacros({
	{"Line Breaker/Insert Linebreak",script_description,nnn},
	{"Line Breaker/Shift Linebreak","Shift line break right",nshift},
	{"Line Breaker/Shift Linebreak Back","Shift line break left",backshift},
	{"Line Breaker/Setup","Line Breaker Setup",shutup},
  },false)
else
	aegisub.register_macro("Line Breaker/Insert Linebreak",script_description,nnn)
	aegisub.register_macro("Line Breaker/Shift Linebreak","Shift line break right",nshift)
	aegisub.register_macro("Line Breaker/Shift Linebreak Back","Shift line break left",backshift)
	aegisub.register_macro("Line Breaker/Setup","Line Breaker Setup",shutup)
end