-- Manual: http://unanimated.hostfree.pw/ts/scripts-manuals.htm#multiedit

script_name="Multi-Line Editor"
script_description="Multi-Line Editor"
script_author="unanimated"
script_version="1.8"
script_namespace="ua.MultiLineEditor"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="1.8.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

re=require'aegisub.re'
unicode=require'aegisub.unicode'
clipboard=require("aegisub.clipboard")

function editlines(subs,sel)
	ADD=aegisub.dialog.display
	ak=aegisub.cancel
	editext=""    dura=""	edeff=""	edact=""	edst=""
	for z,i in ipairs(sel) do
		progress("Reading line: "..z.."/"..#sel.." ("..math.floor(z/#sel*100).."%)")
		line=subs[i]
		text=line.text
		dur=(line.end_time-line.start_time)/1000
		char=text:gsub("%b{}",""):gsub("\\[Nnh]","*"):gsub("%s?%*+%s?"," "):gsub("[%s%p]","")
		linelen=char:len()
		cps=math.ceil(linelen/dur)
		if tostring(dur):match("%.%d$") then dur=dur.."0" end
		if not tostring(dur):match("%.") then dur=dur..".00" end
		if cps<10 then cps="  "..cps end
		if dur=="0.00" then cps="n/a" end
		dura=dura..dur.." .. "..cps.." .. "..linelen.."\n"
		editext=editext..text.."\n"
		edst=edst..line.style.."\n"
		edact=edact..line.actor.."\n"
		edeff=edeff..line.effect.."\n"
	end
	editext=nRem(editext)
	dura=nRem(dura)
	edst=nRem(edst)
	edact=nRem(edact)
	edeff=nRem(edeff)
	editbox(subs,sel)
	if failt==1 then editext=res.dat editbox(subs,sel) end
	return sel
end

function editbox(subs,sel)
	progress("Loading Editor...")
	BH=math.ceil(#sel*0.66)+2
	if BH<7 then BH=7 end
	repeat
	    if editext:len()>=BH*200 then BH=BH+1 end
	until editext:len()<BH*200 or BH>=20
	if BH>20 then BH=20 end
	b=BH+1
	nocom=editext:gsub("%b{}","") :gsub("%—"," ")
	words=0
	for wrd in nocom:gmatch("%S+") do words=words+1 end
	
	R1={x=0,y=b,width=1,class="label",label="Replace:"}
	R2={x=1,y=b,width=15,class="edit",name="rep1",value=lastrep1 or ""}
	R3={x=16,y=b,width=1,class="label",label="with"}
	R4={x=17,y=b,width=15,class="edit",name="rep2",value=lastrep2 or ""}
	R5={x=32,y=b,width=12,class="edit",name="repl",value=""}
	R6={x=44,y=b,class="label",label=" "}
	R7={x=45,y=b,width=7,class="checkbox",name="whole",label="whole word only",hint="only without regexp"}
	R8={x=52,y=b,width=3,class="checkbox",name="reg",label="regexp   ",value=regr}
	R9={x=55,y=b,width=2,class="checkbox",name="lua",label="lua",value=luar}
	
	GUI1={R1,R2,R3,R4,R5,R6,R7,R8,R9,
	{x=0,y=0,width=10,class="label",label=" Multi-line Editor v"..script_version},
	{x=52,y=0,width=5,class="label",label="Duration | CPS | chrctrs "},
	{x=10,y=0,width=22,name="info",class="edit",value="Lines loaded: "..#sel..", Words: "..words..", Characters: "..editext:len()},
	{x=32,y=0,width=3,class="checkbox",name="an",label="\\an8 "},
	{x=35,y=0,width=3,class="checkbox",name="i",label="\\i1 "},
	{x=38,y=0,width=3,class="checkbox",name="b",label="\\b1 "},
	{x=41,y=0,width=5,class="checkbox",name="q",label="\\q2 "},
	{x=47,y=0,width=4,class="checkbox",name="sent",label="Sentences",hint="Capitalise sentences\n(including start of lines)"},
	{x=0,y=1,width=52,height=BH,class="textbox",name="dat",value=editext},
	{x=52,y=1,width=5,height=BH,class="textbox",name="durr",value=dura,hint="This is informative only. \nCPS=Characters Per Second"},
	}
	
	GUI2={R1,R2,R3,R4,R5,R6,R7,R8,R9,
	{x=0,y=0,width=9,class="checkbox",name="rs",label="Style"},
	{x=9,y=0,width=11,class="checkbox",name="ra",label="Actor"},
	{x=20,y=0,width=12,class="checkbox",name="re",label="Effect"},
	{x=32,y=0,width=12,class="checkbox",name="rt",label="Text",value=true},
	{x=44,y=0,width=14,class="label",label="Checkboxes mark what Replacer applies to"},
	{x=0,y=1,width=9,height=BH,class="textbox",name="dast",value=edst},
	{x=9,y=1,width=11,height=BH,class="textbox",name="dact",value=edact},
	{x=20,y=1,width=12,height=BH,class="textbox",name="deaf",value=edeff},
	{x=32,y=1,width=28,height=BH,class="textbox",name="dat",value=editext},
	}
	buttons={"Save","Replace","Remove tags","Rm. comments","Remove \"- \"","Remove \\N","Add tags","Capitalise","Switch","Taller GUI","Cancel"}
	GUI=GUI1
	repeat
	if P~="Save" and P ~="Cancel" and P~=nil then
	    if P=="Add tags" then
	      tg=""
	      if res.q then tg=tg.."{\\q2}" end
	      if res.an then tg=tg.."{\\an8}" end
	      if res.i then tg=tg.."{\\i1}" end
	      if res.b then tg=tg.."{\\b1}" end
	      tg=tg:gsub("}{","")
	      res.dat=res.dat:gsub("$","\n"):gsub("(.-)\n",tg.."%1\n"):gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}"):gsub("\n$","")
	    end
	    if P=="Capitalise" then
		captest=res.dat:gsub("%b{}",""):gsub("\\N","")
		res.dat=res.dat:gsub("$","\n")
		if res.sent then res.dat=res.dat:gsub("(.-)\n",function(a) return sentences(a).."\n" end)
		elseif not captest:match("%l") then res.dat=res.dat:gsub("(.-)\n",function(a) a=lowercase(a) return capitalise(a).."\n" end)
		elseif not captest:match("%u") then res.dat=res.dat:gsub("(.-)\n",function(a) return uppercase(a).."\n" end)
		else res.dat=res.dat:gsub("(.-)\n",function(a) return lowercase(a).."\n" end)
		end
		res.dat=res.dat:gsub("\n$","")
	    end
	    if P=="Remove \\N" then res.dat=res.dat:gsub("%s*\\N%s*"," ") end
	    if P=="Remove tags" then res.dat=res.dat:gsub("{%*?\\[^}]-}","") end
	    if P=="Rm. comments" then res.dat=res.dat:gsub("{[^\\}]-}","") :gsub("{[^\\}]-\\N[^\\}]-}","") end
	    if P=="Remove \"- \"" then res.dat=res.dat:gsub("^%- ","") :gsub("\n%- ","\n") :gsub("^({\\i1})%- ","%1") :gsub("\n({\\i1})%- ","\n%1") end
	    if P=="Replace" then
	      c=0
	      if res.rt or GUI==GUI1 then res.dat=replace(res.dat) end
	      if GUI==GUI2 then
		if res.rs then res.dast=replace(res.dast) end
		if res.ra then res.dact=replace(res.dact) end
		if res.re then res.deaf=replace(res.deaf) end
	      end
	      res.repl=c.." replacements"
	    end
	    if P=="Taller GUI" then
		for key,val in ipairs(GUI1) do
		    if val.y==1 then val.height=val.height+2 end
		    if val.y>1 then val.y=val.y+2 end
		end
		for key,val in ipairs(GUI2) do
		    if val.y==1 then val.height=val.height+2 end
		end
	    end
	    for key,val in ipairs(GUI) do val.value=res[val.name] end
	    if P=="Switch" then
		if GUI==GUI1 then GUI=GUI2 info=res.info else GUI=GUI1 end
		for key,val in ipairs(GUI) do if val.name=="dat" then val.value=res[val.name] end end
	    end
	    for key,val in ipairs(GUI) do
		if val.name=="info" then val.value=info or res[val.name] end
		if val.name=="sent" then val.value=false end
	    end
	end
	P,res=ADD(GUI,buttons,{save='Save',close='Cancel'})
	until P=="Save" or P=="Cancel"
	
	if P=="Cancel" then ak() end
	if P=="Save" then savelines(subs,sel) end
	lastrep1=res.rep1	lastrep2=res.rep2
	regr=res.reg	luar=res.lua
	return sel
end

function replace(d)
    if res.lua then
	d,r=d:gsub(res.rep1,res.rep2)
    elseif res.reg then
	r=re.find(d,res.rep1) or {}
	r=#r
	d=re.sub(d,res.rep1,res.rep2)
    else
	rep1=esc(res.rep1) rerep1=resc(res.rep1)
	if res.whole then
	    r=re.find(d,"\\b"..rerep1.."\\b") or {}
	    r=#r
	    d=re.sub(d,"\\b"..rerep1.."\\b",res.rep2)
	else
	    d,r=d:gsub(rep1,res.rep2)
	end
    end
    c=c+r
    return d
end

function lowercase(t)
	t=t:gsub("\\[Nnh]","{%1}")
	t=t:gsub("^([^{]*)",function(l) return ulower(l) end)
	t=t:gsub("}([^{]*)",function(l) return "}"..ulower(l) end)
	t=t:gsub("{(\\[Nnh])}","%1")
	return t
end

function uppercase(t)
	t=t:gsub("\\[Nnh]","{%1}")
	t=t:gsub("^([^{]*)",function(u) return uupper(u) end)
	t=t:gsub("}([^{]*)",function(u) return "}"..uupper(u) end)
	t=t:gsub("{(\\[Nnh])}","%1")
	return t
end

function sentences(t)
somewords={"English","Japanese","American","British","German","French","Spanish","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday","January","February","April","June","July","August","September","October","November","December"}
hnrfx={"%-san","%-kun","%-chan","%-sama","%-dono","%-se[nm]pai","%-on%a+an"}
	t=re.sub(t,[[^(["']?\l)]],function(l) return uupper(l) end)
	t=re.sub(t,[[^\{[^}]*\}(["']?\l)]],function(l) return uupper(l) end)
	t=re.sub(t,[[[\.\?!](\s|\s\\N|\\N)["']?(\l)]],function(l) return uupper(l) end)
	t=t:gsub(" i([' %?!%.,])"," I%1")
	t=t:gsub("\\Ni([' ])","\\NI%1")
	t=t:gsub(" m(arch %d)"," M%1")
	t=t:gsub(" a(pril %d)"," A%1")
	for l=1,#somewords do t=t:gsub(somewords[l]:lower(),somewords[l]) end
	for h=1,#hnrfx do
	  t=t:gsub("([ %p]%l)(%l*"..hnrfx[h]..")",function(h,f) return h:upper()..f end)
	  t=t:gsub("(\\N%l)(%l*"..hnrfx[h]..")",function(h,f) return h:upper()..f end)
	end
	t=re.sub(t,"\\b(of|in|from|\\d+st|\\d+nd|\\d+rd|\\d+th) m(arch|ay)\\b","\\1 M\\2")
	t=re.sub(t,"\\bm(r|rs|s)\\.","M\\1.")
	t=re.sub(t,"\\bdr\\.","Dr.")
	return t
end

function capitalise(txt)
word={"A","About","Above","Across","After","Against","Along","Among","Amongst","An","And","Around","As","At","Before","Behind","Below","Beneath","Beside","Between","Beyond","But","By","Despite","During","Except","For","From","In","Inside","Into","Near","Nor","Of","On","Onto","Or","Over","Per","Sans","Since","Than","The","Through","Throughout","Till","To","Toward","Towards","Under","Underneath","Unlike","Until","Unto","Upon","Versus","Via","With","Within","Without","According to","Ahead of","Apart from","Aside from","Because of","Inside of","Instead of","Next to","Owing to","Prior to","Rather than","Regardless of","Such as","Thanks to","Up to","and Yet"}
onore={"%-San","%-Kun","%-Chan","%-Sama","%-Dono","%-Se[nm]pai","%-On%a+an"}
nokom={"^( ?)([^{]*)","(})([^{]*)"}
  for n=1,2 do
    txt=txt:gsub(nokom[n],function(no_t,t)
	t=t:gsub("\\[Nnh]","{%1}")
	t=re.sub(t,[[\b\l]],function(l) return uupper(l) end)
	t=re.sub(t,[[[I\l]'(\u)]],function(l) return ulower(l) end)

	for r=1,#word do	w=word[r]
	t=t:gsub("^ "..w.." "," "..w:lower().." ")
	t=t:gsub("([^%.:%?!]) "..w.." ","%1 "..w:lower().." ")
	t=t:gsub("([^%.:%?!]) (%b{})"..w.." ","%1 %2"..w:lower().." ")
	t=t:gsub("([^%.:%?!]) (%*Large_break%* ?)"..w.." ","%1 %2"..w:lower().." ")
	end

	t=t:gsub("$","#")
	-- Roman numbers (this may mismatch some legit words - sometimes there just are 2 options and it's a guess)
	t=t:gsub("(%s?)([IVXLCDM])([ivxlcdm]+)([%s%p#])",function(s,r,m,e) return s..r..m:upper()..e end)
	t=t:gsub("([DLM])ID","%1id")
	t=t:gsub("DIM","Dim")
	t=t:gsub("MIX","Mix")
	t=t:gsub("Ok([%s%p#])","OK%1")
	for h=1,#onore do
	  t=t:gsub(onore[h].."([%s%p#])",onore[h]:lower().."%1")
	end
	t=t:gsub("#$","")
	t=t:gsub("{(\\[Nnh])}","%1")
    return no_t..t end)
  end
  return txt
end

function savelines(subs,sel)
progress("Saving...")
    tdat={}	sdat={}	adat={}	edat={}
    tt=res.dat.."\n"	if #sel==1 then tt=tt:gsub("\n(.)","\\N%1") tt=tt:gsub("\\N "," \\N") end
    ss=res.dast or "" if ss~="" then ss=ss.."\n" end
    aa=res.dact or "" if aa~="" then aa=aa.."\n" end
    ee=res.deaf or "" if ee~="" then ee=ee.."\n" end
    for dataline in tt:gmatch("(.-)\n") do table.insert(tdat,dataline) end
    for dataline in ss:gmatch("(.-)\n") do table.insert(sdat,dataline) end
    for dataline in aa:gmatch("(.-)\n") do table.insert(adat,dataline) end
    for dataline in ee:gmatch("(.-)\n") do table.insert(edat,dataline) end
    
    if #sdat>0 and #sel~=#sdat then t_error("Line count for Style ["..#sdat.."] does not \nmatch the number of selected lines ["..#sel.."].") end
    if #adat>0 and #sel~=#adat then t_error("Line count for Actor ["..#adat.."] does not \nmatch the number of selected lines ["..#sel.."].") end
    if #edat>0 and #sel~=#edat then t_error("Line count for Effect ["..#edat.."] does not \nmatch the number of selected lines ["..#sel.."].") end
    
    failt=0
    if #sel~=#tdat and #sel>1 then failt=1 else
	for z,i in ipairs(sel) do
        line=subs[i]
	line.text=tdat[z]
	line.style=sdat[z] or line.style
	line.actor=adat[z] or line.actor
	line.effect=edat[z] or line.effect
	subs[i]=line
	end
    end
    if failt==1 then
	t_error("Line count of edited text does not \nmatch the number of selected lines.")
	clipboard.set(res.dat)
    end
    aegisub.set_undo_point(script_name)
    return sel
end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
end

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function resc(str) str=str:gsub("[%%%(%)%[%]%.%*%-%+%?%^%$\\{}]","\\%1") return str end
function logg(m) m=m or "nil" aegisub.log("\n "..m) end
function nRem(x) x=x:gsub("\n$","") return x end
ulower=unicode.to_lower_case
uupper=unicode.to_upper_case
STAG="^{>?\\[^}]-}"

-- Re-Split doens't support inline tags (as that would make the functions 3 times as big) --
function resplitl(subs,sel,act)
	line=subs[act]
	text=line.text
	if act<#subs then
	    nl=subs[act+1]
	    nlt=nl.text:gsub("%b{}",""):gsub("^\\N","")
	    first=nlt:match("^(%S+)\\N") or nlt:match("^%S+")
	    if first then
		tags=nl.text:match(STAG) or ""
		nl.text=nl.text:gsub(STAG,""):gsub("^\\N","")
		:gsub("^%S+ *",function(f) if f:match("\\N") then return f:match("\\N(.*)") else return "" end end):gsub("^\\N","")
		nl.text=tags..nl.text
		text=text.."_!!!_"..first
		repeat text,r=text:gsub("({[^\\}]-})(_!!!_[^{ ]+)","%2%1") until r==0
		text=text:gsub("_!!!_"," "):gsub("^({\\[^}]-}) *","%1")
	    end
	    subs[act+1]=nl
	end
	line.text=text
	subs[act]=line
    aegisub.set_undo_point(script_name)
    return sel
end

function resplitr(subs,sel,act)
	line=subs[act]
	text=line.text
	if act<#subs then
	    nl=subs[act+1]
	    ct=text:gsub("%b{}","")
	    last=ct:match("\\N(%S+) *$") or ct:match("(%S+) *$")
	    if last then
		text=text.."_!!!_"
		repeat text,r=text:gsub("(%b{})(_!!!_)","%2%1") until r==0
		text=text:gsub(" *[^} ]+_!!!_",function(f) if f:match("\\N") then return f:match(" *(.*)\\N") else return "" end end)
		:gsub(" *{\\[^}]-}$","")
		tags=nl.text:match(STAG) or ""
		nl.text=tags..last.." "..nl.text:gsub(STAG,"")
	    end
	    subs[act+1]=nl
	end
	line.text=text
	subs[act]=line
    aegisub.set_undo_point(script_name)
    return sel
end

function reverse(subs,sel)
	rvrs={
	{x=0,y=0,class="label",label="Reverse: "},
	{x=1,y=0,class="dropdown",name="rv",items={"text","actor","effect","style","layer","margin l","margin r","margin v","start time","end time"},value="text"},
	}
	Pr,rs=aegisub.dialog.display(rvrs,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if Pr=="Cancel" then aegisub.cancel() end
	target=rs.rv:gsub(" ","_"):gsub("_v","_t")
	tab={}
	for z,i in ipairs(sel) do
		line=subs[i]
		table.insert(tab,line[target])
	end
	for z,i in ipairs(sel) do
		line=subs[sel[#sel-z+1]]
		line[target]=tab[z]
		subs[sel[#sel-z+1]]=line
	end
	return sel
end

function sswitch(subs,sel)
    styles={}
    for i=1,#subs do
        if subs[i].class=="style" then
	    table.insert(styles,subs[i])
	end
	if subs[i].class=="dialogue" then break end
    end
    for x, i in ipairs(sel) do
	line=subs[i]
	style=line.style
	for a,st in ipairs(styles) do
	  if st.name==style then
	    if styles[a+1] then newstyle=styles[a+1].name else newstyle=styles[1].name end
	    style=newstyle
	  break end
	end
	if style==line.style then style=styles[1].name end
	line.style=style
	subs[i]=line
    end
end

if haveDepCtrl then
  depRec:registerMacros({
	{script_name,script_description,editlines},
	{": Non-GUI macros :/MultiEdit: ReSplit - Backward","Resplits lines at a different place",resplitl},
	{": Non-GUI macros :/MultiEdit: ReSplit - Forward","Resplits lines at a different place",resplitr},
	{": Non-GUI macros :/MultiEdit: Reverse","Reverses texts of selected lines, keeping times",reverse},
	{": Non-GUI macros :/MultiEdit: Switch style","Reverses texts of selected lines, keeping times",sswitch},
  },false)
else
	aegisub.register_macro(script_name,script_description,editlines)
	aegisub.register_macro(": Non-GUI macros :/MultiEdit: ReSplit - Backward","Resplits lines at a different place",resplitl)
	aegisub.register_macro(": Non-GUI macros :/MultiEdit: ReSplit - Forward","Resplits lines at a different place",resplitr)
	aegisub.register_macro(": Non-GUI macros :/MultiEdit: Reverse","Reverses texts of selected lines, keeping times",reverse)
	aegisub.register_macro(": Non-GUI macros :/MultiEdit: Switch style","Switch style",sswitch)
end