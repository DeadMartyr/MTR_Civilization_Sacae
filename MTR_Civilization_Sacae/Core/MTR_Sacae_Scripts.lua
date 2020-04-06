-- MTR_Sacae_Scripts
-- Author: Martyr
-- DateCreated: 2020-03-28 12:11:06
--------------------------------------------------------------

--At turn start:
	--Reset information on max distances to zero
	--Record positions of all units for the player whose turn it is
--Upon Unit Moving:
	--Calculate Distance from starting position
		--IF greater than previous maxdistance for that unitID then 
			--HEAL
			--Record maxdistance
		--ELSE DO NOTHING

--====================================================================
--UTILITIES
--Credit: Chrisy15 and LeeS
--====================================================================
--------
--Created by Chrisy15, didn't retool as it functions exactly the way I need it
--------
function MTR_getValidPlayersWithTrait(sTrait)
	local tValidPlayers = {}
	
	for k, v in ipairs(PlayerManager.GetWasEverAliveIDs()) do
		local leaderType = PlayerConfigurations[v]:GetLeaderTypeName()
        for trait in GameInfo.LeaderTraits() do
            if trait.LeaderType == leaderType and trait.TraitType == sTrait then 
                tValidPlayers[v] = true 
            end;
        end
        if not tValidPlayers[v] then
            local civType = PlayerConfigurations[v]:GetCivilizationTypeName()
            for trait in GameInfo.CivilizationTraits() do
                if trait.CivilizationType == civType and trait.TraitType == sTrait then 
                    tValidPlayers[v] = true 
                end;
            end
        end
    end
    return tValidPlayers
end



--------
--Created by LeeS, didn't retool as it functions exactly the way I need it
--------
function UnitIsCombatUnit(pUnit, bConsiderReligious)
	if (pUnit ~= nil) then
		local tUnitData = GameInfo.Units[pUnit:GetType()]
		if (tUnitData ~= nil) then
			if (tUnitData.Combat > 0) or (tUnitData.RangedCombat > 0) or (tUnitData.Bombard > 0) then
				return true
			elseif (bConsiderReligious == true) then
				if (tUnitData.ReligiousStrength > 0) and ((tUnitData.PromotionClass == "PROMOTION_CLASS_APOSTLE") or (tUnitData.PromotionClass == "PROMOTION_CLASS_INQUISITOR")) then
					return true
				end
			end
		end
	end
	return false
end

----------------------------------------------
--My custom method that generates a table of Unit Types with tags for the Classes it's meant to affect
----------------------------------------------
function MTR_getValidUnits()
	local tTable = {}
	print("SELECT Type, Tag FROM TypeTags WHERE (Type NOT NULL OR Tag NOT NULL) AND Tag = 'CLASS_LIGHT_CAVALRY'");
	local tQuery = DB.Query("SELECT Type, Tag FROM TypeTags WHERE (Type NOT NULL OR Tag NOT NULL) AND Tag = 'CLASS_LIGHT_CAVALRY'");
	print("Query Results");
	print(tQuery);
	for k, v in ipairs(tQuery) do
		tTable[v.Type] = true;
		print("ValidUnit:");
		print(v.Type);
	end
	
	print("SELECT Type, Tag FROM TypeTags WHERE (Type NOT NULL OR Tag NOT NULL) AND Tag = 'CLASS_HEAVY_CAVALRY'");
	tQuery = DB.Query("SELECT Type, Tag FROM TypeTags WHERE (Type NOT NULL OR Tag NOT NULL) AND Tag = 'CLASS_HEAVY_CAVALRY'");
	print("Query Results");
	print(tQuery);
	for k, v in ipairs(tQuery) do
		tTable[v.Type] = true;
		print("ValidUnit:");
		print(v.Type);
	end
	
	print("SELECT Type, Tag FROM TypeTags WHERE (Type NOT NULL OR Tag NOT NULL) AND Tag = 'CLASS_RANGED_CAVALRY'");
	tQuery = DB.Query("SELECT Type, Tag FROM TypeTags WHERE (Type NOT NULL OR Tag NOT NULL) AND Tag = 'CLASS_RANGED_CAVALRY'");
	print("Query Results");
	print(tQuery);
	for k, v in ipairs(tQuery) do
		tTable[v.Type] = true;
		print("ValidUnit:");
		print(v.Type);
	end
	return tTable;
