string BASEURL="http://beacon.opensimworld.com/index.php/osgate";
integer channel;
integer zListener=-1;
key dialogUser;
string status;
string cookie;
string listData;
integer curStart=0;
list destAddr;
string mode;
integer selectedItem;
string wkey = "";
integer timeTPused =0;
key listHTTP = NULL_KEY;
key beaconHttp;
string s_rating;
integer nTotalAvis =-1;
string regionName;
integer minsSinceLast=-1;
integer tChanOpen =-1;

integer isWithin(vector v, float x1, float y1, float x2, float y2)
{
    return (v.x <x2) && (v.x >=x1) && (v.y<y2) && (v.y >=y1);
}

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



showListDialog()
{
        list tok = llParseString2List(listData, ["\n"], []);
        string title = llList2String(tok,0);
        integer i;
        string str = "";
        integer j;
        destAddr = [];
        list opts = [];
        opts += ["<<" , "Close", ">>"];
        for (i=curStart+1 ; i < llGetListLength(tok) && i <= curStart+9;i++)
        {
            list e = llParseString2List(llList2String(tok, i), ["#"], []);
            str += "["+(string)i+ "] "+llList2String(e, 2) + " ("+llList2String(e, 1)+" users)\n";
            opts += [(string)i];
        }
 
        llDialog(dialogUser, title+ "\n"+str, opts, channel);   
        mode = "loc"; 
}

partyOn(){
    
    llParticleSystem([]);
 llParticleSystem([
    PSYS_PART_FLAGS, PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_INTERP_SCALE_MASK |
                     
                     PSYS_PART_EMISSIVE_MASK  ,
                     
    PSYS_SRC_PATTERN,  PSYS_SRC_PATTERN_ANGLE_CONE,
    PSYS_PART_MAX_AGE,           2.0,
    PSYS_SRC_BURST_SPEED_MIN,    .0,
    PSYS_SRC_BURST_SPEED_MAX,    .4,
    PSYS_PART_START_ALPHA,       0.8,
    PSYS_PART_END_ALPHA,         0.01,
    PSYS_PART_START_COLOR,      < 0.1, 0.9, 0.0>,
    PSYS_PART_END_COLOR,        < 0, 0.9, 0>,
    PSYS_PART_START_SCALE,      < .1, .1, 2.0>,
    PSYS_PART_END_SCALE,        < .1, 0.1, 1.0>,
    PSYS_SRC_ACCEL,             < 0.0, 0, 0>,
    
    PSYS_SRC_BURST_RATE,        .1,
    PSYS_SRC_BURST_RADIUS,      .3,
    PSYS_SRC_BURST_PART_COUNT,  10,
    PSYS_SRC_OUTERANGLE,        0,
    PSYS_SRC_INNERANGLE,        TWO_PI,
    PSYS_SRC_OMEGA,             < 0.0, 0.0, 100 >, 
    PSYS_SRC_MAX_AGE,           1.0
    ]);
}

redrawScreen()
{
    string CommandList = ""; // Storage for our drawing commands

    CommandList = osSetFontSize( CommandList, 8 );     
    integer y = 0;
    integer x =0;
    CommandList = osMovePen( CommandList, 0, 0 );
    CommandList = osSetPenColor( CommandList, "FF000000" );
    CommandList = osDrawFilledRectangle( CommandList, 256,256);
    
    CommandList = osSetPenColor( CommandList, "FFc9410b" );
    CommandList = osMovePen( CommandList, x, y );
    CommandList = osDrawFilledRectangle( CommandList, 256,14);
    CommandList = osMovePen( CommandList, 20, y );
    CommandList = osSetPenColor( CommandList, "FF000000" );
    CommandList = osDrawText( CommandList,  "Refresh");
    CommandList = osMovePen( CommandList, 220, y );
    CommandList = osDrawText( CommandList,  "More");
    
    if (listData != "" )
    {
        list tok = llParseString2List(listData, ["\n"], []);
        string title = llList2String(tok,0);
        integer i;
        string str = "";
        integer j;
        destAddr = [];
       

        y = 50;
        x =0;
        
        for (i=curStart+1 ; i < llGetListLength(tok) && i <= curStart+10;i++)
        {
            list e = llParseString2List(llList2String(tok, i), ["#"], []);
            str = ""+(string)i+ ". "+llList2String(e, 2) + " ("+llList2String(e, 1)+" users)\n";
            //opts += [(string)i];
            CommandList = osSetPenColor( CommandList, "FF3399EE" );
            CommandList = osMovePen( CommandList, x, y );
            CommandList = osDrawFilledRectangle( CommandList, 256,14);
            CommandList = osMovePen( CommandList, x+20, y );
            CommandList = osSetPenColor( CommandList, "FFFFFFFF" );
            CommandList = osDrawText( CommandList,  str);
            y += 16;
        }
        
 
        //llDialog(dialogUser, title+ "\n"+str, opts, channel);   
        mode = "loc"; 
    }
    
    y = 236;
    x =0;
    CommandList = osSetPenColor( CommandList, "FFcf7000" );
    CommandList = osMovePen( CommandList, x, y );
    CommandList = osDrawFilledRectangle( CommandList, 256,20);
    CommandList = osMovePen( CommandList, x+20, y );
    CommandList = osSetPenColor( CommandList, "FF000000" );
    CommandList = osDrawText( CommandList,  "<< Previous");
    CommandList = osMovePen( CommandList, 200, y );
    CommandList = osDrawText( CommandList,  "Next >>");
    
    osSetDynamicTextureData( "", "vector", CommandList, "width:256,height:256", 0 );
}

