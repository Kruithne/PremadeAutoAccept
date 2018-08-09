--[[
	PremadeAutoAccept (C) Kruithne <kruithne@gmail.com>
	Licensed under GNU General Public Licence version 3.
	
	https://github.com/Kruithne/PremadeAutoAccept
]]--

local eventFrame = CreateFrame("FRAME");
local isAutoAccepting = false;
local displayedRaidConvert = false;
local autoAcceptButton = nil;

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

local function OnAutoAcceptButtonClick(self)
	isAutoAccepting = self:GetChecked();

	if isAutoAccepting then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		InviteApplicants();
	else
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
	end
end

local function CreateAutoAcceptButton()
	autoAcceptButton = CreateFrame("CheckButton", "PremadeAutoAcceptButton", LFGListFrame.ApplicationViewer);
	autoAcceptButton:SetPoint("BOTTOMLEFT", LFGListFrame.ApplicationViewer.InfoBackground, "BOTTOMLEFT", 12, 10);
	autoAcceptButton:SetHitRectInsets(0, -130, 0, 0);
	autoAcceptButton:SetWidth(22);
	autoAcceptButton:SetHeight(22);
	autoAcceptButton:Show();

	autoAcceptButton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
	autoAcceptButton:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
	autoAcceptButton:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight");
	autoAcceptButton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");

	autoAcceptButton:SetScript("OnClick", OnAutoAcceptButtonClick);

	local text = autoAcceptButton:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	text:SetText(LFG_LIST_AUTO_ACCEPT);
	text:SetJustifyH("LEFT");
	text:SetPoint("LEFT", autoAcceptButton, "RIGHT", 2, 0);
end

local function OnLoad()
	eventFrame:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED");
	eventFrame:RegisterEvent("GROUP_LEFT");
	eventFrame:RegisterEvent("PARTY_LEADER_CHANGED");

	CreateAutoAcceptButton();
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