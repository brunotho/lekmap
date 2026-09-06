------------------------------------------------------------------------------
-- Lekmap_PipelineFlowLog.lua
-- Pipeline breadcrumb log. Gated by _lek_pipeline_flow_log (default off).
-- File: ~/Library/Application Support/Sid Meier's Civilization 5/Logs/LekmapPipelineFlow.log
------------------------------------------------------------------------------

_lek_pipeline_flow_seq = 0;
if _lek_pipeline_flow_log == nil then
	_lek_pipeline_flow_log = false;
end

function LekPipelineFlowLogPath()
	if not (os and os.getenv) then
		return nil;
	end
	local home = os.getenv("HOME") or "";
	if home ~= "" then
		return home .. "/Library/Application Support/Sid Meier's Civilization 5/Logs/LekmapPipelineFlow.log";
	end
	local user = os.getenv("USER") or "";
	if user ~= "" then
		return "/Users/" .. user .. "/Library/Application Support/Sid Meier's Civilization 5/Logs/LekmapPipelineFlow.log";
	end
	return nil;
end

-- Truncate file so each map-script load / gen attempt starts clean.
function LekPipelineFlowReset(tag)
	if not _lek_pipeline_flow_log then
		_lek_pipeline_flow_seq = 0;
		return;
	end
	_lek_pipeline_flow_seq = 0;
	local path = LekPipelineFlowLogPath();
	local t = (os and os.clock) and os.clock() or 0;
	local line = "### LekPipelineFlow RESET tag=" .. tostring(tag)
		.. " shape=" .. tostring(_lek_pangaea_land_shape or "na")
		.. " t=" .. string.format("%.3f", t);
	print(line);
	if not path or not io then
		return;
	end
	local ok, err = pcall(function()
		local f = io.open(path, "w");
		if f then
			f:write(line .. "\n");
			f:flush();
			f:close();
		end
	end);
	if not ok then
		print("### LekPipelineFlow RESET write_fail " .. tostring(err));
	end
end

function LekPipelineFlow(stage, detail)
	if not _lek_pipeline_flow_log then
		return;
	end
	_lek_pipeline_flow_seq = (_lek_pipeline_flow_seq or 0) + 1;
	local t = (os and os.clock) and os.clock() or 0;
	local det = "";
	if detail ~= nil and detail ~= "" then
		det = " " .. tostring(detail);
	end
	local line = "### FLOW #" .. tostring(_lek_pipeline_flow_seq)
		.. " t=" .. string.format("%.3f", t)
		.. " shape=" .. tostring(_lek_pangaea_land_shape or "na")
		.. " stage=" .. tostring(stage)
		.. det;
	print(line);
	local path = LekPipelineFlowLogPath();
	if not path or not io then
		return;
	end
	pcall(function()
		local f = io.open(path, "a");
		if f then
			f:write(line .. "\n");
			f:flush();
			f:close();
		end
	end);
end
