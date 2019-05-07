local assets = {
    Asset("ANIM", "anim/wilburncrown.zip"),
    Asset("IMAGE", "images/inventoryimages/wilburncrown.tex"),
    Asset("ATLAS", "images/inventoryimages/wilburncrown.xml"),
}

	local function onequip(inst, owner)
        owner.AnimState:OverrideSymbol("swap_hat", "wilburncrown", "swap_hat")
        owner.AnimState:Show("HAT")
        owner.AnimState:Hide("HAT_HAIR")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")
        
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAIR")

        --add bloom effect
        owner.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

        --allow monster leadership
        if owner.prefab ~= "webber" then
            --Webber already has this one
            owner:AddTag("spiderwhisperer")
        end
        owner:AddTag("houndwhisperer")
    end

	local function onunequip(inst, owner)
        owner.AnimState:Hide("HAT")
        owner.AnimState:Hide("HAT_HAIR")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")
        if owner:HasTag("player") then
            owner.AnimState:Show("HEAD")
            owner.AnimState:Hide("HEAD_HAIR")
        end

        --remove bloom effect... only if no other item applies bloom effect on character.
        local bodyitem = nil
        if owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) then
            bodyitem = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY).prefab
        end
        if not (bodyitem and bodyitem == "yellowamulet") and not owner.wormlight then
            owner.AnimState:ClearBloomEffectHandle()
        end

        --unallow monster leadership
        if owner.prefab ~= "webber" then
            --if you're Webber, you should NOT lose the spiderwhisperer tag on removing the crown, that would be a disaster
            owner:RemoveTag("spiderwhisperer")
        end
        owner:RemoveTag("houndwhisperer")

        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        if owner and owner.components.leader then
            --remove the companion tag for hounds
            for k,v in pairs(owner.components.leader.followers) do
                if k.components.combat and k.components.follower then
                    k:RemoveTag("companion")
                end
            end
            --remove all spider and hound followers
            if owner.prefab ~= "webber" then
                --(if you're Webber, you shouldn't lose your spiders on removing the crown)
                owner.components.leader:RemoveFollowersByTag("spider")
            end
            owner.components.leader:RemoveFollowersByTag("hound") 
        end
    end

	local function fn(Sim)
        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local anim = inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        
        inst:AddTag("wilburncrown")

        anim:SetBank("wilburncrown")
        anim:SetBuild("wilburncrown")
        anim:PlayAnimation("idle")

        if not TheWorld.ismastersim then
            return inst
        end
        inst.entity:SetPristine()

        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh") 
          
        inst:AddComponent("inspectable")
       
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/wilburncrown.xml"

        inst:AddComponent("tradable")

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
        
        inst.components.equippable:SetOnEquip( onequip )
        inst.components.equippable:SetOnUnequip( onunequip )

        MakeHauntableLaunch(inst)

        return inst
    end

return Prefab( "common/inventory/wilburncrown", fn, assets)
