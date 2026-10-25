return function(s)
	for _, m in ipairs(s.monitors) do
		hl.monitor(m)
	end
end