end
----------------------------------------------

--====================================================================



--====================================================================
--Constants
--====================================================================

	local sTrait = "TRAIT_CIVILIZATION_MTR_SACAE_UA";
	local tValidPlayerList = MTR_getValidPlayersWithTrait(sTrait); --Key is PlayerID, returns true or nil based on what MTR_getValidPlayersWithTrait returns
	local tValidUnitList = MTR_getValidUnits(); --Table containing all UnitTypes that are Cavalry
	
	local tUnitStartPoses = {}; -- [player][unit] -> {X, Y}
	local iUnitMaxDistancesCovered = {}; --array of array of integers [player][unit] -> int 
	
	local iHealPerSpaceBase = 10;
	--local iHealScaling = 1.3; --Scaling with distance or diminishing returns can be changed here IMPLEMENT LATER



--====================================================================
-- Custom Functions
--====================================================================



function MTR_CalculateTraveledDistance(iPlayerID, iUnitID, iX, iY) --Calculates traveled distance from starting position
		print("MTR_CalculateTraveledDistance")
		local aX = tUnitStartPoses[iPlayerID][iUnitID].X; 
		local aY = tUnitStartPoses[iPlayerID][iUnitID].Y;
		
		local iDistance = Map.GetPlotDistance(iX, iY, aX, aY)--math.sqrt((aX-iX)^2-(aY-iY)^2);
		print("Distance: ");
		print(iDistance);
		return iDistance;
end


function MTR_ApplyHeal(iPlayerID, iUnitID, iNewDistance, iOldDistance)
		print("MTR_ApplyHeal")
		local iNewHeal = iHealPerSpaceBase*iNewDistance;
		local iOldHeal = iHealPerSpaceBase*iOldDistance;
		print("UnitID: ");
		print(iUnitID);
		print("newHeal: ");
		print(iNewHeal);
		print("oldHeal: ");
		print(iOldHeal);
		
		local pUnit = Players[iPlayerID]:GetUnits():FindID(iUnitID);
		pUnit:ChangeDamage(-1*(iNewHeal-iOldHeal)); --negative damage is healing, positive is damage, set to positive right now for testing purposes
		print("Heal Applied");
		iUnitMaxDistancesCovered[iPlayerID][iUnitID] = iNewDistance;--records maxdistance
		print("Set unit Max Distance: ");
		print(iUnitMaxDistancesCovered[iPlayerID][iUnitID]);
end


--------
--Based off LeeS' work
--------
function MTR_ResetDistances(iPlayerID)
	print("MTR_ResetDistances")
	if tValidPlayerList[iPlayerID] then
		iUnitMaxDistancesCovered[iPlayerID] = {}
		print("PlayerID: ");
		print(iPlayerID);
		local pPlayer = Players[iPlayerID]
		for i,pUnit in pPlayer:GetUnits():Members() do
			print("UnitID: ");
			print(pUnit:GetID());
			iUnitMaxDistancesCovered[iPlayerID][pUnit:GetID()] = 0;
			print("Distance Reset to 0");
			print(iUnitMaxDistancesCovered[iPlayerID][pUnit:GetID()]);
		end
	end
end
function MTR_ResetStartPoses(iPlayerID)
	print("MTR_ResetStartPoses")
	if tValidPlayerList[iPlayerID] then
		tUnitStartPoses[iPlayerID] = {}
		print("PlayerID: ");
		print(iPlayerID);
		local pPlayer = Players[iPlayerID]
		for i,pUnit in pPlayer:GetUnits():Members() do
			print("UnitID: ");
			print(pUnit:GetID());
			tUnitStartPoses[iPlayerID][pUnit:GetID()] = {X = 0, Y = 0};
			print("Pos Reset to 0,0")
		end
	end
end

