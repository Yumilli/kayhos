local KayhosMod = RegisterMod("Kayhos Mod", 1)

local kayhosChar = Isaac.GetPlayerTypeByName("Kayhos", false)

local nullcostume = Isaac.GetCostumeIdByPath("gfx/characters/kayhos_null_costume.anm2")
function KayhosMod:PlayerInit(player)
   if player:GetPlayerType() == kayhosChar then
      player:AddNullCostume(nullcostume)
      local pSprite = player:GetSprite()
      pSprite:Load("gfx/characters/kayhos_animation.anm2", true)
   end
end
KayhosMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, KayhosMod.PlayerInit)

local altar_item = Isaac.GetItemIdByName("Chaotic Altar")
if EID then
   local icons = Sprite()
   icons:Load("gfx/characters/EIDBirthrgith.anm2", true)
   EID:addIcon("Player"..kayhosChar, "Idle", 0, 16, 16, 5, 7, icons)
   EID:addBirthright(kayhosChar, "#It lets you choose between two options")
   EID:addCollectible(altar_item, "#{{ColorRed}}Sacrifice{{CR}} a random item to spawn a completely random one")
   EID:addCollectible(402, "All items are chosen from random item pools#Spawns 1-6 random pickups", "Kayhos", "en_us")
end

local RecentItem = {}
local birthright = 1
local json = require("json")
--Run open
function KayhosMod:OnRunStart(continue)
   if continue == true then
      if KayhosMod:HasData() then
         RecentItem = json.decode(KayhosMod:LoadData())
      end
   else
      RecentItem = {}
   end
   Isaac.GetItemConfig():GetCollectible(altar_item).GfxFileName = "gfx/items/collectibles/Chaotic Altar.png"
   for i = 0, Game():GetNumPlayers() - 1, 1 do
      local player = Isaac.GetPlayer(i)
      if player:HasCollectible(altar_item) and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
         Isaac.GetItemConfig():GetCollectible(altar_item).GfxFileName = "gfx/items/collectibles/Golden Chaotic Altar.png"
      end
   end
end
--Run close
function KayhosMod:OnRunExit()
   KayhosMod:SaveData(json.encode(RecentItem))
end
--Save the recent item
local exception_items = {619, 327, 328, 238, 239, 626, 627, 668}
function KayhosMod:GetItems(item, _, _, _, _, player)
   if Isaac.GetItemConfig():GetCollectible(item).Type == 3 then return end
   if player:GetPlayerType() == kayhosChar then
      if item == 402 then player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_CHAOS)) return end
      if item == 619 then Isaac.GetItemConfig():GetCollectible(altar_item).GfxFileName = "gfx/items/collectibles/Golden Chaotic Altar.png" end
   end
   for i = 1, 8, 1 do if item == exception_items[i] then return end end
   table.insert(RecentItem, item)
end
KayhosMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, KayhosMod.OnRunStart)
KayhosMod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, KayhosMod.OnRunExit)
KayhosMod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, KayhosMod.GetItems)

local item_pools = {ItemPoolType.POOL_TREASURE, ItemPoolType.POOL_SHOP, ItemPoolType.POOL_BOSS, ItemPoolType.POOL_SECRET, ItemPoolType.POOL_DEVIL, ItemPoolType.POOL_ANGEL, ItemPoolType.POOL_PLANETARIUM}
local active = false
local delay = 0
local used = false
local item_removed = {}
local removed_sprite = Sprite()
removed_sprite:Load("gfx/items/sacrificed item.anm2", false)
removed_sprite:Play("Idle")
function TableSize(list)
   local count = 0
   for _ in pairs(list) do count = count + 1 end
   return count
