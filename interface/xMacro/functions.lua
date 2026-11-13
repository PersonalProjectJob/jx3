function checkcd(target, skillID)
bOnCD, currentCDTime, totalCDTime = target.GetSkillCDProgress(skillID, target.GetSkillLevel(skillID))
if currentCDTime/16 == 0 then
	return true
else
	return false
end
end

function CastSkillIDs(p,skillIDs)
	for z,x in pairs(skillIDs) do
		if CheckCD(p,x)==0 then
			OnAddOnUseSkill(x)
			return true
		end
	end
end

function TerminateSkill(p,t,NPCskills,MySkill)
	a,b,c,d=t.GetSkillPrepareState()
	if a then
		for z,x in pairs(NPCskills) do
			if b == x then
				p.StopCurrentAction()
				OnAddOnUseSkill(MySkill)
			end
		end
	end
end

function BuffLastingTime(target,buffID)
for z,x in pairs(target.GetBuffList()) do
if x.dwID==buffID then return (x.nEndFrame-GetLogicFrameCount())/GLOBAL.GAME_FPS end
end
return 0
end

function CheckBuff(target, buffID)
buffed = false
for z,x in pairs(target.GetBuffList() or {}) do
	if x.dwID == buffID then
		buffed = true
	end
end
return buffed
end

function BuffStack(target, buffID)
stack=0
	for z,x in pairs(target.GetBuffList()) do
		if x.dwID == buffID then
			stack = x.nStackNum
		end
	end
	return stack
end