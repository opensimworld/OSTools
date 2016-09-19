string BASEURL="http://beacon.opensimworld.com/index.php/osgate";
integer channel;
integer zListener=-1;
key dialogUser;
string status;
string listData;
integer curStart=0;
list destAddr;
string mode;
integer selectedItem;
string lastCommand;
key req;


showTPDialog()
{
         list e = getListItem(selectedItem);
         string str = "Destination: "+ llList2String(e,2) +
                  "\nHG address: "+ llList2String(e,3)+"  \n" + 
                  "\nSelect how to teleport. If you are in the same grid as the destination region, select 'Local Grid'";
         llDialog(llGetOwner(),str , [  "HyperGrid", "LocalGrid", "Close"], channel);
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
        opts += ["<<" , "CLOSE", ">>"];
        for (i=curStart+1 ; i < llGetListLength(tok) && i <= curStart+9;i++)
        {
            list e = llParseString2List(llList2String(tok, i), ["#"], []);
            str += "["+(string)i+ "] "+llList2String(e, 2) + " ("+llList2String(e, 1)+" users)\n";
            opts += [(string)i];
        }
 
        llDialog(dialogUser, title+ "\n"+str, opts, channel);   
        mode = "loc"; 
}

list getListItem(integer idx)
{
        list tok = llParseString2List(listData, ["\n"], []);
        list e = llParseString2List(llList2String(tok, idx), ["#"], []);
        return e;
     //       str += (string)i+ " "+llList2String(e, 2) + " ("+llList2String(e, 1)+" users)\n";
 
}

startListening()
{
    if (zListener >=0) llListenRemove(zListener);
    channel = -1 - (integer)("0x" + llGetSubString( (string) llGetKey(), -7, -1) );
    zListener =  llListen(channel, "",llGetOwner(),"");
    llSetTimerEvent(300);
}

default
{
    state_entry()
    {

    }
    
    on_rez(integer n)
    {
    }
    
    timer()
    {
        if (zListener >=0) 
        {
            llListenRemove(zListener);
            zListener = -1;
        }
        status = "";
        llSetTimerEvent(0);
    }
    
    
    touch_start(integer n)
    {
        list opts = ["+Like", "+Bookmark", "CLOSE", "Popular", "Latest", "Random", "Bookmarks", "RegionInfo"];
        dialogUser = llDetectedKey(0);
        startListening();
        llDialog(dialogUser, "Select region list:\n", opts, channel);
        status = "wait_menu";
    }

    listen(integer chan, string who, key id, string msg)
    {
        if (status == "waitkey")
        {
            if (msg != "")
            {
                string url=BASEURL+"/setkey/?k="+msg;
                req = llHTTPRequest(url, [], "");
                status = "";
                return;
            }
            return;
        }
        else if (msg == "CLOSE")
        {
            return;
        }
        else if (msg == "OpenSimWorld")
        {
            llLoadURL(dialogUser, "Visit opensimworld.com for more destinations", "http://opensimworld.com/?r=hud");
        }
        else if (msg == "Help")
        {
            llLoadURL(dialogUser, "Visit opensimworld.com for more destinations", "http://opensimworld.com/help/?r=hud");
        }
        else if (msg == "<<")
        {
            if (curStart>0)
                curStart -= 9;
            showListDialog();
        }
        else if (msg == ">>")
        {
            curStart+=9;
            showListDialog();
        }
        else if (msg == "HyperGrid" || msg == "LocalGrid" || msg == "HG Map" || msg == "LocalMap")
        {

                list e = getListItem(selectedItem);
                llOwnerSay("Destination region is "+ llList2String(e,2) +" in HG address "+ llList2String(e,3)+" ");
                vector pos = (vector)llList2String(e,4);

                vector lookat = (vector)llList2String(e,5);
                
                if (msg == "HyperGrid")
                {
                    osTeleportOwner(llList2String(e,3), pos, lookat);
                }
                else if (msg == "LocalGrid")
                {
                    osTeleportOwner(llList2String(e,2), pos, lookat);
                }
                else if (msg == "HG Map")
                {
                    //This only works on touch events or in attachments :(
                   // llMapDestination(llList2String(e,3), <128,128,22>, <0,0,0>);
                }
                else if (msg == "LocalMap")
                {
                    llMapDestination(llList2String(e,2), <128,128,22>, <0,0,0>);
                }
        }
        else if ((integer)msg>0)
        {
            selectedItem = (integer)msg;
            showTPDialog();
        }
        else
        {
            string url=BASEURL+"/list2/?q="+llEscapeURL(msg);
            req = llHTTPRequest(url, [], "");
        }
    }
    
    http_response(key request_id, integer stcode, list metadata, string body)
    {
        //llOwnerSay("Got: "+body);
        if (llGetSubString(body, 0,3) == "MSG^")
        {
            list tok = llParseString2List(body, ["^"], []);
            if (llList2String(tok,1) != "-")
                llDialog(llGetOwner(), llList2String(tok, 1), ["CLOSE"], channel);
            if (llList2String(tok, 2) != "")
                llSay(0, llList2String(tok, 2));
        }
        else if (llGetSubString(body, 0,3) == "URL^")
        {
             list tok = llParseString2List(body, ["^"], []);
             llLoadURL(llGetOwner(),  llList2String(tok, 1), llList2String(tok,2));
        }
        else if (llGetSubString(body, 0,3) == "REQ^" || llGetSubString(body, 0,3) == "CMT^")
        {
            list tok = llParseString2List(body, ["^"], []);
            startListening();
            llTextBox(llGetOwner(), llList2String(tok, 1), channel);

            if (llList2String(tok, 2) != "")
                llSay(0, llList2String(tok, 2));

            if (llGetSubString(body, 0,3) == "REQ^")
                status = "waitkey";
            else 
                status = "waitcmt";
        }
        else
        {
            listData = body;
            curStart =0;
            showListDialog();
        }
    }
    
    
    
}
