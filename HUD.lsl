string BASEURL="http://opensimworld.com/index.php/osgate";
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
string bkey = "";


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
        channel = -1 - (integer)("0x" + llGetSubString( (string) llGetKey(), -7, -1) );
        zListener =  llListen(channel, "","","");
        bkey = llGetObjectDesc();
    }
    
    on_rez(integer n)
    {
        // This will cause a reset on every attach - necessary for changing HUD key
        //llResetScript();

    }
    timer()
    {

    }
    
    
    touch_start(integer n)
    {
        list opts = [ "Bookmarks", "Reset", "Close", "Popular", "Latest", "Random", "OpenSimWorld"];
        dialogUser = llDetectedKey(0);
        llDialog(dialogUser, "Select region list:\n", opts, channel);
        status = "wait_menu";
        
    }
    
    listen(integer chan, string who, key id, string msg)
    {
         if (status == "wait_bkey")
         {
                  if (msg!="")
                  {
                           bkey = msg;

                           llOwnerSay("You have successfully set your HUD key.");
                           status  = "";
                           return;
                  }
         }
        else if (msg == "Close")
        {
            return;
        }
        else if (msg == "Reset")
        {
           llResetScript();
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
                // It seems maps and teleports fail for some viewers
                //if (pos.x>255) pos.x = 255;
                //if (pos.y>255) pos.y = 255;

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
                    //This only works on touch event :(
                   // llMapDestination(llList2String(e,3), <128,128,22>, <0,0,0>);
                }
                else if (msg == "LocalMap")
                {
                    llMapDestination(llList2String(e,2), <128,128,22>, <0,0,0>);
                }

                

        }
        else if (msg == "Bookmarks" && bkey =="")
        {
         
           llTextBox(llGetOwner(), "Please enter your HUD Key. You can find the Key in your account settings on opensimworld.com: http://opensimworld.com/settings.", channel);
           status="wait_bkey";
           return;
        }
        else if ((integer)msg>0)
        {

            selectedItem = (integer)msg;
            showTPDialog();
        }
        else
        {

            string url=BASEURL+"/list2/?q="+msg+"&bkey="+bkey+"&c="+cookie;
            key req = llHTTPRequest(url, [], "");
        }
    }
    
    http_response(key request_id, integer stcode, list metadata, string body)
    {

        listData = body;
        curStart =0;
        showListDialog();
    }
    
    
    changed(integer change)
    {
        if (change & CHANGED_OWNER){
            llResetScript();
        }
    }

    
}
