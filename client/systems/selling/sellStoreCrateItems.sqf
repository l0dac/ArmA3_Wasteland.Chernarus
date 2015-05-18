// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
// Motavar@judgement.net - modified crate selling

#include "sellIncludesStart.sqf";

_this = cursorTarget;

storeSellingHandle = _this spawn
{

		_crate = [_this, 0, objNull, [objNull]] call BIS_fnc_param;
		_sellValue = 0;
		_originalCargo = CARGO_STRING(_crate);

		// Get all the items
		_allCrateItems = _crate call getSellPriceList;

		_objClass = typeOf _crate;
		_objName = getText (configFile >> "CfgVehicles" >> _objClass >> "displayName");


		if (count _allCrateItems == 0) exitWith
		{
				playSound "FD_CP_Not_Clear_F";
				[format ['"%1" does not contain valid items to sell.', _objName], "Error"] call BIS_fnc_guiMessage;
		};

		// Calculate total value
		{
			if (count _x > 3) then
			{
				_sellValue = _sellValue + (_x select 3);
			};
		} forEach _allCrateItems;
		


		// Add total sell value to confirm message
		_confirmMsg = format ["You will obtain $%1 for:<br/>", [_sellValue] call fn_numbersText];

		// Add item quantities and names to confirm message
		{
			_item = _x select 0;
			_itemQty = _x select 1;

			if (_itemQty > 0 && {count _x > 2}) then
			{
				_itemName = _x select 2;
				_confirmMsg = _confirmMsg + format ["<br/><t font='EtelkaMonospaceProBold'>%1</t> x %2%3", _itemQty, _itemName, if (PRICE_DEBUGGING) then { format [" ($%1)", [_x select 3] call fn_numbersText] } else { "" }];
			};
		} forEach _allCrateItems;



		// Display confirmation
		if ([parseText _confirmMsg, "Confirm", "Sell", true] call BIS_fnc_guiMessage) then
		{
				// Check if somebody else manipulated the cargo since the start
				if (CARGO_STRING(_crate) == _originalCargo) then
				{
						// Have to spawn clearing commands due to mysterious game crash...
						_clearing = _crate spawn
						{
							clearBackpackCargoGlobal _this;
							clearMagazineCargoGlobal _this;
							clearWeaponCargoGlobal _this;
							clearItemCargoGlobal _this;
						};

					waitUntil {scriptDone _clearing};
					player setVariable ["cmoney", (player getVariable ["cmoney", 0]) + _sellValue, true];

					_hintMsg = "You sold the inventory of %1 for $%2";
					hint format [_hintMsg, _objName, _sellValue];
					playSound "FD_Finish_F";
				}
				else
				{
					playSound "FD_CP_Not_Clear_F";
					[format ['The contents of "%1" have changed, please restart the selling process.', _objName], "Error"] call BIS_fnc_guiMessage;
				};
		};
};

#include "sellIncludesEnd.sqf";
