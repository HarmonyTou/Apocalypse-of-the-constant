local AddTimeEventPostInit = function(sg, name, index, fn)
    if sg ~= nil then
        local _timeline = sg.states[name].timeline
        if _timeline ~= nil then
            local _timeevent_time = _timeline.time
            local _timeevent_fn = _timeline.fn
            if _timeevent_time ~= nil then
                local _timeevent = TimeEvent(_timeevent_time, function(inst)
                    if fn ~= nil then
                        fn(inst)
                    end
                    if _timeevent_fn ~= nil then
                        _timeevent_fn(inst)
                    end
                end)
                table.remove(_timeline, index)
                table.insert(_timeline, index, _timeevent)
            end
        end
    end
end

return {
    AddTimeEventPostInit = AddTimeEventPostInit,
}
