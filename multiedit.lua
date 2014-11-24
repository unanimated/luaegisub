script_name="Multi-line Editor"
script_description="Multi-line Editor"
script_author="unanimated"
script_version="1.5"

require "clipboard"
re=require'aegisub.re'

function editlines(subs,sel)
    editext=""    dura=""	edeff=""	edact=""	edst=""
    for x, i in ipairs(sel) do
	if aegisub.progress.is_cancelled() then aegisub.cancel() end
    	aegisub.progress.title("Reading line: "..x.."/"..#sel.." ("..math.floor(x/#sel*100).."%)")
	line=subs[i]
	text=line.text
	dur=(line.end_time-line.start_time)/1000
	char=text:gsub("{[^}]-}","")	:gsub("\\[Nn]","*")	:gsub("%s?%*+%s?"," ")	:gsub("[%s%p]","")
	linelen=char:len()
	cps=math.ceil(linelen/dur)
	if tostring(dur):match("%.%d$") then dur=dur.."0" end
	if not tostring(dur):match("%.") then dur=dur..".00" end
	if cps<10 then cps="  "..cps end
	if dur=="0.00" then cps="n/a" end
	editext=editext..text.."\n"
	dura=dura..dur.." .. "..cps.." .. "..linelen.."\n"
	edst=edst..line.style.."\n"
	edact=edact..line.actor.."\n"
	edeff=edeff..line.effect.."\n"
    end
    editext=editext:gsub("\n$","")
    dura=dura:gsub("\n$","")
    edst=edst:gsub("\n$","")
    edact=edact:gsub("\n$","")
    edeff=edeff:gsub("\n$","")
    editbox(subs,sel)
    if failt==1 then editext=res.dat editbox(subs,sel) end
    return sel
end

function esc(str)
str=str
:gsub("%%","%%%%")
:gsub("%(","%%(")
:gsub("%)","%%)")
:gsub("%[","%%[")
:gsub("%]","%%]")
:gsub("%.","%%.")
:gsub("%*","%%*")
:gsub("%-","%%-")
:gsub("%+","%%+")
:gsub("%?","%%?")
return str
end

function resc(str)
str=str:gsub("[%%%(%)%[%]%.%*%-%+%?\\]","\\%1")
return str
end

function editbox(subs,sel)
aegisub.progress.title("Loading Editor...")
	BH=math.ceil(#sel*0.66)+2
	if BH<7 then BH=7 end
	repeat
	  if editext:len()>=BH*200 then BH=BH+1 end
	until editext:len()<BH*200 or BH>=20
	if BH>20 then BH=20 end
	b=BH+1
	nocom=editext:gsub("{[^}]-}","") :gsub("—"," ")
	words=0
	for wrd in nocom:gmatch("%S+") do words=words+1 end
	
	R1={x=0,y=b,width=1,height=1,class="label",label="Replace:"}
	R2={x=1,y=b,width=15,height=1,class="edit",name="rep1",value=lastrep1 or ""}
	R3={x=16,y=b,width=1,height=1,class="label",label="with"}
	R4={x=17,y=b,width=15,height=1,class="edit",name="rep2",value=lastrep2 or ""}
	R5={x=32,y=b,width=12,class="edit",name="repl",value=""}
	R6={x=44,y=b,class="label",label=" "}
	R7={x=45,y=b,width=7,class="checkbox",name="whole",label="whole word only",hint="only without regexp"}
	R8={x=52,y=b,width=3,class="checkbox",name="reg",label="regexp   ",value=regr}
	R9={x=55,y=b,width=2,class="checkbox",name="lua",label="lua",value=luar}
	
	GUI1={R1,R2,R3,R4,R5,R6,R7,R8,R9,
	{x=0,y=0,width=15,height=1,class="label",label=" Multi-line Editor v"..script_version},
	{x=52,y=0,width=5,height=1,class="label",label="Duration | CPS | chrctrs "},
	{x=30,y=0,width=22,height=1,class="edit",name="info",value="Lines loaded: "..#sel..", Words: "..words..", Characters: "..editext:len()},
	{x=0,y=1,width=52,height=BH,class="textbox",name="dat",value=editext},
	{x=52,y=1,width=5,height=BH,class="textbox",name="durr",value=dura,hint="This is informative only. \nCPS=Characters Per Second"},
	}
	
	GUI2={R1,R2,R3,R4,R5,R6,R7,R8,R9,
	{x=0,y=0,width=9,height=1,class="checkbox",name="rs",label="Style"},
	{x=9,y=0,width=11,height=1,class="checkbox",name="ra",label="Actor"},
	{x=20,y=0,width=12,height=1,class="checkbox",name="re",label="Effect"},
	{x=32,y=0,width=12,height=1,class="checkbox",name="rt",label="Text",value=true},
	{x=44,y=0,width=14,height=1,class="label",label="Checkboxes mark what Replacer applies to"},
	{x=0,y=1,width=9,height=BH,class="textbox",name="dast",value=edst},
	{x=9,y=1,width=11,height=BH,class="textbox",name="dact",value=edact},
	{x=20,y=1,width=12,height=BH,class="textbox",name="deaf",value=edeff},
	{x=32,y=1,width=28,height=BH,class="textbox",name="dat",value=editext},
	}
	buttons={"Save","Replace","Remove tags","Rm. comments","Remove \"- \"","Remove \\N","Add italics","Add \\an8","Switch","Taller GUI","Cancel"}
	GUI=GUI1
	repeat
	if P~="Save" and P ~="Cancel" and P~=nil then
	    if P=="Add italics" then
	    res.dat=res.dat:gsub("$","\n") :gsub("(.-)\n","{\\i1}%1\n") :gsub("{\\i1}{\\","{\\i1\\") :gsub("\n$","") end
	    if P=="Add \\an8" then
	    res.dat=res.dat:gsub("$","\n") :gsub("(.-)\n","{\\an8}%1\n") :gsub("{\\an8}{\\","{\\an8\\") :gsub("\n$","") end
	    if P=="Remove \\N" then res.dat=res.dat:gsub("%s*\\N%s*"," ") end
	    if P=="Remove tags" then res.dat=res.dat:gsub("{%*?\\[^}]-}","") end
	    if P=="Rm. comments" then res.dat=res.dat:gsub("{[^\\}]-}","") :gsub("{[^\\}]-\\N[^\\}]-}","") end
	    if P=="Remove \"- \"" then res.dat=res.dat:gsub("^%- ","") :gsub("\n%- ","\n") end
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
		if GUI==GUI1 then GUI=GUI2 else GUI=GUI1 end
		for key,val in ipairs(GUI) do if val.name=="dat" then val.value=res[val.name] end end
	    end
	end
	P,res=aegisub.dialog.display(GUI,buttons,{save='Save',close='Cancel'})
	until P=="Save" or P=="Cancel"

	if P=="Cancel" then aegisub.cancel() end
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

function savelines(subs,sel)
aegisub.progress.title("Saving...")
    tdat={}	sdat={}	adat={}	edat={}
    tt=res.dat.."\n"	if #sel==1 then tt=tt:gsub("\n(.)","\\N%1") tt=tt:gsub("\\N "," \\N") end
    ss=res.dast or "" if ss~="" then ss=ss.."\n" end
    aa=res.dact or "" if aa~="" then aa=aa.."\n" end
    ee=res.deaf or "" if ee~="" then ee=ee.."\n" end
    for dataline in tt:gmatch("(.-)\n") do table.insert(tdat,dataline) end
    for dataline in ss:gmatch("(.-)\n") do table.insert(sdat,dataline) end
    for dataline in aa:gmatch("(.-)\n") do table.insert(adat,dataline) end
    for dataline in ee:gmatch("(.-)\n") do table.insert(edat,dataline) end
    
    if #sdat>0 and #sel~=#sdat then t_error("Line count for Style ["..#sdat.."] does not match the number of selected lines ["..#sel.."].") end
    if #adat>0 and #sel~=#adat then t_error("Line count for Actor ["..#adat.."] does not match the number of selected lines ["..#sel.."].") end
    if #edat>0 and #sel~=#edat then t_error("Line count for Effect ["..#edat.."] does not match the number of selected lines ["..#sel.."].") end
    
    failt=0
    if #sel~=#tdat and #sel>1 then failt=1 else
	for x,i in ipairs(sel) do
        line=subs[i]
	line.text=tdat[x]
	line.style=sdat[x] or line.style
	line.actor=adat[x] or line.actor
	line.effect=edat[x] or line.effect
	subs[i]=line
	end
    end
    if failt==1 then
	aegisub.dialog.display({{class="label",label="Line count of edited text does not \nmatch the number of selected lines."}},{"OK"})
	clipboard.set(res.dat)
    end
    aegisub.set_undo_point(script_name)
    return sel
end

function t_error(message,cancel)
  aegisub.dialog.display({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then aegisub.cancel() end
end

function logg(m) aegisub.log("\n "..m) end

aegisub.register_macro(script_name,script_description,editlines)