-- Manual: http://unanimated.hostfree.pw/ts/scripts-manuals.htm#cycle

script_name="Cycles"
script_description="Cycles blur, border, shadow, alpha, alignment, font spacing"
script_author="unanimated"
script_version="2.0"
script_namespace="ua.Cycles"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="2.0.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

-- SETTINGS - You can change these sequences
blur_sequence={"0.6","0.8","1","1.2","1.5","2","2.5","3","4","5","6","8","10","0.4","0.5"}
bord_sequence={"0","1","1.5","2","2.5","3","4","5","6","7","8","9","10","11","12","15","20"}
shad_sequence={"0","1","1.5","2","2.5","3","4","5","6","7","8","9","10","11","12"}
alpha_sequence={"FF","00","10","30","60","80","A0","C0","E0"}
align_sequence={"1","2","3","4","5","6","7","8","9"}
fsp_sequence={"0","1","2","3","4","5","6","7","8","10","12","15","20","30"}

--[[ Adding more tags
You could make this also work for the following tags: frz, frx, fry, fax, fay, fs, fscx, fscy, be, xbord, xshad, ybord, yshad
by doing 3 things:
1. add a new sequence to the settings above for the tag you want to add
2. add a function below here based on what the others look like (it's adjusted for negative values too)
3. add "aegisub.register_macro("Cycles/YOUR_SCRIPT_NAME","Cycles WHATEVER_YOU_CHOOSE",FUNCTION_NAME_HERE)" at the end of the script
If you at least roughly understand the basics, this should be easy. The main cycle function remains the same for all tags.
Should you want to add other tags with different value patterns, check the existing exceptions for alpha in the cycle function.]]

function blur(subs,sel) cycle(subs,sel,"blur",blur_sequence) end
function bord(subs,sel) cycle(subs,sel,"bord",bord_sequence) end
function shad(subs,sel) cycle(subs,sel,"shad",shad_sequence) end
function alph(subs,sel) cycle(subs,sel,"alpha",alpha_sequence) end
function algn(subs,sel) cycle(subs,sel,"an",align_sequence) end
function fsp(subs,sel) cycle(subs,sel,"fsp",fsp_sequence) end

function cycle(subs,sel,tag,sequence)
    if tag=="alpha" then base=16 else base=10 end
    for z,i in ipairs(sel) do
	line=subs[i]
	text=line.text
	local back
	if line.comment or text:match'{switch}$' then back=true end
	text=text:gsub("\\t(%b())",function(t) return "\\t"..t:gsub("\\","|") end)

	if tag=="alpha" then val1=text:match("^{[^}]-\\alpha&H(%x%x)&") else val1=text:match("^{[^}]-\\"..tag.."(%-?[%d%.]+)") end
	if val1 then
		for n=1,#sequence do
		  N=n+1
		  if back then N=n-1 end
		  if N==0 then N=#sequence end
		  if val1==sequence[n] then val2=sequence[N] or sequence[1] break end
		end
		if val2==nil then
		  for n=1,#sequence do
		    if n>1 or sequence[1]~="FF" then
		      local N=n
		      if back then N=n-1 end
		      if N==0 then N=#sequence end
		      if tonumber(val1,base)<tonumber(sequence[n],base) then val2=sequence[N] break end
		    end
		  end
		end
		if val2==nil then if back then val2=sequence[#sequence] else val2=sequence[1] end end
		if tag=="alpha" then
		  text=text:gsub("^({[^}]-\\alpha&H)%x%x","%1"..val2)
		else
		  text=text:gsub("^({[^}]-\\"..tag..")%-?[%d%.]+","%1"..val2)
		end
		val2=nil
	else
		text="{\\"..tag..sequence[1].."}"..text
		text=text:gsub("alpha(%x%x)}","alpha&H%1&}")
		:gsub("{(\\.-)}{\\","{%1\\")
	end

	text=text:gsub("{\\[^}]-}",function(t) return t:gsub("|","\\") end)
	line.text=text
	subs[i]=line
    end
end

function switch(subs,sel)
    for z,i in ipairs(sel) do
	l=subs[i]
	t=l.text
	t=t.."{switch}"
	t=t:gsub("{switch}{switch}$","")
	l.text=t
	subs[i]=l
    end
end

function logg(m) m=m or "nil" aegisub.log("\n "..m) end

if haveDepCtrl then
    depRec:registerMacros({
	{"Cycles/Blur Cycle","Cycles Blur",blur},
	{"Cycles/Border Cycle","Cycles Border",bord},
	{"Cycles/Shadow Cycle","Cycles Shadow",shad},
	{"Cycles/Alpha Cycle","Cycles Alpha",alph},
	{"Cycles/Alignment Cycle","Cycles Alignment",algn},
	{"Cycles/FontSpacing Cycle","Cycles Font Spacing",fsp},
	{"Cycles/Switch","Switches sequence direction",switch},
    },false)
else
	aegisub.register_macro("Cycles/Blur Cycle","Cycles Blur",blur)
	aegisub.register_macro("Cycles/Border Cycle","Cycles Border",bord)
	aegisub.register_macro("Cycles/Shadow Cycle","Cycles Shadow",shad)
	aegisub.register_macro("Cycles/Alpha Cycle","Cycles Alpha",alph)
	aegisub.register_macro("Cycles/Alignment Cycle","Cycles Alignment",algn)
	aegisub.register_macro("Cycles/FontSpacing Cycle","Cycles Font Spacing",fsp)
	aegisub.register_macro("Cycles/Switch","Switches sequence direction",switch)
end