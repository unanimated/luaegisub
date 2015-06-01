script_name="Change Case"
script_description="Capitalises text or makes it lowercase / uppercase"
script_author="unanimated"
script_version="3.0"
script_namespace="ua.ChangeCase"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="3.0.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

re=require'aegisub.re'
unicode=require'aegisub.unicode'

function case(subs,sel)
    for z,i in ipairs(sel) do
        line=subs[i]
	t=line.text
	if P=="lowercase" then t=lowercase(t) end
	if P=="UPPERCASE" then t=uppercase(t) end
	if P=="Lines" then t=capitalines(t) end
	if P=="Sentences" then
		if res.mod then res.mod=false t=lowercase(t) res.mod=true end
		t=sentences(t)
	end
	if P=="Words" then
		if not res.mod then t=lowercase(t) end
		t=capitalise(t)
	end
	line.text=t
	subs[i]=line
    end
end

function lowercase(t)
	t=t
	:gsub("\\[Nnh]","{%1}")
	:gsub("^([^{]*)",function(l)
		if res.mod then l=re.sub(l,[[\b(\u\u+'?\u*)]],function(u) return ulower(u) end) return l
		else return ulower(l) end end)
	:gsub("}([^{]*)",function(l)
		if res.mod then l=re.sub(l,[[\b(\u\u+'?\u*)]],function(u) return ulower(u) end) return "}"..l
		else return "}"..ulower(l) end end)
	:gsub("{(\\[Nnh])}","%1")
	return t
end

function uppercase(t)
	t=t
	:gsub("\\[Nnh]","{%1}")
	:gsub("^([^{]*)",function(u) return uupper(u) end)
	:gsub("}([^{]*)",function(u) return "}"..uupper(u) end)
	:gsub("{(\\[Nnh])}","%1")
	return t
end

function capitalines(t)
	t=re.sub(t,[[^(["']?\l)]],function(l) return uupper(l) end)
	t=re.sub(t,[[^\{[^}]*\}(["']?\l)]],function(l) return uupper(l) end)
	if not res.mod then
	t=t:gsub(" i([' %?!%.,])"," I%1"):gsub("\\Ni([' ])","\\NI%1")
	end
	return t
end

function sentences(t)
somewords={"English","Japanese","American","British","German","French","Spanish","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday","January","February","April","June","July","August","September","October","November","December"}
hnrfx={"%-san","%-kun","%-chan","%-sama","%-dono","%-se[nm]pai","%-on%a+an"}
	t=re.sub(t,[[^(["']?\l)]],function(l) return uupper(l) end)
	t=re.sub(t,[[^\{[^}]*\}(["']?\l)]],function(l) return uupper(l) end)
	t=re.sub(t,[[[\.\?!](\s|\s\\N|\\N)["']?(\l)]],function(l) return uupper(l) end)
	t=t
	:gsub(" i([' %?!%.,])"," I%1")
	:gsub("\\Ni([' ])","\\NI%1")
	:gsub(" m(arch %d)"," M%1")
	:gsub(" a(pril %d)"," A%1")
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
	t=t
	:gsub("^ "..w.." "," "..w:lower().." ")
	:gsub("([^%.:%?!]) "..w.." ","%1 "..w:lower().." ")
	:gsub("([^%.:%?!]) (%b{})"..w.." ","%1 %2"..w:lower().." ")
	:gsub("([^%.:%?!]) (%*Large_break%* ?)"..w.." ","%1 %2"..w:lower().." ")
	end

	-- Roman numbers (this may mismatch some legit words - sometimes there just are 2 options and it's a guess)
	t=t
	:gsub("$","#")
	:gsub("(%s?)([IVXLCDM])([ivxlcdm]+)([%s%p#])",function(s,r,m,e) return s..r..m:upper()..e end)
	:gsub("([DLM])ID","%1id")
	:gsub("DIM","Dim")
	:gsub("MIX","Mix")
	:gsub("Ok([%s%p#])","OK%1")
	for h=1,#onore do
	  t=t:gsub(onore[h].."([%s%p#])",onore[h]:lower().."%1")
	end
	t=t
	:gsub("#$","")
	:gsub("{(\\[Nnh])}","%1")
    return no_t..t end)
  end
  return txt
end

ulower=unicode.to_lower_case
uupper=unicode.to_upper_case

function logg(m) m=m or "nil" aegisub.log("\n "..m) end

function capital(subs,sel)
	GUI={
	{x=1,y=0,class="label",label="Words - Capitalise Words Like in Titles"},
	{x=1,y=1,class="label",label="    Lines - Capitalise first word in selected lines"},
	{x=1,y=2,class="label",label="        Sentences - Capitalise first word in each sentence"},
	{x=1,y=3,class="label",label="            Lowercase - make text in selected lines lowercase"},
	{x=1,y=4,class="label",label="                Uppercase - MAKE TEXT IN SELECTED LINES UPPERCASE"},
	{x=2,y=5,class="label",label=script_name.." v "..script_version},
	{x=1,y=5,class="checkbox",name="mod",label="mod",hint="Words - leave uppercase words\nLines - don't capitalize 'i'\nSentences - run lowercase first\nlowercase - only for uppercase words"},
	}
	P,res=aegisub.dialog.display(GUI,{"Words","Lines","Sentences","lowercase","UPPERCASE","Cancel"},{ok='Words',close='Cancel'})
	if P=="Cancel" then aegisub.cancel() end
	case(subs,sel)
	aegisub.set_undo_point(script_name)
	return sel
end

if haveDepCtrl then depRec:registerMacro(capital) else aegisub.register_macro(script_name,script_description,capital) end