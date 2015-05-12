// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Version: 1.0
//	@file Name: setupStoreNPC.sqf
//	@file Author: AgentRev
//	@file Created: 12/10/2013 12:36
//  GunStore redesigned by Motavar@judgement.net


#define STORE_ACTION_CONDITION "(player distance _target < 4)"
#define SELL_CRATE_CONDITION "(!isNil 'R3F_LOG_joueur_deplace_objet' && {R3F_LOG_joueur_deplace_objet isKindOf 'ReammoBox_F'})"
#define SELL_CONTENTS_CONDITION "(!isNil 'R3F_LOG_joueur_deplace_objet' && {{R3F_LOG_joueur_deplace_objet isKindOf _x} count ['ReammoBox_F','AllVehicles'] > 0})"
#define SELL_VEH_CONTENTS_CONDITION "{!isNull objectFromNetId (player getVariable ['lastVehicleRidden', ''])}"
#define SELL_BIN_CONDITION "(cursorTarget == _target)"

private ["_npc", "_npcName", "_startsWith", "_building"];

_npc = _this select 0;
_npcName = vehicleVarName _npc;
_npc setName [_npcName,"",""];

_npc allowDamage false;
{ _npc disableAI _x } forEach ["MOVE","FSM","TARGET","AUTOTARGET"];

if (hasInterface) then
{
	_startsWith =
	{
		private ["_needle", "_testArr"];
		_needle = _this select 0;
		_testArr = toArray (_this select 1);
		_testArr resize count toArray _needle;
		(toString _testArr == _needle)
	};

	switch (true) do
	{
		case (["GenStore", _npcName] call _startsWith):
		{
			_npc addAction ["<img image='client\icons\store.paa'/> Open General Store", "client\systems\generalStore\loadGenStore.sqf", [], 1, true, true, "", STORE_ACTION_CONDITION];
		};
		case (["GunStore", _npcName] call _startsWith):
		{
			_npc addAction ["<img image='client\icons\store.paa'/> Open Gun Store", "client\systems\gunStore\loadgunStore.sqf", [], 1, true, true, "", STORE_ACTION_CONDITION];
		};
		case (["VehStore", _npcName] call _startsWith):
		{
			_npc addAction ["<img image='client\icons\store.paa'/> Open Vehicle Store", "client\systems\vehicleStore\loadVehicleStore.sqf", [], 1, true, true, "", STORE_ACTION_CONDITION];
		};
	};

	_npc addAction ["<img image='client\icons\money.paa'/> Sell crate", "client\systems\selling\sellCrateItems.sqf", [false, false, true], 0.99, false, true, "", STORE_ACTION_CONDITION + " && " + SELL_CRATE_CONDITION];
	_npc addAction ["<img image='client\icons\money.paa'/> Sell contents", "client\systems\selling\sellCrateItems.sqf", [], 0.98, false, true, "", STORE_ACTION_CONDITION + " && " + SELL_CONTENTS_CONDITION];
	_npc addAction ["<img image='client\icons\money.paa'/> Sell last vehicle contents", "client\systems\selling\sellVehicleItems.sqf", [], 0.97, false, true, "", STORE_ACTION_CONDITION + " && " + SELL_VEH_CONTENTS_CONDITION];
};

