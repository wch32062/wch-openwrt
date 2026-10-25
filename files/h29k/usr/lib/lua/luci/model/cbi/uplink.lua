-- 互联网接入：以太网(WAN) + 蜂窝(5G/4G)
-- 两者可单独使用，也可同时启用；以太网 metric 更小时优先，蜂窝自动兜底。

local sys = require "luci.sys"

local function sh(cmd)
	local f = io.popen(cmd .. " 2>/dev/null")
	local out = f and f:read("*a") or ""
	if f then f:close() end
	return (out:gsub("%s+$", ""))
end

local function iface_ip(dev)
	local out = sh("ip -4 -o addr show dev " .. dev .. " 2>/dev/null | awk '{print $4}' | head -1")
	return (out ~= "") and out or "无地址"
end

local m = Map("netmode", "互联网",
	"以太网与蜂窝网络可以单独使用，也可以同时启用：metric 较小的那条优先作为默认路由，另一条自动兜底。")

-- ---------------------------------------------------------------- 状态 ---
local s = m:section(SimpleSection, "当前状态")
s.anonymous = true

local o = s:option(DummyValue, "_default_route", "默认路由")
o.rawhtml = false
o.cfgvalue = function()
	local r = sh("ip -4 route show default | head -2 | tr '\\n' ' '")
	return (r ~= "") and r or "（无，尚未接入任何上行）"
end

o = s:option(DummyValue, "_eth", "以太网")
o.cfgvalue = function()
	local dev = "eth0"
	local carrier = sh("cat /sys/class/net/" .. dev .. "/carrier 2>/dev/null")
	local state = (carrier == "1") and "已插网线" or "无网线"
	return dev .. " " .. state .. " / " .. iface_ip(dev)
end

o = s:option(DummyValue, "_cell", "蜂窝")
o.cfgvalue = function()
	local out = sh("ls /sys/class/net 2>/dev/null | grep -E '^(wwan|usb|rmnet)' | tr '\\n' ' '")
	if out == "" then
		return "未检测到蜂窝接口（检查模组/SIM/拨号状态）"
	end
	return out
end

o = s:option(DummyValue, "_qmodem", "模组与信号")
o.cfgvalue = function()
	return "在「调制解调器 → QModem」页面查看信号强度、APN、SIM 状态"
end

-- ------------------------------------------------- 以太网 + 蜂窝 设置 ---
local s2 = m:section(NamedSection, "main", "main", "接入设置")
s2.addremove = false
s2.anonymous = false

o = s2:option(Flag, "ethernet_enabled", "启用有线接入")
o.default = "1"
o.rmempty = false

o = s2:option(ListValue, "mode", "网线端口角色")
o:value("auto", "自动：插网线就作为上行，没有网线时当 LAN（推荐）")
o:value("wan", "固定作为 WAN（管理只能走 Wi-Fi）")
o:value("lan", "固定作为 LAN（原厂行为）")
o.default = "auto"

o = s2:option(ListValue, "wan_proto", "有线接入方式")
o:value("dhcp", "DHCP（自动获取，接光猫或上级路由）")
o:value("pppoe", "PPPoE（宽带拨号）")
o:value("static", "静态 IP")
o.default = "dhcp"

o = s2:option(Value, "wan_username", "PPPoE 账号")
o:depends("wan_proto", "pppoe")

o = s2:option(Value, "wan_password", "PPPoE 密码")
o:depends("wan_proto", "pppoe")
o.password = true

o = s2:option(Value, "wan_ipaddr", "静态 IP 地址")
o:depends("wan_proto", "static")
o.datatype = "ip4addr"

o = s2:option(Value, "wan_netmask", "子网掩码")
o:depends("wan_proto", "static")
o.datatype = "ip4addr"
o.default = "255.255.255.0"

o = s2:option(Value, "wan_gateway", "网关")
o:depends("wan_proto", "static")
o.datatype = "ip4addr"

o = s2:option(Value, "wan_metric", "有线路由优先级 (metric)")
o.datatype = "uinteger"
o.default = "10"
o.description = "数值越小越优先。小于蜂窝的 metric，就会优先走有线。"

o = s2:option(Flag, "cellular_enabled", "启用蜂窝上行")
o.default = "1"
o.rmempty = false

o = s2:option(Value, "modem_metric", "蜂窝路由优先级 (metric)")
o.datatype = "uinteger"
o.default = "30"
o.description = "数值建议大于有线，实现“有线优先、蜂窝兜底”。"

-- 保存后不在这里同步应用：后台 h29k-netmode 监控每 2 秒比对配置指纹，
-- 发现改动就只 ifup wan（不动 LAN），页面因此不会卡在“等待配置被应用”。
m.on_after_commit = function()
	sys.call("sleep 1; /usr/sbin/h29k-netmode apply >/dev/null 2>&1 &")
end

return m
