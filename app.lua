bmiFunction = nil

function findFunction(id)
	for i, fun in ipairs(functions) do
		if fun.id == id then
			return functions[i]
		end
	end
end

function findFunctionMeta(meta)
        local match = 1
        for i, dev in ipairs(functions) do
                match = 1
                for k, v in pairs(meta) do
                        if dev.meta[k] ~= v then
                                match = 0
                        end
                end
                if match == 1 then
                        return functions[i]
                end
        end
        return nil;
end


function create_bmi_function_if_needed(source)
	local func = findFunctionMeta({
		source_function = tostring(source)
	})

	if func == nil then
		fn = {
			type = "bmi",
			installation_id = app.installation_id,
			meta = {
				name = "Body mass index",
				source_function = tostring(source),
				format = "%0.1f BMI",
				topic_read = "obj/bmi/" .. source 
			}
		}

		print("Creating" .. json:encode(fn))
		lynx.createFunction(fn)
	
		local func = findFunctionMeta({
			source_function = tostring(source)
		})
	end

	return(func)
end

function bmi(height, weight)
	return weight / ( height * height / 10000 )
end

function calculateAndSend(topic, payload)
	local p = json:decode(payload)
	local weight = p["value"];
	local timestamp = p["timestamp"];
	local msg = '{"weight": ' .. weight ..  ', "height":' .. cfg.height .. '}' 
	local bmi = bmi(cfg.height, weight)
	
	local newMessage = {value = bmi, msg = msg, timestamp = timestamp}
	mq:pub(bmiFunction.meta.topic_read, json:encode(newMessage))
end

function onCreate()
	local weightFunction = findFunction(cfg.weight_function)
	bmiFunction = create_bmi_function_if_needed(weightFunction.id)
end

function onStart()
	local weightFunction = findFunction(cfg.weight_function)
	local weightTopic = weightFunction.meta.topic_read

	bmiFunction = create_bmi_function_if_needed(weightFunction.id)
	
	mq:sub(weightTopic, 0)
	mq:bind(weightTopic, calculateAndSend)
end
