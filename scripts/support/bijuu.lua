local castBelowHp = 30
macro(100, "MODE BIJUU 30%", function()
  if (hppercent() <= castBelowHp) then
     say('mode bijuu')
  end
end)
