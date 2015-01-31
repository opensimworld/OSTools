string BASEURL="http://opensimworld.com/index.php/osgate";

string regionName = "";
string gridUrl="";
string wkey = "";
integer channel;
integer tChanOpen=0;
integer zListener = -1;
string status;
integer minsSinceLast = 0;
string cookie="";
key dialogUser;

key beaconHttp;
key menuHttp;

integer nTotalAvis =-1;

checkBeacon() { 
        if (wkey == "")
        {
            llSetText("Gate not initialized.", <1.000, 0.1, 0.106>, 1.0);
            return;
        }
        llSetText("", <1.000, 0.522, 0.106>, 1.0);

        regionName = llGetRegionName();
        
        list g = osGetAgents(); 
        integer nNew = llGetListLength(g);
        // Find out how many of them are NPCs
        list avis = osGetAvatarList(); // This will not return the owner
        integer howmany = llGetListLength(avis);
        integer i;
        for (i =0; i < howmany; i+=3)
            if (osIsNpc(llList2Key(avis, i)))
                nNew--;

        if (nNew<0) nNew=0;
        
        if (nNew != nTotalAvis || minsSinceLast > 30)
        {
           nTotalAvis = nNew;
           string url=BASEURL+"/beacon/?k="+wkey+"&na="+(string)nTotalAvis+"&g="+gridUrl+"&r="+regionName;
           beaconHttp = llHTTPRequest(url, [], "");
           minsSinceLast = 0;
        }
        
        
        minsSinceLast++;
}



default
{
    on_rez(integer n)
    {
        llResetScript();
        llOwnerSay("This gate has not been initialized. Please visit http://opensimworld.com/  to register your region and get your key. After that, click on this gate to set the key");
    }
    
    
    state_entry()
    {
       
        checkBeacon();
        llSetTimerEvent(120);
        
    }
    
    timer()
    {
        //gridUrl = osGetGridLoginURI();
        checkBeacon();
        if (tChanOpen > 2 && zListener != -1)
        {
            llListenRemove(zListener);
            zListener = -1;
            status = "";
        }
        tChanOpen++;
    }
        
    touch_start(integer n)
    {
        channel = -1 - (integer)("0x" + llGetSubString( (string) llGetKey(), -7, -1) );
        if (zListener <0)
        {
            zListener =  llListen(channel, "","","");
            tChanOpen  = 0;
        }
          
        if (wkey == "")
        {
            if (llDetectedKey(0) == llGetOwner())
            {
                llTextBox(llDetectedKey(0), "Please register your region on http://opensimworld.com/ and enter the gate you will receive here:", channel);
                status = "wait_key";
            }
            else
                llSay(0,"This gate has not been initialized yet. Please see http://opensimworld.com/ for instructions");
        }
        else
        {
            list opts = ["Popular", "PG&Moderate", "Adult"];
            dialogUser = llDetectedKey(0);
            llDialog(dialogUser, "Click to get a new destination", opts, channel);
            status = "wait_menu";
            
        }
    }
    
    listen(integer chan, string who, key id, string msg)
    {
        if (status == "wait_key")
        {
            wkey = msg;
            if (wkey != "")
            {
                nTotalAvis = -1;
                llOwnerSay("You have set your gate key successfully. It may take a few minutes until your region statistics update on http://opensimworld.com");
                llSetText("", <1,.5, .5>, 1.0);
                checkBeacon();
            }
        }
        else if (status == "wait_menu")
        {
           string url=BASEURL+"/menu/?k="+wkey+"&q="+msg+"&c="+cookie;
           menuHttp = llHTTPRequest(url, [], "");
        }
    }
    
    http_response(key request_id, integer stcode, list metadata, string body)
    {

        if (request_id == beaconHttp)
        {
            if (body != "OK")
                llOwnerSay("Server response: "+body+"");
            // else Nothing to report
        }
        else
        {
            list tok = llParseString2List(body, ["\n"], []);
            string s = llList2String(tok,0);
            string menuTitle = llList2String(tok,1);
            string menu = llList2String(tok,2);
            cookie = llList2String(tok,3);
            
            if (s != "-")
                llSay(0,""+s);
            
            if (menu != "" && menu != "-")
            {
                list op2= llParseString2List(  menu, ["|"], [] );
                llDialog(dialogUser, menuTitle, op2, channel);
            }
        }
    }
}

