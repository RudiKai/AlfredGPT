//+------------------------------------------------------------------+
//|                AlfredAI_Pane.mq5 (Unified Control Center v2)    |
//|   Combines: HUD + Compass + Commentary + Alfred Personality     |
//|   Author: Rudi & ChatGPT (AlfredAI Project)                     |
//+------------------------------------------------------------------+
#property indicator_chart_window
#include <AlfredSettings.mqh>
#include <AlfredInit.mqh>

//--- input parameters
input bool ShowHUD        = true;   // Show HUD metrics
input bool ShowBias       = true;   // Show Compass/Bias info
input bool ShowZones      = true;   // Show Sup/Dem zones (from SupDemCore)
input bool CollapsibleHUD = true;   // Allow toggling HUD visibility
input bool DebugMode      = false;  // Debug prints

//--- internal objects
#define PANE_PREFIX   "AlfredPane_"
#define COMMENT_OBJ   PANE_PREFIX"Comment"

//--- global state
SAlfred settings;          // from AlfredSettings
bool hudVisible = true;    // collapse state
string biasText = "N/A";   // latest bias

//+------------------------------------------------------------------+
//| Custom initialization                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   Alfred_Init(settings); // load defaults
   CreatePaneBase();
   AlfredSay("Pane initialized and ready.",0);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Deinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,PANE_PREFIX);
}
//+------------------------------------------------------------------+
//| OnCalculate (dummy, updates every tick)                         |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
{
   UpdatePane();
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Draw the base panel                                             |
//+------------------------------------------------------------------+
void CreatePaneBase()
{
   string name = PANE_PREFIX+"BG";
   if(ObjectFind(0,name)<0)
   {
      ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,5);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,15);
      ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrBlack);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clrBlack);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,180);
      ObjectSetInteger(0,name,OBJPROP_HEIGHT,140);
      ObjectSetInteger(0,name,OBJPROP_BACK,true);
   }
}
//+------------------------------------------------------------------+
//| Update pane content (called every tick)                         |
//+------------------------------------------------------------------+
void UpdatePane()
{
   string content = "";

   //--- Bias (from Compass)
   if(ShowBias) content += "Bias: "+biasText+"\n";

   //--- HUD Metrics
   if(ShowHUD && hudVisible)
   {
      content += "Spread: "+(string)MarketInfo(Symbol(),MODE_SPREAD)+"\n";
      content += "ATR(14): "+DoubleToString(iATR(Symbol(),Period(),14,0),2)+"\n";
   }

   //--- Zones (placeholder until SupDemCore integration)
   if(ShowZones) content += "Zones: Active\n";

   //--- Alfred Says
   content += "\nAlfred Says: Stay sharp, watch key levels.";

   //--- Draw text object
   DrawLabel(COMMENT_OBJ,content,10,20,clrWhite,10);
}
//+------------------------------------------------------------------+
//| Helper: DrawLabel                                               |
//+------------------------------------------------------------------+
void DrawLabel(string name,string text,int x,int y,color clr,int fontsize)
{
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontsize);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
}
//+------------------------------------------------------------------+
//| Placeholder for Alfred's commentary                             |
//+------------------------------------------------------------------+
void AlfredSay(string msg,int type=0)
{
   if(DebugMode) Print("[Alfred] ",msg);
   // Later: send to AlertCenter + on-screen bubbles
}
//+------------------------------------------------------------------+