if (isServer) then
{
	_building = nearestBuilding _npc;

	_npc setVariable ["storeNPC_nearestBuilding", netId _building, true];

	_facesCfg = configFile >> "CfgFaces" >> "Man_A3";
	_faces = [];

	for "_i" from 0 to (count _facesCfg - 1) do
	{
		_faceCfg = _facesCfg select _i;

		_faceTex = toArray getText (_faceCfg >> "texture");
		_faceTex resize 1;
		_faceTex = toString _faceTex;

		if (_faceTex == "\") then
		{
			_faces pushBack configName _faceCfg;
		};
	};

	_face = _faces call BIS_fnc_selectRandom;
	_npc setFace _face;
	_npc setVariable ["storeNPC_face", _face, true];
}
else
{
	private "_nearestBuilding";

	waitUntil
	{
		sleep 0.1;
		_nearestBuilding = _npc getVariable "storeNPC_nearestBuilding";
		!isNil "_nearestBuilding"
	};

	_building = objectFromNetId _nearestBuilding;
};

if (isNil "_building" || {isNull _building}) then
{
	_building = nearestBuilding _npc;
};

_building allowDamage true;
for "_i" from 1 to 99 do { _building setHit ["glass_" + str _i, 1] }; // pre-break the windows so people can shoot thru them
_building allowDamage false; // disable building damage

if (isServer) then
{
	removeAllWeapons _npc;

	waitUntil {!isNil "storeConfigDone"};

	{
		if (_x select 0 == _npcName) exitWith
		{
			private "_frontOffset";

			//collect our arguments
			_npcPos = _x select 1;
			_deskDirMod = _x select 2;

			if (typeName _deskDirMod == "ARRAY" && {count _deskDirMod > 0}) then
			{
				if (count _deskDirMod > 1) then
				{
					_frontOffset = _deskDirMod select 1;
				};

				_deskDirMod = _deskDirMod select 0;
			};

			_storeOwnerAppearance = [];

			{
				if (_x select 0 == _npcName) exitWith
				{
					_storeOwnerAppearance = _x select 1;
				};
			} forEach (call storeOwnerConfigAppearance);

			{
				_type = _x select 0;
				_classname = _x select 1;

				switch (toLower _type) do
				{
					case "weapon":
					{
						if (_classname != "") then
						{
							//diag_log format ["Applying %1 as weapon for %2", _classname, _npcName];
							_npc addWeapon _classname;
						};
					};
					case "uniform":
					{
						if (_classname != "") then
						{
							//diag_log format ["Applying %1 as uniform for %2", _classname, _npcName];
							_npc addUniform _classname;
						};
					};
					case "switchMove":
					{
						if (_classname != "") then
						{
							//diag_log format ["Applying %1 as switchMove for %2", _classname, _npcName];
							_npc switchMove _classname;
						};
					};
				};
			} forEach _storeOwnerAppearance;


//diag_log format ["GUNSTORE SET POS: %1 %2", _npcName, _deskDirMod];			
_npc setDir _deskDirMod;
_npc setPos getPos _npc;

			private "_bPos";
			switch (toUpper typeName _npcPos) do
			{
				case "SCALAR":
				{
					_bPos = _building buildingPos _npcPos;
				};
				case "ARRAY":
				{
					_bPos = _npcPos;
				};
			};


			//#############################################
			//Place the NPC where he stands
			if (_npcPos == 99) then {
				bPos = [0,0,0];
			} else { 
				_bPos = _building buildingPos _npcPos;
			};
			//#############################################

			if (_bPos isEqualTo [0,0,0]) then
			{
				_bPos = getPosATL _npc;
			}
			else
			{
				_npc setPosATL _bPos;
			};

		
			_desk = createVehicle ["Land_CashDesk_F", _npc, [], 0, "None"];
			//_desk = createVehicle ["OfficeTable_01_old_F", _npc, [], 0, "None"];
						
			_desk setVariable ["R3F_LOG_disabled", true, true];
			_desk allowDamage false;
			_desk disableCollisionWith _npc;
			_npc setVariable ["storeNPC_cashDesk", netId _desk, true];

			sleep 1;
		
			_desk attachto [_npc, [0,1,0] ];  //attach to desk and move it out and up a bit
			_desk setDir 180;
			_desk attachto [_npc, [0,1,0] ];  //attach to desk and move it out and up a bit
			_desk setDir 180;
			_desk setPos (getPos _desk);  //set the position and update clients

			sleep 1;

				_deskOffset = (getPosASL _desk) vectorAdd ([[-0.05,-0.6,0], -(getDir _desk)] call BIS_fnc_rotateVector2D);

				_sellBox = createVehicle ["rhs_weapons_crate_ak_standard", _deskOffset, [], 0, "None"];
				//_sellBox = createVehicle ["Box_IND_Ammo_F", _deskOffset, [], 0, "None"];

				_sellBox allowDamage false;
				_sellBox setVariable ["R3F_LOG_disabled", true, true];
				_sellBox setVariable ["A3W_storeSellBox", true, true];

				clearBackpackCargoGlobal _sellBox;
				clearMagazineCargoGlobal _sellBox;
				clearWeaponCargoGlobal _sellBox;
				clearItemCargoGlobal _sellBox;
				
				sleep 1;

				_sellBox attachto [_desk, [0,-1,0.1] ];  //attach to desk and move it out and up a bit
				_sellBox setPos (getPos _sellBox);  //set the position and update clients
	
			_npc enableSimulation false;
			_desk enableSimulationGlobal false;
			
		};
	} forEach (call storeOwnerConfig);
};



if (isServer) then
{
	_npc setVariable ["storeNPC_setupComplete", true, true];
};


