-- 牌的表达 用数字标识每种牌的

CARD_BEGIN      = 1     -- 循环时用
-- 万字牌
CARD_CHAR_1     = 1
CARD_CHAR_2     = 2
CARD_CHAR_3     = 3
CARD_CHAR_4     = 4
CARD_CHAR_5     = 5
CARD_CHAR_6     = 6
CARD_CHAR_7     = 7
CARD_CHAR_8     = 8
CARD_CHAR_9     = 9
-- 条字牌
CARD_BAMBOO_1   = 11
CARD_BAMBOO_2   = 12
CARD_BAMBOO_3   = 13
CARD_BAMBOO_4   = 14
CARD_BAMBOO_5   = 15
CARD_BAMBOO_6   = 16
CARD_BAMBOO_7   = 17
CARD_BAMBOO_8   = 18
CARD_BAMBOO_9   = 19
-- 筒子牌
CARD_BALL_1     = 21
CARD_BALL_2     = 22
CARD_BALL_3     = 23
CARD_BALL_4     = 24
CARD_BALL_5     = 25
CARD_BALL_6     = 26
CARD_BALL_7     = 27
CARD_BALL_8     = 28
CARD_BALL_9     = 29
-- 风牌
CARD_EAST       = 31
CARD_SOUTH      = 32
CARD_WEST       = 33
CARD_NORTH      = 34
CARD_ZHONG      = 35
-- 發
CARD_FA         = 36
-- 白
CARD_BAI        = 37
-- 花牌
CARD_FLOWER_CHUN    = 41
CARD_FLOWER_XIA     = 42
CARD_FLOWER_QIU     = 43
CARD_FLOWER_DONG    = 44
CARD_FLOWER_MEI     = 45
CARD_FLOWER_LAN     = 46
CARD_FLOWER_ZHU     = 47
CARD_FLOWER_JU      = 48
CARD_END            = 48        -- 循环时用


--定义吃、碰、杠
-- ACTION_EMPTY                = 0x0
-- ACTION_COLLECT              = 0x10
-- ACTION_TRIPLET              = 0x11
-- ACTION_QUADRUPLET           = 0x12      -- 明杠
-- ACTION_QUADRUPLET_CONCEALED = 0x13      -- 暗杠
-- ACTION_QUADRUPLET_REVEALED  = 0x14      -- 被杠
-- ACTION_WIN                  = 0x15
-- ACTION_TING                 = 0x16
-- ACTION_FLOWER               = 0x17


CARDTYPE_NONE = 0     -- 错误的牌
CARDTYPE_CHAR = 1     -- 万字牌
CARDTYPE_BAMBOO = 2   -- 条字牌
CARDTYPE_BALL = 3     -- 筒子牌
CARDTYPE_WIND = 4     -- 风牌
CARDTYPE_FA = 5       -- 發
CARDTYPE_BAI = 6      -- 白
CARDTYPE_FLOWER  = 7  -- 花牌

function GetCardType(nCard)
    if nCard >=CARD_CHAR_1 and nCard <= CARD_CHAR_9 then
        return CARDTYPE_CHAR
    elseif nCard >=CARD_BAMBOO_1 and nCard <= CARD_BAMBOO_9 then
        return CARDTYPE_BAMBOO
    elseif nCard >=CARD_BALL_1 and nCard <= CARD_BALL_9 then
        return CARDTYPE_BALL
    elseif nCard >=CARD_EAST and nCard <= CARD_ZHONG then
        return CARDTYPE_WIND
    elseif nCard == CARD_FA then
        return CARDTYPE_FA
    elseif nCard == CARD_BAI then
        return CARDTYPE_BAI
    elseif nCard >=CARD_FLOWER_CHUN and nCard <= CARD_FLOWER_JU then
        return CARDTYPE_FLOWER
    end
    return CARDTYPE_NONE
end

