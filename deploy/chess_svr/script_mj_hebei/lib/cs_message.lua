
local CSMessage = CSMessage or {}
local stGameState = nil
local stRoundInfo = nil

_GameModule = _GameModule or {}
_GameModule._TableLogic = _GameModule._TableLogic or  {}
_GameModule._TableLogic.SendEvent = _GameModule._TableLogic.SendEvent or function (...) end

local SendEvent = _GameModule._TableLogic.SendEvent
import("core.error_msg_define")

function CSMessage.CreateInit()
    stGameState = GGameState
    stRoundInfo = GRoundInfo
    return true
end

-- PRIVATE FUNCTION START

function CSMessage.NotifyOnePlayerTo (stPlayer, event, para, fromChairID, timeo)

    local notify = {
        _cmd = event,
        _st = "nti",
        _src = "s",
        timeo = timeo,
        _para = para or {}
    }
    if fromChairID ~= nil then
        notify._src = "p" ..fromChairID
        -- if timeo and timeo > 0 then
        --     FlowFramework.SetTimer(fromChairID, timeo)
        -- end
    end
    SendEvent(G_TABLEINFO.tableptr,stPlayer:GetChairID(), stPlayer:GetPlayerID(), notify)
end

function CSMessage.NotifyOnePlayer (stPlayer, event, para, timeo)
    local chairID = stPlayer:GetChairID()
    CSMessage.NotifyOnePlayerTo(stPlayer, event, para, chairID, timeo)
end

function CSMessage.NotifyExceptPlayer (fromPlayer, event, para, timeo)
    local chairID = fromPlayer:GetChairID()
    -- LOG_DEBUG("NotifyExceptPlayer: event:%s, para:%s, from:%d, to:%d", event, vardump(para), chairID, 0);
    for i=1, PLAYER_NUMBER do
        local stPlayer = stGameState:GetPlayerByChair(i)
        if i ~= chairID and stPlayer ~= nil then
            -- LOG_DEBUG("==NotifyExceptPlayer: event:%s, para:%s, from:%d, to:%d", event, vardump(para), chairID, i);
            CSMessage.NotifyOnePlayerTo(stPlayer, event, para, chairID, timeo)
        end
    end
end

function CSMessage.NotifyPlayerFollowNum(FollowNum)
    local para = { followNum = FollowNum }
    LOG_DEBUG("==NotifyPlayerFollowNum: para:%s,", vardump(para));
    CSMessage.NotifyAllPlayer(nil, "followBanker", para)
end

function CSMessage.NotifyAllPlayer (fromPlayer, event, para, timeo)
    local chairID
    if fromPlayer ~= nil then
        chairID = fromPlayer:GetChairID()
        -- if timeo and timeo > 0 then
        --     FlowFramework.SetTimer(chairID, timeo)
        -- end
    end

    for i=1, PLAYER_NUMBER do
        local stPlayer = stGameState:GetPlayerByChair(i)
        if stPlayer ~= nil then
            local fromChairID = chairID or i
            CSMessage.NotifyOnePlayerTo(stPlayer, event, para, fromChairID, timeo)
        end
    end  
end

function CSMessage.NotifyError(stPlayer, nErrorID, msg)
    local para = {
        id = nErrorID,
        msg = msg
    }
    CSMessage.NotifyOnePlayer(stPlayer, "error", para)
end

-- PRIVATE FUNCTION END

-- PUBLIC FUNCTION START 

function CSMessage.NotifyPlayerAskReady(stPlayer)
    -- ready 的消息金币场是不需要超时的, 为-1
    local nTimeout = -1

    -- todo: 是在房卡的非第一局时，才做超时处理
    if GGameCfg.nMoneyMode == ROOM_MODE_SCORE and GGameCfg.nCurrJu ~= 1 then
        nTimeout = GGameCfg.TimerSetting.readyTimeOut
        FlowFramework.SetTimer(stPlayer:GetChairID(), nTimeout)
    end

    CSMessage.NotifyOnePlayer(stPlayer, "ask_ready", {}, nTimeout)
