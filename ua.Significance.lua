script_name="Significance"
script_description="Import stuff, number stuff, chapter stuff, replace stuff, do a significant amount of other stuff to stuff."
script_author="unanimated"
script_version="3.5"
script_namespace="ua.Significance"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="3.5.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

clipboard=require("aegisub.clipboard")
re=require'aegisub.re'

--	Significance GUI		------------------------------------------------------------------------------------------
function significance(subs,sel,act)
	ADD=aegisub.dialog.display
	ADP=aegisub.decode_path
	ak=aegisub.cancel
	ms2fr=aegisub.frame_from_ms
	fr2ms=aegisub.ms_from_frame
	ATAG="{[*>]?\\[^}]-}"
	STAG="^{[*>]?\\[^}]-}"
	COMM="{[^\\}]-}"
	aegisub.progress.title("Loading...")
	datata=datata or ""
	sub1=sub1 or ""
	sub2=sub2 or ""
	sub3=sub3 or 1
	for i=1,#subs do if subs[i].class=="dialogue" then line0=i-1 break end end
	msg={"If it breaks, it's your fault.","This should be doing something...","Breaking your computer. Please wait.","Unspecified operations in progress.","This may or may not work.","Trying to avoid bugs...","Zero one one zero one zero...","10110101001101101010110101101100001","I'm surprised anyone's using this","If you're seeing this for too long, it's a bad sign.","This might hurt a little.","Please wait... I'm pretending to work.","Close all your programs and run."}
	rm=math.random(1,#msg)	msge=msg[rm]
	if lastimp then dropstuff=lastuff lok=lastlog zerozz=lastzeros fld=lastfield mod0=lastmod0
	else dropstuff="replacer" lok=false zerozz="01" fld="effect" mod0="number lines" end
	g_impex={"import OP","import ED","import sign","import signs","export sign","import chptrs","update lyrics"}
	g_stuff={"save/load","replacer","lua calc","split text to actor/effect","reverse text","reverse words","reverse transforms","fake capitals","format dates","fill columns","split into letters (alpha)","explode","dissolve text","randomised transforms","what is the Matrix?","clone clip","clip2margins","duplicate and shift lines","extrapolate tracking","time by frames","convert framerate","transform \\k to \\t\\alpha","fix kara tags for fbf lines","make style from act. line","make comments visible","switch commented/visible","honorificslaughterhouse"}
	LN1=sel[1]-line0
	LN2=sel[#sel]-line0
	lin=LN1.."-"..LN2
	lin=lin:gsub("^(%d+)%-%1$","%1")
	if LN2-LN1+1>#sel then lin=lin:gsub("-"," ... #") end
	unconfig={
	-- Sub --
	{x=0,y=16,width=3,class="label",label="Left                                                    "},
	{x=3,y=16,width=3,class="label",label="Right                                                   "},
	{x=6,y=16,width=3,class="label",label="Mod                                                     "},
	{x=0,y=17,width=3,class="edit",name="rep1",value=sub1},
	{x=3,y=17,width=3,class="edit",name="rep2",value=sub2},
	{x=6,y=17,width=3,class="edit",name="rep3",value=sub3,hint="Numbers: start/repeat[limit]\nreplacer/lua calc: limit"},
	
	-- import
	{x=9,y=3,width=2,class="label",label="Import/Export"},
	{x=9,y=4,width=2,class="dropdown",name="mega",items=g_impex,value="import signs"},
	{x=11,y=4,class="checkbox",name="keep",label="keep line",value=true,},
	{x=9,y=5,width=3,class="checkbox",name="restr",label="style restriction (lyrics)",value=false,},
	{x=9,y=6,width=3,class="edit",name="rest"},
	
	-- chapters
	{x=9,y=7,class="label",label="Chapters"},
	{x=10,y=7,width=2,class="checkbox",name="intro",label="autogenerate \"Intro\"",value=true,},
	{x=9,y=8,width=2,class="label",label="chapter marker:"},
	{x=11,y=8,class="dropdown",name="marker",items={"actor","effect","comment"},value="actor"},
	{x=9,y=9,width=2,class="label",label="chapter name:"},
	{x=11,y=9,class="dropdown",name="nam",items={"comment","effect"},value="comment"},
	{x=9,y=10,width=2,class="label",label="filename from:"},
	{x=11,y=10,class="dropdown",name="sav",items={"script","video"},value="script"},
	{x=9,y=11,width=2,class="checkbox",name="chmark",label="chapter mark:",value=false,hint="just sets the marker. no xml."},
	{x=11,y=11,class="dropdown",name="chap",items={"Intro","OP","Part A","Part B","Part C","ED","Preview"},value="OP"},
	{x=9,y=12,width=3,class="edit",name="lang"},
	
	-- numbers
	{x=9,y=13,width=2,class="label",label="Numbers"},
	{x=9,y=14,width=2,class="dropdown",name="modzero",items={"number lines","number 12321","add to marker","zero fill","random"},value=mod0},
	{x=11,y=14,class="dropdown",name="zeros",items={"1","01","001","0001"},value=zerozz},
	{x=9,y=15,width=2,class="dropdown",name="field",items={"actor","effect","layer","style","text","left","right","vert","comment"},value=fld},
	{x=11,y=15,class="checkbox",name="intxt",label="in text",hint="numbers found in text"},
	
	-- stuff
	{x=0,y=15,class="label",label="&Stuff  "},
	{x=1,y=15,width=2,class="dropdown",name="stuff",items=g_stuff,value=dropstuff}, --dropstuff
	{x=3,y=15,class="dropdown",name="regex",items={"lua patterns","perl regexp"},value="perl regexp"},
	{x=4,y=15,class="checkbox",name="log",label="log",value=lok,hint="provides some information for many of the functions here"},
	{x=8,y=15,class="label",label="Marker:"},
	
	-- textboxes
	{x=0,y=0,width=9,height=15,class="textbox",name="dat",value=data},
	{x=9,y=1,width=3,class="label",label=" Selected Lines: "..#sel.." [#"..lin.."]"},
	
	-- help
	{x=9,y=0,width=3,class="dropdown",name="help",
	items={"--- Help menu ---","Import/Export","Update Lyrics","Do Stuff","Numbers","Chapters"},value="--- Help menu ---"},
	{x=9,y=17,width=3,class="label",label="   Significance version: "..script_version},
	}
	loadconfig()
	repeat
		if P=="&Help" then aegisub.progress.title("Loading Help") aegisub.progress.task("RTFM")
			if res.help=="Import/Export" then help=help_i end
			if res.help=="Update Lyrics" then help=help_u end
			if res.help=="Do Stuff" then help=help_d end
			if res.help=="Numbers" then help=help_n end
			if res.help=="Chapters" then help=help_c end
			if res.help=="--- Help menu ---" then help="Choose something from the menu, dumbass -->" end
			for key,val in ipairs(unconfig) do if val.name=="dat" then val.value=help end end
		end
		if P=="&Info" then aegisub.progress.title("Gathering Info") aegisub.progress.task("...") info(subs,sel,act)
			for key,val in ipairs(unconfig) do if val.name=="dat" then val.value=infodump end end
		end
	P,res=ADD(unconfig,{"Import/Export","Do &Stuff","&Numbers","&Chapters","&Repeat Last","&Info","&Help","Save Config","Cancel"},{ok='Import/Export',cancel='Cancel'})
	until P~="&Help" and P~="&Info"
	if P=="Cancel" then    ak() end
	lastimp=true lastuff=res.stuff lastlog=res.log lastzeros=res.zeros lastfield=res.field lastmod0=res.modzero
	if P=="&Repeat Last" then if not lastres then ak() end P=lastP res=lastres end
	progress("Doing Stuff") aegisub.progress.task(msge)
		sub1=res.rep1
		sub2=res.rep2
		sub3=res.rep3
		zer=res.zeros
	if P=="Import/Export" then    important(subs,sel,act) end
	if P=="&Numbers" then    numbers(subs,sel) end
	if P=="&Chapters" then    chopters(subs,sel) end
	if P=="Do &Stuff" then
		if res.stuff=="convert framerate" then framerate(subs)
		elseif res.stuff=="honorificslaughterhouse" then honorifix(subs,sel)
		else sel=stuff(subs,sel,act) end
	end
	lastP=P
	lastres=res
	if P=="Save Config" then saveconfig() end

	return sel
end





--	IMPORT/EXPORT	--------------------------------------------------------------------------------------------
function important(subs,sel,act)
	aline=subs[act]
	atext=aline.text
	atags=atext:match("^{(\\[^}]-)}") or ""
	atags=atags:gsub("\\move%b()","")
	atxt=atext:gsub(STAG,"")
	-- create table from user data (lyrics)
	sdata={}
	if res.mega=="update lyrics" and res.dat=="" then t_error("No lyrics given.",1)
	else
		res.dat=res.dat.."\n"
		for dataline in res.dat:gmatch("(.-)\n") do if dataline~="" then table.insert(sdata,dataline) end end
	end

	-- user input
	sub1=res.rep1
	sub2=res.rep2
	sub3=res.rep3
	zer=res.zeros
	rest=res.rest

	-- this checks whether the pattern for lines with lyrics was found
	songcheck=0

	-- paths
	scriptpath=ADP("?script")
	if script_path=="relative" then path=scriptpath.."\\"..relative_path end
	if script_path=="absolute" then path=absolute_path end

	-- IMPORT --
	if res.mega:match("import") and not res.mega:match("chptrs") then

		noshift=false	defect=false	keeptxt=false	deline=false

		-- import-single-sign GUI
		if res.mega=="import sign" then
			press,reslt=ADD({
			{x=0,y=0,class="label",label="File name:"},
			{x=0,y=1,width=2,class="edit",name="signame"},
			{x=1,y=0,width=2,class="dropdown",name="signs",items={"title","eptitle","custom","eyecatch"},value="custom"},
			{x=2,y=1,class="label",label=".ass"},
			{x=0,y=2,width=3,class="checkbox",name="matchtime",label="keep current line's times",value=true,},
			{x=0,y=3,width=3,class="checkbox",name="keeptext",label="keep current line's text",value=false,},
			{x=0,y=4,width=3,class="checkbox",name="keeptags",label="combine tags (current overrides) ",value=false,},
			{x=0,y=5,width=3,class="checkbox",name="addtags",label="combine tags (imported overrides)",value=false,},
			{x=0,y=6,width=3,class="checkbox",name="noshift",label="don't shift times (import as is)",value=false,},
			{x=0,y=7,width=3,class="checkbox",name="deline",label="delete original line",value=false,},
			},{"OK","Cancel"},{ok='OK',close='Cancel'})
			if press=="Cancel" then ak() end
			if reslt.signs=="custom" then signame=reslt.signame else signame=reslt.signs end
			noshift=reslt.noshift		keeptxt=reslt.keeptext	deline=reslt.deline
			keeptags=reslt.keeptags		addtags=reslt.addtags
		end

		-- read signs.ass
		if res.mega=="import signs" then
			file=io.open(path.."signs.ass")
			if file==nil then ADD({{class="label",label=path.."signs.ass\nNo such file."}},{"ok"},{cancel='ok'}) ak() end
			signs=file:read("*all")
			io.close(file)
		end

		-- sort out if using OP, ED, signs, or whatever .ass and read the file
		songtype=res.mega:match("import (%a+)")
		if songtype=="sign" then songtype=signame end
		file=io.open(path..songtype..".ass")
		if file==nil then t_error(path..songtype..".ass\nNo such file.",1) end
		song=file:read("*all")
		io.close(file)

		-- cleanup useless stuff
		song=song:gsub("^.-(Dialogue:)","%1")
		song=song.."\n"
		song=song:gsub("\n\n$","\n")
		song=song:gsub("%[[^%]]-%]\n","\n")
		-- make table out of lines
		slines={}
		for sline in song:gmatch("(.-)\n") do
			if sline~="" then table.insert(slines,sline) end
		end
		-- save (some) current line properties
		btext=atext
		basetime=aline.start_time
		basend=aline.end_time
		basestyle=aline.style
		baselayer=aline.layer

		-- import-signs list and GUI
		if res.mega=="import signs" then
			-- make a table of signs in signs.ass
			signlist={}
			signlistxt=""
			for x=1,#slines do
				efct=slines[x]:match("%a+: %d+,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-(,[^,]-,).*")
				esfct=esc(efct)
				if not signlistxt:match(esfct) then signlistxt=signlistxt..efct end
			end
			for sn in signlistxt:gmatch(",([^,]-),") do table.insert(signlist,sn) end
			-- import-signs GUI
			button,reslt=ADD({
			{x=0,y=0,class="label",label="Choose a sign to import:"},
			{x=0,y=1,class="dropdown",name="impsign",items=signlist,value=signlist[1]},
			{x=0,y=2,class="checkbox",name="matchtime",label="keep current line's times",value=true,},
			{x=0,y=3,class="checkbox",name="keeptext",label="keep current line's text",value=false,},
			{x=0,y=4,class="checkbox",name="keeptags",label="combine tags (current overrides) ",value=false,},
			{x=0,y=5,class="checkbox",name="addtags",label="combine tags (imported overrides)",value=false,},
			{x=0,y=6,class="checkbox",name="noshift",label="don't shift times (import as is)",value=false,},
			{x=0,y=7,class="checkbox",name="defect",label="delete 'effect'",value=false,},
			{x=0,y=8,class="checkbox",name="deline",label="delete original line",value=false,},
			},{"OK","Cancel"},{ok='OK',close='Cancel'})
			if button=="Cancel" then ak() end
			if button=="OK" then whatsign=reslt.impsign end
			noshift=reslt.noshift		defect=reslt.defect	keeptxt=reslt.keeptext	deline=reslt.deline
			keeptags=reslt.keeptags		addtags=reslt.addtags
			-- nuke lines for the other signs
			for x=#slines,1,-1 do
				efct=slines[x]:match("%a+: %d+,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,([^,]-),.*")
				if efct~=whatsign then table.remove(slines,x) end
			end
		end

		-- check start time of the first line (for overall shifting)
		starttime=slines[1]:match("%a+: %d+,([^,]+)")
		shiftime=string2time(starttime)
		if res.mega:match("sign") and noshift then shiftime=0 end

		-- importing lines from whatever .ass
		for x=#slines,1,-1 do
			local ltype,layer,s_time,e_time,style,actor,margl,margr,margv,eff,txt=slines[x]:match("(%a+): (%d+),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),(.*)")
			l2=aline
			if ltype=="Comment" then l2.comment=true else l2.comment=false end
			l2.layer=layer
			-- timing/shifting depending on settings
			if res.mega:match("import sign") and reslt.matchtime then l2.start_time=basetime l2.end_time=basend else
			  s_time=string2time(s_time)
			  e_time=string2time(e_time)
			  if not noshift then s_time=s_time+basetime  e_time=e_time+basetime end
			  l2.start_time=s_time-shiftime
			  l2.end_time=e_time-shiftime
			end
			l2.style=style
			l2.actor=actor
			l2.margin_l=margl
			l2.margin_r=margr
			l2.margin_t=margv
			l2.effect=eff
			if defect then l2.effect="" end
			l2.text=txt
			atext=txt 
			if keeptxt and actor~="x" then
			    btext2=btext:gsub("{\\[^}]-}","")
			    l2.text=l2.text:gsub("^({\\[^}]-}).*","%1"..btext2) atext=btext2
			end
			if keeptags and actor~="x" then
			    l2.text=addtag(atags,l2.text)
			    l2.text=l2.text:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
			    :gsub("({%*?\\[^}]-})",function(tg) return extrakill(tg,2) end)
			end
			if addtags and actor~="x" then
			    l2.text="{"..atags.."}"..l2.text
			    l2.text=l2.text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
			    :gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
			    :gsub("({%*?\\[^}]-})",function(tg) return extrakill(tg,2) end)
			end
			subs.insert(act+1,l2)
		end
		-- delete line if not keeping
		if deline then res.keep=false end
		if not res.keep then subs.delete(act) else 
		-- keep line, restore initial state + comment out
		atext=btext aline.comment=true aline.start_time=basetime aline.end_time=basend aline.style=basestyle aline.actor="" aline.effect=""
		aline.layer=baselayer aline.text=atext subs[act]=aline
		end
	end

	-- EXPORT --
	if res.mega=="export sign" then
		exportsign=""
		for z,i in ipairs(sel) do
			line=subs[i]
			text=line.text
			if z==1 then snam=line.effect end
			exportsign=exportsign..line.raw.."\n"
		end
		press,reslt=ADD({
			{x=0,y=0,class="label",label="Target:",},
			{x=0,y=1,class="label",label="Name:",},
			{x=1,y=0,width=2,class="dropdown",name="addsign",
			items={"Add to signs.ass","Save to new file:"},value="Add to signs.ass"},
			{x=1,y=1,width=2,class="edit",name="newsign",value=snam},
			},{"OK","Cancel"},{ok='OK',close='Cancel'})
		if press=="Cancel" then ak() end
		if press=="OK" then
		if reslt.newsign=="" then t_error("No name supplied.",1) end
		newsgn=reslt.newsign:gsub("%.ass$","")
		if reslt.addsign=="Add to signs.ass" then 
			file=io.open(path.."signs.ass")
			if not file then file=io.open(path.."signs.ass","w") end
			sign=file:read("*all") or ""
			file:close()
			exportsign=exportsign:gsub("(%u%a+: %d+,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-),[^,]-,(.-)\n","%1,"..reslt.newsign..",%2\n")
			sign=sign:gsub("%u%a+: [^\n]+,"..esc(reslt.newsign)..",.-\n","") :gsub("^\n*","")
			sign=sign.."\n"..exportsign
			file=io.open(path.."signs.ass","w")
			file:write(sign)
		end
		if reslt.addsign=="Save to new file:" then
			file=io.open(path..newsgn..".ass","w")
			file:write(exportsign)
		end
		file:close()
		end
	end

	-- IMPORT CHAPTERS
	if res.mega=="import chptrs" then
		xml=aegisub.dialog.open("Chapters file (xml)","",scriptpath.."\\","*.xml",false,true)
		if xml==nil then ak() end
		file=io.open(xml)
		xmlc=file:read("*all")
		io.close(file)
		chc=0
		for ch in xmlc:gmatch("<ChapterAtom>(.-)</ChapterAtom>") do
			chnam=ch:match("<ChapterString>(.-)</ChapterString>")
			chtim=ch:match("<ChapterTimeStart>(.-)</ChapterTimeStart>")
			chtim=chtim:gsub("(%d%d):(%d%d):(%d%d)%.(%d%d%d?)(.*)",function(a,b,c,d,e) if d:len()==2 then d=d.."0" end return d+c*1000+b*60000+a*3600000 end)
			l2=aline
			if fr2ms(1)==nil then chs=chtim else chs=fr2ms(ms2fr(chtim)) end
			l2.start_time=chs
			l2.end_time=chs+1
			l2.actor="chptr"
			l2.text="{"..chnam.."}"
			subs.insert(act+chc,l2)
			chc=chc+1
		end
	end

	-- Update Lyrics
	if res.mega=="update lyrics" then
		sup1=esc(sub1)	sup2=esc(sub2)
		for z,i in ipairs(sel) do
			progress("Updating Lyrics... "..round(z/#sel)*100 .."%")
			line=subs[i]
			text=line.text
			
			songlyr=sdata
			if line.style:match(rest) then stylecheck=1 else stylecheck=0 end
			if res.restr and stylecheck==0 then pass=0 else pass=1 end
			if res.field=="actor" then marker=line.actor
			elseif res.field=="effect" then marker=line.effect end
			denumber=marker:gsub("%d","")
			-- marked lines
			if marker:match(sup1.."%d+"..sup2) and denumber==sub1..sub2 and pass==1 then
			    index=tonumber(marker:match(sup1.."(%d+)"..sup2))
			    puretext=text:gsub("{%*?\\[^}]-}","")
			    lastag=text:match("({\\[^}]-}).$")
			    if songlyr[index]~=nil and songlyr[index]~=puretext then
				text=text:gsub("^({\\[^}]-}).*","%1"..songlyr[index])
				if not text:match("^{\\[^}]-}") then text=songlyr[index] end
			    end
			    songcheck=1
			    if songlyr[index]~=puretext then
				if lastag~=nil then text=text:gsub("(.)$",lastag.."%1") end
				change="   (Changed)"
				else change=""
			    end
			    aegisub.log("\nupdate: "..puretext.." --> "..songlyr[index]..change)
			end
			line.text=text
			subs[i]=line
		end
	end

	if res.mega=="update lyrics" and songcheck==0 then press,reslt=ADD({{x=0,y=0,class="label",label="The "..res.field.." field of selected lines doesn't match given pattern \""..sub1.."#"..sub2.."\".\n(Or style pattern wasn't matched if restriction enabled.)\n#=number sequence"}},{"ok"},{cancel='ok'}) end
	noshift=nil		defect=nil	keeptxt=nil	deline=nil	keeptags=nil	addtags=nil
end





--	 NUMBERS	-------------------------------------------------------------------------------------------
function numbers(subs,sel)
	zl=zer:len()
	if sub3:match("[,/;]") then startn,int=sub3:match("(%d+)[,/;](%d+)") int=tonumber(int) else startn=sub3:gsub("%[.-%]","") int=1 end
	if sub3:match("%[") then numcycle=tonumber(sub3:match("%[(%d+)%]")) else numcycle=0 end
	if sub3=="" then startn=1 end
	startn=tonumber(startn)
	mark=res.field:gsub("left","margin_l"):gsub("right","margin_r"):gsub("vert","margin_t")
	if res.modzero=="number lines" and res.intxt then res.field='nope' end
	if res.modzero=="number 12321" then
		NB={}
		if numcycle==0 then t_error("You must set a counting limit 'Y': X[Y]",1) end
		for q=startn,numcycle do
			qq=0
			repeat
				table.insert(NB,q)
				qq=qq+1
			until qq>=int
		end
		for q=numcycle-1,startn+1,-1 do
			qq=0
			repeat
				table.insert(NB,q)
				qq=qq+1
			until qq>=int
		end
	end
	if res.modzero=="random" then
		if not tonumber(sub1) or not tonumber(sub2) then t_error("No valid input. \nUse Left and Right fields to set limits \nfor random number generation.",1) end
		if not tonumber(sub3) or tonumber(sub3)<1 then t_error("Error. Mod must be 1 or higher.",1) end
		if string.match("layer style text",res.field) then t_error("Invalid marker. \nOnly actor, effect, comment, and margins.",1)  end
		
		ranTab={}
		local R=math.ceil(#sel/sub3)
		for i=1,R do
			local rndm=round(math.random(sub1*1000,sub2*1000)/1000,zl-1)
			table.insert(ranTab,rndm)
		end
		
	end
	
	for z=1,#sel do
		i=sel[z]
		line=subs[i]
		text=line.text
		
		if res.modzero:match"number" then
		progress("Numbering... "..round(z/#sel)*100 .."%")
			if startn==nil or numcycle>0 and startn>numcycle then t_error("Wrong parameters. Syntax: start/repeat[limit]\nExamples:\n5    (5 6 7 8...)\n5/3    (5 5 5 6 6 6 7 7 7...)\n5/3[6]    (5 5 5 6 6 6 5 5 5 6 6 6...)\n5[6]    (5 6 5 6 5 6...)",1) end
			local Z=z
			if res.modzero=="number lines" then
				-- regular numbering
				count=math.ceil(Z/int)+(startn-1)
				if numcycle>0 and count>numcycle then
					repeat count=count-(numcycle-startn+1) until count<=numcycle
				end
			else	-- 1 2 3 4 5 4 3 2 1
				if Z>#NB then repeat Z=Z-#NB until Z<=#NB end
				count=NB[Z]
			end
			
			count=tostring(count)
			if zl>count:len() then repeat count="0"..count until zl==count:len() end
			if not mark:match'margin' and mark~='layer' then number=sub1..count..sub2 else number=count end
			
			if res.intxt then text=text:gsub("%d+",number)
			elseif mark=="comment" then text=text..wrap(number) 
			elseif mark=="text" then text=number
			else line[mark]=number
			end
		end
		
		if res.modzero=="add to marker" then
		progress("Adding... "..round(z/#sel)*100 .."%")
			if res.field=="actor" then line.actor=sub1..line.actor..sub2
			elseif res.field=="effect" then line.effect=sub1..line.effect..sub2
			elseif res.field=="text" then text=sub1..text..sub2
			end
		end
		
		if res.modzero=="zero fill" then
		progress("Filling... "..round(z/#sel)*100 .."%")
			form="%0"..zl.."d"
			mark=res.field
			aet="actoreffect"
			if aet:match(mark) then
				target=line[mark]
				target=target:gsub("(%d+)",function(d) return string.format(form,d) end)
				line[mark]=target
			end
			if mark=='text' then
				nt=''
				repeat
					seg,t2=text:match("^(%b{})(.*)")
					if not seg then seg,t2=text:match("^([^{]+)(.*)")
						if not seg then break end
						seg=seg:gsub("(%-?[%d.]+)",function(d)
						if tonumber(d)>0 and not d:match("%.%d") then return string.format(form,d) else return d end
						end)
					end
					nt=nt..seg
					text=t2
				until text==''
				text=nt
			end
		end
		
		if res.modzero=="random" then
			li=math.ceil(z/sub3)
			local num=0
			for t=1,#ranTab do
				if li==t then num=ranTab[t] break end
			end
			if mark:match "margin" and num<0 then num=0-num end
			if mark=="comment" then
				text=text..wrap("random: "..num)
			else
				line[mark]=num
			end
		end
		
		line.text=text
		subs[i]=line
	end
end





--	CHAPTERS	------------------------------------------------------------------------------------------------
function chopters(subs,sel)
    if res.marker=="effect" and res.nam=="effect" then t_error("Error. Both marker and name cannot be 'effect'.",1) end
    if res.chmark then
	if res.lang~="" then kap=res.lang else kap=res.chap end
	for z,i in ipairs(sel) do
		line=subs[i]
		text=line.text
		if res.marker=="actor" then line.actor="chptr" end
		if res.marker=="effect" then line.effect="chptr" end
		if res.marker=="comment" then text=text.."{chptr}" end
		if res.nam=="effect" then line.effect=kap end
		if res.nam=="comment" then text=nobra(text) text=wrap(kap)..text end
		line.text=text
		subs[i]=line
	end
    else
	euid=2013
	chptrs={}
	subchptrs={}
	if res.lang=="" then clang="eng" else clang=res.lang end
	
	for i=1,#subs do
		if subs[i].class=="info" then
			if subs[i].key=="Video File" then videoname=subs[i].value videoname=videoname:gsub("%.mkv","") end
		end
		if subs[i].class=="dialogue" then
			line=subs[i]
			text=line.text
			actor=line.actor
			effect=line.effect
			start=line.start_time
			if text:match("{[Cc]hapter}") or text:match("{[Cc]hptr}") or text:match("{[Cc]hap}") then comment="chapter" else comment="" end
			if res.marker=="actor" then marker=actor:lower() end
			if res.marker=="effect" then marker=effect:lower() end
			if res.marker=="comment" then marker=comment:lower() end
			
			if marker=="chapter" or marker=="chptr" or marker=="chap" then
				if res.nam=="comment" then
				name=text:match("^{([^}]*)}")
				name=name:gsub(" [Ff]irst [Ff]rame",""):gsub(" [Ss]tart",""):gsub("part a","Part A"):gsub("part b","Part B"):gsub("preview","Preview")
				else
				name=effect
				end
				
				if name:match("::") then main,subname=name:match("(.+)::(.+)") sub=1
				else sub=0
				end
				
				lineid=start+2013+i
				
				timecode=math.floor(start/1000)
				tc1=math.floor(timecode/60)
				tc2=timecode%60
				tc3=start%1000
				tc4="00"
				if tc2==60 then tc2=0 tc1=tc1+1 end
				if tc1>119 then tc1=tc1-120 tc4="02" end
				if tc1>59 then tc1=tc1-60 tc4="01" end
				if tc1<10 then tc1="0"..tc1 end
				if tc2<10 then tc2="0"..tc2 end
				if tc3<100 then tc3="0"..tc3 end
				linetime=tc4..":"..tc1..":"..tc2.."."..tc3
				if linetime=="00:00:00.00" then linetime="00:00:00.033" end
				
				if sub==0 then
				cur_chptr={id=lineid,name=name,tim=linetime}
				table.insert(chptrs,cur_chptr)
				else
				cur_chptr={id=lineid,subname=subname,tim=linetime,main=main}
				table.insert(subchptrs,cur_chptr)
				end
			end
			if line.style=="Default" then euid=euid+text:len() end
		end
	end

	-- subchapters
	subchapters={}
	for c=1,#subchptrs do
		local ch=subchptrs[c]
		ch_main=ch.main
		ch_uid=ch.id
		ch_name=ch.subname
		ch_time=ch.tim
		schapter="      <ChapterAtom>\n        <ChapterDisplay>\n          <ChapterString>"..ch_name.."</ChapterString>\n          <ChapterLanguage>"..clang.."</ChapterLanguage>\n        </ChapterDisplay>\n        <ChapterUID>"..ch_uid.."</ChapterUID>\n        <ChapterTimeStart>"..ch_time.."</ChapterTimeStart>\n        <ChapterFlagHidden>0</ChapterFlagHidden>\n        <ChapterFlagEnabled>1</ChapterFlagEnabled>\n      </ChapterAtom>\n"
		subchapter={main=ch_main,chap=schapter}
		table.insert(subchapters,subchapter)
	end

	-- chapters
	insert_chapters=""

	if res.intro then
		insert_chapters="    <ChapterAtom>\n      <ChapterUID>"..#subs.."</ChapterUID>\n      <ChapterFlagHidden>0</ChapterFlagHidden>\n      <ChapterFlagEnabled>1</ChapterFlagEnabled>\n      <ChapterDisplay>\n        <ChapterString>Intro</ChapterString>\n        <ChapterLanguage>"..clang.."</ChapterLanguage>\n      </ChapterDisplay>\n      <ChapterTimeStart>00:00:00.033</ChapterTimeStart>\n    </ChapterAtom>\n"
	end
	
	table.sort(chptrs,function(a,b) return a.tim<b.tim or (a.tim==b.tim and a.id<b.id) end)

	for c=1,#chptrs do
		local ch=chptrs[c]
		ch_uid=ch.id
		ch_name=ch.name
		ch_time=ch.tim
		local subchaps=""
		for c=1,#subchapters do 
		local subc=subchapters[c]
		if subc.main==ch_name then subchaps=subchaps..subc.chap end
		end
		chapter="    <ChapterAtom>\n      <ChapterUID>"..ch_uid.."</ChapterUID>\n      <ChapterFlagHidden>0</ChapterFlagHidden>\n      <ChapterFlagEnabled>1</ChapterFlagEnabled>\n      <ChapterDisplay>\n        <ChapterString>"..ch_name.."</ChapterString>\n        <ChapterLanguage>"..clang.."</ChapterLanguage>\n      </ChapterDisplay>\n"..subchaps.."      <ChapterTimeStart>"..ch_time.."</ChapterTimeStart>\n    </ChapterAtom>\n"
		insert_chapters=insert_chapters..chapter
	end
	
	chapters="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<Chapters>\n  <EditionEntry>\n    <EditionFlagHidden>0</EditionFlagHidden>\n    <EditionFlagDefault>0</EditionFlagDefault>\n    <EditionUID>"..euid.."</EditionUID>\n"..insert_chapters.."  </EditionEntry>\n</Chapters>"

	scriptpath=ADP("?script")
	scriptname=aegisub.file_name()
	scriptname=scriptname:gsub("%.ass","")
	if ch_script_path=="relative" then path=scriptpath.."\\"..ch_relative_path end
	if ch_script_path=="absolute" then path=ch_absolute_path end
	path=path:gsub("([^\\])$","%1/"):gsub("\\$","/")
	repeat path,r=path:gsub("\\[^\\]+\\%.%.[\\/]","/") until r==0
	if not videoname then videoname=aegisub.project_properties().video_file:gsub("^.*\\",""):gsub("%.mkv","") end
	if res.sav=="script" then filename=scriptname else filename=videoname end

	chdialog={
	{x=0,y=0,width=35,class="label",label="Text to export (You can edit it before saving/copying):"},
	{x=0,y=1,width=35,height=20,class="textbox",name="copytext",value=chapters},
	{x=0,y=21,width=35,class="label",label='File "'..filename..'.xml" will be saved in "'..path..'"\nIf you want to change the path, use Save Config.'},
	{x=35,y=0,width=12,class="label",label="You can also edit this && refresh"},	-- #4
	}
	q=1
	for chn in chapters:gmatch("<ChapterString>(.-)</ChapterString>") do
		table.insert(chdialog,{x=35,y=q,width=12,name='ch_'..q,class="edit",value=chn})
		q=q+1
	end
	repeat
		if pressed=="Refresh" then
			q=0
			reslt.copytext=reslt.copytext:gsub("(<ChapterString>).-(</ChapterString>)",function(a,b) q=q+1 return a..reslt["ch_"..q]..b end)
			for k,v in ipairs(chdialog) do
				if v.class=='edit' then v.value=reslt[v.name] end
				if v.name=='copytext' then v.value=reslt.copytext end
			end
		end
	pressed,reslt=ADD(chdialog,{"Save xml file","mp4-compatible chapters","Cancel","Copy to clipboard","Refresh"},{cancel='Cancel'})
	until pressed~="Refresh"
	chapters=reslt.copytext
	if pressed=="Copy to clipboard" then clipboard.set(chapters) end
	if pressed=="Save xml file" then
		local file=io.open(path..filename..".xml","w")
		if file==nil then os.execute("mkdir \""..path.."\"") file=io.open(path..filename..".xml","w") end
		if file==nil then t_error("File could not be saved. Probably path doesn't exist:\n"..path,1) end
		file:write(chapters)
		file:close()
	end
	if pressed=="mp4-compatible chapters" then
		mp4chap=""
		m4c=1
		for ch in chapters:gmatch("<ChapterAtom>(.-)</ChapterAtom>") do
			chnam=ch:match("<ChapterString>(.-)</ChapterString>")
			chtim=ch:match("<ChapterTimeStart>(.-)</ChapterTimeStart>")
			num=tostring(m4c)
			if num:len()==1 then num="0"..num end
			chnum="CHAPTER"..num
			mp4chap=mp4chap..chnum.."="..chtim.."\n"..chnum.."NAME="..chnam.."\n\n"
			m4c=m4c+1
		end
		chapters=mp4chap:gsub("\n\n$","")
		chdialog[2].value=chapters
		chdialog[3].label=chdialog[3].label:gsub('%.xml','_chapters.txt')
		for c=#chdialog,4,-1 do table.remove(chdialog,c) end
		pressed,reslt=ADD(chdialog,{"Save txt file","Cancel","Copy to clipboard"},{cancel='Cancel'})
		chapters=reslt.copytext
		if pressed=="Copy to clipboard" then clipboard.set(chapters) end
		if pressed=="Save txt file" then
			local file=io.open(path..filename.."_chapters.txt","w")
			if file==nil then os.execute("mkdir \""..path.."\"") file=io.open(path..filename.."_chapters.txt","w") end
			file:write(chapters)
			file:close()
		end
	end
    end
end





--	STUFF	---------------------------------------------------------------------------------------------------
function stuff(subs,sel,act)
    STAG="^{\\[^}]-}"
    repl=0
    data={}	raw=res.dat.."\n"
    for dataline in raw:gmatch("(.-)\n") do table.insert(data,dataline) end
    nsel={} for z,i in ipairs(sel) do table.insert(nsel,i) end
    orig_sel=#sel
    nope=nil
    
    if res.stuff=="make style from act. line" then
	line=subs[act]
	text=line.text
	sr=stylechk(subs,line.style)
	nontra=text:gsub("\\t%b()","")
	tags=nontra:match("^{\\[^}]-}") or ""
	
	a1=tags:match("\\1a&H(%x%x)&") or sr.color1:match("&H(%x%x)")
	a2=tags:match("\\2a&H(%x%x)&") or sr.color2:match("&H(%x%x)")
	a3=tags:match("\\3a&H(%x%x)&") or sr.color3:match("&H(%x%x)")
	a4=tags:match("\\4a&H(%x%x)&") or sr.color4:match("&H(%x%x)")
	color1=tags:match("\\1?c&H(%x%x%x%x%x%x)&") or sr.color1:match("&H%x%x(%x%x%x%x%x%x)&")
	color2=tags:match("\\2c&H(%x%x%x%x%x%x)&") or sr.color2:match("&H%x%x(%x%x%x%x%x%x)&")
	color3=tags:match("\\3c&H(%x%x%x%x%x%x)&") or sr.color3:match("&H%x%x(%x%x%x%x%x%x)&")
	color4=tags:match("\\4c&H(%x%x%x%x%x%x)&") or sr.color4:match("&H%x%x(%x%x%x%x%x%x)&")
	sr.color1="&H"..a1..color1.."&"
	sr.color2="&H"..a2..color2.."&"
	sr.color3="&H"..a3..color3.."&"
	sr.color4="&H"..a4..color4.."&"
	sr.bold=tags:match("\\b([01])") or sr.bold 
	sr.italic=tags:match("\\i([01])") or sr.italic 
	sr.underline=tags:match("\\u([01])") or sr.underline 
	sr.strikeout=tags:match("\\s([01])") or sr.strikeout 
	sr.fontname=tags:match("\\fn([^\\}]+)") or sr.fontname
	sr.fontsize=tags:match("\\fs(%d+)") or sr.fontsize 
	sr.scale_x=tags:match("\\fscx([^\\}]+)") or sr.scale_x
	sr.scale_y=tags:match("\\fscx([^\\}]+)") or sr.scale_y
	sr.spacing=tags:match("\\fsp([^\\}]+)") or sr.spacing
	sr.angle=tags:match("\\frz([^\\}]+)") or sr.angle
	sr.outline=tags:match("\\bord([^\\}]+)") or sr.outline
	sr.shadow=tags:match("\\shad([^\\}]+)") or sr.shadow
	sr.align=tags:match("\\an(%d)") or sr.align
	sr.margin_l=line.margin_l or sr.margin_l
	sr.margin_r=line.margin_r or sr.margin_r
	sr.margin_t=line.margin_t or sr.margin_t
	
	stylename={{class="label",label="Style Name"},{y=1,class="edit",name="snam",value=""},
	{y=2,class="checkbox",name="switch",label="switch to new style",value=true},
	{y=3,class="checkbox",name="del",label="delete style tags from line",value=true},
	}
	pres,rez=ADD(stylename,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if pres=="Cancel" then ak() end
	sr.name=rez.snam:gsub(",",";")
	if rez.del then
		tags=text:match(STAG)
		tags=tags
		:gsub("\\t(%b())",function(t) return "\\tra"..t:gsub("\\","/") end)
		:gsub("\\%d?[ac]%b&&","")
		:gsub("\\f[ns][^\\}]+","")
		:gsub("\\frz[^\\}]+","")
		:gsub("\\[ibus][01]","")
		:gsub("\\...d[^\\}]+","")
		:gsub("\\an%d","")
		:gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
		:gsub("{}","")
		line.text=text:gsub(STAG,tags)
		line.margin_l=0
		line.margin_r=0
		line.margin_t=0
	end
	if rez.switch then line.style=sr.name end
	subs[act]=line
	for i=1,#subs do
		if subs[i].class=="style" then
		    st=subs[i]
		    if st.name==sr.name then t_error("Style with that name already exists",1) end
		end
		if subs[i].class=="dialogue" then subs.insert(i,sr)
		for z,s in ipairs(sel) do sel[z]=sel[z]+1 end
		break end
	end
    end
    
    -- DATES GUI --
    if res.stuff=="format dates" then
	dategui=
	{{x=0,y=0,class="dropdown",name="date",value="January 1st",items={"January 1","January 1st","1st of January","1st January"}},
	{x=1,y=0,class="checkbox",name="log",label="log",value=false,}}
	pres,rez=ADD(dategui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if pres=="Cancel" then ak() end
	datelog=""
    end
    
    -- EXPLODE GUI --
    if res.stuff=="explode" then
	-- remember values
	if exploded then
	    exx=expl_dist_x exy=expl_dist_y htype=ex_hor vtype=ex_ver expropx=xprop expropy=yprop exf=exfad cfad=cfade
	    exinvx=xinv exinvy=yinv implo=implode exquence=exseq exkom=excom seqinv=invseq seqpercent=seqpc rmmbr=exremember
	else
	    exx=0 exy=0 htype="all" vtype="all" expropx=false expropy=false exf=0 cfad=0 exinvx=false exinvy=false
	    implo=false exquence=false exkom=false seqinv=false seqpercent=100 rmmbr=false
	end
	explodegui={
	{x=0,y=0,class="label",label="Horizontal distance: "},
	{x=1,y=0,class="floatedit",name="edistx",value=exx,hint="Maximum horizontal distance for move"},
	{x=0,y=1,class="label",label="Vertical distance: "},
	{x=1,y=1,class="floatedit",name="edisty",value=exy,hint="Maximum vertical distance for move"},

	{x=2,y=0,class="label",label="direction: "},
	{x=3,y=0,class="dropdown",name="hortype",value=htype,items={"only left","mostly left","all","mostly right","only right"}},
	{x=4,y=0,class="checkbox",name="xprop",label="proportional",value=expropx,hint="Uniform move rather than random"},
	{x=5,y=0,class="checkbox",name="xinv",label="inverse",value=exinvx,hint="Uniform move in the other direction"},

	{x=2,y=1,class="label",label="direction: "},
	{x=3,y=1,class="dropdown",name="vertype",value=vtype,items={"only up","mostly up","all","mostly down","only down"}},
	{x=4,y=1,class="checkbox",name="yprop",label="proportional",value=expropy,hint="Uniform move rather than random"},
	{x=5,y=1,class="checkbox",name="yinv",label="inverse",value=exinvy,hint="Uniform move in the other direction"},

	{x=0,y=2,class="checkbox",name="ecfo",label="Custom fade:",hint="Default is line length",value=cfad},
	{x=1,y=2,class="floatedit",name="exfad",value=exf},

	{x=2,y=2,class="checkbox",name="exseq",label="sequence",value=exquence,hint="move in a sequence instead of all at the same time"},
	{x=3,y=2,class="floatedit",name="seqpc",value=seqpercent,step=nil,min=1,max=100,hint="how much time should the sequence take up"},
	{x=4,y=2,class="label",label="% of move"},
	{x=5,y=2,class="checkbox",name="invseq",label="inverse",value=seqinv,hint="inverse sequence"},

	{x=0,y=3,class="checkbox",name="impl",label="Implode",value=implo},
	{x=1,y=3,class="checkbox",name="rem",label="Same for all lines",value=rmmbr,hint="use only for layered lines with the same text"},
	{x=3,y=3,class="checkbox",name="excom",label="Leave original line commented out",value=exkom,width=3},
	}
	pres,rez=ADD(explodegui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if pres=="Cancel" then ak() end
    	expl_dist_x=rez.edistx	expl_dist_y=rez.edisty
	exfad=rez.exfad		cfade=rez.ecfo
	ex_hor=rez.hortype	ex_ver=rez.vertype
	xprop=rez.xprop		yprop=rez.yprop
	xinv=rez.xinv		yinv=rez.yinv
	implode=rez.impl	exseq=rez.exseq
	seqpc=round(rez.seqpc)	invseq=rez.invseq
	exremember=rez.rem	excom=rez.excom
	exploded=true
    end
    
    -- Randomised Transforms GUI --
    if res.stuff=="randomised transforms" then
	rine=subs[sel[1]]
	durone=rine.end_time-rine.start_time
	rtgui={
	{x=0,y=0,class="checkbox",name="rtfad",label="Random Fade",width=2,value=true},
	{x=0,y=1,class="checkbox",name="rtdur",label="Random Duration",width=2,value=true},
	{x=2,y=0,class="label",label="Min: "},
	{x=2,y=1,class="label",label="Max: "},
	{x=3,y=0,class="floatedit",name="minfad",value=math.floor(durone/5),min=0},
	{x=3,y=1,class="floatedit",name="maxfad",value=durone},
	{x=4,y=0,class="checkbox",name="rtin",label="Fade In",width=3,value=false,hint="In instead of Out"},
	{x=4,y=1,class="checkbox",name="maxisdur",label="Max = Current Duration",width=4,value=true,hint="The maximum will be the duration of each selected line"},

	{x=0,y=2,class="checkbox",name="movet",label="t1+t2 in \\move",width=2,hint="use given timecodes in \\move"},
	{x=2,y=2,class="label",label="\\t 1"},
	{x=4,y=2,class="label",label="\\t 2"},
	{x=3,y=2,class="floatedit",name="t1",value=0},
	{x=5,y=2,class="floatedit",name="t2",value=0,width=3},

	{x=0,y=3,class="label",label="Transform"},
	{x=1,y=3,class="dropdown",name="rttag",value="blur",
	items={"blur","bord","shad","fs","fsp","fscx","fscy","fax","fay","frz","frx","fry","xbord","ybord","xshad","yshad"}},
	{x=2,y=3,class="label",label="Min: "},
	{x=4,y=3,class="label",label=" Max: "},
	{x=3,y=3,class="floatedit",name="mintfn",value=0,hint="Minimum value for a given tag"},
	{x=5,y=3,class="floatedit",name="maxtfn",width=3,value=0,hint="Maximum value for a given tag"},

	{x=0,y=4,class="label",width=2,label="Colour Transform"},
	{x=2,y=4,class="label",label="Max: "},
	{x=3,y=4,class="floatedit",name="rtmaxc",value=100,min=1,max=100,hint="Maximum % of colour change.\nColour tag must be present. Otherwise set to 100%."},
	{x=4,y=4,class="label",label="%"},
	{x=5,y=4,class="checkbox",name="rtc1",label="\\c ",value=true},
	{x=6,y=4,class="checkbox",name="rtc3",label="\\3c ",value=false},
	{x=7,y=4,class="checkbox",name="rtc4",label="\\4c ",value=false},

	{x=0,y=5,class="checkbox",name="rtacc",label="Use Acceleration",width=2,value=false},
	{x=2,y=5,class="label",label="Min: "},
	{x=3,y=5,class="floatedit",name="minacc",value=1,min=0},
	{x=4,y=5,class="label",label=" Max:"},
	{x=5,y=5,class="floatedit",name="maxacc",width=3,value=1,min=0},

	{x=0,y=6,class="checkbox",name="rtmx",label="Random Move X",width=2,value=false},
	{x=2,y=6,class="label",label="Min: "},
	{x=3,y=6,class="floatedit",name="minmx",value=0},
	{x=4,y=6,class="label",label=" Max:"},
	{x=5,y=6,class="floatedit",name="maxmx",width=3,value=0},

	{x=0,y=7,class="checkbox",name="rtmy",label="Random Move Y",width=2,value=false},
	{x=2,y=7,class="label",label="Min: "},
	{x=3,y=7,class="floatedit",name="minmy",value=0},
	{x=4,y=7,class="label",label=" Max:"},
	{x=5,y=7,class="floatedit",name="maxmy",width=3,value=0},
	}
	if rtremember then
	    for key,val in ipairs(rtgui) do
		if val.class~="label" then val.value=rez[val.name] end
	    end
	end
	rtchoice={"Fade/Duration","Number Transform","Colour Transform","Help","Cancel"}
	rthlp={"Fade/Duration","Number Transform","Colour Transform","Cancel"}
	pres,rez=ADD(rtgui,rtchoice,{ok='Fade/Duration',close='Cancel'})
	if pres=="Help" then
	    rthelp={x=0,y=8,width=8,height=6,class="textbox",value="This is supposed to be used after 'split into letters (alpha)' or with gradients.\n\nFade/Duration Example:  Min: 500, Max: 2000.\nA random number between those is generated for each line, let's say 850.\nThis line's duration will be 850ms, and it will have a 850ms fade out.\n\nNumber Transform Example:  Blur, Min: 0.6, Max: 2.5\nRandom number generated: 1.7. Line will have: \\t(\\blur1.7)\n\nRandom Colour Transform creates transforms to random colours. \nMax % transform limits how much the colour can change.\n\nAccel works with either transform function.\n\nRandom Move works as an additional option with any function.\nIt can be used on its own if you uncheck other stuff. Works with Fade In."}
	    table.insert(rtgui,rthelp)
	    pres,rez=ADD(rtgui,rthlp,{ok='Fade/Duration',close='Cancel'})
	end
	if pres=="Cancel" then ak() end
	if pres=="Fade/Duration" then RTM="FD" end
	if pres=="Number Transform" then RTM="NT" end
	if pres=="Colour Transform" then RTM="CT" end
	rtremember=true
	RTF=rez.rtfad	RTD=rez.rtdur
	MnF=rez.minfad	MxF=rez.maxfad
	RTin=rez.rtin	RTMax=rez.maxisdur
	RTT=rez.rttag	MnT=rez.mintfn		MxT=rez.maxtfn
	RTA=rez.rtacc	MnA=rez.minacc	MxA=rez.maxacc
	MnX=rez.minmx	MxX=rez.maxmx	MnY=rez.minmy	MxY=rez.maxmy
	MxC=round(rez.rtmaxc*255/100)
	rtcol={}
	if rez.rtc1 then table.insert(rtcol,1) end
	if rez.rtc3 then table.insert(rtcol,3) end
	if rez.rtc4 then table.insert(rtcol,4) end
	t_times=""
    end
    
    -- Clone Clip GUI --
    if res.stuff=="clone clip" then
	if clone_h then cchc=clone_h else cchc=2 end
	if clone_v then ccvc=clone_v else ccvc=2 end
	if dist_h then cchd=dist_h else cchd=20 end
	if dist_v then ccvd=dist_v else ccvd=20 end
	if ccshift then ccsh=ccshift else ccsh=0 end
	ccgui={
	{x=0,y=0,class="label",label="Horizontal distance:  "},
	{x=1,y=0,class="intedit",name="hdist",value=cchd,min=1},
	{x=0,y=1,class="label",label="Horizontal clones:  "},
	{x=1,y=1,class="intedit",name="hclone",value=cchc,min=1},
	{x=0,y=2,class="label",label="Vertical distance:  "},
	{x=1,y=2,class="intedit",name="vdist",value=ccvd,min=1},
	{x=0,y=3,class="label",label="Vertical clones:  "},
	{x=1,y=3,class="intedit",name="vclone",value=ccvc,min=1},
	{x=0,y=4,class="label",label="Shift even rows by:"},
	{x=1,y=4,class="intedit",name="ccshift",value=ccsh,min=0},
	}
	pres,rez=ADD(ccgui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if pres=="Cancel" then ak() end
	clone_h=rez.hclone	dist_h=rez.hdist
	clone_v=rez.vclone	dist_v=rez.vdist
	ccshift=rez.ccshift
    end
    
    -- DISSOLVE GUI ---------------------------------------------------------------------------------------------
    if res.stuff=="dissolve text" then
	if dlast then ddistance=v_dist ddlines=dlines dshape=shape dalter=alternate dissin=disin otherd=otherdis v2direction=v2d
	else ddistance=10 ddlines=10 dshape="square" dalter=true dissin=false otherd=false v2direction="randomly"
	end
	dissgui={
	{x=0,y=0,class="label",label="Distance between points:  "},
	{x=1,y=0,class="floatedit",name="ddist",value=ddistance,min=4,step=2},
	{x=0,y=1,class="label",label="Shape of clips:"},
	{x=1,y=1,class="dropdown",name="shape",items={"square","square 2","diamond","triangle 1","triangle 2","hexagon","wave/hexagram","vertical lines","horizontal lines"},value=dshape},
	{x=0,y=2,class="checkbox",name="alt",label="Shift even rows (all except vertical/horizontal lines)",value=dalter,width=2},
	{x=0,y=3,class="checkbox",name="disin",label="Reverse effect (fade in rather than out)",value=dissin,width=2},
	{x=0,y=4,class="checkbox",name="otherdiss",label="Dissolve v2.  ...  Lines:",value=otherd,hint="only square, diamond, vertical lines"},
	{x=1,y=4,class="floatedit",name="modlines",value=ddlines,min=6,step=2},
	{x=0,y=5,class="label",label="      Dissolve v2:   Dissolve"},
	{x=1,y=5,class="dropdown",name="v2dir",items={"randomly","from top","from bottom","from left","from right"},value=v2direction},
	}
	pres,rez=ADD(dissgui,{"OK","What Is This","Cancel"},{ok='OK',close='Cancel'})
	if pres=="What Is This" then
	    dishelp={x=0,y=6,width=10,height=8,class="textbox",value="The script can either automatically draw a clip around the text,\nor you can make your own clip.\nThe automation only considers position, alignment, and scaling,\nso for anything more complex, make your own.\nYou can just try it without a clip,\nand if the result isn't right, draw a clip first. (Only 4 points!)\n\n'Distance between points' will be the distance between the\nstarting points of all the little iclips.\nLess Distance = more clips = more lag,\nso use the lowest values only for smaller text.\nYou can run this on one line or fbf lines.\nThe ideal 'fade' is as many frames as the given Distance.\nThat way the clips grow by 1 pixel per frame.\nAny other way doesn't look too good,\nbut you can apply Distance 10 over 20 lines\nand have each 2 consecutive lines identical.\nMore Distance than lines doesn't look so bad, and the effect is 'faster'.\nIf you apply this to 1 line, the line will be split to have the effect applied to as many frames as the Distance is. (This is preferred.)\nFor hexagon, the actual distance is twice the input. (It grows faster.)\n\nThe shapes should be self-explanatory, so just experiment.\n\n'Shift even rows' means that even rows will have an offset\nfrom odd rows by half of the given Distance.\nNot checking this will have a slightly different and less regular effect,\nthough it also depends on the shape. Again, experiment.\n\nIf you need to apply this to several layers, you have to do it one by one. The GUI remembers last values. But more layers = more lag.\n\nAll kinds of things can make this lag, so use carefully.\nLines are less laggy than other shapes.\nHorizontal lines are the least laggy. (Unless you have vertical text.)\n\nFor longer fades, use more Distance.\nThis works great with vertical lines but is pretty useless with horizontal.\n\n'Reverse effect' is like fade in while the default is fade out.\nWith one line selected, it applies to the first frames.\n\n'Dissolve v2' is a different kind of dissolve\nand only works with square, diamond, and vertical lines.\nLine count for this is independent on distance between points.\nIt's the only effect that allows Distance 4.\n'Shift even rows' has no effect here.\n\nYou can set a direction of Dissolve v2.\nObviously top and bottom is nonsense for vertical lines.\n'Reverse effect' reverses the direction too, so choose the opposite.\n\nThere may be weird results with some combinations of settings.\nThere may be some malfunctions, as the script is pretty complex.\nSome of them -might- be fixed by reloading automation scripts.\nMakes no sense with \\move. Nukes \\fad.\n\nThere are some fun side effects.\nFor example with 'square 2' and 'Shift even rows',\nyou get a brick wall on the last frame."}
	    table.insert(dissgui,dishelp)
	    pres,rez=ADD(dissgui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	end
	if pres=="Cancel" then ak() end
	dlast=true
	v_dist=rez.ddist
	shape=rez.shape
	alternate=rez.alt
	disin=rez.disin
	otherdis=rez.otherdiss
	dlines=rez.modlines
	v2d=rez.v2dir
	dis2=false
	if v2d=="randomly" then dir=5 end
	if v2d=="from top" then dir=8 end
	if v2d=="from bottom" then dir=2 end
	if v2d=="from left" then dir=4 end
	if v2d=="from right" then dir=6 end
	if not otherdis and v_dist==4 then
	  t_error("Distance 4 is only allowed for square mod. Changing to 6.")
	  v_dist=6
	end
	if otherdis then
	    if shape=="square" or shape=="diamond" or shape=="vertical lines" then dis2=true else dis2=false end
	    if shape=="square" then alternate=false end
	    if shape=="diamond" then alternate=true end
	end
	if dis2 and #sel==1 then linez=dlines 
	elseif dis2 and #sel>1 then linez=#sel
	else linez=v_dist end
	
	-- DISSOLVE create lines if only one selected ------------------------
	if #sel==1 then
		rine=subs[sel[1]]
		rine.text=rine.text:gsub("\\fad%(.-%)","")
		start=rine.start_time	    endt=rine.end_time
		startf=ms2fr(start)		    endf=ms2fr(endt)
		lframes=ms2fr(endt-start)
		if lframes<linez then t_error("Line must be at least "..linez.." frames long.",1) end
		if disin then
			for l=1,linez do
				rine.start_time=fr2ms(startf+l-1)
				rine.end_time=fr2ms(startf+l)
				subs.insert(sel[1],rine)
				sel[1]=sel[1]+1
			end
			for s=1,linez do   table.insert(sel,sel[1]-s)   end
			table.sort(sel)
			rine.start_time=fr2ms(startf+linez)
			rine.end_time=endt
			subs[sel[#sel]]=rine
			table.remove(sel,#sel)
		else
			for l=1,linez do
				rine.start_time=fr2ms(endf-l)
				rine.end_time=fr2ms(endf-l+1)
				subs.insert(sel[1]+1,rine)
			end
			for s=1,linez do   table.insert(sel,sel[1]+s)   end
			rine.start_time=start
			rine.end_time=fr2ms(endf-linez)
			subs[sel[1]]=rine
			table.remove(sel,1)
		end
	end
    if disin then table.sort(sel,function(a,b) return a>b end) end
    
    -- DISSOLVE Initial Calculations -----------------------------------------------------------------
    line=subs[sel[1]]
    text=line.text
	text=text:gsub("\\clip%(([%d.-]+),([%d.-]+),([%d.-]+),([%d.-]+)%)",function(a,b,c,d) 
		a=math.floor(a) b=math.floor(b) c=math.ceil(c) d=math.ceil(d) 
		return string.format("\\clip(m %d %d l %d %d %d %d %d %d)",a,b,c,b,c,d,a,d) end)
	-- draw clip when no clip present
	if not text:match("\\clip") then
		styleref=stylechk(subs,line.style)
		vis=text:gsub("%b{}","")
		width,height,descent,ext_lead=aegisub.text_extents(styleref,vis)
		bord=text:match("\\bord([%d%.]+)")	if bord==nil then bord=styleref.outline end
		bord=math.ceil(bord)
		scx=text:match("\\fscx([%d%.]+)")	if scx==nil then scx=styleref.scale_x end	scx=scx/100
		scy=text:match("\\fscy([%d%.]+)")	if scy==nil then scy=styleref.scale_y end	scy=scy/100
		wi=round(width)
		he=round(height)
		text2=getpos(subs,text)
		if not text:match("\\pos") then text=text2 end
		xx,yy=text:match("\\pos%(([%d.-]+),([%d.-]+)%)")
		if h_al=="left" then	cx1=xx			cx2=xx+wi*scx end
		if h_al=="right" then	cx1=xx-wi*scx		cx2=xx end
		if h_al=="mid" then	cx1=xx-wi/2*scx		cx2=xx+wi/2*scx end
		if v_al=="top" then	cy1=yy			cy2=yy+he*scy end
		if v_al=="bottom" then	cy1=yy-he*scy		cy2=yy end
		if v_al=="mid" then	cy1=yy-he/2*scy		cy2=yy+he/2*scy end
		cx1=math.floor(cx1-bord)   cx2=math.ceil(cx2+bord)
		cy1=math.floor(cy1-bord)   cy2=math.ceil(cy2+bord)
		text=addtag("\\clip(m "..cx1.." "..cy1.." l "..cx2.." "..cy1.." "..cx2.." "..cy2.." "..cx1.." "..cy2..")",text)
	end
	-- get outermost clip points even if it's irregular (though it should be fucking regular)
	exes={} wais={}
	klip=text:match("\\clip%(m [%d%-]+ [%d%-]+ l [%d%-]+ [%d%-]+ [%d%-]+ [%d%-]+ [%d%-]+ [%d%-]+")
	for ex,wai in klip:gmatch("([%d%-]+) ([%d%-]+)") do
		table.insert(exes,tonumber(ex))
		table.insert(wais,tonumber(wai))
	end
	table.sort(exes)	  table.sort(wais)
	x1=exes[1]-2	  x2=exes[4]+2	  y1=wais[1]-2	  y2=wais[4]+2
	width=x2-x1	height=y2-y1
	h_dist=2*v_dist
	if shape=="hexagon" then h_dist=math.floor(h_dist*2) end
	rows=math.ceil(height/v_dist)
	rows2=math.ceil(height/v_dist/2)
	points=math.ceil(width/h_dist)+1
	if shape=="horizontal lines" then vert=2*v_dist rows=math.ceil(rows/2)+1 else vert=v_dist end
	if shape:match("triangle") or shape=="wave/hexagram" then rows=rows+1 end
	  
	xpoints={}
	for w=1,points do point=x1+h_dist*(w-1) table.insert(xpoints,point) end
	ypoints={}
	for w=1,rows do point=y1+vert*(w-1) table.insert(ypoints,point) end
	ypoints2={}
	for w=1,rows2 do point=y1+2*v_dist*(w-1) table.insert(ypoints2,point) end
	  
	-- this is all centers of individual iclip shapes
	allpoints1={}
	for w=1,#ypoints do
	    for z=1,#xpoints do
		u=0
		if alternate and w%2==0 then u=h_dist/2 else u=0 end	-- every even row is shifted by half of h_dist from odd rows
		rnum=math.random(2000,6000)
		if dir==5 then rindex=rnum end
		if dir==8 then rindex=rnum*ypoints[w]^2 end
		if dir==4 then rindex=rnum*xpoints[z]^2 end
		if dir==2 then rindex=0-rnum*ypoints[w]^2 end
		if dir==6 then rindex=0-rnum*xpoints[z]^2 end
		point={xpoints[z]+u,ypoints[w],rindex}
		table.insert(allpoints1,point)
	    end
	end
	  
	allpoints2={}
	for w=1,#ypoints2 do
	    for z=1,#xpoints do
		u=0
		if alternate and w%2==0 then u=h_dist/2 else u=0 end	-- every even row is shifted by half of h_dist from odd rows
		rnum=math.random(2000,6000)
		if dir==5 then rindex=rnum end
		if dir==8 then rindex=rnum*ypoints2[w]^2 end
		if dir==4 then rindex=rnum*xpoints[z]^2 end
		if dir==2 then rindex=0-rnum*ypoints2[w]^2 end
		if dir==6 then rindex=0-rnum*xpoints[z]^2 end
		point={xpoints[z]+u,ypoints2[w],rindex}
		table.insert(allpoints2,point)
	    end
	end
	
	if dis2 and shape=="square" or shape=="square 2" or shape=="hexagon" then allpoints=allpoints2 else allpoints=allpoints1 end
	if dis2 and shape=="vertical lines" then allpoints={}
	    for w=1,#xpoints do
		rnum=math.random(2000,6000)
		if dir==4 then rindex=rnum*xpoints[w]^2
		elseif dir==6 then rindex=0-rnum*xpoints[w]^2
		else rindex=rnum end
		table.insert(allpoints,{xpoints[w],0,rindex})
	    end
	end
	if dis2 then table.sort(allpoints,function(a,b) return a[3]<b[3] end) end
	
	-- DISSOLVE v2 Calculations ------------------------------------------
	if dis2 then d2c=0 fullclip="" dis2tab={} rnd=1 ppl=#allpoints/linez
	    for w=1,#allpoints do
		pt=allpoints[w]
		vd=v_dist

		if shape=="square" then
		krip="m "..pt[1]-vd.." "..pt[2]-vd.." l "..pt[1]+vd.." "..pt[2]-vd.." "..pt[1]+vd.." "..pt[2]+vd.." "..pt[1]-vd.." "..pt[2]+vd.." "
		end

		if shape=="diamond" then
		krip="m "..pt[1].." "..pt[2]-vd.." l "..pt[1]+vd.." "..pt[2].." "..pt[1].." "..pt[2]+vd.." "..pt[1]-vd.." "..pt[2].." "
		end

		if shape=="vertical lines" then
		krip="m "..pt[1]-vd.." "..y1.." l "..pt[1]+vd.." "..y1.." "..pt[1]+vd.." "..y2.." "..pt[1]-vd.." "..y2.." "
		end

		fullclip=fullclip..krip
		d2c=d2c+1
		if d2c>=math.floor(ppl) and w>=ppl*rnd then d2c=0 rnd=rnd+1 table.insert(dis2tab,fullclip) end
	  end
	end
    -- DISSOLVE END --------------------------------------------------------------------
    end
    
    -- What Is the Matrix --
    if res.stuff=="what is the Matrix?" then
        matrixgui={
	{x=0,y=0,class="label",label="Max. transformations per letter: "},
	{x=1,y=0,class="intedit",name="tpl",value=4,min=2},
	{x=0,y=1,class="label",label="Frames to stay the same: "},
	{x=1,y=1,class="intedit",name="fts",value=2,min=1},
	{x=0,y=2,class="label",label="Character set: "},
	{x=1,y=2,class="dropdown",name="charset",items={"UPPERCASE","lowercase","Both","More","Everything"},value="Both"},
	{x=0,y=3,class="label",label="Chance to keep letter (0-10):"},
	{x=1,y=3,class="intedit",name="mkeep",value=5,min=0,max=10},
	{x=0,y=4,width=2,class="checkbox",name="showall",label="Show all letters from the start",value=true,},
	{x=0,y=5,width=2,class="label",label="Monospace fonts are optimal. For others, use left alignment."},
	}
	if matrixres then
	  for key,val in ipairs(matrixgui) do
	    if val.class=="checkbox" or val.class=="dropdown" or val.class=="intedit" then val.value=rez[val.name] end
	  end
	end
	pres,rez=ADD(matrixgui,{"What Is the Matrix?","Cancel"},{ok='What Is the Matrix?',close='Cancel'})
	if pres=="Cancel" then ak() end
	AB="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	ab="abcdefghijklmnopqrstuvwxyz"
	Ab="!?()$&+-="
	aB="@#%^*/[]';:,.|"
	if rez.charset=="UPPERCASE" then chset=AB.." "
	elseif rez.charset=="lowercase" then chset=ab.." "
	elseif rez.charset=="Both" then chset=AB..ab.." "
	elseif rez.charset=="More" then chset=AB..ab..Ab.." "
	else chset=AB..ab..Ab..aB.." " end
	ABC=chset:len()
	mframes=rez.tpl
	fpl=rez.fts
	matrixres=rez
    end
    
    if res.stuff=="time by frames" then frs=res.rep1:match("%-?%d+") or 0 fre=res.rep2:match("%-?%d+") or 0
	rine=subs[sel[1]]
	fstart=ms2fr(rine.start_time)
	fendt=ms2fr(rine.end_time)
	rine.start_time=fr2ms(fstart)
	rine.end_time=fr2ms(fendt)
	subs[sel[1]]=rine
	if frs==0 and fre==0 then t_error("Use Left/Right to input \nnumber of frames \nto shift by for start/end.",1) end
    end
        
    if res.stuff=="duplicate and shift lines" then
	FB=tonumber(res.rep1:match("^%d+")) or 0
	FA=tonumber(res.rep2:match("^%d+")) or 0
	if FA+FB==0 then t_error("Use the Left and Right fields to set how many times you want to duplicate the line.",1) end
	FALL=FA+FB+1
	FB1=FB+1
    end

	if res.stuff=="split text to actor/effect" then
		sep1=esc(res.rep1)
		sep2=esc(res.rep2)
		target1=res.field
		if target1~="actor" and target1~="effect" then t_error("Marker must be Actor or Effect.",1) end
		if sep1=="" then t_error("No separator given. (Use Left field.)",1) end
		if sep2~="" then
			if target1=="actor" then target2="effect" else target2="actor" end
		end
	end
	
	if res.stuff=="clip2margins" then
		resx,resy=nil,nil
		for i=1,#subs do
			if subs[i].class=="info" then
				local k=subs[i].key
				local v=subs[i].value
				if k=="PlayResX" then resx=v end
				if k=="PlayResY" then resy=v end
			end
			if resx and resy then break end
		end
		local G={
		{x=0,y=0,width=2,class="checkbox",name="l",label="Set left margin"},
		{x=0,y=1,width=2,class="checkbox",name="r",label="Set right margin"},
		{x=0,y=2,width=2,class="checkbox",name="v",label="Set vertical margin"},
		{x=0,y=3,class="label",label="Vertical:"},
		{x=1,y=3,class="dropdown",name="tb",items={"from top","from bottom"},value='from top'},
		{x=0,y=4,width=2,class="checkbox",name="a",label="Set all"},
		}
		P2,rez=ADD(G,{"+","-"},{ok='+',close='-'})
		if rez.a then rez.l=true rez.r=true rez.v=true end
	end
	
	if res.stuff=="extrapolate tracking" then
		l01=subs[sel[1]]
		l02=subs[sel[#sel]]
		e01=l01.effect:lower()
		e02=l02.effect:lower()
		if e01~='x' and e02~='x' or e01=='x' and e02=='x' then t_error("The first OR last line of the selection must be marked with 'x' in Effect.",1) end
		if e01=='x' then fade='in' else fade='out' end
		if fade=='in' then table.sort(sel,function(a,b) return a>b end) end
		for z,i in ipairs(sel) do
			l=subs[i]
			t=l.text
			if l.effect=='x' then break end
			tags=t:match(STAG) or ''
			tags=tags:gsub('\\t%b()','')
			posx,posy=tags:match('\\pos%((.-),(.-)%)')
			fscx=tags:match('\\fscx([%d.]+)') or '100'
			fscy=tags:match('\\fscy([%d.]+)') or '100'
			if z==1 then r1tags={posx,posy,fscx,fscy} end
			r2tags={posx,posy,fscx,fscy}
			refl=z-1
		end
		-- loggtab(r1tags)
		-- loggtab(r2tags)
		PX=(r2tags[1]-r1tags[1])/refl
		PY=(r2tags[2]-r1tags[2])/refl
		SX=(r2tags[3]-r1tags[3])/refl
		SY=(r2tags[4]-r1tags[4])/refl
		-- logg(PX)
		-- logg(PY)
		-- logg(SX)
		-- logg(SY)
		c=0
		for z,i in ipairs(sel) do
			l=subs[i]
			t=l.text
			if l.effect=='x' then
				c=c+1
				CPX=round(r2tags[1]+PX*c,2)
				CPY=round(r2tags[2]+PY*c,2)
				t=t:gsub('\\pos%(.-,.-%)','\\pos('..CPX..','..CPY..')')
				if SX~=0 or SY~=0 then
					t=t:gsub('\\fscx([%d.]+)',function(a) return '\\fscx'..round(a+SX*c,2) end)
					t=t:gsub('\\fscy([%d.]+)',function(a) return '\\fscy'..round(a+SY*c,2) end)
				end
			end
			l.text=t
			subs[i]=l
		end
		
		
	end

    KO1=subs[sel[1]].start_time
    
    if res.stuff:match("replacer") or res.stuff=="fix kara tags for fbf lines" or res.stuff=="fill columns" then table.sort(sel,function(a,b) return a>b end) end



	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- LINES START HERE ---------------------------------------------------------------------------------------------------------------------------------------------------------
    for z=#sel,1,-1 do
	i=sel[z]
        progress("Processing line #"..i-line0.." ["..#sel+1-z.."/"..#sel.."]")
	line=subs[i]
        text=line.text
	orig=text
	style=line.style
	
	-- What Is the Matrix --
	if res.stuff=="what is the Matrix?" then
	    start=line.start_time endt=line.end_time
	    startf=ms2fr(start)
	    tags=text:match("^{\\[^}]-}") or ""
	    visible=text:gsub("%b{}","")
	    ltrs={}
	    ltrs2={}
	    matches=re.find(visible,".")
	      for l=1,#matches do
	        table.insert(ltrs,matches[l].str)
		r=math.random(1,ABC)
	        table.insert(ltrs2,chset:sub(r,r))
	      end
	    base=""
	    lines={}
	    for l=1,#ltrs do
	      for f=1,mframes do
		if f<mframes then
		    x=math.random(1,ABC)
		    letter=chset:sub(x,x)
		    z=math.random(0,9)
		    if z<rez.mkeep and f>1 then letter=lastletter end
		    if l==1 and letter==" " then letter="e" end
		    if l==#ltrs and letter==" " then letter="s" end
		    txt=base..letter
		    lastletter=letter
		else letter=ltrs[l] txt=base..letter base=txt
		end
		if not rez.showall then txt=txt.."{\\alpha&HFF&}" end
		for n=l+1,#ltrs do
		  if rez.showall then
		    y=math.random(1,ABC)
		    letter=chset:sub(y,y)
		    z=math.random(0,9)
		    if z<rez.mkeep and n>l then letter=ltrs2[n] end
		    ltrs2[n]=letter
		    if n==#ltrs and letter==" " then letter="k" end
		    txt=txt..letter
		  else
		    txt=txt..ltrs[n]
		  end
		end
		txt=tags..txt
		fact=l*mframes+f-mframes-1
		startfr=startf+fact*fpl
		st=fr2ms(startfr)
		et=fr2ms(startfr+fpl)
		l2={txt,st,et}
		table.insert(lines,l2)
	      end
	      lastletter=nil
	    end
	    for ln=#lines,1,-1 do
	      lin=lines[ln]
	      line.text=lin[1]
	      line.start_time=lin[2]
	      line.end_time=lin[3]
	      if ln==#lines and endt>lin[3] then line.end_time=endt end
	      subs.insert(i+1,line)
	    end
	    line.comment=true
	end
	
	if res.stuff=="save/load" and z==1 then
	    if savedata==nil then savedata="" end
	    if res.dat~="" then
		savedata=savedata.."\n\n"..res.dat
		savedata=savedata
		:gsub("^\n\n","")
		:gsub("\n\n\n","\n\n")
		ADD({{class="label",label="Data saved.",x=0,y=0,width=20,height=2}},{"OK"},{close='OK'})
	    else
		ADD({{x=0,y=0,width=50,height=18,class="textbox",name="savetxt",value=savedata},},{"OK"},{close='OK'})
	    end
	end
	
	if res.stuff=="replacer" then
	  lim=sub3:match("^%d+")
	  if lim==nil then limit=1 else limit=tonumber(lim) end
	  replicant1=sub1
	  replicant2=sub2
	  tk=text
	  count=0
	  if res.regex=="lua patterns" then
	    repeat 
	    text=text:gsub(replicant1,replicant2) count=count+1
	    until count==limit
	    if text~=tk then repl=repl+1
	      if res.log then 
		r1=replicant1:gsub("%%%(","_L_"):gsub("%%%)","_R_"):gsub("%(",""):gsub("%)",""):gsub("_L_","%%%("):gsub("_R_","%%%)")
		for l1 in tk:gmatch(r1) do
		  aegisub.log("\nOrig: "..l1)
		  l2=l1:gsub(replicant1,replicant2)
		  aegisub.log("\nMod: "..l2)
		end
	      end
	    end
	  else
	    if replicant1=='' then t_error('Replacing an empty string is not allowed with regexp.',1) end
	    repeat
	    text=re.sub(text,replicant1,replicant2) count=count+1
	    until count==limit
	    if text~=tk then repl=repl+1
	      if res.log then 
		for r1 in re.gfind(tk,replicant1) do
		  aegisub.log("\nOrig: "..r1)
		  r2=re.sub(r1,replicant1,replicant2)
		  aegisub.log("\nMod: "..r2)
		end
	      end
	    end
	  end
	end
	
	if res.stuff=="lua calc" then
	    lim=sub3:match("^%d+")
	    if lim==nil then limit=1 else limit=tonumber(lim) end
	    replicant1=sub1:gsub("\\","\\")
	    replicant2=sub2:gsub("\\","\\")
	    replicant1=sub1:gsub("\\\\","\\")
	    replicant2=sub2:gsub("\\\\","\\")
	    replicant2="||"..replicant2.."||"
	    replicant2=replicant2:gsub("%.%.","||")
	    tk=text
	    count=0
	    repeat 
	    text=text:gsub(replicant1,function(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p)
		tab1={"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p"}
		tab2={a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p}
		r2=replicant2
		asd=1
		repeat
		for r=1,16 do
		  r2=r2
		  :gsub(tab1[r].."%*([%d%.]+)",function(num) return tab2[r]*tonumber(num) end)
		  :gsub(tab1[r].."%/([%d%.]+)",function(num) return tab2[r]/tonumber(num) end)
		  :gsub(tab1[r].."%+([%d%.]+)",function(num) return tab2[r]+tonumber(num) end)
		  :gsub(tab1[r].."%-([%d%.]+)",function(num) return tab2[r]-tonumber(num) end)
		  :gsub("([%d%.]+)%*([%d%.]+)",function(n1,n2) return tonumber(n1)*tonumber(n2) end)
		  :gsub("([%d%.]+)%/([%d%.]+)",function(n1,n2) return tonumber(n1)/tonumber(n2) end)
		  :gsub("([%d%.]+)%+([%d%.]+)",function(n1,n2) return tonumber(n1)+tonumber(n2) end)
		  :gsub("([%d%.]+)%-([%d%.]+)",function(n1,n2) return tonumber(n1)-tonumber(n2) end)
		end
		for r=1,16 do
		    if tab2[r]~=nil then
		    r2=r2:gsub("([|%*%/%+%-])"..tab1[r].."|","%1"..tab2[r].."|")
		    r2=r2:gsub("%("..tab1[r].."%)","("..tab2[r]..")")
		    end
		end
		r2=r2:gsub("round%(([^%)]+)%)",function(num) return math.floor(tonumber(num)+0.5) end)
		asd=asd+1
		until not r2:match("[%*%/%+%-]") or asd==12
		r2=r2:gsub("||","")
		return r2 end) count=count+1
	    until count==limit
	    if text~=tk then
		repl=repl+1
		if res.log then logg("1. "..tk.."\n 2. "..text.."\n") end
	    
	    end
	end
	
	if res.stuff=="make comments visible" then text=text:gsub("\\N","/N"):gsub(" *{ *([^\\}]-)}"," %1"):gsub("/N","\\N")
		if text~=orig then repl=repl+1 else nope=1 end
	end
	
	if res.stuff=="switch commented/visible" then
		text=text
		:gsub("\\N","_br_")
		:gsub("{([^\\}]-)}","}%1{")
		:gsub("^([^{]+)","{%1")
		:gsub("([^}]+)$","%1}")
		:gsub("([^}])({\\[^}]-})([^{])","%1}%2{%3")
		:gsub("^({\\[^}]-})([^{])","%1{%2")
		:gsub("([^}])({\\[^}]-})$","%1}%2")
		:gsub("{}","")
		:gsub("_br_","\\N")
		if text~=orig then repl=repl+1 else nope=1 end
	end
	
	if res.stuff=="reverse text" then
		tags=text:match(STAG) or ""
		if not tags:match('\\p1') then
			text=text:gsub(STAG,""):gsub("(\\[Nh])","{%1}")
			inTags=inline_pos(text)
			text=text:gsub("%b{}","")
			local er
			local count=0
			repeat
				t2=""
				er=0
				for L in re.gfind(text,".") do
					t2=L..t2
					-- errors
					if L=="" or re.find(L,"..") then er=er+1 end
				end
				count=count+1
			until er==0 or count==30
			
			t2=inline_ret(t2,inTags)
			t2=t2:gsub("{(\\[Nh])}","%1")
			
			if count==30 and er>0 then
				logg("Repeated re module failure on line #"..i-line0.." (30 times).\n Some characters keep disappearing or being added.\n Skipping this line. Please redo it separately.")
			else
				text=tags..t2
			end
		end
		if text~=orig then repl=repl+1 else nope=1 end
	end
	
	if res.stuff=="reverse words" then
		tags=text:match(STAG) or ""
		visible=text:gsub("%b{}",""):gsub("\\N","")
		if visible:match(" ") then
			text=text:gsub("%b{}",""):gsub(" *\\N *"," \\N")
			breaks={}
			local k=1
			for w in text:gmatch("(%S+%s*)") do
				if w:match('\\N') then table.insert(breaks,k) end
				k=k+1
			end
			text=text:gsub("\\N","")
			nt=""
			for l in text:gmatch("%S+") do nt=" "..l..nt end
			nt2=''
			k=1
			for w in nt:gmatch("(%S+%s*)") do
				for i,n in ipairs(breaks) do
					if n==k then w='\\N'..w end
				end
				nt2=nt2..w
				k=k+1
			end
			text=tags..nt2
		end
		if text~=orig then repl=repl+1 else nope=1 end
	end
	
	if res.stuff=="fill columns" and #sel>1 then
		local G={
		{x=0,y=0,class="checkbox",name="layer",label="Layer"},
		{x=0,y=1,class="checkbox",name="start_time",label="Start Time"},
		{x=0,y=2,class="checkbox",name="end_time",label="End Time"},
		{x=0,y=3,class="checkbox",name="margin_l",label="Left Margin"},
		{x=0,y=4,class="checkbox",name="margin_r",label="Right Margin"},
		{x=0,y=5,class="checkbox",name="margin_t",label="Vertical Margin"},
		{x=0,y=6,class="checkbox",name="style",label="Style"},
		{x=0,y=7,class="checkbox",name="actor",label="Actor"},
		{x=0,y=8,class="checkbox",name="effect",label="Effect"},
		{x=0,y=9,class="checkbox",name="text",label="Text"},
		}
		if z==#sel then
			local buttons={'Fill','All/None','Fail'}
			fcr=fcr or {}
			repeat
				if FCP=='All/None' then
					local Q=0
					for k,v in ipairs(G) do
						if fcr[v.name]==false then Q=1 end
					end
					for k,v in ipairs(G) do
						if Q==1 then v.value=true else v.value=false end
					end
				end
				FCP,fcr=ADD(G,buttons,{ok='Fill',close='Fail'})
				if FCP=='Fail' then ak() end
			until FCP~='All/None'
			rrine=line
		else
			for k,v in ipairs(G) do
				if (line[v.name]=='' or line[v.name]==0) and fcr[v.name] then line[v.name]=rrine[v.name] end
			end
			text=line.text
			rrine=line
		end
	end
	
	-- REVERSE TRANSFORMS ------------------
	if res.stuff=="reverse transforms" then
	    styleref=stylechk(subs,line.style)
	    text=text:gsub("\\1c","\\c")
	    tags=text:match(STAG) or ""
	    text=text:gsub(STAG,"")
	    tags=cleantr(tags)
	    tags=duplikill(tags)
	    tags=tags:gsub("\\fs(%d)","\\fsize%1")
	    notrans=tags:gsub("\\t%b()","")
	    for tr in tags:gmatch("\\t%b()") do
		tr=tr:gsub("\\i?clip%([^%)]+%)","") :gsub("\\t%(","") :gsub("%)$","")
		for tag in tr:gmatch("\\[1234]?%a+") do
		    if not notrans:match(tag) then
			tags=fill_in(tags,tag)
		    end
		    tags=tags:gsub(tag.."([^\\}]+)([^}]-)"..tag.."([^\\}%)]+)",tag.."%3%2"..tag.."%1")
		end
	    end
	    tags=tags:gsub("(i?clip%([^%)]+%))([^}]-\\t[^}]-)(i?clip%([^%)]+%))","%3%2%1") :gsub("\\fsize","\\fs")
	    text=tags..text
	    if text~=orig then repl=repl+1 else nope=1 end
	end
	
	if res.stuff=="fake capitals" then
		tags=text:match(STAG) or ""
		text=text:gsub(STAG,"")
		text=re.sub(text,"(\\u)","{\\\\fs"..sub1.."}\\1{\\\\fs}")
		text=text:gsub("{\\fs}(%-?){\\fs"..sub1.."}","%1")
		text=tags..text
		text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
		if text~=orig then repl=repl+1 else nope=1 end
	end
	
	if res.stuff=="format dates" then
	    text2=text:gsub("%b{}","")
	    if rez.date=="January 1" then
		text=re.sub(text,"(January|February|March|April|May|June|July|August|September|October|November|December) (\\d+)(st|nd|th)","\\1 \\2")
		text=re.sub(text,"(\\d+)(st|nd|th|st of|nd of|th of) (January|February|March|April|May|June|July|August|September|October|November|December)","\\3 \\1")
	    end
	    if rez.date=="January 1st" then
		text=re.sub(text,"(January|February|March|April|May|June|July|August|September|October|November|December) (\\d+)","\\1 \\2th")
		text=re.sub(text,"(\\d+)(st|nd|th|st of|nd of|th of) (January|February|March|April|May|June|July|August|September|October|November|December)","\\3 \\1th")
		text=text:gsub("(%d)thth","%1th") :gsub("1thst","1st") :gsub("2thnd","2nd") :gsub("1th","1st") :gsub("2th","2nd")
	    end
	    if rez.date=="1st of January" then
		text=re.sub(text,"(January|February|March|April|May|June|July|August|September|October|November|December) (\\d+)(st|nd|th)?","\\2\\3 of \\1")
		text=re.sub(text,"(\\d+) of (January|February|March|April|May|June|July|August|September|October|November|December)","\\1th of \\2")
		text=text:gsub("(%d)thth","%1th") :gsub("1thst","1st") :gsub("2thnd","2nd") :gsub("1th","1st") :gsub("2th","2nd")
		text=re.sub(text,"(\\d+)(st|nd|th) (January|February|March|April|May|June|July|August|September|October|November|December)","\\1\\2 of \\3")
	    end
	    if rez.date=="1st January" then
		text=re.sub(text,"(January|February|March|April|May|June|July|August|September|October|November|December) (\\d+)(st|nd|th)?","\\2\\3 \\1")
		text=re.sub(text,"(\\d+) (January|February|March|April|May|June|July|August|September|October|November|December)","\\1th \\2")
		text=text:gsub("(%d)thth","%1th") :gsub("1thst","1st") :gsub("2thnd","2nd") :gsub("1th","1st") :gsub("2th","2nd")
		text=re.sub(text,"(\\d+)(st|nd|th) of (January|February|March|April|May|June|July|August|September|October|November|December)","\\1\\2 \\3")
	    end
	    textn=text:gsub("%b{}","")
	    if text2~=textn then datelog=text2.." -> "..textn.."\n"..datelog end
	    if text~=orig then repl=repl+1 else nope=1 end
	end
	
	if res.stuff=="transform \\k to \\t\\alpha" then
	    repeat text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") until not text:match("{(\\[^}]-)}{(\\[^}]-)}")
	    if text:match("^{[^}]-\\alpha") then alf=text:match("^{[^}]-\\alpha&H(%x%x)&") else alf="00" end
	    text=text:gsub("\\alpha&H%x%x&","")
	    tab={}
	    for kpart in text:gmatch("{[^}]-\\k[fo][%d%.]+[^}]-}[^{]*") do
		table.insert(tab,kpart)
	    end
	    lastim=0
	    text=""
	    for k=1,#tab do
		part=tab[k]
		tim=tonumber(part:match("\\k[fo]([%d%.]+)"))*10
		part=part:gsub("\\k[fo][%d%.]+","\\alpha&HFF&\\t("..lastim..","..lastim+tim..",\\alpha&H"..alf.."&)")
		tab[k]=part
		lastim=lastim+tim
		text=text..tab[k]
	    end
	    if text~=orig then repl=repl+1 else nope=1 end
	end
	
	-- SPLIT and EXPLODE -------------------------------------------
	if res.stuff=="split into letters (alpha)" or res.stuff=="explode" then
	    l2=line
	    tags=text:match(STAG) or ""
	    vis=text:gsub("%b{}","")
	    af="{\\alpha&HFF&}"
	    a0="{\\alpha&H00&}"
	    letters={}
	    ss=0
	    ltrmatches=re.find(vis,".")
	    for l=1,#ltrmatches do
		table.insert(letters,ltrmatches[l].str)
	    end
	    if savetab==nil then savetab={} end
	    -- create texts for all resulting lines
	    for l=#letters,1,-1 do
	    tx=af
		ltr=a0..letters[l]..af
		for t=1,#letters do
		    ltr2=letters[t]
		    if t==l then ltr2=ltr end
		    tx=tx..ltr2
		end
		tx=textmod(text,tx)
		txt2=tags..tx
		if not txt2:match("\\pos") then txt2=getpos(subs,txt2) end
		txt2=txt2:gsub("{\\alpha&HFF&}$","")
		txt2=tagmerge(txt2)
		txt2=txt2:gsub(ATAG,function(tg) return duplikill(tg) end)
		  -- Explode
		  if res.stuff=="explode" then
		    dur=line.end_time-line.start_time
		    if cfade then FO=exfad else FO=dur end
		    if implode then expfad="\\fad("..FO..",0)" else expfad="\\fad(0,"..FO..")" end
		    if FO==0 then EFO="" else EFO=expfad end
		    if ex_hor=="all" then 		ex1a=0-expl_dist_x	ex1b=expl_dist_x end
		    if ex_hor=="only left" then 	ex1a=0-expl_dist_x	ex1b=0 end
		    if ex_hor=="only right" then 	ex1a=0			ex1b=expl_dist_x end
		    if ex_hor=="mostly left" then 	ex1a=0-expl_dist_x	ex1b=expl_dist_x/3 end
		    if ex_hor=="mostly right" then 	ex1a=0-expl_dist_x/3	ex1b=expl_dist_x end
		    if ex_ver=="all" then 		ex2a=0-expl_dist_y	ex2b=expl_dist_y end
		    if ex_ver=="only up" then 		ex2a=0-expl_dist_y	ex2b=0 end
		    if ex_ver=="only down" then 	ex2a=0			ex2b=expl_dist_y end
		    if ex_ver=="mostly up" then 	ex2a=0-expl_dist_y	ex2b=expl_dist_y/3 end
		    if ex_ver=="mostly down" then 	ex2a=0-expl_dist_y/3	ex2b=expl_dist_y end
		    rvrs=#letters-l+1
		    if xinv then xind=rvrs else xind=l end
		    if yinv then yind=rvrs else yind=l end
		    if invseq then seqt=rvrs else seqt=l end
		    if implode then seqt=#letters-seqt+1 end
		    if exremember and z<#sel then
			tab=savetab[rvrs]
			ex1=tab.x1 ex2=tab.x2
		    else
		      if xprop then
			xhdist=(ex1b-ex1a)/#letters
			ex1=round(ex1a+xhdist*xind)
		      else
			ex1=math.ceil(math.random(ex1a,ex1b))
		      end
		      if yprop then
			xvdist=(ex2b-ex2a)/#letters
			ex2=round(ex2a+xvdist*yind)
		      else
			ex2=math.ceil(math.random(ex2a,ex2b))
		      end
		    end
		    if exremember and z==#sel then table.insert(savetab,{x1=ex1,x2=ex2}) end
		    
		    -- move sequence
		    if exseq then
		        tfrag=round(dur/#letters/(100/seqpc))
			xt1=tfrag*seqt-tfrag
		    else
		        xt1=0
		    end
		    xt2=dur
		    if implode and exseq then xt2=dur-xt1 xt1=0 end
		    txt2=txt2:gsub("\\move%(([%d.-]+),([%d.-]+).-%)","\\pos(%1,%2)")
		    txt2=txt2:gsub("\\fad%(.-%)","")
		    if implode then
			txt2=txt2:gsub("\\pos%(([%d.-]+),([%d.-]+)%)",
		        function(a,b) return EFO.."\\move("..a+ex1..","..b+ex2..","..a..","..b..","..xt1..","..xt2..")" end)
		    else
			txt2=txt2:gsub("\\pos%(([%d.-]+),([%d.-]+)%)",
		        function(a,b) return EFO.."\\move("..a..","..b..","..a+ex1..","..b+ex2..","..xt1..","..xt2..")" end)
		    end
		    txt2=txt2:gsub("{\\[^}]-}$","")
		  end
		l2.text=txt2
		-- I hope I don't ever have to touch this shit again
		if letters[l]~=" " then subs.insert(i+1,l2)
			ss=ss+1
			shift=orig_sel-z
			if shift>0 then
				for s=#sel,1,-1 do
					if s>z+ss-1 then sel[s]=sel[s]+1 end
				end
			end
			table.insert(sel,sel[z]+ss)
			table.sort(sel)
		end
	    end
	    line.comment=true
	end
	
	-- Clone Clip
	if res.stuff=="clone clip" and text:match("\\clip%((.-)%)") then
	    text=text:gsub("\\clip%(([%d.-]+),([%d.-]+),([%d.-]+),([%d.-]+)%)",function(a,b,c,d) 
		a=math.floor(a) b=math.floor(b) c=math.ceil(c) d=math.ceil(d) 
		return string.format("\\clip(m %d %d l %d %d %d %d %d %d)",a,b,c,b,c,d,a,d) end)
	    clip=text:match("\\clip%((.-)%)")
	    clip=clip.." "
	    h_clip=clip
	    for h=1,clone_h-1 do
		hc=clip:gsub("([%d%-]+) ([%d%-]+)",function(a,b) return a+dist_h*h.." "..b end)
		h_clip=h_clip..hc
	    end
	    fullclip=h_clip
	    for v=1,clone_v-1 do
		if v%2==1 then offset=ccshift else offset=0 end
		vc=h_clip:gsub("([%d%-]+) ([%d%-]+)",function(a,b) return a+offset.." "..b+dist_v*v end)
		fullclip=fullclip..vc
	    end
	    fullclip=fullclip:gsub(" $","")
	    text=text:gsub("\\clip%((.-)%)","\\clip("..fullclip..")")
	    if text~=orig then repl=repl+1 else nope=1 end
	end
	
	if res.stuff=="clip2margins" and text:match("\\clip%(([%d.,-]-)%)") then
		local l,t,r,b=text:match("\\clip%(([%d.-]+),([%d.-]+),([%d.-]+),([%d.-]+)%)")
		if rez.l then line.margin_l=round(l) end
		if rez.r then line.margin_r=round(resx-r) end
		if rez.v and rez.tb=="from top" then line.margin_t=round(t) end
		if rez.v and rez.tb=="from bottom" then line.margin_t=round(resy-b) end
	end

	-- DISSOLVE Individual Lines --------------------------------------------------------------------------------------
	if res.stuff=="dissolve text" then
	  
	  fullklip=""
	  -- radius of clips based on # of sel. lines and shapes
	  r=math.ceil(z*linez/#sel-1) 
	  if shape=="diamond" and not alternate then r=math.floor(r*1.5) end
	  if shape:match("triangle") and alternate then r=math.floor(r*1.4) end
	  if shape:match("triangle") and not alternate then r=math.floor(r*1.5) end
	  if shape=="wave/hexagram" then r=math.floor(r*1.55) end
	  xpt=0		sw=0	osq=0
	  
	  if not dis2 and not shape:match("lines") and r>0 then
	    for w=1,#allpoints do
	      pt=allpoints[w]
	      
	      if shape=="square" or shape=="square 2" then
		krip="m "..pt[1]-r.." "..pt[2]-r.." l "..pt[1]+r.." "..pt[2]-r.." "..pt[1]+r.." "..pt[2]+r.." "..pt[1]-r.." "..pt[2]+r.." "
	      end
	      
	      if shape=="diamond" then
		krip="m "..pt[1].." "..pt[2]-r.." l "..pt[1]+r.." "..pt[2].." "..pt[1].." "..pt[2]+r.." "..pt[1]-r.." "..pt[2].." "
	      end
	      
	      if shape=="triangle 1" then
		krip="m "..pt[1].." "..pt[2]-r.." l "..pt[1]+r.." "..pt[2]+r.." "..pt[1]-r.." "..pt[2]+r.." "
	      end
	      
	      if shape=="triangle 2" then
		krip="m "..pt[1]-r.." "..pt[2]-r.." l "..pt[1]+r.." "..pt[2]-r.." "..pt[1].." "..pt[2]+r.." "
	      end
	      
	      if shape=="hexagon" then
		krip="m "..pt[1].." "..pt[2]-2*r.." l "..pt[1]+2*r.." "..pt[2]-r.." "..pt[1]+2*r.." "..pt[2]+r.." "..pt[1].." "..pt[2]+2*r.." "..pt[1]-2*r.." "..pt[2]+r.." "..pt[1]-2*r.." "..pt[2]-r.." "
	      end
	      
	      if shape=="wave/hexagram" then
		if sw==0 then
		krip="m "..pt[1].." "..pt[2]-r+1 .." l "..pt[1]+r.." "..pt[2]+r+1 .." "..pt[1]-r.." "..pt[2]+r+1 .." "
		else
		krip="m "..pt[1]-r.." "..pt[2]-r.." l "..pt[1]+r.." "..pt[2]-r.." "..pt[1].." "..pt[2]+r.." "
		end
		xpt=xpt+1
		if xpt==#xpoints then xpt=0 sw=1-sw end
	      end
	      
	      fullklip=fullklip..krip
	    end
	  end
	  
	  if not dis2 and shape=="vertical lines" and r>0 then
	    for w=1,#xpoints do
	      pt=xpoints[w]
		krip="m "..pt-r.." "..y1.." l "..pt+r.." "..y1.." "..pt+r.." "..y2.." "..pt-r.." "..y2.." "
	      fullklip=fullklip..krip
	    end
	  end
	  
	  if not dis2 and shape=="horizontal lines" and r>0 then
	    for w=1,#ypoints do
	      pt=ypoints[w]
		krip="m "..x1-vert.." "..pt-r.." l "..x2+vert.." "..pt-r.." "..x2+vert.." "..pt+r.." "..x1-vert.." "..pt+r.." "
	      fullklip=fullklip..krip
	    end
	  end
	  
	  if dis2 and r>0 then fullklip=dis2tab[r] end
	  
	  fullklip=fullklip:gsub(" $","")
	  
	  text=text:gsub("\\clip%(.-%)","")
	  if r>0 then text=addtag("\\iclip("..fullklip..")",text) end
	end
	-- DISSOLVE END 2 ----------------------------------------------
	
	-- RANDOMISED TRANSFORMS ---------------------------------------
	if res.stuff=="randomised transforms" then
	  dur=line.end_time-line.start_time
	  t_1=rez.t1 t_2=rez.t2
	  if rez.t1<0 then t_1=dur+rez.t1 end
	  if rez.t2<0 then t_2=dur+rez.t2 end
	  if t_1~=0 or t_2~=0 then
		t_times=round(t_1)..","..round(t_2)..","
	  end
	  if rez.movet then
		m_times=t_times:gsub("(.*),",",%1"):gsub(",0$",","..dur):gsub("%-%d+","0")
	  else m_times=""
	  end
	  if RTMax then MxF=dur end
	  
	    -- Fade/Duration
	    if RTM=="FD" then
	      FD=math.random(MnF,MxF)
	      if RTD and not RTin then line.end_time=line.start_time+FD end
	      if RTD and RTin then line.start_time=line.end_time-FD end
	      if RTF then text=text:gsub("\\fad%b()","") end
	      if RTF and not RTin then text="{\\fad(0,"..FD..")}"..text text=text:gsub(FD.."%)}{",FD..")") end
	      if RTF and RTin then text="{\\fad("..FD..",0)}"..text text=text:gsub(",0%)}{",",0)") end
	    end
	    
	    -- Number Transform
	    if RTM=="NT" then
	      NT=math.random(MnT*10,MxT*10)/10
	      if RTA then NTA=math.random(MnA*10,MxA*10)/10 axel=NTA.."," else axel="" end
	      text=addtag("\\t("..t_times..axel.."\\"..RTT..NT..")",text)
	    end
	    
	    -- Colour Transform
	    if RTM=="CT" then
	      CTfull=""
	      for c=1,#rtcol do
		ctype="\\"..rtcol[c].."c"
		ctype=ctype:gsub("\\1c","\\c")
	        Bluu,Grin,Rett=text:match("^{[^}]-"..ctype.."&H(%x%x)(%x%x)(%x%x)&")
		if Bluu~=nil then
		  R=tonumber(Rett,16)
		  G=tonumber(Grin,16)
		  B=tonumber(Bluu,16)
		  Red=math.random(R-MxC,R+MxC)
		  Green=math.random(G-MxC,G+MxC)
		  Blue=math.random(B-MxC,B+MxC)
		else
		  Red=math.random(0,255)
		  Green=math.random(0,255)
		  Blue=math.random(0,255)
		end
		CT=ctype.."&H"..tohex(Blue)..tohex(Green)..tohex(Red).."&"
		CTfull=CTfull..CT
	      end
	      if RTA then NTA=math.random(MnA*10,MxA*10)/10 axel=NTA.."," else axel="" end
	      if CTfull~="" then text=addtag("\\t("..t_times..axel..CTfull..")",text) end
	    end
	    
	    -- Move X
	    if rez.rtmx then
	      MMX=math.random(MnX,MxX)
	      text=text:gsub("\\move%(([%d.-]+),([%d.-]+),([%d.-]+),([%d.-]+)",
		function(a,b,c,d) if RTin then a=a+MMX else c=c+MMX end
		return "\\move("..a..","..b..","..c..","..d..m_times end)
	      text=text:gsub("\\pos%(([%d.-]+),([%d.-]+)",
		function(a,b) a2=a if RTin then a=a+MMX else a2=a2+MMX end
		return "\\move("..a..","..b..","..a2..","..b..m_times end)
	    end
	    
	    -- Move Y
	    if rez.rtmy then
	      MMY=math.random(MnY,MxY)
	      text=text:gsub("\\move%(([%d.-]+),([%d.-]+),([%d.-]+),([%d.-]+)",
		function(a,b,c,d) if RTin then b=b+MMY else d=d+MMY end
		return "\\move("..a..","..b..","..c..","..d..m_times end)
	      text=text:gsub("\\pos%(([%d.-]+),([%d.-]+)",
		function(a,b) b2=b if RTin then b=b+MMY else b2=b2+MMY end
		return "\\move("..a..","..b..","..a..","..b2..m_times end)
	    end
	end
	
	if res.stuff=="time by frames" and z>1 then
	    line.start_time=fr2ms(fstart+(z-1)*frs)
	    line.end_time=fr2ms(fendt+(z-1)*fre)
	end
	
	if res.stuff=="split text to actor/effect" then
		local t1,txt=text:match("^(..-)"..sep1.."(.*)$")
		local t2,txt2
		if t1 and sub3=="0" then t1=t1..sep1 end
		if sep2~="" then
			txt=txt or text
			t2,txt2=txt:match("^(..-)"..sep2.."(.*)$")
			if t2 and sub3=="0" then t2=t2..sep2 end
			if t2 and sub3=="2" then t2=sep2..t2 end
			t2=t2 or ""
			if target1=="actor" then line.effect=line.effect..t2 else line.actor=line.actor..t2 end
		end
		if txt and sub3=="2" then txt=sep1..txt end
		if txt2 and sub3=="2" then txt2=sep2..txt2 end
		if target1=="actor" then line.actor=line.actor..t1 or "" else line.effect=line.effect..t1 or "" end
		text=txt2 or txt or text
		if text~=orig then repl=repl+1 else nope=1 end
	end
	
	-- DUPLICATE AND SHIFT LINES
	if res.stuff=="duplicate and shift lines" then
	  SF=ms2fr(line.start_time)
	  EF=ms2fr(line.end_time)
	  l2=line
	  effect=line.effect
	  for x=FALL,1,-1 do
	    F=x-FB1
	    -- Main line
	    if F==0 then
		l2.start_time=fr2ms(SF)
		l2.end_time=fr2ms(EF)
		l2.effect=effect.."[0]"
		l2.text=text
	    end
	    -- Before
	    if F<0 then
		l2.start_time=fr2ms(SF+F)
		l2.end_time=fr2ms(SF+F+1)
		l2.effect=effect.."["..F.."]"
		l2.text=text
		:gsub("\\move%(([%d.-]+),([%d.-]+),([%d.-]+),([%d.-]+).-%)","\\pos(%1,%2)")
		:gsub("\\t%b()","")
		:gsub("\\fad%b()","")
	    end
	    -- After
	    if F>0 then
		l2.start_time=fr2ms(EF+F-1)
		l2.end_time=fr2ms(EF+F)
		l2.effect=effect.."["..F.."]"
		l2.text=text
		:gsub("\\move%(([%d.-]+),([%d.-]+),([%d.-]+),([%d.-]+).-%)","\\pos(%3,%4)")
		:gsub("\\t%b()",function(t) return t:gsub("\\t%([^\\]*",""):gsub("%)$","") end)
		:gsub("\\fad%b()","")
		l2.text=l2.text:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
	    end
	    if res.rep3=="0" then l2.effect=effect end
	    subs.insert(sel[#sel]+1,l2)
	  end
	end
	
	if res.stuff=="fix kara tags for fbf lines" then
	  KOD=line.start_time-KO1
	  if KOD>0 then
	    LINE={}
	    for k in text:gmatch("%b{}[^{]*") do table.insert(LINE,k) end
	    for K=1,#LINE do
	      seg=LINE[K]
	      seg=seg:gsub("^(.-)(\\k[of]?)([%d%.]+)(.-)$",function(s,t,k,e)
		k=k*10
		KOD=KOD-k
		if KOD>=0 then return s..e end
		if KOD<0 and k+KOD>0 then k=(k+KOD)/10 return s..t..k..e end
		if KOD<0 and k+KOD<0 then k=k/10 return s..t..k..e end
	      end)
	      LINE[K]=seg:gsub("{}","")
	    end
	    nt=""
	    for K=1,#LINE do nt=nt..LINE[K] end
	    text=nt
	  end
	  if text~=orig then repl=repl+1 else nope=1 end
	end
	
	line.text=text
	subs[i]=line
	if res.stuff=="what is the Matrix?" then subs.delete(i) end
    end
    progress("Operation complete.")
    
    -- END of LINES
    if res.stuff:match"replacer" or res.stuff=="lua calc" then progress("All stuff has been finished.")
	if repl==1 then rp=" modified line" else rp=" modified lines" end
	press,reslt=ADD({},{repl..rp},{cancel=repl..rp})
    end
    if res.stuff=="duplicate and shift lines" then
	SEL=#sel
	for z=#sel,1,-1 do
	  subs.delete(sel[z])
	end
	for x=1,(FA+FB)*SEL do
	  table.insert(sel,sel[SEL]+x)
	end
    end
    if res.stuff=="split into letters (alpha)" or res.stuff=="explode" and not rez.excom then
	for i=#sel,1,-1 do
		line=subs[sel[i]]
		if line.comment then subs.delete(sel[i]) table.remove(sel,i) 
			for s=i,#sel do sel[s]=sel[s]-1 end
		end
	end
    end
    if res.stuff=="format dates" and rez.log then aegisub.log(datelog) end
    if noclip then t_error("Some lines weren't processed - missing clip.") noclip=nil end
    if res.log then
	if repl>1 or nope then t_error(repl.." out of "..#sel.." lines have been modified.") end
    end
    
    savetab=nil
    return sel
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

function shiftsel2(sel,i,mode)
	if i<sel[#sel] then
		for s=1,#sel do
			if sel[s]>i then sel[s]=sel[s]+1 end
		end
	end
	if mode==1 then table.insert(sel,i+1) end
	table.sort(sel)
return sel
end

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

--	Honorificslaughterhouse		--
function honorifix(subs,sel)
    for i=#subs,1,-1 do
      if subs[i].class=="dialogue" then
        line=subs[i]
        line.text=line.text
	:gsub("%-san","{-san}")
	:gsub("%-tan","{-tan}")
	:gsub("%-chan","{-chan}")
	:gsub("%-kun","{-kun}")
	:gsub("%-sama","{-sama}")
	:gsub("%-niisan","{-niisan}")
	:gsub("%-oniisan","{-oniisan}")
	:gsub("%-oniichan","{-oniichan}")
	:gsub("%-oneesan","{-oneesan}")
	:gsub("%-oneechan","{-oneechan}")
	:gsub("%-neesama","{-neesama}")
	:gsub("%-sensei","{-sensei}")
	:gsub("%-se[mn]pai","{-senpai}")
	:gsub("%-dono","{-dono}")
	:gsub("Onii{%-chan}","Brother{Onii-chan}")
	:gsub("Onii{%-san}","Brother{Onii-san}")
	:gsub("Onee{%-chan}","Sister{Onee-chan}")
	:gsub("Onee{%-san}","Sister{Onee-san}")
	:gsub("Onee{%-sama}","Sister{Onee-sama}")
	:gsub("onii{%-chan}","brother{onii-chan}")
	:gsub("onii{%-san}","brother{onii-san}")
	:gsub("onee{%-chan}","sister{onee-chan}")
	:gsub("onee{%-san}","sister{onee-san}")
	:gsub("onee{%-sama}","sister{onee-sama}")
	:gsub("{{","{")
	:gsub("}}","}")
	:gsub("({[^{}]-){(%-%a-)}([^{}]-})","%1%2%3")
        subs[i]=line
      end
    end
end


--	framerate	--
function framerate(subs)
	f1=res.rep1
	f2=res.rep2
	if not tonumber(f1) or not tonumber(f2) then
		local GUI={
		{x=0,y=0,width=2,class="label",label="No framerates supplied.\nTry these. (From -> to)"},
		{x=0,y=1,class="dropdown",name="f1",items={23.976,24,25,29.970,30},value=23.976},
		{x=1,y=1,class="dropdown",name="f2",items={23.976,24,25,29.970,30},value=25},
		}
		fP,fres=ADD(GUI,{"OK","Cancel"},{ok='OK',close='Cancel'})
		if fP=="Cancel" then ak() end
		f1=fres.f1 f2=fres.f2
	end
	for i=1,#subs do
		if subs[i].class=="dialogue" then
			local line=subs[i]
			line.start_time=line.start_time/f2*f1
			line.end_time=line.end_time/f2*f1
			subs[i]=line
		end
	end
end





--	reanimatools 	---------------------------------------------------
function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function wrap(str) return "{"..str.."}" end
function nobra(t) return t:gsub("%b{}","") end
function nobrea(t) return t:gsub("%b{}",""):gsub("\\[Nh]","") end
function nobrea1(t) return t:gsub("%b{}",""):gsub(" *\\[Nh] *"," ") end
function tagmerge(t) repeat t,r=t:gsub("({\\[^}]-)}{(\\[^}]-})","%1%2") until r==0 return t end
function addtag(tag,text) text=text:gsub("^({\\[^}]-)}","%1"..tag.."}") return text end
function round(n,dec) dec=dec or 0 n=math.floor(n*10^dec+0.5)/10^dec return n end
function logg(m) m=tf(m) or "nil" aegisub.log("\n "..m) end
function logg2(m)
	local lt=type(m)
	aegisub.log("\n >> "..lt)
	if lt=='table' then
		aegisub.log(" (#"..#m..")")
		if not m[1] then
			for k,v in pairs(m) do
				if type(v)=='table' then vvv='[table]' elseif type(v)=='number' then vvv=v..' (n)' else vvv=v end
				aegisub.log("\n	"..k..': '..vvv)
			end
		elseif type(m[1])=='table' then aegisub.log("\n nested table")
		else aegisub.log("\n {"..table.concat(m,', ').."}") end
	else
		m=tf(m) or "nil" aegisub.log("\n "..m)
	end
end
function loggtab(m) m=tf(m) or "nil" aegisub.log("\n {"..table.concat(m,', ').."}") end
function progress(msg) if aegisub.progress.is_cancelled() then ak() end aegisub.progress.title(msg) end
function t_error(message,cancel) ADD({{class="label",label=message}},{"OK"},{close='OK'}) if cancel then ak() end end

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

function string2line(str)
	local ltype,layer,s_time,e_time,style,actor,margl,margr,margv,eff,txt=str:match("(%a+): (%d+),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),(.*)")
	l2={}
	l2.class="dialogue"
	if ltype=="Comment" then l2.comment=true else l2.comment=false end
	l2.layer=layer
	l2.start_time=string2time(s_time)
	l2.end_time=string2time(e_time)
	l2.style=style
	l2.actor=actor
	l2.margin_l=margl
	l2.margin_r=margr
	l2.margin_t=margv
	l2.effect=eff
	l2.text=txt
	return l2
end

function string2time(timecode)
	timecode=timecode:gsub("(%d):(%d%d):(%d%d)%.(%d%d)",function(a,b,c,d) return d*10+c*1000+b*60000+a*3600000 end)
	return timecode
end

function duplikill(tagz)
	local tags1={"blur","be","bord","shad","xbord","xshad","ybord","yshad","fs","fsp","fscx","fscy","frz","frx","fry","fax","fay"}
	local tags2={"c","2c","3c","4c","1a","2a","3a","4a","alpha"}
	tagz=tagz:gsub("\\t%b()",function(t) return t:gsub("\\","|") end)
	for i=1,#tags1 do
	    tag=tags1[i]
	    repeat tagz,c=tagz:gsub("|"..tag.."[%d.-]+([^}]-)(\\"..tag.."[%d.-]+)","%1%2") until c==0
	    repeat tagz,c=tagz:gsub("\\"..tag.."[%d.-]+([^}]-)(\\"..tag.."[%d.-]+)","%2%1") until c==0
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

function extrakill(text,o)
	local tags3={"pos","move","org","fad"}
	for i=1,#tags3 do
	    tag=tags3[i]
	    if o==2 then
	    repeat text,c=text:gsub("(\\"..tag.."[^\\}]+)([^}]-)(\\"..tag.."[^\\}]+)","%3%2") until c==0
	    else
	    repeat text,c=text:gsub("(\\"..tag.."[^\\}]+)([^}]-)(\\"..tag.."[^\\}]+)","%1%2") until c==0
	    end
	end
	repeat text,c=text:gsub("(\\pos[^\\}]+)([^}]-)(\\move[^\\}]+)","%1%2") until c==0
	repeat text,c=text:gsub("(\\move[^\\}]+)([^}]-)(\\pos[^\\}]+)","%1%2") until c==0
	return text
end

function cleantr(tags)
	trnsfrm=""
	zerotf=""
	for t in tags:gmatch("\\t%b()") do
		if t:match("\\t%(\\") then
			zerotf=zerotf..t:match("\\t%((.*)%)$")
		else
			trnsfrm=trnsfrm..t
		end
	end
	zerotf="\\t("..zerotf..")"
	tags=tags:gsub("\\t%b()",""):gsub("^({[^}]*)}","%1"..zerotf..trnsfrm.."}"):gsub("\\t%(%)","")
	return tags
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

function t_error(message,cancel)
	ADD({{class="label",label=message}},{"OK"},{close='OK'})
	if cancel then ak() end
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


function getpos(subs,text)	-- modified version
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
		if defst then st=defst else t_error("Style '"..line.style.."' not found.\nStyle 'Default' not found.",1) end
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
	if alignleft:match(acalign) then horz=acleft h_al="left"
	elseif alignright:match(acalign) then horz=resx-acright h_al="right"
	elseif alignmid:match(acalign) then horz=resx/2 h_al="mid" end
	if aligntop:match(acalign) then vert=acvert v_al="top"
	elseif alignbot:match(acalign) then vert=resy-acvert v_al="bottom"
	elseif aligncent:match(acalign) then vert=resy/2 v_al="mid" end
    end
    if horz>0 and vert>0 then 
	if not text:match("^{\\") then text="{\\rel}"..text end
	text=text:gsub("^({\\[^}]-)}","%1\\pos("..horz..","..vert..")}") :gsub("\\rel","")
    end
    return text
end

-- save inline tags
function inline_pos(t)
	inTags={}
	tl=t:len()
	if tl==0 then return {} end
	p=0
	t1=''
	repeat
		seg=t:match("^(%b{})") -- try to match tags/comments
		if seg then
			table.insert(inTags,{n=p,t=seg})
		else
			seg=t:match("^([^{]+)") -- or match text
			if not seg then t_error("Error: There appears to be a problem with the brackets here...\n"..t1..t,1) end
			SL=re.find(seg,".")
			p=p+#SL -- position of next '{' [or end]
		end
		t1=t1..seg
		t=t:gsub("^"..esc(seg),"")
		tl=t:len()
	until tl==0
	return inTags
end

-- rebuild inline tags
function inline_ret(t,tab)
	tl=t:len()
	nt=''
	kill='_Z#W_' -- this is supposed to never match
	for k,v in ipairs(tab) do
		N=tonumber(v.n)
		if N==0 then nt=nt..v.t
		else
			m='.'
			-- match how many chars at the start
			m=m:rep(N)
			RS=re.find(t,m)
			if not RS then logg(">>> Fatal error. Try rescanning Autoload dir. <<<") end
			seg=RS[1].str
			seg=re.sub(seg,'^'..kill,'')
			nt=nt..seg..v.t
			kill=m -- how many matched in the last round
		end
	end
	-- the rest
	seg=re.sub(t,'^'..kill,'')
	nt=nt..seg
	return nt
end

--	Config Stuff	--
function saveconfig()
	unconf="Unimportant Configuration\n\n"
	for key,val in ipairs(unconfig) do
		if val.class=="floatedit" or val.class=="dropdown" then
			unconf=unconf..val.name..":"..res[val.name].."\n"
		end
		if val.class=="checkbox" and val.name~="save" then
			unconf=unconf..val.name..":"..tf(res[val.name]).."\n"
		end
	end

	unimpkonfig=ADP("?user").."\\unimportant.conf"
	file=io.open(unimpkonfig)
	if file~=nil then
		konf=file:read("*all")
		io.close(file)
		imp1=konf:match("imp1:(.-)\n")
		imp2=konf:match("imp2:(.-)\n")
		imp3=konf:match("imp3:(.-)\n")
		chap1=konf:match("chap1:(.-)\n")
		chap2=konf:match("chap2:(.-)\n")
		chap3=konf:match("chap3:(.-)\n")
	end
	if imp1==nil then imp1="relative" end
	if imp2==nil then imp2="" end
	if imp3==nil then imp3="D:\\typesetting\\" end
	if chap1==nil then chap1="relative" end
	if chap2==nil then chap2="" end
	if chap3==nil then chap3="D:\\typesetting\\" end

	savestuff={
	{x=0,y=0,width=3,class="label",label="This will save the values of dropdown menus and checkboxes, plus the following:"},
	{x=0,y=1,class="label",label="Import script path:"},
	{x=0,y=2,class="label",label="Import relative path:"},
	{x=0,y=3,class="label",label="Import absolute path:"},
	{x=0,y=4,class="label",label="Chapters save path:"},
	{x=0,y=5,class="label",label="Chapters relative path:"},
	{x=0,y=6,class="label",label="Chapters absolute path:"},
	{x=1,y=1,class="dropdown",name="imp1",items={"relative","absolute"},value=imp1,hint="relative = script folder"},
	{x=1,y=2,class="edit",width=2,name="imp2",value=imp2,hint="path from script folder"},
	{x=1,y=3,class="edit",width=2,name="imp3",value=imp3},
	{x=1,y=4,class="dropdown",name="chap1",items={"relative","absolute"},value=chap1,hint="relative = script folder"},
	{x=1,y=5,class="edit",width=2,name="chap2",value=chap2,hint="path from script folder"},
	{x=1,y=6,class="edit",width=2,name="chap3",value=chap3},
	{x=0,y=7,width=3,class="label",label="Default ('relative' + '') is the script path. 'ABC' in 'relative path' will use subfolder 'ABC'.\n'..' in 'relative path' will go one folder higher."},
	}

	click,rez=ADD(savestuff,{"Save","Cancel"},{ok='Save',close='Cancel'})
	if click=="Cancel" then ak() end
	rez.imp3=rez.imp3:gsub("[^\\]$","%1\\")
	rez.chap3=rez.chap3:gsub("[^\\]$","%1\\")

	for key,val in ipairs(savestuff) do
		if val.x==1 then unconf=unconf..val.name..":"..rez[val.name].."\n" end
	end

	file=io.open(unimpkonfig,"w")
	file:write(unconf)
	file:close()
	ADD({{class="label",label="Config saved to:\n"..unimpkonfig}},{"OK"},{close='OK'})
end

function loadconfig()
unimpkonfig=ADP("?user").."\\unimportant.conf"
file=io.open(unimpkonfig)
script_path="relative"
relative_path=""
absolute_path="D:\\typesetting\\"
ch_script_path="relative"
ch_relative_path=""
ch_absolute_path="D:\\typesetting\\"
    if file~=nil then
	konf=file:read("*all")
	file:close()
	if konf:match("^%-%-") then konf="" t_error("Your config file is outdated.\nUse the 'Save Config' button to save a new one.")
	else
	  for key,v in ipairs(unconfig) do
	    if v.class=="floatedit" or v.class=="checkbox" or v.class=="dropdown" then
		if konf:match(v.name) then v.value=detf(konf:match(v.name..":(.-)\n")) end
		if lastimp and v.name=="stuff" then v.value=lastuff end
		if lastimp and v.name=="log" then v.value=lastlog end
		if lastimp and v.name=="zeros" then v.value=lastzeros end
		if lastimp and v.name=="field" then v.value=lastfield end
		if lastimp and v.name=="modzero" then v.value=lastmod0 end
	    end
	  end
	end
	script_path=konf:match("imp1:(.-)\n") or "relative"
	relative_path=konf:match("imp2:(.-)\n") or ""
	absolute_path=konf:match("imp3:(.-)\n") or "D:\\typesetting\\"
	ch_script_path=konf:match("chap1:(.-)\n") or "relative"
	ch_relative_path=konf:match("chap2:(.-)\n") or ""
	ch_absolute_path=konf:match("chap3:(.-)\n") or "D:\\typesetting\\"
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

function analyze(l)
	text=l.text
	dur=l.end_time-l.start_time
	dura=dur/1000
	txt=text:gsub("%b{}","") :gsub("\\N","")
	visible=text:gsub("{\\alpha&HFF&}[^{}]-%b{}",""):gsub("{\\alpha&HFF&}[^{}]*$",""):gsub("%b{}",""):gsub("\\N","\n"):gsub(" *\n+ *"," "):gsub("^ *(.-) *$","%1")
	wrd=0	for word in txt:gmatch("([%a\']+)") do wrd=wrd+1 end
	chars=visible:gsub(" ",""):gsub("[.,\"]","")
	char=chars:len()
	cps=math.ceil(char/dura)
	if dur==0 then cps=0 end
end

function info(subs,sel,act)
	styletab={}
	dc=0
	sdur=0
	S=subs[sel[1]].start_time
	E=subs[sel[#sel]].end_time
	video=nil stitle=nil colorspace=nil resx=nil resy=nil
	prop=aegisub.project_properties()
	for x,i in ipairs(sel) do
		line=subs[i]
		dur=line.end_time-line.start_time
		if line.start_time<S then S=line.start_time end
		if line.end_time>E then E=line.end_time end
		sdur=sdur+dur
	end
	seldur=sdur/1000
	for i=1,#subs do
		if subs[i].class=="info" then
			local k=subs[i].key
			local v=subs[i].value
			if k=="Title" then stitle=v end
			if k=="Video File" then video=v end
			if k=="YCbCr Matrix" then colorspace=v end
			if k=="PlayResX" then resx=v end
			if k=="PlayResY" then resy=v end
		end
		if video==nil then video=prop.video_file:gsub("^.*\\","") end
		if stitle==nil then sct="" else sct="Script title: "..stitle.."\n" end
		if video==nil then vf="" else vf="Video file: "..video.."\n" end
		if resy==nil then reso="" else reso="Script resolution: "..resx.."x"..resy.."\n" end
		if colorspace==nil then cols="" else cols="Colorspace: "..colorspace.."\n" end
		nfo=sct..vf..reso..cols
		if subs[i].class=="style" then
			local s=subs[i]
			table.insert(styletab,s)
		end
		if subs[i].class=="dialogue" then
			dc=dc+1
			local l=subs[i]
			if i==act then
				ano=dc
				analyze(l)
				for s=1,#styletab do st=styletab[s]
				    if st.name==l.style then
					acfont=st.fontname
					acsize=st.fontsize
					acalign=st.align
					acleft=st.margin_l
					acright=st.margin_r
					acvert=st.margin_t
					acbord=st.outline
					acshad=st.shadow
					if st.bold then actbold="Bold" else actbold="Regular" end
				    end 
				end
				ast=l.start_time
				aet=l.end_time
				if ms2fr(1) then
					afr=" ("..ms2fr(aet)-ms2fr(ast).." frames)"
					fps=round(aegisub.frame_from_ms(99999999)/(99999999/1000)*1000)/1000
					frate="\nFramerate: "..fps.." fps"
				else afr='' frate="\nFramerate: unknown"
				end
				actime=(l.end_time-ast)/1000 ..'s'..afr
				actime=actime:gsub("(%(1 frame)s","%1")
				if stfr~=nil then  else fps=0 end

				aligntop="789" alignbot="123" aligncent="456"
				alignleft="147" alignright="369" alignmid="258"
				if aligntop:match(acalign) then vert=acvert
				elseif alignbot:match(acalign) then vert=resy-acvert
				elseif aligncent:match(acalign) then vert=resy/2 end
				if alignleft:match(acalign) then horz=acleft
				elseif alignright:match(acalign) then horz=resx-acright
				elseif alignmid:match(acalign) then horz=resx/2 end

				aktif="Active line: #"..ano.."\nStyle used: "..l.style.."\nFont used: "..acfont.."\nWeight: "..actbold.."\nFont size: "..acsize.."\nBorder: "..acbord.."\nShadow: "..acshad.."\nDuration: "..actime.."\nCharacters: "..char.."\nCharacters per second: "..cps.."\nDefault position: "..horz..","..vert.."\n\nVisible text:\n"..visible
			end
		end
	end
	if ms2fr(1) then selfr=" ("..ms2fr(E)-ms2fr(S).." frames)" else selfr='' end
	selfr=selfr:gsub("(%(1 frame)s","%1")
	infodump=nfo.."Styles used: "..#styletab.."\nDialogue lines: "..dc..", Selected: "..#sel.."\nCombined length of selected lines: "..seldur.."s\nSelection duration: "..(E-S)/1000 .."s"..selfr..frate.."\n\n"..aktif
end

help_i=[[
- IMPORT/EXPORT -

This allows you to import OP/ED or signs (or whatever) from an external .ass file.
OP/ED must be saved as OP.ass and ED.ass; a sign can have any name.
The .ass file may contain headers, or it can be just the dialogue lines.
The imported stuff will be shifted to your currently selected line (or the first one in your selection).
The first line of the saved file works as a reference point, so use a "First frame of OP" line etc.
(You can save your OP/ED shifted to 0 or you can just leave it as is;
   the times will be recalculated to start at the current line.)
"keep line" will keep your current line and comment it. Otherwise the line gets deleted.

IMPORT SIGN / IMPORT SIGNS - works like OP/ED, but you have to input the sign's name.
The difference between the two is:
SIGN - each sign must be saved in its own .ass file.
In the GUI, input the sign's/file's name, for example "eptitle"[.ass].
SIGNS - all signs must be saved in signs.ass.
They are distinguished by what's in the "effect" field - that's the sign's name.
For SIGN, make something like eptitle.ass, eyecatch.ass;
for SIGNS, put "eptitle" or "eyecatch" in the effect field, and put all the signs in signs.ass.
(You can have blank lines between signs for clarity. The script can deal with those.)
The GUI will then show you a list of signs that it gets from the effect fields.
I recommend using SIGNS, as it's imo more efficient (but SIGN was written first and I didn't nuke it).

Options:
With nothing checked, stuff is shifted to the first frame of your active line (like OP/ED).
(SIGN) File name: "custom" will use what you type below. The other ones are presets.
"keep current line's times" - all imported lines will have the start/end time of your active line
"keep current line's text" - all imported lines will have their text (not tags) replaced with your active line's text
   - If you want to replace only some lines and keep others, like masks, put 'x' in actor field of the mask.
"combine tags (current overrides)" - tags from current + imported line get combined (current overrides imported)
"combine tags (imported overrides)" - same as above, but imported overrides current
   - Both of these will also be ignored for imported lines that have "x" in actor field.
"don't shift times" - times of imported lines will be kept as they were saved
"delete original line" - this overrides the "keep line" option in the main menu.
(I thought it would be convenient to have it here.)

EXPORT SIGN - Saves the selected sign(s) either to 'signs.ass' or to a new file.
Effect field must contain the signs' names.

You can use relative or absolute paths. (Check the settings below.)
Default is the script's folder. If you want the default to be one folder up, use "..\".
You can use an absolute path, have one huge signs.ass there,
and have all the signs marked "show_name-sign_name" in the effect field.

IMPORT CHPTRS - Imports chapters from xml files - creates lines with "chptr" in actor and {ch. name} as text.

The path for importing things can be set in 'Save Config'. Default is script path.]]

help_u=[[
UPDATE LYRICS

This is probably the most complicated part, but if your songs have some massive styling with layers + tracking,
this will make updating lyrics, which would otherwise be a pain in the ass, really easy.
The only styling that will prevent this from working is inline tags - gradient by character etc.

The prerequisite here is that your OP/ED MUST have NUMBERED lines!
(See NUMBERS section - might be good to read that first.)
The numbers must correspond to the verses, not to lines in the script.
If line 1 of the SONG is mocha-tracked over 200 frames, all of those frames must be numbered 01.
It is thus most convenient to number the lines before you start styling, when it's still simple.

How this works:
Paste your updated lyrics into the large, top-left area of the GUI.
Use the Left and Right fields to set the markers to detect the right lines.
Without markers it will just look for numbers.
If your OP lines are numbered with "OP01eng", you must set "OP" under Left and "eng" under Right.
For now, everything is case-sensitive (I might change that later if it gets really annoying and pointless).
You must also correctly set the actor/effect choice in the bottom-right part of the GUI.
If you pasted lyrics, selected "update lyrics", and set markers and actor/effect.
Then hit Import, and lyrics will be updated.

How it works - example:
The lyrics you pasted in the data box get their lines assigned with numbers from 1 to whatever.
Let's say your markers are "OP01eng" and you're using the effect field.
The script looks for lines with that pattern in the effect field.
When it finds one, it reads the number (for example "01" from "OP01eng")
and replaces the line's text (skipping tags) with line 1 from the pasted lyrics.
For every line marked "OP##eng" it replaces the current lyrics with line ## from your pasted updated lyrics.

To make sure this doesn't fuck up tremendously, it shows you a log with all replacements at the end.

That's pretty much all you really need to know for updating lyrics, but there are a few more things.

If the script doesn't find any lines that match the markers, it gives you a message like this:
"The effect field of selected lines doesn't match given pattern..."
This means the lines either don't exist in your selection, or you probably forgot to set the markers.

"style restriction" is an extra option that lets you limit the replacing to lines whose style contains given pattern.
Let's give some examples:
You check the restriction and type "OP" in the field below.
You can now select the whole script instead of selecting only the OP lines,
and only lines with "OP" in style will be updated.
You may have the ED numbered the same way, but the "OP" restriction will ignore it.
This can be also useful if you have lines numbered just 01, 02 etc.,
and you have english and romaji, all mixed together.
If your styles are OP-jap and OP-eng, you can type "jap" in the restriction field if you're updating romaji
to make sure the script doesn't update the english lines as well (replacing them with romaji).
It is, however, recommended to just use different markers, like j01 / e01.]]

help_c=[[
- CHAPTERS -

This will generate chapters from the .ass file. Use 'Save Config' to set path for saving the .xml.

MARKER: For a line to be used for chapters, it has to be marked with "chapter"/"chptr"/"chap"
in actor/effect field (depending on settings) or the same 3 options as a separate comment, ie. {chapter} etc.

CHAPTER NAME: What will be used as chapter name.
It's either the content of the effect field, or the line's FIRST comment.
If the comment is {OP first frame} or {ED start}, the script will remove " first frame" or " start",
so you can keep those.

If you use default settings, just put "chapter" in actor field and make comments like {OP} or {Part A}.

Subchapters: You can make subchapters like this {Part A::Scene 5}.
This will be a subchapter of "Part A" called "Scene 5".

If you want a different LANGUAGE than 'eng', set it in the textbox below "chapter mark"

CHAPTER MARK: Sets the selected chapter for selected line(s). Uses marker and name. (Doesn't create xml.)
If you want a custom chapter name, type it in the textbox below this.

mp4-compatible chapters: switches to this format:
CHAPTER01=00:00:00.033
CHAPTER01NAME=Intro]]

help_n=[[
- NUMBERS -

This is a tool to number lines and add various markers to actor/effect fields.
The dropdown with "01" lets you choose how many leading zeros you want.
The Left and Right fields will add stuff to the numbers. If Left is "x" and Right is "yz",
the first marker will be "x01yz".
What makes this function much more versatile is the "Mod" field.
If you put in one number, then that's the number from which the numbering will start, so "5" -> 5, 6, 7, etc.
You can, however, use a comma or slash to modify the numbering some more.
"8,3" or "8/3" will start numbering from 8, repeating each number 3 times, so 8, 8, 8, 9, 9, 9, 10, 10, 10, etc.
This allows you to easily number lines that are typeset in layers etc.
Additionally, you can set a limit in [], for example 1/3[2], which will start from 1, use each number 3 times,
and only go up to 2 and then start again, so: 1 1 1 2 2 2 1 1 1 2 2 2
2/3[4] would give you 2 2 2 3 3 3 4 4 4 2 2 2 3 3 3 4 4 4 ...

"number 12321" works the same, but...
1. requires the limit in [] because...
2. numbers up and back, so 1[5] gives 1 2 3 4 5 4 3 2 1 2 3 4 5 4 3 2 ...

"add to marker" uses the Left and Right fields to add stuff to the current content of actor/effect/text.
If you number lines for the OP, you can set "OP-" in Left and "-eng" in Right to get "OP-01-eng".
(Mod does nothing when adding markers.)

"zero fill" finds numbers and fills them with zeroes based on the dropdown menu. Works only for actor, effect, and text.
For text, it skips tags and comments, as well as negative numbers and decimals.

"in text" works with "number lines".
The Marker field is ignored, and numbering is applied to numbers found in text.
In every line, wherever a number is detected in text, it's replaced by the number for that line.
Mostly useful for non-subbing purposes. Make 20 lines with: <img src="name01.jpg"><br>
Run the function and the number of the jpg will change for each line. (Copypaste back to html.)

"random" generates random numbers.
Use Left and Right fields to set the limits, e.g. from 1 to 100 or from -20 to 20.
Marker is where the numbers will appear. You can use effect, actor, comment (it'll be {random: #}),
or margins, though they can't have negatives and decimals, so the functionality is limited.
Rounding is set by the dropdown menu on the right: 1 is whole numbers, 01 can be 0.1, 001 -> 0.001, etc.
These numbers can then be used by other functions to modify various things (Relocator's Randomise).
Mod 1 is one result per line, Mod 2 will give the same result for each 2 lines, etc. This can be used to keep the same results for all layers on the same frame.]]

help_d=[[
- DO STUFF -

- Save/Load -
You can use this to save for example bits of text you need to paste frequently (like a multi-clipboard).
Paste text in the data area to save it. If the data area is empty, the function will load your saved texts.

- Replacer + Lua Patterns  -
Use "Left" and "Right" for a lua regexp replace function.

- Replacer + Perl Regexp -
Use "Left" and "Right" for a perl regexp replace function.

- Lua Calc -
Use "Left" and "Right" with lua regexp to perform calculations on captured numbers.
Captures will be named a, b, c... up to p (16 captures max).
Functions are +, -, *, /, and round(a), which rounds the number captured in a.
> Example: (%d)(%d)(%d) -> a+1b*2c-3
This will match 3-digit patterns, add 1 to first digit, multiply the second by 2, and subtract 3 from the 3rd.
If you want to leave one of the captures as is, use .. to separate it from other letters: a+1b..c-3
> Example: pos%(([%d%.]+),([%d%.]+) -> pos(a+50,b-100
This will shift position right by 50 and up by 100.

- Split Text to Actor/Effect
This allows you to split off patterns of text and move them to Effect/Actor.
If text is "Abc/def/xyz", you put / in Left, and you set Marker to Effect, you'll get "Abc" in Effect and "def/xyz" in Text.
If you set Mod to "0", the separator will be included, so with } in Left, you can move start tags to Effect.
If you set Mod to "2", the separator will be left in Text.
If there's another separator in Right, there's a second split and the chunk goes to Actor. ("Abc" in Effect, "def" in Actor, "xyz" in Text.)
If you select Actor in Marker, it will be the primary target and Effect the secondary.
Obviously no other fields than Eff/Act are really useful for this, so they don't work.
If you repeat the function, new chunks will be added to Actor/Effect, so you can for example separate by \ and move stuff tag by tag.
(Text thus split can be put back together with MultiCopy's Attach function.)

- Reverse Text -
Reverses text (character by character). Nukes comments and inline tags.

- Reverse Words -
Reverses text (word by word). Nukes comments and inline tags.

- Fill Columns -
For selected columns, each line with an empty entry for that column (empty string or zero) will inherit the value from the previous selected line.

- Reverse Transforms -
\blur1\t(\blur3) becomes \blur3\t(\blur1). Only for initial tags. Only one transform for each tag.

- Fake Capitals -
Creates fake capitals by increasing font size for first letters.
With all caps, for first letters of words. With mixed text, for uppercase letters.
Set the \fs for the capitals in the Left field.
Looks like this: {\fs60}F{\fs}AKE {\fs60}C{\fs}APITALS

- Format Dates -
Formats dates to one of 4 options. Has its own GUI. Only converts from the other 3 options in the GUI.

- Split into Letters (alpha) -
Makes a line for each letter, making the other letters invisible with alpha.
This lets you do things with each letter separately.

- Explode -
This splits the line into letters and makes each of them move in a different direction and fade out.

- Dissolve Text -
Various modes of dissolving text. Has its own Help.

- Randomised Transforms -
Various modes of randomly transforming text. Has its own Help.

- Clone Clip -
Clones/replicates a clip you draw.
Set how many rows/columns and distances between them, and you can make large patterns.

- Clip2Margins -
Sets margins for the line from a rectangular clip if present. You can choose which margins to set.
Margins are set around the clip.

- Duplicate and Shift Lines -
Duplicates selected lines as many times you want before and/or after the current line.
Use Left/Right fields to set how many frames should be duplicated before/after the line.
\move and \t --> lines before get \pos with start coordinates and state before transforms;
lines after get end coordinates and state after transforms.
Lines are automatically numbered in Effect field. You can disable that by typing 0 in Mod field.

- Extrapolate Tracking -
Extrapolates position and scaling for beginning/end of a mocha-tracked line that didn't track,
usually because of a fade. Only works for linear movement/zoom.
If mocha doesn't track the first/last few frames, apply the data without those frames.
Mark the untracked frames with 'x' in Effect. Select those plus a few frames before or after, and use this.
How many frames to select will depend on how exactly "linear" the movement is.
With perfectly linear, you can select all the tracked lines to get a more accurate per-frame average.
If there seems to be a little bit of an acceleration, use only about 4-6 reference frames.
Requirements:
	- All selected lines must be 1 frame long! (Use line2fbf if they aren't.)
	- Lines to apply extrapolation to must be marked with 'x' in effect. The rest are reference lines.
	- Selection must be consecutive, lines sorted by time, etc. Not fool-proofed for stupid shit.
	- If you have several signs and/or layers, each must be done separately.
	  (Since layers will have the same values, you can use MultiCopy to copy from one to another.)

- Time by Frames -
Left = frames to shift start time by, each line (2 = each new line starts 2 frames later than previous)
Right = frames to shift end time by, each line (4 = each new line ends 4 frames later than previous)

- Convert Framerate -
Converts framerate from a to b where a is the input from "Left" and b is input from "Right".

- Fix Kara Tags for fbf Lines -
If you need to split a line with kara tags, this adjusts the tags so that the text appears continuously as it should.
Selection must include the first line for reference. Applies to all karaoke tags indiscriminately - \k, \kf, \ko.

- Make Style from Act. Line -
Creates a new style from the values in start tags in active line combined with the current style.

- Make Comments Visible -
Nukes { } from comments, thus making them part of the text visible on screen.

- Switch Commented/Visible -
Comments out what's visible and makes visible what's commented. Allows switching between two texts.

- Honorificslaughterhouse -
Comments out honorifics.]]

function switch(subs,sel)
res={}
res.dat=''
res.stuff='switch commented/visible'
stuff(subs,sel)
end

function rvrstxt(subs,sel)
res={}
res.dat=''
res.stuff='reverse text'
stuff(subs,sel)
end

function rvrswrds(subs,sel)
res={}
res.dat=''
res.stuff='reverse words'
stuff(subs,sel)
end

if haveDepCtrl then
  depRec:registerMacros({
	{script_name,script_description,significance},
	{": Non-GUI macros :/Significance: Switch commented && visible text","Switch commented & visible text",switch},
	{": Non-GUI macros :/Significance: Reverse text","Reverse text",rvrstxt},
	{": Non-GUI macros :/Significance: Reverse words","Reverse words",rvrswrds},
  },false)
else
	aegisub.register_macro(script_name,script_description,significance)
	aegisub.register_macro(": Non-GUI macros :/Significance: Switch commented && visible text","Switch commented & visible text",switch)
	aegisub.register_macro(": Non-GUI macros :/Significance: Reverse text","Reverse text",rvrstxt)
	aegisub.register_macro(": Non-GUI macros :/Significance: Reverse words","Reverse words",rvrswrds)
end