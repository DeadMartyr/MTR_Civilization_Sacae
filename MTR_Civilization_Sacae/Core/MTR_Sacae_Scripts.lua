-- MTR_Sacae_Scripts
-- Author: Angelo
-- DateCreated: 2020-03-28 12:11:06
--------------------------------------------------------------

--NOTE
--It's been a while since I've used lua, i remember that you still declared variables with datatypes(int, String, etc)
--but the file im referencing doesn't so I'm writing it with the same syntax
--I've used java for a while and this hurts writing without "(" and ")" and ";"


--CONCERNS
--Are theres variables unique to each unit?
	--If not would I have to make a table with the unit's unitID and the corresponding variables I need?
--How do I even query data? I don't actually know what Object/function/anything to call

--------------------------------------------------------------------------
--UTILITIES
--------------------------------------------------------------------------
function MTR_ValidTrait(sTrait)
		local tValid = {}
		----------------
		--Chrisy's Vodoo Magic to get array of all players with Trait
		----------------
		return tValid;
end

function MTR_CalculateDistance(aPosX, aPosY, bPosX, bPosY)
		-----------------------------------------------------------------
		--VODOO MAGIC TO GET DISTANCE AND RETURN IT AS INTEGER
		-----------------------------------------------------------------------
end

function MTR_ApplyHeal(newDistance, oldDistance)
		------------------------------------------------------------
		--Heal if you moved extra distance away, 
		--making sure to not heal for distance that was already applied before
		--
		--Assumes newDistance > oldDistance
		-------------------------------------------------------------
end

--------------------------------------------------------------------------
--Constants
--------------------------------------------------------------------------

	--Dunno if I need this, but I don't know how else the game is gonna know what units this'll apply to
	local sTrait = "TRAIT_CIVILIZATION_MTR_SACAE_UA";
	local tTraitPlayers = MTR_ValidTrait(sTrait);


    --At start of turn this will be set, does not need to be defined here, just ensure that at turn start it sets this to whereever the unit is
	local startPosX;
	local startPosY;
	
	--At start resets to zero, upon the unit moving another function calculates distance the unit is from where it started that turn, 
	--if it's bigger than this, it'll set this to what distance it has and heal accordingly.
	--i.e. if i move two spaces away heal me 10, if i move 1 space back to where i started, 
	--i dont heal, if i move 2 more tiles away then im 3 tiles away and heal me an additional 5
	local maxDistanceCoveredThisTurn;
	
	local healPerSpaceBase = 5;
	local healScaling = 1.3; --Scaling with distance or diminishing returns can be changed here


--------------------------------------------------------------------------
--Runs at turn start
--------------------------------------------------------------------------
function MTR_SacaeUA_TurnStart()
	--Record Position at start of turn
	startPosX = --GetUnitPosX();
	startPosY = --GetUnitPosY();
	--Reset distance to zero
	maxDistanceCoveredThisTurn = 0;
end

--------------------------------------------------------------------------
--Runs when player unit moves
--------------------------------------------------------------------------
function MTR_SacaeUA_UnitMove()
	local currentPosX = --GetUnitPosX();
	local currentPosY = --GetUnitPosY();

	local currentDistanceCovered = MTR_CalculateDistance(startPosX, startPosY, currentPosX, currentPosY);

	if (currentDistanceCovered > maxDistanceCoveredThisTurn)
		MTR_ApplyHeal(currentDistanceCovered, maxDistanceCovered);
		maxDistanceCovered = currentDistanceCovered;
	end
	else
		--DO NOTHING;
	end
end

-------------------------------------------------
--Inputting Functions into the Game Events (This is what I think this does)
-------------------------------------------------
Events.TurnBegin.Add(MTR_SacaeUA_TurnStart());
Events.UnitMoved.Add(MTR_SacaeUA_UnitMove());





--------------------------------------------------------------
--UNIT HEALS BY MOVING
--
--IDEAS:
--  1) As soon as move, heal based on moves used
--	ref: 
--  Lua objects: GetMaxMoves and GetExtraMoves
--  Events: UnitMovementPointsChanged /UnitMovementPointsCleared (not this one)
--		Pros:
--			+Directly visible and apparent, flashy
--			+Easy to implement
--		Cons:
--			-Would have to be insignificant amount or else people would move to heal and come back to same spot and then attack, it'd be really annoying to fight
--
--
--	2) At turn end, heal based on moves used
--	ref: 
--  Lua objects: GetMaxMoves and GetExtraMoves
--  Events: TurnEnd
--		Pros: 
--			+Easy to implement
--			+Could be up-d as it would be less cheesy to happen at the end of the turn
--		Cons:
--			-Loses flashiness, like you might as well just give them the march promotion
--			-**MAJOR**, if attacking reduces units moves to 0, this basically just gives all calvary a heal no matter what action they take, could be stationary and shoot and get the heal
--			-Still cheesy as people could move to use the moves and then just go back to same spot
--
--
--	3) At turn end, heal based on distance covered
--	ref: 
--  Lua objects: GetLocation
--  Events: TurnEnd TurnBegin // UnitMoved, UnitMoveComplete, UnitMovementPointsChanged
--		Pros:
--			+Best reflects what I'm trying to do
--			+Woods and hills wood restrict movement and therefore the healing directly, gives a clear weakness, and because of this can be more impactful on flat terrain
--			+Prevents cheese with moving out and into the same tile to get the heal
--		Cons:
--			-Most difficult to implement
--				Need to figure out how to get starting location at start of turn and then ending location at end of turn and apply heal based on the distance between the two
--			-Cannot be set to whenever you move, otherwise the cheese with "move out two spaces, move back two spaces, get heal" is still an issue
--				+POTENTIALLY, can make it so if it remembers where you started at the start of the turn and if you move X away from it, then it heals you for that amount, but not anymore if you move back closer to it, only if you go farther
--			-Because of above, it loses a bit of flashiness UNLESS that idea can be ironed out, then it reflects the idea even better than idea number 1
--
--
-- GOING WITH IDEA 3
--------------------------------------------------------------------------