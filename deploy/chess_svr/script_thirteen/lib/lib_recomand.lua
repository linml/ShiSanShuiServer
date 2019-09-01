local LibBase = import(".lib_base")
local libRecomand = class("libRecomand", LibBase)

function libRecomand:ctor()
end

function libRecomand:CreateInit(strSlotName)
    return true
end

function libRecomand:OnGameStart()
end

--获取点数相同的所有数据
function libRecomand:Get_Same_Poker(cards, count)
    local hash = {}
    for i=1, 14 do
        hash[i] = {}
    end

    for i, v in ipairs(cards) do
        local nV = GetCardValue(v)
        table.insert(hash[nV], v)
    end

    local t = {}
    for i, v in ipairs(hash) do
        if #v == count then
            table.insert(t, v)
        end
    end

    if #t > 0 then
        return true, t
    else
        return false
    end
end

function libRecomand:Get_Same_Poker_Ext(cards, count)
    local hash = {}
    for i=1, 14 do
        hash[i] = {}
    end

    for i, v in ipairs(cards) do
        local nV = GetCardValue(v)
        table.insert(hash[nV], v)
    end

    local t = {}
    for i, v in ipairs(hash) do
        if #v >= count then
            table.insert(t, v)
        end
    end

    if #t > 0 then
        return true, t
    else
        return false
    end
end

--过滤 牌型相同且点数相同的牌  只要一副就行  返回false不过滤 true过滤
function libRecomand:DissSameCards(recommend, destTypes, destValues)
    for _, v in ipairs(recommend) do
        local tempTypes = v.Types
        local tempValues = v.Values
        --所有牌型一样  比较牌值
        if tempTypes[1] == destTypes[1] 
            and tempTypes[2] == destTypes[2]
            and tempTypes[3] == destTypes[3]
            --牌型一样就只要一副
            -- and Array.IsSubSet(destValues[1], tempValues[1]) == true
            -- and Array.IsSubSet(destValues[2], tempValues[2]) == true
            -- and Array.IsSubSet(destValues[3], tempValues[3]) == true
            then
                return true
        end
    end
    return false
end


