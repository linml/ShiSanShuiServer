-- 返回 STEP_SUCCEED 流程继续
-- 返回 STEP_FAILED 流程终止
local function logic_notify_player_op_logic_func_other(stPlayer, msg)
    LOG_DEBUG("Run LogicStep notify_player_op_logic_func_other")

    local stPlayerBlockState = LibGameLogic:GetPlayerBlockState(stPlayer:GetChairID())

    local bIsQuick = stPlayer:IsTrust() or  stPlayer:IsWin();
    local nbixuhu =0
    local nDealerCardLeft = GDealer:GetDealerCardGroup():GetCurrentLength()
    local stResult =stPlayerBlockState:GetReuslt()
    if stPlayerBlockState:GetReuslt().bCanWin ==true and nDealerCardLeft<=4 then
        nbixuhu =1
        stResult.nbixuhu =nbixuhu
    end
    
    CSMessage.NotifyPlayerAskBlock(stPlayer, stResult, false, bIsQuick)

    if  stPlayer:IsWin() == false and stPlayerBlockState:IsCanTing() then
        --
        -- CSMessage.NotifyWinHint(stPlayer, stPlayerBlockState:GetTingGroupAll())
    end
    return STEP_SUCCEED
end


return logic_notify_player_op_logic_func_other
