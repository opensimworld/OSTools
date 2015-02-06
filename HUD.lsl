string BASEURL="http://opensimworld.com/index.php/osgate";

string regionName = "";
string wkey = "";
integer channel;
integer tChanOpen=0;
integer zListener = -1;
string status;
integer minsSinceLast = 0;
string cookie="";
key dialogUser;
string description;
string address;
string s_rating;
integer allowed=0;

list currentMenu;
list currentValues;
key beaconHttp;
key menuHttp;

integer nTotalAvis =-1;


list knownGrids =  [
"grid.3rdrockgrid.com:8002","3RD Rock",
"craft-world.org:8002","CraftWorld",
"login.inworldz.com:8002","InWorldz",
"islandoasisgrid.biz:8002","Island Oasis",
"lfgrid.com:8002","Littlefield Grid",
"login.francogrid.org","FrancoGrid",
"login.osgrid.org","OSGrid",
"hypergrid.org:8002","Metropolis",
"grid.kitely.com:8002","Kitely",
"-","Other..."
];




checkBeacon() { 
    if ( wkey == "" ) {
        llSetText("Beacon not initialized. Click to initialize.", <1.0,0.1,0.1>, 1.0);
        return;
    }
    llSetText("", <1.0,0.5,0.1>, 1.0);
    regionName = llGetRegionName();
    integer nNew = 0;
    list avis = llGetAgentList(AGENT_LIST_REGION, []);
    integer howmany = llGetListLength(avis);
    integer i;
    for ( i = 0; i < howmany; i++ ) {
        if ( ! osIsNpc(llList2Key(avis, i)) )
            nNew++; // only non-NPC's
    }
    if ( nNew != nTotalAvis || minsSinceLast > 30 ) {
        nTotalAvis = nNew;
        beaconHttp = llHTTPRequest(
            BASEURL+"/beacon/"+
            "?wk="+wkey+
            "&na="+(string)nTotalAvis+
            "&r="+llEscapeURL(regionName)+
            "&rat="+s_rating+
            "&pos="+llEscapeURL((string)llGetPos()),
            [], ""
        );
        minsSinceLast = 0;
    }
}

saveLoginURI(string msg)
{
            wkey = msg;
            llOwnerSay("Login URI Set to "+ msg );
            checkBeacon();

}

default
{
    on_rez(integer n)
    {
        llResetScript();
        llOwnerSay("This beacon has not been initialized. Please visit http://opensimworld.com/  to register your region and get your beacon key. After that, click on this beacon to set the key.");
    }
    
    
    state_entry()
    {
        
        /*list details = llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_OWNER, PARCEL_DETAILS_ID]);
        if (llGetOwner() != llList2Key(details, 0))
        {
            llOwnerSay("You must place the beacon on a region that you own. The beacon won't work in  a region that you don't own");
            return;
        }*/
        allowed = 1;
        
        checkBeacon();
        llSetTimerEvent(60);
        key gRateingQuery = llRequestSimulatorData( llGetRegionName(), DATA_SIM_RATING );
    }
    
    timer()
    {
        checkBeacon();
        if (tChanOpen > 2 && zListener != -1)
        {
            llListenRemove(zListener);
            zListener = -1;
        }
        tChanOpen++;
        minsSinceLast++;
    }
    
    dataserver(key query_id, string data)
    {
        s_rating = data;
    }
        
    touch_start(integer n)
    {
        if (!allowed) return;
        
        channel = -1 - (integer)("0x" + llGetSubString( (string) llGetKey(), -7, -1) );
        if (zListener <0)
        {
            zListener =  llListen(channel, "","","");
            tChanOpen  = 0;
        }
        
        
        if (llDetectedKey(0) == llGetOwner())
        {
            dialogUser = llDetectedKey(0);
            llTextBox(dialogUser, "Please go to http://opensimworld.com/ to add your region and get your beacon key. Enter the key in the space below: ", channel);
            status = "wait_key";
        }
        else
        {
            llLoadURL(llDetectedKey(0), "Visit OpenSimWorld for more hypergrid destinations.", "http://opensimworld.com/?r=b");
        }
    }
    
    
    
    listen(integer chan, string who, key id, string msg)
    {
        //llOwnerSay("status="+status+" msg="+msg);
        if (status == "wait_key")
        {
            if (msg!= "")
            {
                wkey = msg;
                nTotalAvis = -1;
                llOwnerSay("You have set your beacon key successfully. It may take a few minutes until your region statistics update on http://opensimworld.com/");
                checkBeacon();
            }
            else
                return;
        }
        else if (status == "wait_menu")
        {

        }
    }
    
    http_response(key request_id, integer stcode, list metadata, string body)
    {

        if (request_id == beaconHttp)
        {
            if (body != "OK")
                llOwnerSay("Server: "+body+"");
        }
        else if (0)
        {
            list tok = llParseString2List(body, ["\n"], []);
            string s = llList2String(tok,0);
            string menuTitle = llList2String(tok,1);
            string menu = llList2String(tok,2);
            string menuVals = llList2String(tok,3);

            if (s != "-")
                llSay(0,""+s);
            
            if (menu != "" && menu != "-")
            {
                currentMenu = llParseString2List(  menu, ["|"], [] );
                currentValues = llParseString2List(  menuVals, ["|"], [] );
                
                llDialog(dialogUser, menuTitle, currentMenu, channel);
                status = "auto_menu";
            }
        }
    }
}
