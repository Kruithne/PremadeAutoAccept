--[[
	PremadeAutoAccept (C) Kruithne <kruithne@gmail.com>
	Licensed under GNU General Public Licence version 3.
	
	https://github.com/Kruithne/PremadeAutoAccept
]]--

local eventFrame = CreateFrame("FRAME");
local isAutoAccepting = false;
local displayedRaidConvert = false;

local function InviteApplicants()
	local applicants = C_LFGList.GetApplicants();
	for i = 1, #applicants do
		local id, status, pendingStatus, numMembers = C_LFGList.GetApplicantInfo(applicants[i]);

		-- Using the premade "invite" feature does not work, as Blizzard have broken auto-accept intentionally
		-- Because of this, we can't invite groups, but we can still send normal invites to singletons.
		if numMembers == 1 and (pendingStatus or status == "applied") then
			local name = C_LFGList.GetApplicantMemberInfo(id, 1);
			InviteUnit(name);
		end
	end
end

local function OnLoad()
	eventFrame:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED");
	eventFrame:RegisterEvent("GROUP_LEFT");
	eventFrame:RegisterEvent("PARTY_LEADER_CHANGED");

	-- Force the auto-accept button to show even when the server says no.
	C_LFGList.CanActiveEntryUseAutoAccept = function()
		return true;
	end

	-- Overwrite the old handler for clicking the auto-accept button.
	LFGListFrame.ApplicationViewer.AutoAcceptButton:SetScript("OnClick", function(self)
		if self:GetChecked() then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		else
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
		end

		isAutoAccepting = self:GetChecked();
		if isAutoAccepting then
			InviteApplicants();
		end
	end);

	-- Prevent Blizzard UI from changing the tick-state of the auto-accept button.
	local old_SetChecked = LFGListFrame.ApplicationViewer.AutoAcceptButton.SetChecked;
	LFGListFrame.ApplicationViewer.AutoAcceptButton.SetChecked = function()
		old_SetChecked(LFGListFrame.ApplicationViewer.AutoAcceptButton, isAutoAccepting);
	end
end

local function OnApplicantListUpdated()
	if UnitIsGroupLeader("player", LE_PARTY_CATEGORY_HOME) then
		if isAutoAccepting then
			-- Display conversion to raid notice.
			if not displayedRaidConvert and not IsInRaid(LE_PARTY_CATEGORY_HOME) then
				local futureCount = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) + C_LFGList.GetNumInvitedApplicantMembers() + C_LFGList.GetNumPendingApplicantMembers();
				if futureCount > (MAX_PARTY_MEMBERS + 1) then
					StaticPopup_Show("LFG_LIST_AUTO_ACCEPT_CONVERT_TO_RAID");
					displayedRaidConvert = true;
				end
			end

			InviteApplicants();
		end
	end

	LFGListFrame.ApplicationViewer.AutoAcceptButton:SetChecked(isAutoAccepting);
end

local function OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...;
		local ADDON_NAME = "PremadeAutoAccept";

		if addonName == "PremadeAutoAccept" then
			OnLoad();
			self:UnregisterEvent("ADDON_LOADED");
		end
	elseif event == "LFG_LIST_APPLICANT_LIST_UPDATED" or event == "PARTY_LEADER_CHANGED" then
		OnApplicantListUpdated();
	elseif event == "GROUP_LEFT" then
		isAutoAccepting = false;
		displayedRaidConvert = false;
	end
end

eventFrame:RegisterEvent("ADDON_LOADED");
eventFrame:SetScript("OnEvent", OnEvent);