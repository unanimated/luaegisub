-- Manual: http://unanimated.xtreemhost.com/ts/scripts-manuals.htm#ibus

script_name="iBus"
script_description="Italy Bold Under Strike"
script_author="unanimated"
script_version="1.7"
script_namespace="ua.iBus"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="1.7.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

function isub(subs,sel)
	for z,i in ipairs(sel) do
		l=subs[i]
		t=l.text
		sr=scheck(subs,l.style)
		v=1 if sr[sref] then v=0 end
		t=t:gsub("\\"..T.."([\\}])","\\"..T.."".. 1-v.."%1")
		if t:match("^{[^}]-\\"..T.."%d") then
			t=t:gsub("\\"..T.."(%d)",function(n) return "\\"..T.. 1-n end)
		else
			if t:match("\\"..T.."([01])") then iv=t:match("\\"..T.."([01])") end
			if iv==v then t=t:gsub("\\"..T.."(%d)",function(n) return "\\"..T.. 1-n end) end
			t="{\\"..T..v.."}"..t
			t=t:gsub("{(\\%a%d})({\\[^}]*)}","%2%1")
		end
		l.text=t
		subs[i]=l
	end
end

function scheck(subs,sn)
	for i=1,#subs do
		if subs[i].class=="style" then
		if sn==subs[i].name then sr=subs[i] break end
		end
	end
	return sr
end

function ita(subs,sel) T="i" sref="italic" isub(subs,sel) end
function bol(subs,sel) T="b" sref="bold" isub(subs,sel) end
function und(subs,sel) T="u" sref="underline" isub(subs,sel) end
function str(subs,sel) T="s" sref="strikeout" isub(subs,sel) end

if haveDepCtrl then
  depRec:registerMacros({
	{"iBus/Italics",script_description,ita},
	{"iBus/Bold",script_description,bol},
	{"iBus/Underline",script_description,und},
	{"iBus/Strikeout",script_description,str}
  },false)
else
	aegisub.register_macro("iBus/Italics",script_description,ita)
	aegisub.register_macro("iBus/Bold",script_description,bol)
	aegisub.register_macro("iBus/Underline",script_description,und)
	aegisub.register_macro("iBus/Strikeout",script_description,str)
end