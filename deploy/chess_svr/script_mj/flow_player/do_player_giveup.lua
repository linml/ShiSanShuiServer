-- 返回 STEP_SUCCEED 流程继续
-- 返回 STEP_FAILED 流程终止
local function logic_do_player_giveup(stPlayer, msg)
    LOG_DEBUG("Run LogicStep do_player_giveup")
    local nChair = stPlayer:GetChairID()
    local stPlayerBlockState = LibGameLogic:GetPlayerBlockState(nChair)
    --LOG_DEBUG("====stPlayerBlockState befor clear: %s", vardump(stPlayerBlockState))
    stPlayerBlockState:Clear()
    --LOG_DEBUG("====stPlayerBlockState after clear: %s", vardump(stPlayerBlockState))
    LOG_DEBUG("--do_player_giveup----nchair=====:%d !!!!!!!!!!!!!\n", nChair)
    FlowFramework.DelTimer(nChair, 0)
    return STEP_SUCCEED
end


return logic_do_player_giveup