list getListItem(integer idx)
{
        list tok = llParseString2List(listData, ["\n"], []);
        list e = llParseString2List(llList2String(tok, idx), ["#"], []);
        return e;
     //       str += (string)i+ " "+llList2String(e, 2) + " ("+llList2String(e, 1)+" users)\n";
 
}

default
{
    state_entry()
    {
        llParticleSystem([]);
        
        channel = -1 - (integer)("0x" + llGetSubString( (string) llGetKey(), -7, -1) );
        //zListener =  llListen(channel, "","","");
        redrawScreen();  
        llSetTexture("oswteleport", ALL_SIDES);
        status="init";
        
        checkBeacon();
        llSetTimerEvent(60);
        key gRateingQuery = llRequestSimulatorData( llGetRegionName(), DATA_SIM_RATING );
    }
    
    on_rez(integer n)
    {
        // reset to request new key
        llResetScript();
    }
    
    timer()
    {
     
        if (timeTPused > 2 && status=="working")
        {    
            llSetTexture("oswteleport", ALL_SIDES);
            status = "sleeping";
        }
        
        checkBeacon();
        
        tChanOpen++;
        minsSinceLast++;
        timeTPused++;
    }
    
    dataserver(key query_id, string data)
    {
        s_rating = data;
    }
    
    touch_start(integer n)
    {
        dialogUser = llDetectedKey(0);
        
        if (wkey == "" )
        {
            if (llGetOwner() == llDetectedKey(0))
            {
                if (zListener <0)
                {
                    zListener =  llListen(channel, "","","");
                    tChanOpen  = 0;
                }
                llTextBox(llGetOwner(), "Please register your region at http://opensimworld.com/ and enter the Beacon Key you will receive below.", channel);
            }
            else
            {
                llSay(0, "This beacon has not been initialized by its owner");
            }
            return;
        }
        vector pos = llDetectedTouchST(0);
     
        //llOwnerSay("Pos="+(string)pos);
            
        string cmd;
        
        timeTPused =0;
        
        if (status == "sleeping")
        {
            cmd = "Popular";
        }
        else if (status == "working")
        {
        
            if (isWithin(pos, 0,0, .3, .07)) //previous
            {
                if (curStart>0)
                    curStart -= 10;
                redrawScreen();
                return;
            }
            else if (isWithin(pos, 0.7,0, 1., .07)) //next
            {
                curStart+=10;
                redrawScreen();
                return;
            }
            else if (isWithin(pos, 0.005,0.19, 0.9,0.8))
            {
                integer index = (integer)(11- 10*(pos.y - 0.19)/(0.8-0.19));
                index +=curStart;
                list e = getListItem(index);
                vector lpos =(vector)llList2String(e,4);
                if ((integer)llList2String(e,7) ==1)
                    llMapDestination(llList2String(e,2), lpos, <0,0,0>);                        
                else
                    llMapDestination(llList2String(e,3), lpos, <0,0,0>);             
                return;
            }
            else if (isWithin(pos,  0.853615,0.943537, 1,1))
            {
                llLoadURL(dialogUser, "Visit OpenSimWorld for more destinations and to get your own beacon", "http://opensimworld.com");
                return;
            }
            else if (isWithin(pos, 0, 0.95, 1, 1))
            {
                cmd = "Popular";
            }
            else
                return;
        }
        
        partyOn();

        //Refresh
        if (cmd == "Popular")
        {

            string url=BASEURL+"/gate1/?q="+cmd+"&wkey="+wkey+"&c="+cookie;
            listHTTP = llHTTPRequest(url, [], "");
        }
        
        //opts += ["Popular", "Latest", "Random", "OpenSimWorld", "Help", "Close"];

        //llDialog(dialogUser, "Select region list:\n", opts, channel);
        //status = "wait_menu";
        
    }
    
    listen(integer chan, string who, key id, string msg)
    {
         if (wkey == "" && llGetOwner() == dialogUser)
         {
              if (msg!="")
              {
                       wkey = llStringTrim(msg, STRING_TRIM);
                       llOwnerSay("You have successfully set your Beacon key.");
                       status  = "sleeping";
                       llListenRemove(zListener);
                       zListener = -1;
                       checkBeacon();
                       return;
              }
         }

    }
    
    http_response(key request_id, integer stcode, list metadata, string body)
    {
        if (request_id == listHTTP)
        {
            listData = body;
            curStart =0;
            status="working";
            redrawScreen();
        }
        else if (request_id == beaconHttp)
        {
            if (body == "DISABLE")
            {
                llResetScript();
            }
            else if (body != "OK" && llStringLength(body)>0)
                llOwnerSay("Server: "+body+"");
        }
    }

}