end
function CSMessage.NotifyPlayerReAskReady(stPlayer,nTime)
    -- ready 的消息金币场是不需要超时的, 为-1
    local nTimeout = -1

    -- todo: 是在房卡的非第一局时，才做超时处理
    if GGameCfg.nMoneyMode == ROOM_MODE_SCORE and GGameCfg.nCurrJu ~= 1 then
        nTimeout = nTime
        FlowFramework.SetTimer(stPlayer:GetChairID(), nTimeout)
    end

    CSMessage.NotifyOnePlayer(stPlayer, "ask_ready", {}, nTimeout)
end

function CSMessage.NoitfyPlayerGameCfg(stPlayer, stGameCfg)
    local cfg = {
        nMoneyMode = stGameCfg.nMoneyMode,
        nPlayerNum = stGameCfg.nPlayerNum,
        nJuNum = stGameCfg.nJuNum,
        nCurrJu = stGameCfg.nCurrJu,
        rno = stGameCfg.rno,
        rid = stGameCfg.rid,
        gid = stGameCfg._gid,
        owner_uid = stGameCfg.uid,
        CardPoolType = stGameCfg.CardPoolType,
        TimerSetting = stGameCfg.TimerSetting,
        GameSetting = stGameCfg.GameSetting,
        chairID = stPlayer:GetChairID(),
    }
    CSMessage.NotifyOnePlayer(stPlayer, "game_cfg", cfg)
end

function CSMessage.NotifyPlayerEnterTo(stPlayerEnter, stPlayerTo)
    local para = stPlayerEnter:GetUserInfo()
    para.gid = GGameCfg._gid
    -- LOG_DEBUG("GID=%d, cfg=%s", GGameCfg._gid, vardump(GGameCfg));
    CSMessage.NotifyOnePlayerTo(stPlayerTo, "enter", para, stPlayerEnter:GetChairID())
end

function CSMessage.NotifyPlayerReadyTo(stPlayerReady, stPlayerTo)
    local para = {
        _chair = stPlayerReady:GetChairID(),
        _uid = stPlayerReady:GetUin()
    }
    CSMessage.NotifyOnePlayerTo(stPlayerTo, "ready", para, stPlayerReady:GetChairID())
end

function CSMessage.NotifyPlayerEnterToAll(stPlayerEnter)
    local para = stPlayerEnter:GetUserInfo()
    para.gid = GGameCfg._gid or 0--tonumber(GGameCfg._gid)
    LOG_DEBUG("GID= 2 %d, cfg=%s", para.gid, vardump(para));
    CSMessage.NotifyAllPlayer(stPlayerEnter, "enter", para);
end

function CSMessage.NotifyPlayerReadyToAll(stPlayer)
    local para = {
        _chair = stPlayer:GetChairID(),
        _uid = stPlayer:GetUin()
    }
    CSMessage.NotifyAllPlayer(stPlayer, "ready", para)
end

function CSMessage.NotifyPlayerLeave(stPlayer, reason)
    -- CSMessage.NotifyExceptPlayer(stPlayer, "leave", stPlayer:GetUserInfo())
    local para = stPlayer:GetUserInfo();
    para.reason = reason;

    -- 离开原因增加换桌 E_ChangeTableFromClient = 12 
    if reason == 12 then
        CSMessage.NotifyExceptPlayer(stPlayer, "leave", para)
    else
        CSMessage.NotifyAllPlayer(stPlayer, "leave", para)
    end
  
end

function CSMessage.NotifyPlayerOffline(stPlayer,nActive)
      local para = stPlayer:GetUserInfo();
    para.active = nActive;
    CSMessage.NotifyExceptPlayer(stPlayer, "offline", para)
end

