_G.DelayAssaultWave = _G.DelayAssaultWave or {}
DelayAssaultWave.DELAY_SECONDS = DelayAssaultWave.DELAY_SECONDS or 300
DelayAssaultWave._first_wave_notified = DelayAssaultWave._first_wave_notified or true

local function format_minutes(seconds)
    local minutes = seconds / 60
    if minutes == math.floor(minutes) then
        return tostring(minutes)
    end

    return string.format("%.1f", minutes)
end

local function notify_first_wave(seconds)
    local text = string.format("First assault wave delayed by %s minutes.", format_minutes(seconds))

    if managers.chat and ChatManager then
        local color = (tweak_data and tweak_data.system_chat_color) or Color.green
        local channel = ChatManager.GAME or 1
        managers.chat:_receive_message(channel, "Delayed Assault", text, color)
    end

    if managers.hud and managers.hud.present_mid_text then
        managers.hud:present_mid_text({
            text = text,
            title = "Delayed Assault",
            time = 6
        })
    end
end

if RequiredScript == "lib/managers/group_ai_states/groupaistatebesiege" and not DelayAssaultWave._hooked then
    DelayAssaultWave._hooked = true
    local DELAY = DelayAssaultWave.DELAY_SECONDS
    local original_begin_assault_task = GroupAIStateBesiege._begin_assault_task

    function GroupAIStateBesiege:_begin_assault_task(...)
        original_begin_assault_task(self, ...)

        local task_data = self._task_data and self._task_data.assault
        if task_data then
            local now = TimerManager:game():time()
            -- Add the delay directly to the anticipation timer so the assault engages later.
            task_data.phase_end_t = (task_data.phase_end_t or now) + DELAY

            if task_data.next_dispatch_t then
                task_data.next_dispatch_t = task_data.next_dispatch_t + DELAY
            end

            if task_data.force_start_t then
                task_data.force_start_t = task_data.force_start_t + DELAY
            end

            if self._assault_mode_next_opportunity_t then
                self._assault_mode_next_opportunity_t = self._assault_mode_next_opportunity_t + DELAY
            end
        end

        if not DelayAssaultWave._first_wave_notified then
            DelayAssaultWave._first_wave_notified = true
            notify_first_wave(DELAY)
        end
    end
end