--[[获取推荐牌型
SetRecommandLaizi(cards)函数说明：
参数cards: 为玩家手牌 共13张

格式：cards = {1,2,3,...}

返回值：recommend_cards = 
{
    {
        Cards={1,2,3,4,5,...},  --1-5是后墩 6-10是中墩 11-13是前墩
        Types={1,2,3},      --依次为尾中前牌型
        Values={
            {1,2,3,4,5},    --尾墩牌的点数
            {1,2,3,4,5},    --中墩牌的点数
            {1,2,3}         --前墩牌的点数
        }
    }, 
    ....
}
--]]
function libRecomand:SetRecommandLaizi(cards)
    --1.把癞子牌和普通牌分离
    local normalCards = {}
    local laiziCards = {}
    for _, v in ipairs(cards) do
        local nValue = GetCardValue(v)
        if LibLaiZi:IsLaiZi(nValue) then
            table.insert(laiziCards, v)
        else
            table.insert(normalCards, v)
        end
    end
    local nLaziCount = #laiziCards

    -- LOG_DEBUG("SetRecommandLaizi...#normalCards:%d, normalCards:%s\n", #normalCards, vardump(normalCards))
    -- LOG_DEBUG("SetRecommandLaizi...#laiziCards:%d,  laiziCards:%s\n", #laiziCards, vardump(laiziCards))
    local recommend_cards = {}

    ----1.尾墩
    local bthirdFind, thirdAllResult = self:Get_Five_Cards_Laizi(normalCards, nLaziCount)
    -- LOG_DEBUG("SetRecommandLaizi.........bthirdFind:%s, thirdAllResult:%s\n", tostring(bthirdFind), vardump(thirdAllResult))

    ---可能组成尾墩的所有牌型 
    --thirdAllResult = {result, result, result...}
    --result = {{card={1,2,3..}, index={1,2} },....}
    for _, thirdResult in ipairs(thirdAllResult) do
        for _, thi in ipairs(thirdResult) do
            local stLaiziCards = Array.Clone(laiziCards)    --癞子牌初始数据
            local tempthirdCards = thi.card                 --组成牌型的牌
            local tempthirdIndex = thi.index                --癞子牌在thi.card中位置

            --剩余的癞子牌
            local nThirdUsedLaizi = 0
            for _, v in pairs(tempthirdIndex) do
                nThirdUsedLaizi = nThirdUsedLaizi + 1
            end
            local thirdLeftLaizi = nLaziCount - nThirdUsedLaizi

            --需要移除的牌, 把癞子牌剔除
            local stThirdDelCards = {}
            for k, v in ipairs(tempthirdCards) do
                if tempthirdIndex[k] == nil then
                    table.insert(stThirdDelCards, v)
                end
            end
            --去除尾墩后剩余的牌的数量
            local thirdLeftCards = Array.Clone(normalCards)
            -- LOG_DEBUG("=======================thirdLeftCards1111:%s", vardump(thirdLeftCards))
            Array.DelElements(thirdLeftCards, stThirdDelCards)

            ----2.中墩
            local bSecFind, secondAllResult = self:Get_Five_Cards_Laizi(thirdLeftCards, thirdLeftLaizi)
            -- LOG_DEBUG("SetRecommandLaizi.........bSecFind:%s, secondAllResult:%s\n", tostring(bSecFind), vardump(secondAllResult))

            for _, secondResult in ipairs(secondAllResult) do
                for _, sec in ipairs(secondResult) do
                    local tempSecCards = sec.card
                    local tempSecIndex = sec.index

                    --剩余的癞子牌
                    local nSecUsedLaizi = 0
                    for _, v in pairs(tempSecIndex) do
                        nSecUsedLaizi = nSecUsedLaizi + 1
                    end
                    local secondLeftLaizi = thirdLeftLaizi - nSecUsedLaizi

                    --需要移除的牌, 把癞子牌剔除
                    local stSecDelCards = {}
                    for k, v in ipairs(tempSecCards) do
                        if tempSecIndex[k] == nil then
                            table.insert(stSecDelCards, v)
                        end
                    end
                    --去除中墩后剩余的牌的数量
                    local secondLeftCards = Array.Clone(thirdLeftCards)
                    Array.DelElements(secondLeftCards, stSecDelCards)

                    ----3.前墩
                    local bFirstFind, firstAllResult = self:Get_Three_Cards_Laizi(secondLeftCards, secondLeftLaizi)
                    -- LOG_DEBUG("SetRecommandLaizi.........bFirstFind:%s, firstAllResult:%s\n", tostring(bFirstFind), vardump(firstAllResult))
                    for _, firstResult in ipairs(firstAllResult) do
                        for _, fir in ipairs(firstResult) do
                            local tempFirstCards = fir.card
                            local tempFirstIndex = fir.index

                            --剩余的癞子牌
                            local nFirstUsedLaizi = 0
                            for _, v in pairs(tempFirstIndex) do
                                nFirstUsedLaizi = nFirstUsedLaizi + 1
                            end
                            local firstLeftLaizi = secondLeftLaizi - nFirstUsedLaizi

                            --需要移除的牌, 把癞子牌剔除
                            local stFirstDelCards = {}
                            for k, v in ipairs(tempFirstCards) do
                                if tempFirstIndex[k] == nil then
                                    table.insert(stFirstDelCards, v)
                                end
                            end
                            --去除前墩后剩余的牌的数量
                            local firstLeftCards = Array.Clone(secondLeftCards)
                            Array.DelElements(firstLeftCards, stFirstDelCards)

                            --组合成的牌型
                            local firstCards, secondCards, thirdCards = {}, {}, {}

                            --第三墩  把鬼牌换上
                            local stthirdLaiziCards = Array.Clone(stLaiziCards)
                            for k, v in ipairs(tempthirdCards) do
                                if tempthirdIndex[k] and #stthirdLaiziCards > 0 then
                                    local nLaiziCard = table.remove(stthirdLaiziCards)
                                    table.insert(thirdCards, nLaiziCard)
                                else
                                    table.insert(thirdCards, v)
                                end
                            end
                            --第二墩  把鬼牌换上
                            for k, v in ipairs(tempSecCards) do
                                if tempSecIndex[k] and #stthirdLaiziCards > 0 then
                                    local nLaiziCard = table.remove(stthirdLaiziCards)
                                    table.insert(secondCards, nLaiziCard)
                                else
                                    table.insert(secondCards, v)
                                end
                            end
                            --第一墩  把鬼牌换上
                            for k, v in ipairs(tempFirstCards) do
                                if tempFirstIndex[k] and #stthirdLaiziCards > 0 then
                                    local nLaiziCard = table.remove(stthirdLaiziCards)
                                    table.insert(firstCards, nLaiziCard)
                                else
                                    table.insert(firstCards, v)
                                end
                            end

                            --记得把剩余的鬼牌也加上 防止少牌
                            for _, v in pairs(stthirdLaiziCards) do
                                table.insert(firstLeftCards, v)
                            end
                            ---补充牌 使其成牌
                            for i=1, 5-#tempthirdCards do
                                local nCard = table.remove(firstLeftCards)
                                table.insert(thirdCards, nCard)
                            end
                            for i=1, 5-#tempSecCards do
                                local nCard = table.remove(firstLeftCards)
                                table.insert(secondCards, nCard)
                            end
                            for i=1, 3-#tempFirstCards do
                                local nCard = table.remove(firstLeftCards)
                                table.insert(firstCards, nCard)
                            end

                            --
                            local bSuc1, firstType, values1 = LibNormalCardLogic:GetCardTypeByLaizi(firstCards)
                            local bSuc2, secondType, values2 = LibNormalCardLogic:GetCardTypeByLaizi(secondCards)
                            local bSuc3, thirdType, values3 = LibNormalCardLogic:GetCardTypeByLaizi(thirdCards)
                            --判断相公  相公则交换牌
                            local nXianggongCount = 0
                            if LibNormalCardLogic:CompareCardsLaizi(firstType, secondType, values1, values2) > 0 then
                                nXianggongCount = nXianggongCount + 1
                                local temp1 = Array.Clone(firstCards)
                                local temp2 = Array.Clone(secondCards)
                                firstCards[1] = temp2[1]
                                firstCards[2] = temp2[2]
                                firstCards[3] = temp2[3]
                                secondCards[1] = temp1[1]
                                secondCards[2] = temp1[2]
                                secondCards[3] = temp1[3]
                            end
                            if LibNormalCardLogic:CompareCardsLaizi(secondType, thirdType, values2, values3) > 0 then
                                nXianggongCount = nXianggongCount + 1
                                local temp2 = Array.Clone(secondCards)
                                local temp3 = Array.Clone(thirdCards)
                                secondCards[1] = temp3[1]
                                secondCards[2] = temp3[2]
                                secondCards[3] = temp3[3]
                                secondCards[4] = temp3[4]
                                secondCards[5] = temp3[5]
                                thirdCards[1] = temp2[1]
                                thirdCards[2] = temp2[2]
                                thirdCards[3] = temp2[3]
                                thirdCards[4] = temp2[4]
                                thirdCards[5] = temp2[5]
                            end
                            if LibNormalCardLogic:CompareCardsLaizi(firstType, thirdType, values1, values3) > 0 then
                                nXianggongCount = nXianggongCount + 1
                                local temp1 = Array.Clone(firstCards)
                                local temp3 = Array.Clone(thirdCards)
                                firstCards[1] = temp3[1]
                                firstCards[2] = temp3[2]
                                firstCards[3] = temp3[3]
                                thirdCards[1] = temp1[1]
                                thirdCards[2] = temp1[2]
                                thirdCards[3] = temp1[3]
                            end
                            --重新获取一遍
                            bSuc1, firstType, values1 = LibNormalCardLogic:GetCardTypeByLaizi(firstCards)
                            bSuc2, secondType, values2 = LibNormalCardLogic:GetCardTypeByLaizi(secondCards)
                            bSuc3, thirdType, values3 = LibNormalCardLogic:GetCardTypeByLaizi(thirdCards)

                            --需要重新再比一次  防止换牌后还有相公
                            local bXianggong = false
                            if nXianggongCount > 0 then
                                if LibNormalCardLogic:CompareCardsLaizi(firstType, secondType, values1, values2) > 0 then
                                    bXianggong = true
                                end
                                if bXianggong == false and LibNormalCardLogic:CompareCardsLaizi(secondType, thirdType, values2, values3) > 0 then
                                    bXianggong = true
                                end
                                if bXianggong == false and LibNormalCardLogic:CompareCardsLaizi(firstType, thirdType, values1, values3) > 0 then
                                    bXianggong = true
                                end
                            end

                            if bXianggong == false then
                                --最后形成的推荐牌
                                local stCards = {}
                                for _, v in ipairs(thirdCards) do
                                    table.insert(stCards, v)
                                end
                                for _, v in ipairs(secondCards) do
                                    table.insert(stCards, v)
                                end
                                for _, v in ipairs(firstCards) do
                                    table.insert(stCards, v)
                                end

                                ---判断牌是否正确
                                if #stCards ~= #cards or Array.IsSubSet(stCards, cards) == false then
                                    LOG_DEBUG("=============ERROR==========SrcCards:%s\n, DestCards:%s", vardump(cards), vardump(stCards))
                                else
                                    local stTypes = {thirdType, secondType, firstType}
                                    local stValues = {values3, values2, values1}
                                    local stFinds = { Cards = stCards, Types = stTypes, Values = stValues }
                                    --在过滤 摆的牌一模一样的
                                    local bDiss = self:DissSameCards(recommend_cards, stTypes, stValues)
                                    -- LOG_DEBUG("==========bDiss:%s", tostring(bDiss))
                                    if bDiss == false then
                                        table.insert(recommend_cards, stFinds)
                                        -- LOG_DEBUG("============SetRecommandLaizi======stFinds: %s\n", vardump(stFinds))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- LOG_DEBUG("SetRecommandLaizi..........recommend_cards：%s", vardump(recommend_cards))
    -- LOG_DEBUG("libRecomand:SetRecommandLaizi.......#recommend_cards: %d", #recommend_cards)
    --先按牌型排序
    table.sort(recommend_cards, function(a, b)
        if a.Types[1] == b.Types[1] then
            if a.Types[2] == b.Types[2] then
                return a.Types[3] > b.Types[3]
            else
                return a.Types[2] > b.Types[2]
            end
        else
            return a.Types[1] > b.Types[1]
        end
    end)
    return recommend_cards
end

--===============================================================
--下面是获取尾中前三墩牌的接口
--[[
接口的参数一样:function libRecomand:xxx(cards, nLaziCount)
参数说明：
cards：玩家手上除了癞子牌剩余的牌
nLaziCount：剩余的癞子数量

返回值说明：
bFind：是否找到相应的牌型 false没有 true有
stAllCardTypes：保存找到的牌型牌数据 格式如下
stAllCardTypes = 
{
    result,
    result,
    result,
    ...
}


result格式：
{
    {
        card = {1,2,3...}, --最多5张 最少2张
        index = {[2]=2, [4]=4 } --[位置]=位置 保存癞子牌在card的位置
    },
    ....
}
--]]
--===============================================================
--获取能组成5张牌的所有牌型
function libRecomand:Get_Five_Cards_Laizi(cards, nLaziCount)
    local copyCards = Array.Clone(cards)
    LibNormalCardLogic:Sort(copyCards)

    local tempCards = Array.Clone(copyCards)
    local stAllCardTypes = {}

    local bFind, result = self:Get_Pt_Five_Laizi(tempCards, nLaziCount)
    if bFind then
        table.insert(stAllCardTypes, result)
        -- return bFind, result
    end

    local tempCards = Array.Clone(copyCards)
    local bFind, result = self:Get_Pt_Straight_Flush_Laizi(tempCards, nLaziCount)
    if bFind then
        table.insert(stAllCardTypes, result)
        -- return bFind, result
    end

    local tempCards = Array.Clone(copyCards)
    local bFind, result = self:Get_Pt_Four_Laizi(tempCards, nLaziCount)
    if bFind then
        table.insert(stAllCardTypes, result)
        -- return bFind, result
    end

    local tempCards = Array.Clone(copyCards)
    local bFind, result = self:Get_Pt_Full_Hosue_Laizi(tempCards, nLaziCount)
    if bFind then
        table.insert(stAllCardTypes, result)
        -- return bFind, result
    end

    local tempCards = Array.Clone(copyCards)
    local bFind, result = self:Get_Pt_Flush_Laizi(tempCards, nLaziCount)
    if bFind then
        table.insert(stAllCardTypes, result)
        -- return bFind, result
    end

    local tempCards = Array.Clone(copyCards)
    local bFind, result = self:Get_Pt_Straight_Laizi(tempCards, nLaziCount)
    if bFind then
        table.insert(stAllCardTypes, result)
        -- return bFind, result
    end

    local tempCards = Array.Clone(copyCards)
    local bFind, result = self:Get_Pt_Three_Laizi(tempCards, nLaziCount)
    if bFind then
        table.insert(stAllCardTypes, result)
        -- return bFind, result
    end

    local tempCards = Array.Clone(copyCards)
    local bFind, result = self:Get_Pt_Two_Pair_Laizi(tempCards, nLaziCount)
    if bFind then
        table.insert(stAllCardTypes, result)
        -- return bFind, result
    end

    local tempCards = Array.Clone(copyCards)
    local bFind, result = self:Get_Pt_One_Pair_Laizi(tempCards, nLaziCount)
    if bFind then
        table.insert(stAllCardTypes, result)
        -- return bFind, result
    end

    local tempCards = Array.Clone(copyCards)
    if #stAllCardTypes == 0 then
        --散牌5张
        local result = {}
        local temp = {}
        local index = {}
        local cardType = GStars_Normal_Type.PT_SINGLE

        if nLaziCount >= 5 then
            table.insert(temp, 0x3E)
            table.insert(temp, 0x3E)
            table.insert(temp, 0x3E)
            table.insert(temp, 0x3E)
            table.insert(temp, 0x3E)

            index[1] = 1
            index[2] = 2
            index[3] = 3
            index[4] = 4
            index[5] = 5
            cardType = GStars_Normal_Type.PT_FIVE
        elseif nLaziCount == 2 then
            table.insert(temp, tempCards[#tempCards])
            table.insert(temp, tempCards[#tempCards])
            table.insert(temp, tempCards[#tempCards])
            index[2] = 2
            index[3] = 3
            cardType = GStars_Normal_Type.PT_THREE
        elseif nLaziCount == 1 then
            table.insert(temp, tempCards[#tempCards])
            table.insert(temp, tempCards[#tempCards])
            index[2] = 2
            cardType = GStars_Normal_Type.PT_ONE_PAIR
        else
            table.insert(temp, tempCards[#tempCards])
            table.insert(temp, tempCards[#tempCards-1])
            table.insert(temp, tempCards[#tempCards-2])
            table.insert(temp, tempCards[#tempCards-3])
            table.insert(temp, tempCards[#tempCards-4])
            cardType = GStars_Normal_Type.PT_SINGLE
        end
        table.insert(result, { card = temp, index = index })

        table.insert(stAllCardTypes, result)
    end

    return true, stAllCardTypes
end

--获取能组成3张牌的所有牌型
function libRecomand:Get_Three_Cards_Laizi(cards, nLaziCount)
    local copyCards = Array.Clone(cards)
    LibNormalCardLogic:Sort(copyCards)

    local tempCards = Array.Clone(copyCards)
    local stAllCardTypes = {}

    local bFind, result = self:Get_Pt_Three_Laizi(tempCards, nLaziCount)
    if bFind then
        table.insert(stAllCardTypes, result)
        -- return bFind, result
    end

    local tempCards = Array.Clone(copyCards)
    local bFind, result = self:Get_Pt_One_Pair_Laizi(tempCards, nLaziCount)
    if bFind then
        -- LOG_DEBUG("11111=======Get_Three_Cards_Laizi:%s", vardump(result))
        if nLaziCount >= 1 then
            table.insert(result[1].card, result[1].card[1])
            result[1].index[3] = 3
            -- result.type = GStars_Normal_Type.PT_THREE
        else
            -- result.type = GStars_Normal_Type.PT_ONE_PAIR
        end
        -- LOG_DEBUG("2222=======Get_Three_Cards_Laizi:%s", vardump(result.card))
        table.insert(stAllCardTypes, result)
        -- return bFind, result
    end

    local tempCards = Array.Clone(copyCards)
    if #stAllCardTypes == 0 then
        --散牌
        local result = {}
        local temp = {}
        local index = {}
        local cardType = GStars_Normal_Type.PT_SINGLE

        if nLaziCount == 3 then
            table.insert(temp, 0x3E)
            table.insert(temp, 0x3E)
            table.insert(temp, 0x3E)

            index[1] = 1
            index[2] = 2
            index[3] = 3
            cardType = GStars_Normal_Type.PT_THREE
        elseif nLaziCount == 2 then
            table.insert(temp, tempCards[#tempCards])
            table.insert(temp, tempCards[#tempCards])
            table.insert(temp, tempCards[#tempCards])
            index[2] = 2
            index[3] = 3
            cardType = GStars_Normal_Type.PT_THREE
        elseif nLaziCount == 1 then
            table.insert(temp, tempCards[#tempCards])
            table.insert(temp, tempCards[#tempCards])
            index[2] = 2
            cardType = GStars_Normal_Type.PT_ONE_PAIR
        else
            table.insert(temp, tempCards[#tempCards])
            table.insert(temp, tempCards[#tempCards-1])
            table.insert(temp, tempCards[#tempCards-2])
            cardType = GStars_Normal_Type.PT_SINGLE
        end
        table.insert(result, { card = temp, index = index })

        -- LOG_DEBUG("========#index:%d", #index)
        -- for k, v in pairs(index) do
        --     LOG_DEBUG("xxxxxxxxxxxxx%d---%d", k, v)
        -- end

        table.insert(stAllCardTypes, result)
    end


    return true, stAllCardTypes
end



--==============================================================
--下面是获取具体牌牌型算法
--[[
所有算法参数一样function libRecomand:xxx(cards, nLaziCount)
参数说明：
cards：玩家手上除了癞子牌剩余的牌
nLaziCount：剩余的癞子数量

返回值参数说明function libRecomand:xxx(cards, nLaziCount)  returne bFind, result  end
bFind：是否找到相应的牌型 false没有 true有
result：保存找到的牌型牌数据 格式如下
result = 
{
    {
        card = {1,2,3...}, --最多5张 最少2张
        index = {[2]=2, [4]=4 } --[位置]=位置 保存癞子牌在card的位置
    },
    ....
}
--]]
--==============================================================

--5同  +鬼牌把所有的能组成的5同都找出来了
function libRecomand:Get_Pt_Five_Laizi(cards, nLaziCount)
    local result = {} ---result = {{card={1,2,3,4,5}, index={2,3}}, ...}
    local bFind = false
    for i=5, 5-nLaziCount, -1 do
        local bSuc, t = self:Get_Same_Poker(cards, i)
        -- LOG_DEBUG("Get_Pt_Five_Laizi...i:%d, bSuc:%s, t:%s", i, tostring(bSuc), vardump(t))
        if bSuc then
            local tempCards = {}
            local index = {}
            --取最大一个
            for _, v in ipairs(t[#t]) do
                table.insert(tempCards, v)
            end
            for k=1, 5-i do
                table.insert(tempCards, tempCards[1])
                -- table.insert(index, #tempCards)
                index[#tempCards] = #tempCards
            end
            bFind = true
            table.insert(result, { card = tempCards, index = index })

            --只拿一副最大的
            -- break
        end
    end
    -- LOG_DEBUG("Get_Pt_Five_Laizi...bFind:%s, result:%s", tostring(bFind), vardump(result))
    return bFind, result
end

--同花顺 +鬼牌把所有的能组成的同花顺都找出来了
function libRecomand:Get_Pt_Straight_Flush_Laizi(cards, nLaziCount)
    local flush = {}
    --按花色分组:0-3
    LibNormalCardLogic:Sort_By_Color(cards)
    for _, v in ipairs(cards) do
        local color = GetCardColor(v)
        if not flush[color] then
            flush[color] = {}
        end
        table.insert(flush[color], v)
    end

    local result = {}
    local bFind = false
    for color, hash in pairs(flush) do
        if #hash + nLaziCount >= 5 then
            local values = {}
            for i=1, 14 do
                values[i] = 0
            end
            for _, v in ipairs(hash) do
                local val = GetCardValue(v)
                values[val] = values[val] + 1
            end
            values[1] = values[14]

            for i=1, 10 do
                local values2 = Array.Clone(values)
                local straight = true
                local tempLaizi = nLaziCount

                local tempCards = {}
                local index = {}
                for j=1, 5 do
                    if values2[i+j-1] == 0 then
                        if tempLaizi <= 0 then
                            straight = false
                            break
                        else
                            values2[i+j-1] = 1
                            --对A做处理
                            if i + j - 1 == 1 then
                                values2[14] = 1
                            end
                            if i + j - 1 == 14 then
                                values2[1] = 1
                            end
                            tempLaizi = tempLaizi -1
                            index[j] = j
                        end
                    end
                end
                --是顺子
                if straight then
                    for k=1, 5 do
                        --数量-1 防止重用
                        local nv = i+k-1
                        values2[nv] = values2[nv] - 1
                        --对A做处理
                        if nv == 1 then
                            values2[14] = values2[14] - 1
                        end
                        if nv == 14 then
                            values2[1] = values2[1] - 1
                        end
                        if nv == 1 then
                            nv = 14
                        end
                        local nCard = GetCardByColorValue(color, nv)
                        -- LOG_DEBUG("========Get_Pt_Straight_Flush_Laizi=======color:%d, nv:%d, nCard:%d", color, nv, nCard)
                        table.insert(tempCards, nCard)
                    end
                    -- LOG_DEBUG("========Get_Pt_Straight_Flush_Laizi=======tempCards:%s", vardump(tempCards))
                    -- LOG_DEBUG("========Get_Pt_Straight_Flush_Laizi=======index:%s", vardump(index))
                    bFind = true
                    table.insert(result, { card = tempCards, index = index }) 
                end
            end
        end
    end
    -- LOG_DEBUG("Get_Pt_Straight_Flush_Laizi...bFind:%s, #result:%d", tostring(bFind), #result)

    return bFind, result
end

--4条 +鬼牌把所有的能组成的4条都找出来了
function libRecomand:Get_Pt_Four_Laizi(cards, nLaziCount)
    ---result = {{card={1,2,3,4,5}, index={2,3}}, ...}
    local result = {}
    local bFind = false
    for i=4, 4-nLaziCount, -1 do
        local bSuc, t = self:Get_Same_Poker(cards, i)
        -- LOG_DEBUG("Get_Pt_Four_Laizi...i:%d, bSuc:%s, t:%s", i, tostring(bSuc), vardump(t))
        if bSuc then
            local tempCards = {}
            local index = {}
            --取最大一个
            -- LOG_DEBUG("Get_Pt_Four_Laizi.......t[#t]:%s", vardump(t[#t]))
            for _, v in ipairs(t[#t]) do
                -- LOG_DEBUG("Get_Pt_Four_Laizi......v:%d", v)
                table.insert(tempCards, v)
            end
            for k=1, 4-i do
                table.insert(tempCards, tempCards[1])
                index[#tempCards] = #tempCards
            end
            bFind = true
            table.insert(result, { card = tempCards, index = index })

            --只拿一副最大的
            -- break
        end
    end
    -- LOG_DEBUG("Get_Pt_Four_Laizi...bFind:%s, result:%s", tostring(bFind), vardump(result))

    return bFind, result
end

--葫芦 +鬼牌
function libRecomand:Get_Pt_Full_Hosue_Laizi(cards, nLaziCount)
    local result = {}
    local bFind = false

    if nLaziCount == 0 then
        local bSuc3, t3 = self:Get_Same_Poker(cards, 3)
        -- LOG_DEBUG("Get_Pt_Full_Hosue_Laizi111111111...bSuc3:%s, t3:%s", tostring(bSuc3), vardump(t3))
        if bSuc3 then
            local bSuc2, t2 = self:Get_Same_Poker(cards, 2)
            if bSuc2 then
                -- for _, v3 in ipairs(t3) do
                    local tempCards = {}
                    for _, nc in ipairs(t3[#t3]) do
                        table.insert(tempCards, nc)
                    end
                    --最小的一对
                    for _, nc in ipairs(t2[1]) do
                        table.insert(tempCards, nc)
                    end
                    bFind = true
                    table.insert(result, { card = tempCards, index = {} })
                -- end
            end
            --不用考虑癞子牌  这样会变成4条或5同
        end
    else
        local bSuc, t = self:Get_Same_Poker(cards, 2)
        -- LOG_DEBUG("Get_Pt_Full_Hosue_Laizi2222222...bSuc:%s, t:%s", tostring(bSuc), vardump(t))
        if bSuc and #t > 1 and nLaziCount > 0 then
            local tempCards = {}
            local index = {}
            --取最大一个
            for _, v in ipairs(t[#t]) do
                table.insert(tempCards, v)
            end
            --加一张鬼牌
            table.insert(tempCards, tempCards[1])
            index[#tempCards] = #tempCards
            --最小的一对
            for _, v in ipairs(t[1]) do
                table.insert(tempCards, v)
            end
            bFind = true
            table.insert(result, { card = tempCards, index = index })
        end
    end

    -- LOG_DEBUG("Get_Pt_Full_Hosue_Laizi...bFind:%s, result:%s", tostring(bFind), vardump(result))
    return bFind, result
end

--葫芦 +鬼牌
function libRecomand:Get_Pt_Full_Hosue_Laizi_Ext(cards, nLaziCount)
    local result = {}
    local bFind = false

    if nLaziCount == 0 then
        local bSuc3, t3 = self:Get_Same_Poker_Ext(cards, 3)
        -- LOG_DEBUG("Get_Pt_Full_Hosue_Laizi111111111...bSuc3:%s, t3:%s", tostring(bSuc3), vardump(t3))
        if bSuc3 then
            local bSuc2, t2 = self:Get_Same_Poker(cards, 2)
            if bSuc2 then
                --三条
                for _, v3 in ipairs(t3) do
                    local tempCards = {}
                    local nValue1 = GetCardValue(v3[1])
                    for i=1, 3 do
                        table.insert(tempCards, v3[i])
                    end
                    --对子
                    for _, v2 in ipairs(t2) do
                        local ttc = Array.Clone(tempCards)
                        local nValue2 = GetCardValue(v2[1])
                        if nValue1 ~= nValue2 then
                            for j=1, 2 do
                                table.insert(ttc, v2[j])
                            end
                            bFind = true
                            table.insert(result, { card = ttc, index = {} })
                        end
                    end
                end
            end
        end
    end


    --癞子
    local bSuc, t = self:Get_Same_Poker(cards, 2)
    -- LOG_DEBUG("Get_Pt_Full_Hosue_Laizi2222222...bSuc:%s, t:%s", tostring(bSuc), vardump(t))
    if bSuc and #t > 1 and nLaziCount > 0 then
        for i=#t, 1, -1 do
            local tempCards = {}
            local index = {}
            --取最大一个
            for _, v in ipairs(t[i]) do
                table.insert(tempCards, v)
            end
            --加一张鬼牌
            table.insert(tempCards, tempCards[1])
            index[#tempCards] = #tempCards
            --最小的一对
            for j=i-1, 1, -1 do
                local ttc = Array.Clone(tempCards)
                for _, v in ipairs(t[j]) do
                    table.insert(ttc, v)
                end
                bFind = true
                table.insert(result, { card = ttc, index = index })
            end
        end
    end

    -- LOG_DEBUG("Get_Pt_Full_Hosue_Laizi...bFind:%s, result:%s", tostring(bFind), vardump(result))
    return bFind, result
end

--同花 +鬼牌把所有的能组成的同花都找出来了
function libRecomand:Get_Pt_Flush_Laizi(cards, nLaziCount)
    -- LOG_DEBUG("=======Get_Pt_Flush_Laizi======nLaziCount:%d, cards:%s", nLaziCount, vardump(cards))
    local flush = {}
    --按花色分组:0-3
    LibNormalCardLogic:Sort_By_Color(cards)
    for k, v in ipairs(cards) do
        local color = GetCardColor(v)
        if not flush[color] then
            flush[color] = {}
        end
        table.insert(flush[color], v)
    end
    -- LOG_DEBUG("=======Get_Pt_Flush_Laizi======flush:%s", vardump(flush))
    --之前已经过滤过同花顺   这就不要过滤
    --不好判断了  只能在之后做比较

    local result = {}
    local bFind = false
    for j, v in pairs(flush) do
        -- LOG_DEBUG("=====Get_Pt_Flush_Laizi===nLaziCount:%d, color:%d, v:%s", nLaziCount, j, vardump(v))
        local tempLaizi = nLaziCount
        if #v >= 5 then
            for i=1, #v-4 do
                local tempCards = {}
                for k=1, 5 do
                    table.insert(tempCards, v[i+k-1])
                end
                -- LOG_DEBUG("==Get_Pt_Flush_Laizi====i:%d, tempCards:%s", i, vardump(tempCards))
                --最小的放最后面
                bFind = true
                table.insert(result, { card = tempCards, index = {} }) 
            end
            -- LOG_DEBUG("==Get_Pt_Flush_Laizi1111111====result:%s", vardump(result))
        elseif #v + tempLaizi >= 5 then
            --癞子补   对同花
            local tempCards = {}
            local index = {}
            for k=1, #v do
                table.insert(tempCards, v[k])
            end

            local nUniq = LibNormalCardLogic:Uniqc(v)
            if nUniq == 1 then
                --不应该出现会组成5同
            elseif nUniq == 2 then
                if #v == 2 then
                    --不应该出现 会组成4条
                elseif #v == 3 then
                    --不应该出现 会组成4条
                elseif #v == 4 then
                    --不应该出现这种情况 会组成葫芦
                end
            elseif nUniq == 3 then
                if #v == 3 then
                    table.insert(tempCards, v[#v])
                    index[#tempCards] = 1

                    table.insert(tempCards, v[#v-1])
                    index[#tempCards] = #tempCards
                    bFind = true
                elseif #v == 4 then
                    --单牌最大的那个
                    local nc = 0
                    if v[3] == v[4] then
                        nc = v[2]
                    else
                        nc = v[4]
                    end
                    table.insert(tempCards, nc)
                    index[#tempCards] = #tempCards
                    bFind = true
                end
            elseif nUniq == 4 then
                table.insert(tempCards, v[#v])
                index[#tempCards] = #tempCards
                bFind = true
            end
            -- LOG_DEBUG("==Get_Pt_Flush_Laizi====tempCards:%s", vardump(tempCards))
            --因为有对同花在  所以分不清楚 谁大谁小
            if bFind then
                table.insert(result, { card = tempCards, index = index })
            end
            -- LOG_DEBUG("==Get_Pt_Flush_Laizi222222222====result:%s", vardump(result))
        end
    end
    -- LOG_DEBUG("Get_Pt_Flush_Laizi...bFind:%s, result:%s", tostring(bFind), vardump(result))

    -- LOG_DEBUG("Get_Pt_Flush_Laizi...bFind:%s, #result:%d", tostring(bFind), #result)
    return bFind, result
end

--顺子 +鬼牌把所有的能组成的顺子都找出来了
function libRecomand:Get_Pt_Straight_Laizi(cards, nLaziCount)
    --设置各个牌值的数量
    local values = {}   --[牌值]=数量
    for i=1, 14 do
        values[i] = 0
    end

    local stColors = {}
    local nColor = 0
    for _, v in ipairs(cards) do
        local val = GetCardValue(v)
        nColor = GetCardColor(v)
        if stColors[val] == nil then
            stColors[val] = {}
        end
        table.insert(stColors[val], v)
        values[val] = values[val] + 1
    end
    values[1] = values[14]

    local result = {}
    local bFind = false

    --A1234
    local bHasA5 = false
    --10JQKA
    local bHasKA = false

    for i=1, 10 do
        local values2 = Array.Clone(values)
        local stColors2 = clone(stColors)
        local straight = true
        local tempLaizi = nLaziCount

        local tempCards = {}
        local index = {}
        for j=1, 5 do
            if values2[i+j-1] == 0 then
                if tempLaizi <= 0 then
                    straight = false
                    break
                else
                    values2[i+j-1] = 1
                    --对A做处理
                    if i + j - 1 == 1 then
                        values2[14] = 1
                    end
                    if i + j - 1 == 14 then
                        values2[1] = 1
                    end
                    tempLaizi = tempLaizi -1
                    index[j] = j
                end
            end
        end
        --是顺子
        if straight then
            if i==1 then
                bHasA5 = true
            end
            if i==10 then
                bHasKA = true
            end

            for k=1, 5 do
                --数量-1 防止重用
                local nv = i+k-1
                values2[nv] = values2[nv] - 1
                --对A做处理
                if nv == 1 then
                    values2[14] = values2[14] - 1
                end
                if nv == 14 then
                    values2[1] = values2[1] - 1
                end
                if nv == 1 then
                    nv = 14
                end

                local nCard = GetCardByColorValue(nColor, nv)
                if stColors2[nv] then
                    nCard = table.remove(stColors2[nv])
                end
                -- LOG_DEBUG("========Get_Pt_Straight_Laizi=======nColor:%d, nv:%d, nCard:%d", nColor, nv, nCard)
                table.insert(tempCards, nCard)
            end
            -- LOG_DEBUG("========Get_Pt_Straight_Laizi=======tempCards:%s", vardump(tempCards))
            -- LOG_DEBUG("========Get_Pt_Straight_Laizi=======index:%s", vardump(index))
            bFind = true
            table.insert(result, { card = tempCards, index = index }) 
        end
    end

    -- LOG_DEBUG("Get_Pt_Straight_Laizi...bFind:%s, result:%s", tostring(bFind), vardump(result))
    -- LOG_DEBUG("Get_Pt_Straight_Laizi...bFind:%s, #result:%d", tostring(bFind), #result)
    return bFind, result
end

--3条
function libRecomand:Get_Pt_Three_Laizi(cards, nLaziCount)
    local result = {}
    local bFind = false
    if nLaziCount == 0 then
        local bSuc3, t3 = self:Get_Same_Poker(cards, 3)
        -- LOG_DEBUG("Get_Pt_Three_Laizi11111111111111...bSuc3:%s, t3:%s", tostring(bSuc3), vardump(t3))
        if bSuc3 then
            for _, v3 in ipairs(t3) do
                local tempCards = {}
                for _, nc in ipairs(v3) do
                    table.insert(tempCards, nc)
                end
                bFind = true
                table.insert(result, { card = tempCards, index = {} })
            end
        end
    else
        local bSuc, t = self:Get_Same_Poker(cards, 2)
        -- LOG_DEBUG("Get_Pt_Three_Laizi222222222...bSuc:%s, t:%s", tostring(bSuc), vardump(t))
        if bSuc and #t == 1 and nLaziCount > 0 then
            local tempCards = {}
            local index = {}
            --取最大一个
            for _, v in ipairs(t[#t]) do
                table.insert(tempCards, v)
            end
            --加一张鬼牌
            table.insert(tempCards, tempCards[1])
            index[#tempCards] = #tempCards

            bFind = true
            table.insert(result, { card = tempCards, index = index })
        end
    end

    -- LOG_DEBUG("Get_Pt_Three_Laizi...bFind:%s, result:%s", tostring(bFind), vardump(result))
    return bFind, result
end

--2对
function libRecomand:Get_Pt_Two_Pair_Laizi(cards, nLaziCount)
    --不考虑癞子  加癞子组成的牌型永远大于两对
    local result = {}
    local bFind = false

    local bSuc, t = self:Get_Same_Poker(cards, 2)
    -- LOG_DEBUG("Get_Pt_Two_Pair_Laizi...bSuc:%s, t:%s", tostring(bSuc), vardump(t))
    if bSuc and #t > 1 then
        local tempCards = {}
        local index = {}
        --取最大一个
        -- LOG_DEBUG("=====================t[#t]:%s", vardump(t[#t]))
        for _, v in ipairs(t[#t]) do
            -- LOG_DEBUG("11111111===============v:%d", v)
            table.insert(tempCards, v)
        end
        --取次大
        for _, v in ipairs(t[#t-1]) do
            -- LOG_DEBUG("22222222===============v:%d", v)
            table.insert(tempCards, v)
        end

        bFind = true
        table.insert(result, { card = tempCards, index = index })
    end
    -- LOG_DEBUG("Get_Pt_Two_Pair_Laizi...bFind:%s, result:%s", tostring(bFind), vardump(result))
    return bFind, result
end

--1对
function libRecomand:Get_Pt_One_Pair_Laizi(cards, nLaziCount)
    --不考虑癞子 加癞子组成的牌型永远大于1对
    local result ={}
    local bFind = false

    local bSuc, t = self:Get_Same_Poker(cards, 2)
    -- LOG_DEBUG("Get_Pt_One_Pair_Laizi...bSuc:%s, t:%s", tostring(bSuc), vardump(t))
    if bSuc and #t == 1 then
        local tempCards = {}
        local index = {}
        --取最大一个
        for _, v in ipairs(t[#t]) do
            table.insert(tempCards, v)
        end

        bFind = true
        table.insert(result, { card = tempCards, index = index })
    end

    -- LOG_DEBUG("Get_Pt_One_Pair_Laizi...bFind:%s, result:%s", tostring(bFind), vardump(result))
    return bFind, result
end


---------前段摆牌使用接口------------

--按值降序 14-2
function libRecomand:Sort(cards)
    -- --LOG_DEBUG("LibNormalCardLogic:Sort..before, cards: %s\n", TableToString(cards))
    if not cards.isSorted then
        table.sort(cards, function(a,b)
            local valueA,colorA = GetCardValue(a), GetCardColor(a)
            local valueB,colorB = GetCardValue(b), GetCardColor(b)
            if valueA == valueB then
                return colorA > colorB
            else
                return valueA > valueB
            end
        end)
        cards.isSorted = true
    end
    -- --LOG_DEBUG("LibNormalCardLogic:Sort..end, cards: %s\n", TableToString(cards))
end

--5同  +鬼牌把所有的能组成的5同都找出来了
function libRecomand:Get_Pt_Five_Laizi_second(cards, nLaziCount)
    local result = {} ---result = {{card={1,2,3,4,5}, index={2,3}}, ...}
    local bFind = false
    local copyCards = cards
    LibNormalCardLogic:Sort(copyCards)
    for i=5, 5-nLaziCount, -1 do
        local bSuc, t = self:Get_Same_nCard_Split(copyCards, i)
        -- LOG_DEBUG("Get_Pt_Five_Laizi...i:%d, bSuc:%s, t:%s", i, tostring(bSuc), vardump(t))
        if bSuc then
            --取最大一个
            for j=#t, 1, -1 do
                local tempCards = {}
                local index = {}
                for _, v in ipairs(t[j]) do
                    table.insert(tempCards, v)
                end
                for k=1, 5-i do
                    table.insert(tempCards, tempCards[1])
                    index[#tempCards] = #tempCards
                end
                
                bFind = true
                table.insert(result, { card = tempCards, index = index })
            end 
        end
    end
    -- LOG_DEBUG("Get_Pt_Five_Laizi...bFind:%s, result:%s", tostring(bFind), vardump(result))
    return bFind, result
end


--同花顺 +鬼牌把所有的能组成的同花顺都找出来了
function libRecomand:Get_Pt_Straight_Flush_Laizi_second(cards, nLaziCount)
    local flush = {}
    --按花色分组:0-3
    LibNormalCardLogic:Sort_By_Color(cards)
    for _, v in ipairs(cards) do
        local color = GetCardColor(v)
        if not flush[color] then
            flush[color] = {}
        end
        table.insert(flush[color], v)
    end

    local result = {}
    local bFind = false
    for color, hash in pairs(flush) do
        if #hash + nLaziCount >= 5 then
            local values = {}
            for i=1, 14 do
                values[i] = 0
            end
            for _, v in ipairs(hash) do
                local val = GetCardValue(v)
                values[val] = values[val] + 1
            end
            values[1] = values[14]

            for i=1, 10 do
                local values2 = Array.Clone(values)
                local straight = true
                local tempLaizi = nLaziCount

                local tempCards = {}
                local index = {}
                for j=1, 5 do
                    if values2[i+j-1] == 0 then
                        if tempLaizi <= 0 then
                            straight = false
                            break
                        else
                            values2[i+j-1] = 1
                            --对A做处理
                            if i + j - 1 == 1 then
                                values2[14] = 1
                            end
                            if i + j - 1 == 14 then
                                values2[1] = 1
                            end
                            tempLaizi = tempLaizi -1
                            index[j] = j
                        end
                    end
                end
                --是顺子
                if straight then
                    for k=1, 5 do
                        --数量-1 防止重用
                        local nv = i+k-1
                        values2[nv] = values2[nv] - 1
                        --对A做处理
                        if nv == 1 then
                            values2[14] = values2[14] - 1
                        end
                        if nv == 14 then
                            values2[1] = values2[1] - 1
                        end
                        if nv == 1 then
                            nv = 14
                        end
                        local nCard = GetCardByColorValue(color, nv)
                        table.insert(tempCards, nCard)
                    end
                    bFind = true
                    table.insert(result, { card = tempCards, index = index })
                    --把所有的鬼牌位置都替换为0
                    for k, v in ipairs(result) do 
                        local Cards = v.card
                        local Index = v.index
                        for k2, v2 in ipairs(Cards) do 
                            if Index[k2] == k2 then
                                Cards[k2] = 0
                            end
                        end
                    end
                    
                end
            end
        end
    end
    --把所有顺子都放入结果集  
    local result1 = {}

    for i=1, #result-1 do
        local temp = false
        local arrCopy1 = {}
        local arrCopy2 = {}
        table.insert(result1, result[i])
        for j=i+1, #result do  
            arrCopy1 = Array.Clone(result[i].card)
            arrCopy2 = Array.Clone(result[j].card)
            Array.DelElements(arrCopy1, arrCopy2)
            if #arrCopy1 == 0 then
                temp = true
                break
            end
        end
        if i == #result - 1 then
            table.insert(result1, result[i+1])
        end
        if temp then
            result1[i].card = {} 
            result1[i].index = {}
        end
    end 
    if #result == 1 then
        table.insert(result1, result[1])
    end
  
    return bFind, result1
end


--4条 +鬼牌把所有的能组成的4条都找出来了
function libRecomand:Get_Pt_Four_Laizi_second(cards, nLaziCount)
    ---result = {{card={1,2,3,4,5}, index={2,3}}, ...}
    local result = {}
    local bFind = false
    local copyCards = cards
    LibNormalCardLogic:Sort(copyCards)
    for i=4, 4-nLaziCount, -1 do
        local bSuc, t = self:Get_Same_nCard_Split(copyCards, i)
        -- LOG_DEBUG("Get_Pt_Four_Laizi...i:%d, bSuc:%s, t:%s", i, tostring(bSuc), vardump(t))
        if bSuc then
            --取所有的四条
           for j=#t, 1, -1 do
                local tempCards = {}
                local index = {}
                for _, v in ipairs(t[j]) do
                    table.insert(tempCards, v)
                end
                for k=1, 4-i do
                    table.insert(tempCards, tempCards[1])
                    index[#tempCards] = #tempCards
                end
                
                bFind = true
                table.insert(result, { card = tempCards, index = index })
            end
        end 
    end
    -- LOG_DEBUG("Get_Pt_Four_Laizi...bFind:%s, result:%s", tostring(bFind), vardump(result))

    return bFind, result
end


--葫芦 +鬼牌
function libRecomand:Get_Pt_Full_Hosue_Laizi_second(cards, nLaziCount)
    local result = {}
    local result1 = {}
    local bFind1 = false
    local stCards = cards
    local bFind = false
  
    bFind1, result1 = libRecomand:Get_Pt_Three_Laizi_second(cards, nLaziCount)
    if bFind1 then
        for k1, v1 in ipairs(result1) do
            local stCards = Array.Clone(cards) 
            local stnLaiziCount = nLaziCount
            local Index1 = v1.index
            local Cards1 = v1.card

            local tempCards1 = {}
            local tempIndex1 = {}
            local count = 0  
            for _,v in pairs(Index1) do  
                count = count + 1  
            end  
           
            stnLaiziCount = stnLaiziCount - count
            for k,v in ipairs(Cards1) do
                table.insert(tempCards1, v)
                if Index1[k] then
                    tempIndex1[k] = Index1[k]
                end
            end
            for k,v in ipairs(Cards1) do
                if tempIndex1[k] then
                    Array.RemoveOne(Cards1, Cards1[k])
                end
            end
          
            
            LibNormalCardLogic:RemoveCard(stCards, Cards1)
            local bFind2, result2 = libRecomand:Get_Pt_One_Pair_Laizi_second(stCards, stnLaiziCount)
            if bFind2 then
                for k2, v2 in ipairs(result2) do
                    local t = v2.card
                    local temp1 = GetCardValue(t[1])
                    local temp2 = GetCardValue(Cards1[1])
                    if temp1 ~= temp2 then
                        local tempCards2 = Array.Clone(tempCards1)
                        local tempIndex2 = {}
                        for k, v in pairs(tempIndex1) do 
                            tempIndex2[k] = v 
                        end
                        --local tempIndex2 = Array.Clone(tempIndex1)
                        local Cards2 = v2.card
                        local Index2 = v2.index
                        for k, v in ipairs(Cards2) do 
                            table.insert(tempCards2, v)
                            if Index2[k] then 
                                tempIndex2[3+k] = 3+k
                            end
                        end
                        local temp1 = GetCardValue(tempCards1[1])
                        local temp2 = GetCardValue(tempCards2[4])
                        if temp1 ~= temp2 then
                            table.insert(result, {card = tempCards2, index = tempIndex2})
                            bFind = true
                        end
                    end
                end
            end
        end
    end
    -- LOG_DEBUG("Get_Pt_Full_Hosue_Laizi...bFind:%s, result:%s", tostring(bFind), vardump(result))
     local result1 = {}

    for i=1, #result-1 do
        local temp = false
        local arrCopy1 = {}
        local arrCopy2 = {}
        table.insert(result1, result[i])
        for j=i+1, #result do  
            arrCopy1 = Array.Clone(result[i].card)
            arrCopy2 = Array.Clone(result[j].card)
            Array.DelElements(arrCopy1, arrCopy2)
            if #arrCopy1 == 0 then
                temp = true
                break
            end
        end
        if i == #result - 1 then
            table.insert(result1, result[i+1])
        end
        if temp then
            result1[i].card = {} 
            result1[i].index = {}
        end
    end 
    if #result == 1 then
        table.insert(result1, result[1])
    end
  
    return bFind, result1
end

--葫芦 +鬼牌
function libRecomand:Get_Pt_Full_Hosue_Laizi_third(cards, nLaziCount)
    local result = {}
    local bFind = false

    local bSuc3, t3 = self:Get_Same_nCard_Split(cards, 3)
    if bSuc3 then           
        for _, v3 in ipairs(t3) do
            local tempCards = {}
            for _, nc1 in ipairs(v3) do
              table.insert(tempCards, nc1)
            end
            
            local bSuc2, t2 = self:Get_Same_nCard_Split(cards, 2)
            if bSuc2 then
                --取所有的三条
                for _, v2 in ipairs(t2) do
                    local tempCards2 = Array.Clone(tempCards)
                    if tempCards[1] ~= v2[1] then
                        for _, nc2 in ipairs(v2) do
                            table.insert(tempCards2, nc2)
                        end
                    end
                    if #tempCards2 >= 5 then
                        bFind = true
                        table.insert(result, { card = tempCards2, index = {} })
                    end          
                end
                
            end
        end
    end
    local bSuc, t = self:Get_Same_nCard_Split(cards, 2)
    if bSuc and #t > 1 and nLaziCount > 0 then
        --取所有的一对
        for k, v1 in ipairs(t) do
            if k+1 <= #t then
                local tempCards = {}
                local index = {}
                for _, v2 in ipairs(t[k]) do
                    table.insert(tempCards, v2)
                end
                for _, v3 in ipairs(t[k+1]) do
                    table.insert(tempCards, v3)
                end
                   --加一张鬼牌
                table.insert(tempCards, tempCards[1])
                index[#tempCards] = #tempCards
                bFind = true
                table.insert(result, { card = tempCards, index = index })
            end
        end
           
    end

    return bFind, result
end

--同花 +鬼牌把所有的能组成的同花都找出来了
function libRecomand:Get_Pt_Flush_Laizi_second(cards, nLaziCount)
    -- LOG_DEBUG("=======Get_Pt_Flush_Laizi======nLaziCount:%d, cards:%s", nLaziCount, vardump(cards))
    local flush = {}
    --按花色分组:0-3
    LibNormalCardLogic:Sort_By_Color(cards)
    for k, v in ipairs(cards) do
        local color = GetCardColor(v)
        if not flush[color] then
            flush[color] = {}
        end
        table.insert(flush[color], v)
    end

    local result = {}
    local bFind = false
    for j, v in pairs(flush) do
        for i=1, nLaziCount do
            table.insert(v, 0)
        end
        libRecomand:Sort(v)
        local tempLaizi = nLaziCount
        if #v >= 5 then
             for i=1, #v - 4 do
                for h=i+1, #v - 3 do
                    for k=h+1, #v - 2 do
                        for l=k+1, #v - 1 do
                            for m=l+1, #v do
                                local tempCards = {}
                                local index = {}
                                table.insert(tempCards, v[i])
                                table.insert(tempCards, v[h])
                                table.insert(tempCards, v[k])
                                table.insert(tempCards, v[l])
                                table.insert(tempCards, v[m])
                                for a=1, #tempCards do
                                    if tempCards[a] == 0 then
                                        index[a] = a
                                    end
                                end
                                bFind = true
                                local temp = true 
                                local stcards = Array.Clone(tempCards)
                                for k, v1 in ipairs(result) do 
                                    local arrCopy = Array.Clone(v1.card)
                                    Array.DelElements(arrCopy, tempCards)
                                    if #arrCopy == 0 then
                                        temp = false
                                    end
                                end
                                if temp then
                                    table.insert(result, { card = tempCards, index = index })
                                end
                                if #result >= 20 then
                                    return bFind, result
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bFind, result
end

--顺子 +鬼牌把所有的能组成的顺子都找出来了
function libRecomand:Get_Pt_Straight_Laizi_second(cards, nLaziCount)
    --设置各个牌值的数量
    local values = {}   --[牌值]=数量
    for i=1, 14 do
        values[i] = 0
    end

    local stColors = {}
    local nColor = 0
    for _, v in ipairs(cards) do
        local val = GetCardValue(v)
        nColor = GetCardColor(v)
        if stColors[val] == nil then
            stColors[val] = {}
        end
        table.insert(stColors[val], v)
        values[val] = values[val] + 1
    end
    values[1] = values[14]

    local result = {}
    local bFind = false

    --A2345
    local bHasA5 = false
    --10JQKA
    local bHasKA = false

    for i=1, 10 do
        local values2 = Array.Clone(values)
        local stColors2 = clone(stColors)
        local straight = true
        local tempLaizi = nLaziCount

        local tempCards = {}
        local index = {}
        for j=1, 5 do
            if values2[i+j-1] == 0 then
                if tempLaizi <= 0 then
                    straight = false
                    break
                else
                    values2[i+j-1] = 1
                    --对A做处理
                    if i + j - 1 == 1 then
                        values2[14] = 1
                    end
                    if i + j - 1 == 14 then
                        values2[1] = 1
                    end
                    tempLaizi = tempLaizi -1
                    index[j] = j
                end
            end
        end
        --是顺子
        if straight then
            if i==1 then
                bHasA5 = true
            end
            if i==10 then
                bHasKA = true
            end

            for k=1, 5 do
                --数量-1 防止重用
                local nv = i+k-1
                values2[nv] = values2[nv] - 1
                --对A做处理
                if nv == 1 then
                    values2[14] = values2[14] - 1
                end
                if nv == 14 then
                    values2[1] = values2[1] - 1
                end
                if nv == 1 then
                    nv = 14
                end

                local nCard = GetCardByColorValue(nColor, nv)
                if stColors2[nv] then
                    nCard = table.remove(stColors2[nv])
                end
                table.insert(tempCards, nCard)
            end

            bFind = true
            table.insert(result, { card = tempCards, index = index })
            --把所有的鬼牌位置都替换为0
            for k, v in ipairs(result) do 
                local Cards = v.card
                local Index = v.index
                for k2, v2 in ipairs(Cards) do 
                    if Index[k2] == k2 then
                        Cards[k2] = 0
                    end
                end
            end
      
        end
    
    end
    --把所有顺子都放入结果集  
    local result1 = {}
    
    for i=1, #result-1 do
        local temp = false
        local arrCopy1 = {}
        local arrCopy2 = {}
        table.insert(result1, result[i])
        for j=i+1, #result do  
            arrCopy1 = Array.Clone(result[i].card)
            arrCopy2 = Array.Clone(result[j].card)
            Array.DelElements(arrCopy1, arrCopy2)
            if #arrCopy1 == 0 then
                temp = true
                break
            end
        end
        if i == #result - 1 then
            table.insert(result1, result[i+1])
        end
        if temp then
            result1[i].card = {} 
            result1[i].index = {}
        end
    end
    if #result == 1 then
        table.insert(result1, result[1])
    end
    return bFind, result1
end

--三条 +鬼牌把所有的能组成的三条都找出来
function libRecomand:Get_Pt_Three_Laizi_second(cards, nLaziCount)
    local result = {}
    local bFind = false
    local copyCards = cards
    LibNormalCardLogic:Sort(copyCards)
    for i=3, 3-nLaziCount, -1 do
        local bSuc, t = self:Get_Same_nCard_Split(copyCards, i)
        if bSuc then  
            --取所有三条
            for j=#t, 1, -1 do
                local tempCards = {}
                local index = {}
                for _, v in ipairs(t[j]) do
                    table.insert(tempCards, v)
                end
                for k=1, 3-i do
                    table.insert(tempCards, 0)
                    index[#tempCards] = #tempCards
                end
                
                bFind = true
                table.insert(result, { card = tempCards, index = index })
            end 
        end
    end

    return bFind, result
end

--2对 +鬼牌把所有的能组成的2对都找出来
function libRecomand:Get_Pt_Two_Pair_Laizi_second(cards, nLaziCount)
    local result = {} 
    local bFind = false
    local tempResult1 = {}
    local tempResult2 = {}
    local nLaiziNum = nLaziCount
    bFind, t = self.Get_Pt_One_Pair_Laizi_second(cards, nLaiziNum)
    if bFind and #t > 1 then
        for i=1, #t-1 do
            tempResult1 = {}
            tempResult2 = {}
            for j=i+1, #t do
                nLaiziNum = nLaziCount
                --取一个
                table.insert(tempResult1, t[i])
                if t[i].index ~= nil then
                    nLaiziNum = nLaiziNum - 1
                end
                if t[j].index == nil then
                    --取第二个
                    table.insert(tempResult2, t[j])
                else
                    if nLaiziNum > 0 then
                        table.insert(tempResult2, t[j])
                    else
                        tempResult1 = {}
                        tempResult2 = {}
                        break
                    end 
                end
                
                bFind = true
                table.insert(result, tempResult1)
                table.insert(result, tempResult2)
            end
        end
    end
    return bFind, result
end

--1对 +鬼牌把所有的能组成的1对都找出来
function libRecomand:Get_Pt_One_Pair_Laizi_second(cards, nLaziCount)
    local result = {}
    local bFind = false
    local copyCards = cards
    local nLaiziNum = nLaziCount

    LibNormalCardLogic:Sort(copyCards)

    for i=2, 1, -1 do
        if nLaiziNum == 0 and i == 1 then
            break
        end
        local bSuc, t = self:Get_Same_nCard_Split(copyCards, i)
        if bSuc then
            --取所有对子
            for j=#t, 1, -1 do
                local tempCards = {}
                local index = {}
                for _, v in ipairs(t[j]) do
                    table.insert(tempCards, v)
                end
                for k=1, 2-i do
                    table.insert(tempCards, 0)
                    index[#tempCards] = #tempCards
                end
                
                bFind = true
                table.insert(result, { card = tempCards, index = index })
            end 
        end
    end
    return bFind, result
end

--换上鬼牌
function libRecomand:Get_Rec_Cards_Laizi(stResult, stLaiziCards)
    local stRecLaiziCards = Array.Clone(stLaiziCards)
    local result = {}
    local t = {}
    for _, v1 in ipairs(stResult) do
        local Card = v1.card
        if #Card ~= 0 then
            stRecLaiziCards =  Array.Clone(stLaiziCards)
            local Cards = v1.card
            local Index = v1.index
            local RecCards = {}
            for k, v2 in ipairs(Cards) do
                if Index[k] and #stRecLaiziCards > 0 then
                    local nLaiziCard = table.remove(stRecLaiziCards)
                    table.insert(RecCards, nLaiziCard)
                else
                    table.insert(RecCards, v2)
                end
            end
            table.insert(result, RecCards)
        end
    end
    return result
end

--获得所有的单张、一对、三条、四条等
function libRecomand:Get_Same_nCard_Split(cards, n)
    local t = {}
    local ret = false
    local bSuc = {}
    local result = {}
    for i=6, 1, -1 do 
        bSuc[i], t[i] = self:Get_Same_Poker(cards, i)
    end
    for j=n, 6 do 
        if bSuc[j] then
            for k, v1 in ipairs(t[j]) do 
                local stCards = {}
                for _, v2 in ipairs(v1) do  
                    table.insert(stCards, v2)
                    if #stCards >= n then
                        ret = true
                        table.insert(result, stCards)
                        break
                    end 
                end  
                
            end
        end
    end
    return ret, result
end



return libRecomand