--玩家重连进来后发送其他玩家的断线情况给重连玩家
function CSMessage.NotifyPlayerOfflineTo(stPlayerTo, stPlayerOffline)
    local para = stPlayerOffline:GetUserInfo();
    para.active = stPlayerOffline:GetPlayOfflineStatus()
    CSMessage.NotifyOnePlayerTo(stPlayerTo, "offline", para, stPlayerOffline:GetChairID())
end

function CSMessage.NotifyAllPlayerStartGame()
    CSMessage.NotifyAllPlayer(nil, "game_start")
end

function CSMessage.NotifyOnePlayerStartGame(stPlayer)
    CSMessage.NotifyOnePlayer(stPlayer, "game_start")
end

function CSMessage.NotifyPlayerBanker(stPlayer)
    local para = {
        banker = stRoundInfo:GetBanker(),  -- 庄家  
        dice = stRoundInfo:GetDice()      --色子
    }
    CSMessage.NotifyOnePlayer(stPlayer, "banker", para);
end

function CSMessage.NotifyPlayerDeal(stPlayer, stCardCount, nDealerCardLeft)
    local para = {
        cards = stPlayer:GetPlayerCardGroup():ToArray(),
        --currentCardsNum = #arrCards,
        banker = stRoundInfo:GetBanker()  ,  -- 庄家
        roundWind = stRoundInfo:GetRoundWind(),   -- 圈风
        subRound = stRoundInfo:GetSubRoundWind(),    -- 该圈的第几轮
        dice = stRoundInfo:GetDice(),
        cardCount = stCardCount,
        cardLeft = nDealerCardLeft       
    }
    CSMessage.NotifyOnePlayer(stPlayer, "deal", para);
end

function CSMessage.NotifyAskXiaPao(stPlayer, arrAllowXiapao)
    local para = {
        optional = arrAllowXiapao,
        recommend = 1
    }
    local timeo = GGameCfg.TimerSetting.XiaPaoTimeOut
    --房卡房间并且有限制时不设置超时
    if GGameCfg.nMoneyMode ~= ROOM_MODE_SCORE or GGameCfg.TimerSetting.TimeOutLimit ~= -1 then

        -- 下跑超时
        FlowFramework.SetTimer(stPlayer:GetChairID(), timeo)
    else
        --房卡房间也设置超时timeid设为-1，在Time_mng做判断，不发超时事件
        FlowFramework.SetTimer(stPlayer:GetChairID(), timeo,-1)

        --test
        -- FlowFramework.SetTimer(stPlayer:GetChairID(), 3)
    end
    CSMessage.NotifyOnePlayer(stPlayer, "ask_xiapao", para, timeo)
end

--重进时
function CSMessage.NotifyAskReXiaPao(stPlayer, arrAllowXiapao,ntime)
    local para = {
        optional = arrAllowXiapao,
        recommend = 1
    }
    --房卡房间并且有限制时不设置超时
    if GGameCfg.nMoneyMode ~= ROOM_MODE_SCORE or GGameCfg.TimerSetting.TimeOutLimit ~= -1 then
    -- 下跑超时
        FlowFramework.SetTimer(stPlayer:GetChairID(), ntime)
    else
        --房卡房间也设置超时timeid设为-1，在Time_mng做判断，不发超时事件
         FlowFramework.SetTimer(stPlayer:GetChairID(), ntime,-1)
    end 
    CSMessage.NotifyOnePlayer(stPlayer, "ask_xiapao", para, ntime)
end

function CSMessage.NotifyAllPlayStart()
    CSMessage.NotifyAllPlayer(nil, "play_start");
end

function CSMessage.NotifyOnePlayStart(stPlayer)
    CSMessage.NotifyOnePlayer(stPlayer, "play_start");
end

