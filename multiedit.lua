script_name="Multi-line Editor"
script_description="Multi-line Editor"
script_author="unanimated"
script_version="1.4"

require "clipboard"
re=require'aegisub.re'

function editlines(subs, sel)
    editext=""
    dura=""
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
    end
    editext=editext:gsub("\n$","")
    dura=dura:gsub("\n$","")
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
	GUI=
	{
	    {x=0,y=0,width=15,height=1,class="label",label=" Multi-line Editor v"..script_version},
	    {x=52,y=0,width=5,height=1,class="label",label="Duration | CPS | chrctrs "},
	    
	    {x=0,y=b,width=1,height=1,class="label",label="Replace:"},
	    {x=1,y=b,width=15,height=1,class="edit",name="rep1",value=lastrep1 or ""},
	    {x=16,y=b,width=1,height=1,class="label",label="with"},
	    {x=17,y=b,width=15,height=1,class="edit",name="rep2",value=lastrep2 or ""},
	    
	    {x=30,y=0,width=22,height=1,class="edit",name="info",value="Lines loaded: "..#sel..", Words: "..words..", Characters: "..editext:len() },
	    
	    {x=0,y=1,width=52,height=BH,class="textbox",name="dat",value=editext},
	    {x=52,y=1,width=5,height=BH,class="textbox",name="durr",value=dura,hint="This is informative only. \nCPS=Characters Per Second"},
	    
	    {x=32,y=b,width=12,class="edit",name="repl",value=""},
	    {x=44,y=b,class="label",label=" "},
	    {x=45,y=b,width=7,class="checkbox",name="whole",label="whole word only",hint="only without regexp"},
	    {x=52,y=b,width=3,class="checkbox",name="reg",label="regexp   "},
	    {x=55,y=b,width=2,class="checkbox",name="lua",label="lua"},
	}
	buttons={"Save","Replace","Remove tags","Rm. comments","Remove \"- \"","Remove \\N","Add italics","Add \\an8","Reload text","Taller GUI","Cancel"}
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
	      if res.lua then
		res.dat,r=res.dat:gsub(res.rep1,res.rep2)
	      elseif res.reg then
		r=re.find(res.dat,res.rep1) or {}
		r=#r
		res.dat=re.sub(res.dat,res.rep1,res.rep2)
	      else
		rep1=esc(res.rep1) rerep1=resc(res.rep1)
		if res.whole then
		    r=re.find(res.dat,"\\b"..rerep1.."\\b") or {}
		    r=#r
		    res.dat=re.sub(res.dat,"\\b"..rerep1.."\\b",res.rep2)
		else
		    res.dat,r=res.dat:gsub(rep1,res.rep2)
		end
	      end
	      res.repl=r.." replacements"
	    end
	    if P=="Taller GUI" then
		for key,val in ipairs(GUI) do
		    if val.y==1 then val.height=val.height+2 end
		    if val.y>1 then val.y=val.y+2 end
		end
	    end
	    for key,val in ipairs(GUI) do
		if P~="Reload text" then
		    val.value=res[val.name]
		else
		    if val.name=="dat" then val.value=editext end
		end
	    end
	end
	P,res=aegisub.dialog.display(GUI,buttons,{save='Save',close='Cancel'})
	until P=="Save" or P=="Cancel"

	if P=="Cancel" then aegisub.cancel() end
	if P=="Save" then savelines(subs,sel) end
	lastrep1=res.rep1
	lastrep2=res.rep2
	return sel
end

function savelines(subs,sel)
aegisub.progress.title("Saving...")
    local data={}	raw=res.dat.."\n"
    if #sel==1 then raw=raw:gsub("\n(.)","\\N%1") raw=raw:gsub("\\N "," \\N") end
    for dataline in raw:gmatch("(.-)\n") do table.insert(data,dataline) end
    failt=0    
    if #sel~=#data and #sel>1 then failt=1 else
	for x,i in ipairs(sel) do
        line=subs[i]
	line.text=data[x]
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

aegisub.register_macro(script_name, script_description, editlines)