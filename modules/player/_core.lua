return {order = 0, page = false, build = function(ctx)
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local P = {orig = setmetatable({}, {__mode = "k"})}
	ctx.player = P

	function P.humanoid()
		local c = LocalPlayer.Character
		return c and c:FindFirstChildWhichIsA("Humanoid")
	end
	function P.remember(h)
		if not P.orig[h] then
			P.orig[h] = {WalkSpeed = h.WalkSpeed, JumpPower = h.JumpPower, UseJumpPower = h.UseJumpPower}
		end
	end
	function P.restoreWalk()
		local h = P.humanoid()
		local o = h and P.orig[h]
		if o then h.WalkSpeed = o.WalkSpeed end
	end
	function P.restoreJump()
		local h = P.humanoid()
		local o = h and P.orig[h]
		if o then h.UseJumpPower = o.UseJumpPower; h.JumpPower = o.JumpPower end
	end
end}