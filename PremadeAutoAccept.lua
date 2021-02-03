--[[
	PremadeAutoAccept (C) Kruithne <kruithne@gmail.com>
	Licensed under GNU General Public Licence version 3.

	https://github.com/Kruithne/PremadeAutoAccept
]]--

local eventFrame = CreateFrame("FRAME");
local isAutoAccepting = false;
local displayedRaidConvert = false;
local autoAccepting = {};

local function InviteApplicants()
	local applicants = C_LFGList.GetApplicants();
	for i = 1, #applicants do
		local applicantData = C_LFGList.GetApplicantInfo(applicants[i]);

		-- Using the premade "invite" feature does not work, as Blizzard have broken auto-accept intentionally
		-- Because of this, we can't invite groups, but we can still send normal invites to singletons.
		if applicantData and (applicantData.applicationStatus == "applied" or applicantData.pendingApplicationStatus == "applied") and applicantData.numMembers == 1 then

			local name, _, _, _, _, _, _, _, _, assignedRole  = C_LFGList.GetApplicantMemberInfo(applicants[i], 1);
			if autoAccepting[assignedRole] then
				C_PartyInfo.InviteUnit(name);
			end
		end
	end
end

local function OnCheckBoxClick(self)
	isAutoAccepting = self:GetChecked();
	autoAccepting[self.role] = isAutoAccepting;

	if isAutoAccepting then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		InviteApplicants();
	else
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
	end
end

local function CreateCheckbox(atlas, role)
	local button = CreateFrame("CheckButton", nil, LFGListFrame.ApplicationViewer);
	button:SetWidth(22);
	button:SetHeight(22);
	button:Show();

	button:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
	button:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
	button:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight");
	button:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");

	button.role = role;
	button:SetScript("OnClick", OnCheckBoxClick);

	local icon = button:CreateTexture(nil, "ARTWORK");
	icon:SetAtlas(atlas);
	icon:SetWidth(17);
	icon:SetHeight(17);
	icon:SetPoint("LEFT", button, "RIGHT", 2, 0);
	button.icon = icon;

	return button;
end

local function CreateAutoAcceptButtons()
	local header = LFGListFrame.ApplicationViewer:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	header:SetPoint("BOTTOMLEFT", LFGListFrame.ApplicationViewer.InfoBackground, "BOTTOMLEFT", 12, 30);
	header:SetText(LFG_LIST_AUTO_ACCEPT);
	header:SetJustifyH("LEFT");

	local damageButton = CreateCheckbox("groupfinder-icon-role-large-dps", "DAMAGER");
	damageButton:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -1);

	local healerButton = CreateCheckbox("groupfinder-icon-role-large-heal", "HEALER");
	healerButton:SetPoint("LEFT", damageButton.icon, "RIGHT", 5, 0);

	local tankButton = CreateCheckbox("groupfinder-icon-role-large-tank", "TANK");
	tankButton:SetPoint("LEFT", healerButton.icon, "RIGHT", 5, 0);
end

local function OnLoad()
	eventFrame:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED");
	eventFrame:RegisterEvent("GROUP_LEFT");
	eventFrame:RegisterEvent("PARTY_LEADER_CHANGED");

	CreateAutoAcceptButtons();
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
			-- tried to fix the raid convert spam bug
			if displayedRaidConvert and not IsInRaid(LE_PARTY_CATEGORY_HOME) then
				if futureCount < (MAX_PARTY_MEMBERS + 1) then
					InviteApplicants();
					do return end;
				else
					do return end;
				end 
			end
			InviteApplicants();
		end
	end
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
