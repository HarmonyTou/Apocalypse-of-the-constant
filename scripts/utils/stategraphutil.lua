local AddTimeEventPostInit = function(sg, name, index, fn, time)
    if sg ~= nil then
        local _timeline = sg.states[name].timeline
        if _timeline ~= nil then
            local _timeevent_time = _timeline.time
            local _timeevent_fn = _timeline.fn
            local _timeevent = TimeEvent(time ~= nil and time * FRAMES or _timeevent_time, function(inst)
                if fn ~= nil then
                    fn(inst)
                end
                _timeevent_fn(inst)
            end)

            table.remove(_timeline, index)
            table.insert(_timeline, index, _timeevent)
        end
    end
end

return {
    AddTimeEventPostInit = AddTimeEventPostInit,
}
