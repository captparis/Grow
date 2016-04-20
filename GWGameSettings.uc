class GWGameSettings extends UDKGameSettingsCommon;

`include(GWOnlineConstants.uci)

/** The UID of the steam game server, for use with steam sockets */
var databinding string SteamServerId;

/**
 * Builds a URL string out of the properties/contexts and databindings of this object.
 */
function BuildURL(out string OutURL) {
	local int SettingIdx;
	local name PropertyName;

	OutURL = "";

	// Append properties marked with the databinding keyword to the URL
	AppendDataBindingsToURL(OutURL);
	
	// add all properties
	for (SettingIdx = 0; SettingIdx < Properties.length; SettingIdx++) {
		PropertyName = GetPropertyName(Properties[SettingIdx].PropertyId);
		if (PropertyName != '') {
			switch(Properties[SettingIdx].PropertyId) {
				default:
					OutURL $= "?" $ PropertyName $ "=" $ GetPropertyAsString(Properties[SettingIdx].PropertyId);
					break;
			}
		}
	}
}
function setServerName(string serverName) {
	SetStringProperty(PROPERTY_MYSERVERNAME, serverName);
}

function string getServerName() {
	return GetPropertyAsString(PROPERTY_MYSERVERNAME);
}

DefaultProperties
{
	// Properties and their mappings
	Properties(0)=(PropertyId=PROPERTY_MYSERVERNAME,Data=(Type=SDT_String),AdvertisementType=ODAT_QoS)
	PropertyMappings(0)=(Id=PROPERTY_MYSERVERNAME,Name="MyServerName")
}