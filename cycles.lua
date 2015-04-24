-- On pressing the assigned hotkey, cycles through the relevant sequence you see below, changing the value of the given tag.

script_name="Cycles"
script_description="Cycles blur, border, shadow, alpha, alignment"
script_author="unanimated"
script_version="1.8"

-- SETTINGS - You can change these sequences
blur_sequence={"0.6","0.8","1","1.2","1.5","2","3","4","5","6","8","0.4","0.5"}
bord_sequence={"0","1","2","3","4","5","6","7","8","9","10","11","12"}
shad_sequence={"0","1","2","3","4","5","6","7","8","9","10","11","12"}
alpha_sequence={"FF","00","10","30","60","80","A0","C0","E0"}
align_sequence={"1","2","3","4","5","6","7","8","9"}

--[[ Adding more tags
You could make this also work for the following tags: frz, frx, fry, fax, fay, fs, fsp, fscx, fscy, be, xbord, xshad, ybord, yshad
by doing 3 things:
1. add a new sequence to the settings above for the tag you want to add
2. add a function below here based on what the others look like (all mentioned tags would be base 10) (it's adjusted for negative values too)
3. add "aegisub.register_macro("Cycles/YOUR_SCRIPT_NAME","Cycles WHATEVER_YOU_CHOOSE",FUNCTION_NAME_HERE)" at the end of the script
If you at least roughly understand the basics, this should be easy. The main cycle function remains the same for all tags.
Should you want to add other tags with different value patterns, check the existing exceptions for alpha in the cycle function. ]]

function blur(subs,sel) sequence=blur_sequence base=10 tag="blur" cycle(subs,sel) end
function bord(subs,sel) sequence=bord_sequence base=10 tag="bord" cycle(subs,sel) end
function shad(subs,sel) sequence=shad_sequence base=10 tag="shad" cycle(subs,sel) end
function alph(subs,sel) sequence=alpha_sequence base=16 tag="alpha" cycle(subs,sel) end
function algn(subs,sel) sequence=align_sequence base=10 tag="an" cycle(subs,sel) end

function cycle(subs,sel)
    for z,i in ipairs(sel) do
	line=subs[i]
	text=line.text
	text=text:gsub("\\t(%b())",function(t) return "\\t"..t:gsub("\\","|") end)

	    if tag=="alpha" then val1=text:match("^{[^}]-\\alpha&H(%x%x)&") else val1=text:match("^{[^}]-\\"..tag.."(%-?[%d%.]+)") end
	    if val1 then
		for n=1,#sequence do
		  if val1==sequence[n] then val2=sequence[n+1] end
		end
		if val2==nil then
		  for n=1,#sequence do
		    if n>1 or sequence[1]~="FF" then
		      if tonumber(val1,base)<tonumber(sequence[n],base) then val2=sequence[n] break end
		    end
		  end
		end
		if val2==nil then val2=sequence[1] end
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
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro("Cycles/Blur Cycle","Cycles Blur",blur)
aegisub.register_macro("Cycles/Border Cycle","Cycles Border",bord)
aegisub.register_macro("Cycles/Shadow Cycle","Cycles Shadow",shad)
aegisub.register_macro("Cycles/Alpha Cycle","Cycles Alpha",alph)
aegisub.register_macro("Cycles/Alignment Cycle","Cycles Alignment",algn)