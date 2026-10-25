-- 互联网接入页：以太网(WAN) + 蜂窝(5G/4G) 两种上行的切换与叠加
module("luci.controller.uplink", package.seeall)

function index()
	entry({ "admin", "network", "uplink" }, cbi("uplink"), "互联网", 8)
end