--------
--Retooled from LeeS, changed to return a table instead of directly setting the values on an existing table
--Can be used like this at multiple stages now, and doesn't need clutter from "bIsFirstTimeThisTurn"
--------
function MTR_GetUnitPositions(iPlayerID)
	print("MTR_GetUnitPositions")
	local tUnitPoses = {}

	if tValidPlayerList[iPlayerID] then
		tUnitPoses[iPlayerID] = {}
		print("PlayerID: ");
		print(iPlayerID);
		local pPlayer = Players[iPlayerID]
		for i,pUnit in pPlayer:GetUnits():Members() do
			print("UnitID: ");
			print(pUnit:GetID());
			tUnitPoses[iPlayerID][pUnit:GetID()] = {X = pUnit:GetX(), Y = pUnit:GetY()}
			print("Unit X: ");
			print(pUnit:GetX());
			print("Unit Y: ");
			print(pUnit:GetY());
		end
	end
	return tUnitPoses[iPlayerID]--Returns the table for that playerID
end




--====================================================================
--Runs at turn start
--Essentially just calls the Utilities as long as it's not called more than once
--====================================================================
function MTR_PlayerTurnActivated(iPlayerID, bIsFirstTimeThisTurn)
	print("Player Turn Activated");
	if (tValidPlayerList[iPlayerID] ~= true) then return end --abort if not ValidPlayer
	print("Is ValidPlayer")
	if (bIsFirstTimeThisTurn == false) then return end --abort if not first time this turn
	print("Is FirstTime")
	
	
	MTR_ResetStartPoses(iPlayerID);--resets values for this player to zero
	MTR_ResetDistances(iPlayerID);--resets values for this player to zero
	tUnitStartPoses[iPlayerID] = MTR_GetUnitPositions(iPlayerID);--SetPlayerPositions (specific for that playerID)
end

--====================================================================
--Runs when player unit moves
--====================================================================
function MTR_SacaeUA_UnitMoved(iPlayerID, iUnitID, iX, iY, locallyVisible, stateChange)
	print("Unit Moved Proc:");
	if (tValidPlayerList[iPlayerID] ~= true) then return end --abort if not ValidPlayer
	print("Unit is from ValidPlayer");
	local pPlayer = Players[iPlayerID];
	local pUnit = pPlayer:GetUnits():FindID(iUnitID);
	local sType = GameInfo.Units[pUnit:GetType()].UnitType
	print("UnitType: ");
	print(sType);
	print("UnitId: ");
	print(iUnitID);
	if (tValidUnitList[sType] ~= true) then return end --abort if not valid UnitType
	print("Valid UnitType");
	
	
	local iNewDistance = MTR_CalculateTraveledDistance(iPlayerID, iUnitID, iX, iY);
	
	print("iUnitMaxDistancesCovered[iPlayerID][UnitID] :")
	print(iUnitMaxDistancesCovered[iPlayerID][iUnitID]);
	if (iUnitMaxDistancesCovered[iPlayerID][iUnitID] == nil) then --Safety if value doesn't exist
		iUnitMaxDistancesCovered[iPlayerID][iUnitID] = 0;
		print("iOldDistance set to 0 because iUnitMaxDistancesCovered[iPlayerID][pUnit:GetID()] was nil");
	end
	iOldDistance = iUnitMaxDistancesCovered[iPlayerID][iUnitID];
	
	print("NewDist: "); 
	print(iNewDistance);
	print("OldDist: ");
	print(iOldDistance);
	if (iNewDistance > iOldDistance) then --getting error for comparing number to nil here
		print("NewDist is greater than OldDist!")
		MTR_ApplyHeal(iPlayerID, iUnitID, iNewDistance, iOldDistance);
		print("Double Checking Max Distance: ");
		print(iUnitMaxDistancesCovered[iPlayerID][iUnitID]);
	end
	--else do nothing
end

--====================================================================
--Inputting Functions into the Game Events (This is what I think this does)
--====================================================================
Events.PlayerTurnActivated.Add(MTR_PlayerTurnActivated);
Events.UnitMoved.Add(MTR_SacaeUA_UnitMoved);