end
function KayhosMod:ActiveItem(_, _, player)
   if TableSize(RecentItem) == 0 then return {ShowAnim = true} end
   local random_item = math.random(TableSize(RecentItem))
   while not player:HasCollectible(RecentItem[random_item]) do
      random_item = math.random(TableSize(RecentItem))
   end
   local item_to_remove = RecentItem[random_item]
   player:RemoveCollectible(item_to_remove)
   table.remove(RecentItem, random_item)
   if player:GetPlayerType() == kayhosChar and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then birthright = 2 end
   local pickup_options = -1
   for num = 1, birthright, 1 do
      local random_result = math.random(100) - 1 + math.random(10) * 0.1 - 0.1
      local item_pool = 0
      if random_result <= 55.7 then item_pool = 1 elseif random_result <= 66.3 then item_pool = 5 elseif random_result <= 75.6 then item_pool = 3 elseif random_result <= 83.5 then item_pool = 6 elseif random_result <= 91.5 then item_pool = 2 elseif random_result <= 98.2 then item_pool = 4 else item_pool = 7 end
      local item_to_spawn = Game():GetItemPool():GetCollectible(item_pools[item_pool], false, Random(), CollectibleType.COLLECTIBLE_NULL)
      while Isaac.GetItemConfig():GetCollectible(item_to_spawn).Type == 3 do
         item_to_spawn = Game():GetItemPool():GetCollectible(item_pools[item_pool], false, Random(), CollectibleType.COLLECTIBLE_NULL)
      end
      Game():GetItemPool():RemoveCollectible(item_to_spawn)
      SFXManager():Play(SoundEffect.SOUND_DOGMA_ANGEL_TRANSFORM)
      local pos = player.Position
      if birthright == 2 then pos = player.Position - Vector(40, 0) end
      if num == 1 then
         local item = Game():Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, Isaac.GetFreeNearPosition(pos, 40), Vector.Zero, nil, item_to_spawn, Game():GetRoom():GetSpawnSeed()):ToPickup()
         item.OptionsPickupIndex = item.Index
         pickup_options = item.OptionsPickupIndex
      elseif num == 2 then
         Game():Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, Isaac.GetFreeNearPosition(player.Position + Vector(40, 0), 40), Vector.Zero, nil, item_to_spawn, Game():GetRoom():GetSpawnSeed()):ToPickup().OptionsPickupIndex = pickup_options
      end
      birthright = 1
   end
   if active == false then while TableSize(item_removed) > 0 do table.remove(item_removed, 1) end end
   table.insert(item_removed, item_to_remove)
   active = true
   delay = 0
   used = true
   removed_sprite.Rotation = 0
   removed_sprite.Scale = Vector.One
   return {ShowAnim = true}
end
KayhosMod:AddCallback(ModCallbacks.MC_USE_ITEM, KayhosMod.ActiveItem, altar_item)

function KayhosMod:ShowRemovedItem(player)
   if used == false then return end
   if delay < 2 then delay = delay + 1 else active = false end
   if not Game():IsPaused() then
      removed_sprite.Rotation = removed_sprite.Rotation + 15
      removed_sprite.Scale = removed_sprite.Scale - Vector(0.03, 0.03)
   end
   if removed_sprite.Scale.X > 0 then
      for i = 1, TableSize(item_removed), 1 do
         removed_sprite:ReplaceSpritesheet(0, Isaac.GetItemConfig():GetCollectible(item_removed[i]).GfxFileName, true)
         removed_sprite:Render(Isaac.WorldToScreen(player.Position) - Vector((TableSize(item_removed) - 1) * 12 - (i - 1) * 23, 60), Vector.Zero, Vector.Zero)
      end
   end
end
KayhosMod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, KayhosMod.ShowRemovedItem)

local altar_sprite = Sprite()
altar_sprite:Load("gfx/items/chaotic altar.anm2", true)
function KayhosMod:TakeBirthrightSprite(player, slot, offset, _, scale)
   if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and player:GetPlayerType() == kayhosChar and player:GetActiveItem(slot) == altar_item then
      altar_sprite.Scale = Vector(scale, scale)
      altar_sprite:SetFrame("Idle", 1)
      altar_sprite:Render(Vector(16, 16) * scale + offset)
   end
end
KayhosMod:AddCallback(ModCallbacks.MC_POST_PLAYERHUD_RENDER_ACTIVE_ITEM, KayhosMod.TakeBirthrightSprite)