-- 给牌玩家了
function CSMessage.NotifyPlayerGiveCard(stPlayer, stCards, nDealCardLeft,bLast)
    local para = {
        cards = stCards,
        cardLeft = nDealCardLeft,
        bLast = bLast
    }
    CSMessage.NotifyOnePlayer(stPlayer, "give_card", para)

    para = {}
    para = {
        nCardNum = #stCards,
        cardLeft = nDealCardLeft,
        bLast = bLast
    }
    CSMessage.NotifyExceptPlayer(stPlayer, "give_card", para)
end

function CSMessage.NotifyAskPlay(stPlayer, bIsQuick,bSelfTrust)
    -- 问了，就得要求超时
    local bSelfTrust = bSelfTrust or false
    local nTimeout = GGameCfg.TimerSetting.AutoPlayTimeOut
    if not bIsQuick then
        nTimeout = GGameCfg.TimerSetting.giveTimeOut
    end
    local nChair = stPlayer:GetChairID()
    local stPlayerBlockState = LibGameLogic:GetPlayerBlockState(nChair)

    -- 房卡房间并且有限制时不设置超时
    if GGameCfg.nMoneyMode ~= ROOM_MODE_SCORE or GGameCfg.TimerSetting.TimeOutLimit ~= -1 then

        if GRoundInfo:IsDealerFirstTurn() then
            nTimeout = nTimeout+10
        end
        FlowFramework.SetTimer(stPlayer:GetChairID(), nTimeout)
    else
        -- 房卡房间也设置超时timeid设为-1，在Time_mng做判断，不发超时事件
        FlowFramework.SetTimer(stPlayer:GetChairID(), nTimeout, -1)
    end
    
    -- 不能出的牌，后续考虑加癞子牌
    local stNoCanPlayCards={}
    CSMessage.NotifyExceptPlayer(stPlayer, "ask_play", stNoCanPlayCards, nTimeout)
    local nGiveStatus = GRoundInfo:GetGiveStatus()
    if nGiveStatus == GIVE_STATUS_COLLECT then
        local stPlayerCardSet = stPlayer:GetPlayerCardSet()
        local bySetCount = stPlayerCardSet:GetCurrentLength()
        local combineTile = stPlayer:GetPlayerCardSet():ToArray()

        local nVaule = combineTile[bySetCount].value
        local nLastCard = combineTile[bySetCount].card + nVaule

        stNoCanPlayCards[#stNoCanPlayCards+1] = nLastCard
    end

    --机器人的话发给客户端显示的时间,还有托管时
    if stPlayer:IsRobot()  or bIsQuick then
        nTimeout = GGameCfg.TimerSetting.giveTimeOut
        if GRoundInfo:IsDealerFirstTurn()  then
            nTimeout = nTimeout+10
        end
    end
    if bSelfTrust == false then
        CSMessage.NotifyAllPlayer(stPlayer, "ask_play", {}, nTimeout)
    end
end

function CSMessage.NotifyPlayerAskBlock(stPlayer, stBlockResut, bNeedTimer, bIsQuick)
    local nTimeout

    if bNeedTimer then
        nTimeout = GGameCfg.TimerSetting.AutoPlayTimeOut
        if not bIsQuick then
            nTimeout = GGameCfg.TimerSetting.blockTimeOut
        end
        -- 房卡房间并且有限制时不设置超时---block时还是设置超时
        -- if GGameCfg.nMoneyMode ~= ROOM_MODE_SCORE or GGameCfg.TimerSetting.TimeOutLimit ~= -1 then
            FlowFramework.SetTimer(stPlayer:GetChairID(), nTimeout)
        -- end
    end
    CSMessage.NotifyOnePlayer(stPlayer, "ask_block", stBlockResut, nTimeout)
end

--重进时
function CSMessage.NotifyAskRePlay(stPlayer, bIsQuick,nTime)
    -- 问了，就得要求超时
    local nTimeout = GGameCfg.TimerSetting.AutoPlayTimeOut
    if not bIsQuick then
        nTimeout = nTime
    end
    -- 房卡房间并且有限制时不设置超时
    if GGameCfg.nMoneyMode ~= ROOM_MODE_SCORE or GGameCfg.TimerSetting.TimeOutLimit ~= -1 then
        FlowFramework.SetTimer(stPlayer:GetChairID(), nTimeout)
    else
        -- 房卡房间也设置超时timeid设为-1，在Time_mng做判断，不发超时事件
        FlowFramework.SetTimer(stPlayer:GetChairID(), nTimeout,-1)
    end
    
    -- 不能出的牌，后续考虑加癞子牌
    local stNoCanPlayCards={}
    local nTurn = stRoundInfo:GetWhoIsOnTurn()
    local nchair =stPlayer:GetChairID()
    local nGiveStatus = GRoundInfo:GetGiveStatus()
    if nGiveStatus == GIVE_STATUS_COLLECT   and nTurn ==nchair then
        local stPlayerCardSet = stPlayer:GetPlayerCardSet()
        local bySetCount = stPlayerCardSet:GetCurrentLength()
        local combineTile = stPlayer:GetPlayerCardSet():ToArray()
        if next(combineTile) then
            local nVaule = combineTile[bySetCount].value
            local nLastCard = combineTile[bySetCount].card + nVaule
            stNoCanPlayCards[#stNoCanPlayCards+1] = nLastCard
        end
    end
    CSMessage.NotifyOnePlayer(stPlayer, "ask_play", stNoCanPlayCards, nTimeout)
end

function CSMessage.NotifyPlayerReAskBlock(stPlayer, stBlockResut, bNeedTimer, bIsQuick,nTime)
    local nTimeout
    if bNeedTimer then
        nTimeout = GGameCfg.TimerSetting.AutoPlayTimeOut
        if not bIsQuick then
            nTimeout = nTime
        end
        --if GGameCfg.nMoneyMode ~= ROOM_MODE_SCORE or GGameCfg.TimerSetting.TimeOutLimit ~= -1 then
            FlowFramework.SetTimer(stPlayer:GetChairID(), nTimeout)
        --end
    end
    CSMessage.NotifyOnePlayer(stPlayer, "ask_block", stBlockResut, nTimeout)
end

--吃
function CSMessage.NotifyBlockCollect(stPlayer, collectWho, nCollectCard, stUseCards)
    local para = {
        collectWho = collectWho,
        cardCollect = { collect = nCollectCard, useCards = stUseCards },
    }
    CSMessage.NotifyAllPlayer(stPlayer, "collect", para)
end

-- who  碰谁的 牌
function CSMessage.NotifyBlockTriplet(stPlayer, nTurn, nCard)
    local para = {
        tripletWho = nTurn,
        cardTriplet = {triplet=nCard, useCards={nCard, nCard}},
    }
    CSMessage.NotifyAllPlayer(stPlayer, "triplet", para)
end
function CSMessage.NotifyBlockQuadruplet(stPlayer, nCard, nTurn, nType)
    local quadrupletType = 1
    
    -- 杠别人
    local stQuadruplet = {}
    if nType == ACTION_QUADRUPLET then
        quadrupletType = 1
        stQuadruplet = {quadruplet = nCard, useCards = {nCard, nCard, nCard}}
    elseif nType == ACTION_QUADRUPLET_REVEALED then
        -- 2 碰上加杠 明杠
        quadrupletType = 2
        stQuadruplet = { useCards = {nCard}}
    elseif nType == ACTION_QUADRUPLET_CONCEALED then
        -- 3 暗杠，现在也让别人看到的
        quadrupletType = 3
        stQuadruplet = {useCards = {nCard, nCard, nCard, nCard}}
    end

    local para = {
        quadrupletWho = nTurn,
        quadrupletType = quadrupletType,
        cardQuadruplet = stQuadruplet,
    }
    CSMessage.NotifyAllPlayer(stPlayer, "quadruplet", para)
end

--[[function CSMessage.NotifyPlayerBlockTing(stPlayer, stTingCards)
    local para = {
        cardWin = stTingCards
    }
    CSMessage.NotifyOnePlayer(stPlayer, "ting", para)

    para = {
        bTing = true
    }
    CSMessage.NotifyExceptPlayer(stPlayer, "ting", para)
end
--]]

--ting
function CSMessage.NotifyPlayerBlockTing(stPlayer, stTingCards)
    local para = {
        stTingCards = stTingCards,
    }
    CSMessage.NotifyOnePlayer(stPlayer, "ting", para)
end

function CSMessage.NotifyPlayerOtherPlayerPlay(stPlayer, playChairID, stCards)
    local para = {
        cards = stCards
    }
    CSMessage.NotifyOnePlayerTo(stPlayer, "play", para, playChairID);    
end

function CSMessage.NotifyPlayerPlayCard(stPlayer, stCards)
    LOG_DEBUG("NotifyPlayerPlayCard, %d, %s", stPlayer:GetChairID(), vardump(stCards))
    local para = {
        cards = stCards
    }
    CSMessage.NotifyAllPlayer(stPlayer, "play", para);
end

function CSMessage.NotifyPlayerLaizi(stPlayer, sit, card, laizi)
    local para = {
        sits = sit,
        cards= card,
        laizi= laizi
    }
    if stPlayer ~= nil then
        CSMessage.NotifyOnePlayer(stPlayer, "laizi", para);
    else
        CSMessage.NotifyAllPlayer(nil, "laizi", para);
    end
end

function CSMessage.NotifyPlayerCi(stPlayer, sit, card)
    local para = {
        sits = sit,
        cards= card,
    }
    if stPlayer ~= nil then
        CSMessage.NotifyOnePlayer(stPlayer, "ci", para);
    else
        CSMessage.NotifyAllPlayer(nil, "ci", para);
    end
end


function CSMessage.NotifyBanlanceChangeListToAll(stBalanceList)
    local para = {
        accountList = stBalanceList
    }
    CSMessage.NotifyAllPlayer(nil, "account", para)
end

function CSMessage.NotifyPlayerWin(stWinList)
    local nChair =stWinList[1].winner
    local cards={}
    local stPlayer =GGameState:GetPlayerByChair(nChair)

    cards= stPlayer:GetPlayerCardGroup():ToArray()
    local para = {
        stWinList = stWinList,
        cards = cards,
    }
    CSMessage.NotifyAllPlayer(nil, "win", para)   
end

function CSMessage.SendRoundResultToPlayer(stPlayer, notifyData)
    CSMessage.NotifyOnePlayer(stPlayer, "rewards", notifyData)
end

function CSMessage.SendAllRoundResultToPlayer(stPlayer, notifyData)
    CSMessage.NotifyOnePlayer(stPlayer, "total_rewards", notifyData)
end

function CSMessage.NotifySyncAllCards(stPlayer, stSyncAllCards)
    CSMessage.NotifyOnePlayer(stPlayer, "sync_table", stSyncAllCards)
end

function CSMessage.NotifyWinHint(stPlayer, stWinNotice)
    local para = {
        hintList = stWinNotice
    }
    CSMessage.NotifyOnePlayer(stPlayer, "win_hint", para)
end

function CSMessage.NotifyTrustToAll(stPlayerTrust, nStatus)
    local para = {
        setStatus = nStatus
    }
    CSMessage.NotifyAllPlayer(stPlayerTrust, "autoplay", para)
end

function CSMessage.SendSyncBeginNotify(stPlayer)
    CSMessage.NotifyOnePlayer(stPlayer, "sync_begin")
end

function CSMessage.SendSyncEndNotify(stPlayer)
    CSMessage.NotifyOnePlayer(stPlayer, "sync_end")
end

function CSMessage.NotifyPlayerPointsRefresh(stPlayer)
    local para = {
        stPlayer:GetPlayerPointsSt()
    }
    CSMessage.NotifyAllPlayer(stPlayer, "points_refresh", para)
end

function CSMessage.NotifyResultBeforeToAll(stHands)
    local para = {
        handTile = stHands
    }
    CSMessage.NotifyAllPlayer(nil, "show_all_hands", para)
end

function CSMessage.SendChatMessageToOther(stPlayer,content,contenttype,givewho)
    local para = {
        content = content,
        contenttype = contenttype
    }
    if contenttype==4 then
        para.givewho =givewho
    end
    LOG_DEBUG("Run LogicStep do_chat=send==%s",vardump(para))
    CSMessage.NotifyAllPlayer(stPlayer, "chat", para)
end

function CSMessage.NotifyPlayerAddMoneyToContinue(stPlayer)
    local para = {
        reason = CONTINUE_PLAY_REASON_MONEY
    }
    CSMessage.NotifyAllPlayer(stPlayer, "ask_continue_play", para)
end

function CSMessage.NotifyAllPlayerGiveupPlay(stPlayerGiveup)
    local para = {
        giveup = true
    }
    CSMessage.NotifyAllPlayer(stPlayerGiveup, "continue_play", para)
end

function CSMessage.ResponsePlayerInfo(stPlayer, _chair , stPlayerRsp)
    local para = {
        stPlayerRsp
    }
    CSMessage.NotifyOnePlayerTo(stPlayer, "player_info", para, _chair)
end

 function CSMessage.NotifyPlayerXiaPao (stPlayerXiaPao, nBeishu)
    local para = {}
    for i=1,PLAYER_NUMBER do
        if (GGameState:GetPlayerByChair(i) == stPlayerXiaPao) then
        	para["p" ..i] = nBeishu
        end
    end
    CSMessage.NotifyAllPlayer(stPlayerXiaPao, "xiapao", para)
 end

 --重连时通知自己 别人包括自己的下跑状态
function CSMessage.ReNotifyPlayerXiaPao (stPlayerXiaPao)
    local para = {}
    for i=1,PLAYER_NUMBER do
        if  GGameCfg.GameSetting.bSupportXiaPao then
            local nPlayerXiaPao = LibXiaPao:GetPlayerXiaPao(i)
            if (nPlayerXiaPao ~= -1) then
                para["p" ..i] = nPlayerXiaPao
                CSMessage.NotifyOnePlayer(stPlayerXiaPao, "xiapao", para)
            end
        end
    end
end

function CSMessage.NotifyXiaPaoResult(stPlayer, stXiaPaoResult)
    local para = {}
    for i=1,PLAYER_NUMBER do
        para["p" ..i] = stXiaPaoResult[i]
    end

    if stPlayer ~= nil then
        CSMessage.NotifyOnePlayer(stPlayer, "allplayerxiapao", para);
    else
        CSMessage.NotifyAllPlayer(nil, "allplayerxiapao", para);
    end
end

function CSMessage.NotifyAllPlayerGameEnd()
    CSMessage.NotifyAllPlayer(nil, "gameend")
end

function CSMessage.NotifyReEnterMessageToOther(stPlayer, nLeftTime)
    local para = {
        nLeftTime = nLeftTime
    }
    CSMessage.NotifyExceptPlayer(stPlayer, "reenter", para)
end

function CSMessage.NotifyAllPlayerTingType(stPlayer, tingType)
    local handCard = {}
    if tingType == TING_XIAOSA then
        handCard = stPlayer:GetPlayerCardGroup():ToArray()
    end
    
    local para = {
        tingType = tingType,  -- 听牌类型
        handCard = handCard,  -- 手牌 潇洒时有效
        tingChair = stPlayer:GetChairID(),  -- 听牌玩家
    }
    CSMessage.NotifyAllPlayer(stPlayer, "tingType", para)
end


return CSMessage