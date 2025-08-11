//+------------------------------------------------------------------+
//|                   AAI_Indicator_Dashboard.mq5                    |
//|             v2.1 - UI Upgrade: Collapsible Sections              |
//|        (Displays all data from the AAI indicator suite)          |
//|                                                                  |
//| Copyright 2025, AlfredAI Project                                 |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_plots 0 // Suppress "no indicator plot" warning
#property version "2.1"

// --- Optional Inputs ---
input bool ShowAlfredBrainModule = true;       // Show AlfredBrain signal module
input bool ShowDebugInfo = false;               // Toggle for displaying debug information
input bool EnableDebugLogging = false;          // Toggle for printing detailed data fetch logs to the Experts tab
input bool ShowZoneHeatmap = true;              // Toggle for the Zone Heatmap
input bool ShowMagnetProjection = true;         // Toggle for the Magnet Projection status
input bool ShowMultiTFMagnets = true;         // Toggle for the Multi-TF Magnet Summary
input bool ShowHUDActivitySection = true;       // Toggle for the HUD Zone Activity section
input bool ShowConfidenceMatrix = true;         // Toggle for the Confidence Matrix
input bool ShowTradeRecommendation = true;      // Toggle for the Trade Recommendation
input bool ShowRiskModule = true;               // Toggle for the Risk & Positioning module
input bool ShowSessionModule = true;            // Toggle for the Session & Volatility module
input bool ShowNewsModule = true;               // Toggle for the Upcoming News module
input bool ShowEmotionalState = true;           // Toggle for the Emotional State module
input bool ShowAlertCenter = true;              // Toggle for the Alert Center module
input bool ShowPaneSettings = true;             // Toggle for the Pane Settings summary module
input bool ShowAlfredSays = true;               // Toggle for the "Alfred Says" module

// --- Includes
#include <ChartObjects\ChartObjectsTxtControls.mqh>
#include <AAI_Include_Settings.mqh> // UPDATED INCLUDE

// --- Enums for State Management
enum ENUM_BIAS { BIAS_BULL, BIAS_BEAR, BIAS_NEUTRAL };
enum ENUM_ZONE { ZONE_DEMAND, ZONE_SUPPLY, ZONE_NONE };
enum ENUM_ZONE_INTERACTION { INTERACTION_INSIDE_DEMAND, INTERACTION_INSIDE_SUPPLY, INTERACTION_NONE };
enum ENUM_TRADE_SIGNAL { SIGNAL_NONE, SIGNAL_BUY, SIGNAL_SELL };
enum ENUM_HEATMAP_STATUS { HEATMAP_NONE, HEATMAP_DEMAND, HEATMAP_SUPPLY };
enum ENUM_MAGNET_RELATION { RELATION_ABOVE, RELATION_BELOW, RELATION_AT };
enum ENUM_VOLATILITY { VOLATILITY_LOW, VOLATILITY_MEDIUM, VOLATILITY_HIGH };
enum ENUM_NEWS_IMPACT { IMPACT_LOW, IMPACT_MEDIUM, IMPACT_HIGH };
enum ENUM_EMOTIONAL_STATE { STATE_CAUTIOUS, STATE_CONFIDENT, STATE_OVEREXTENDED, STATE_ANXIOUS, STATE_NEUTRAL };
enum ENUM_ALERT_STATUS { ALERT_NONE, ALERT_PARTIAL, ALERT_STRONG };
enum ENUM_REASON_CODE
{
    REASON_NONE,
    REASON_BUY_LIQ_GRAB_ALIGNED,
    REASON_SELL_LIQ_GRAB_ALIGNED,
    REASON_NO_ZONE,
    REASON_LOW_ZONE_STRENGTH,
    REASON_BIAS_CONFLICT
};
// --- Structs for Data Handling
struct LiveTradeData { bool trade_exists; double entry, sl, tp; };
struct CompassData { ENUM_BIAS bias; double confidence; };
struct MatrixRowData { ENUM_BIAS bias; ENUM_ZONE zone; ENUM_MAGNET_RELATION magnet; int score; };
struct TradeRecommendation { ENUM_TRADE_SIGNAL action; string reasoning; };
struct RiskModuleData { double risk_percent; double position_size; string rr_ratio; };
struct SessionData { string session_name; string session_overlap; ENUM_VOLATILITY volatility; };
struct NewsEventData { string time; string currency; string event_name; ENUM_NEWS_IMPACT impact; };
struct EmotionalStateData { ENUM_EMOTIONAL_STATE state; string text; };
struct AlertData { ENUM_ALERT_STATUS status; string text; };
struct AlfredComment { string text; color clr; };
// --- Structs for Live Data Caching ---
struct CachedCompassData { ENUM_BIAS bias; double confidence; };
struct CachedSupDemData
{
   ENUM_ZONE zone;
   double magnet_level;
   double zone_p1;
   double zone_p2;
   double strength;
   double freshness;
   double volume;
   double liquidity;
};
struct CachedHUDData { bool zone_active; };
struct CachedBrainData
{
   ENUM_TRADE_SIGNAL signal;
   double confidence;
   ENUM_REASON_CODE reasonCode;
   int zoneTF;
};
// --- Constants for Panel Layout
#define PANE_PREFIX "AAI_Dashboard_"
#define PANE_WIDTH 230
#define PANE_X_POS 15
#define PANE_Y_POS 15
#define PANE_BG_COLOR clrDimGray
#define PANE_BG_OPACITY 210
#define CONFIDENCE_BAR_MAX_WIDTH 100
#define SEPARATOR_TEXT "──────────────────" // Thinner separator
#define MAX_NEWS_ITEMS 3

// --- Colors
#define COLOR_BULL clrLimeGreen
#define COLOR_BEAR clrOrangeRed
#define COLOR_NEUTRAL_TEXT clrWhite
#define COLOR_NEUTRAL_BIAS clrGoldenrod
#define COLOR_HEADER clrSilver
#define COLOR_TOGGLE clrLightGray
#define COLOR_DEMAND clrLimeGreen
#define COLOR_SUPPLY clrOrangeRed
#define COLOR_CONF_HIGH clrLimeGreen
#define COLOR_CONF_MED clrOrange
#define COLOR_CONF_LOW clrOrangeRed
#define COLOR_SEPARATOR clrGray
#define COLOR_NA clrGray
#define COLOR_NO_SIGNAL clrGray
#define COLOR_HIGHLIGHT_DEMAND (color)ColorToARGB(clrDarkGreen, 100)
#define COLOR_HIGHLIGHT_SUPPLY (color)ColorToARGB(clrMaroon, 100)
#define COLOR_HIGHLIGHT_NONE (color)ColorToARGB(clrGray, 50)
#define COLOR_MAGNET_AT clrGoldenrod
#define COLOR_TEXT_DIM clrSilver
#define COLOR_SESSION clrCyan
#define COLOR_VOL_HIGH_BG (color)ColorToARGB(clrMaroon, 80)
#define COLOR_VOL_MED_BG (color)ColorToARGB(clrGoldenrod, 80)
#define COLOR_VOL_LOW_BG (color)ColorToARGB(clrDarkGreen, 80)
#define COLOR_IMPACT_HIGH clrRed
#define COLOR_IMPACT_MEDIUM clrOrange
#define COLOR_IMPACT_LOW clrLimeGreen
#define COLOR_STATE_CAUTIOUS clrYellow
#define COLOR_STATE_CONFIDENT clrLimeGreen
#define COLOR_STATE_OVEREXTENDED clrRed
#define COLOR_STATE_ANXIOUS clrDodgerBlue
#define COLOR_STATE_NEUTRAL clrGray
#define COLOR_ALERT_STRONG clrLimeGreen
#define COLOR_ALERT_PARTIAL clrYellow
#define COLOR_ALERT_NONE clrGray
#define COLOR_FOOTER clrDarkGray
#define COLOR_ALFRED_CAUTION clrGoldenrod


// --- Font Sizes & Spacing
#define FONT_SIZE_NORMAL 8
#define FONT_SIZE_HEADER 9
#define FONT_SIZE_SIGNAL 10
#define FONT_SIZE_SIGNAL_ACTIVE 11
#define SPACING_SMALL 14
#define SPACING_MEDIUM 16
#define SPACING_LARGE 24
#define SPACING_SEPARATOR 12

// --- Indicator Handles & Globals
SAlfred Alfred; // Global settings instance
int hATR_current;
int atr_period = 14;
double g_pip_value;
string g_timeframe_strings[];
ENUM_TIMEFRAMES g_timeframes[];
string g_heatmap_tf_strings[];
ENUM_TIMEFRAMES g_heatmap_tfs[];
string g_magnet_summary_tf_strings[];
ENUM_TIMEFRAMES g_magnet_summary_tfs[];
string g_matrix_tf_strings[];
ENUM_TIMEFRAMES g_matrix_tfs[];
string g_hud_tf_strings[];
ENUM_TIMEFRAMES g_hud_tfs[];
// --- UI State Globals ---
bool g_market_overview_expanded = true;
bool g_zone_context_expanded = true;
bool g_magnets_hud_expanded = true;
bool g_alerts_events_expanded = true;

// --- Live Data Caches ---
CachedCompassData g_compass_cache[7];
CachedSupDemData  g_supdem_cache[7];
CachedHUDData     g_hud_cache[7];
CachedBrainData   g_brain_cache;
string g_last_alfred_comment = "";


//+------------------------------------------------------------------+
//|                        LIVE DATA & CACHING FUNCTIONS             |
//+------------------------------------------------------------------+
void UpdateLiveDataCaches()
{
   if(EnableDebugLogging)
      Print("--- AAI Dashboard: Updating Live Data Caches ---");
   // --- Cache SignalBrain Data ---
   if(ShowAlfredBrainModule)
   {
      double brain_buffers[4]; // 0:Signal, 1:Confidence, 2:ReasonCode, 3:ZoneTF
      if(CopyBuffer(iCustom(_Symbol, _Period, "AAI_Indicator_SignalBrain.ex5"), 0, 0, 4, brain_buffers) >= 4)
      {
         g_brain_cache.signal = (ENUM_TRADE_SIGNAL)brain_buffers[0];
         g_brain_cache.confidence = brain_buffers[1];
         g_brain_cache.reasonCode = (ENUM_REASON_CODE)brain_buffers[2];
         g_brain_cache.zoneTF = (int)brain_buffers[3];
      }
   }
      
   // Get handles ONCE per update cycle for efficiency
   int hud_handle = iCustom(_Symbol, _Period, "AAI_Indicator_HUD.ex5");
   for(int i = 0; i < ArraySize(g_timeframes); i++)
   {
      ENUM_TIMEFRAMES tf = g_timeframes[i];
      string tf_str = g_timeframe_strings[i];

      // --- Cache BiasCompass Data ---
      int compass_handle = iCustom(_Symbol, tf, "AAI_Indicator_BiasCompass.ex5");
      if(compass_handle != INVALID_HANDLE)
      {
         double bias_buffer[1], conf_buffer[1];
         if(CopyBuffer(compass_handle, 0, 0, 1, bias_buffer) > 0 && CopyBuffer(compass_handle, 1, 0, 1, conf_buffer) > 0)
         {
            if(bias_buffer[0] > 0.5) g_compass_cache[i].bias = BIAS_BULL;
            else if(bias_buffer[0] < -0.5) g_compass_cache[i].bias = BIAS_BEAR;
            else g_compass_cache[i].bias = BIAS_NEUTRAL;
            g_compass_cache[i].confidence = conf_buffer[0];
         }
      }

      // --- Cache ZoneEngine Data ---
      int zone_engine_handle = iCustom(_Symbol, tf, "AAI_Indicator_ZoneEngine.ex5");
      if(zone_engine_handle != INVALID_HANDLE)
      {
         double zone_buffer[1], magnet_buffer[1], strength_buffer[1], fresh_buffer[1], volume_buffer[1], liq_buffer[1];
         g_supdem_cache[i].zone = ZONE_NONE;
         if(CopyBuffer(zone_engine_handle, 0, 0, 1, zone_buffer) > 0)
         {
            if(zone_buffer[0] > 0.5) g_supdem_cache[i].zone = ZONE_DEMAND;
            else if(zone_buffer[0] < -0.5) g_supdem_cache[i].zone = ZONE_SUPPLY;
         }
         if(CopyBuffer(zone_engine_handle, 1, 0, 1, magnet_buffer) > 0) g_supdem_cache[i].magnet_level = magnet_buffer[0];
         if(CopyBuffer(zone_engine_handle, 2, 0, 1, strength_buffer) > 0) g_supdem_cache[i].strength = strength_buffer[0];
         if(CopyBuffer(zone_engine_handle, 3, 0, 1, fresh_buffer) > 0) g_supdem_cache[i].freshness = fresh_buffer[0];
         if(CopyBuffer(zone_engine_handle, 4, 0, 1, volume_buffer) > 0) g_supdem_cache[i].volume = volume_buffer[0];
         if(CopyBuffer(zone_engine_handle, 5, 0, 1, liq_buffer) > 0) g_supdem_cache[i].liquidity = liq_buffer[0];
      }

      // --- Cache HUD Data ---
      if(hud_handle != INVALID_HANDLE)
      {
         int buffer_index = -1;
         if(tf == PERIOD_M15) buffer_index = 5;
         else if(tf == PERIOD_H1) buffer_index = 3;
         else if(tf == PERIOD_H4) buffer_index = 1;
         if(buffer_index != -1)
         {
            double activity_buffer[1];
            if(CopyBuffer(hud_handle, buffer_index, 0, 1, activity_buffer) > 0)
            {
               g_hud_cache[i].zone_active = (activity_buffer[0] > 0.5);
            }
         }
      }
   }
}


// Helper to get the correct cache index for a given timeframe
int GetCacheIndex(ENUM_TIMEFRAMES tf)
{
   for(int i = 0; i < ArraySize(g_timeframes); i++)
   {
      if(g_timeframes[i] == tf)
         return i;
   }
   return -1; // Not found
}


//+------------------------------------------------------------------+
//|                   LIVE & MOCK DATA FUNCTIONS                     |
//+------------------------------------------------------------------+
CompassData GetCompassData(ENUM_TIMEFRAMES tf)
{
   CompassData data;
   int index = GetCacheIndex(tf);
   if(index != -1)
   {
      data.bias = g_compass_cache[index].bias;
      data.confidence = g_compass_cache[index].confidence;
   }
   else
   {
      data.bias = BIAS_NEUTRAL;
      data.confidence = 0.0;
   }
   return data;
}

CachedSupDemData GetSupDemData(ENUM_TIMEFRAMES tf)
{
   CachedSupDemData data;
   int index = GetCacheIndex(tf);
   if(index != -1)
   {
      return g_supdem_cache[index];
   }
   data.zone = ZONE_NONE;
   data.magnet_level = 0.0;
   data.strength = 0.0;
   data.freshness = 0.0;
   data.volume = 0.0;
   data.liquidity = 0.0;
   return data;
}


ENUM_ZONE GetZoneStatus(ENUM_TIMEFRAMES tf)
{
   int index = GetCacheIndex(tf);
   if(index != -1)
   {
      return g_supdem_cache[index].zone;
   }
   return ZONE_NONE;
}

double GetMagnetLevelTF(ENUM_TIMEFRAMES tf)
{
   int index = GetCacheIndex(tf);
   if(index != -1)
   {
      return g_supdem_cache[index].magnet_level;
   }
   return 0.0;
}

bool GetHUDZoneActivity(ENUM_TIMEFRAMES tf)
{
   int index = GetCacheIndex(tf);
   if(index != -1)
   {
      return g_hud_cache[index].zone_active;
   }
   return false;
}

double GetMagnetProjectionLevel()
{
   return GetMagnetLevelTF(_Period);
}

ENUM_TRADE_SIGNAL GetTradeSignal()
{
   TradeRecommendation rec = GetTradeRecommendation();
   return rec.action;
}

ENUM_ZONE_INTERACTION GetCurrentZoneInteraction()
{
   ENUM_ZONE current_zone = GetZoneStatus(_Period);
   switch(current_zone)
   {
      case ZONE_DEMAND: return INTERACTION_INSIDE_DEMAND;
      case ZONE_SUPPLY: return INTERACTION_INSIDE_SUPPLY;
      default: return INTERACTION_NONE;
   }
}

ENUM_HEATMAP_STATUS GetZoneHeatmapStatus(ENUM_TIMEFRAMES tf)
{
   switch(GetZoneStatus(tf))
   {
      case ZONE_DEMAND: return HEATMAP_DEMAND;
      case ZONE_SUPPLY: return HEATMAP_SUPPLY;
      default: return HEATMAP_NONE;
   }
}

ENUM_MAGNET_RELATION GetMagnetProjectionRelation(double price, double magnet)
{
   if(price == 0 || magnet == 0) return RELATION_AT;
   double proximity = 5 * _Point;
   if(price > magnet + proximity) return RELATION_ABOVE;
   if(price < magnet - proximity) return RELATION_BELOW;
   return RELATION_AT;
}

ENUM_MAGNET_RELATION GetMagnetRelationTF(double price, double magnet)
{
   if(price == 0 || magnet == 0) return RELATION_AT;
   if(price > magnet) return RELATION_ABOVE;
   if(price < magnet) return RELATION_BELOW;
   return RELATION_AT;
}

MatrixRowData GetConfidenceMatrixRow(ENUM_TIMEFRAMES tf)
{
   MatrixRowData data;
   data.bias = GetCompassData(tf).bias;
   data.zone = GetZoneStatus(tf);
   double magnet_level = GetMagnetLevelTF(tf);
   data.magnet = GetMagnetRelationTF(SymbolInfoDouble(_Symbol, SYMBOL_BID), magnet_level);
   double strength_raw = iCustom(_Symbol, tf, "AAI_Indicator_ZoneEngine.ex5", 2, 0);
   double freshness_raw = iCustom(_Symbol, tf, "AAI_Indicator_ZoneEngine.ex5", 3, 0);
   double volume_raw = iCustom(_Symbol, tf, "AAI_Indicator_ZoneEngine.ex5", 4, 0);
   double liquidity_raw = iCustom(_Symbol, tf, "AAI_Indicator_ZoneEngine.ex5", 5, 0);

   int zoneStrength = (int)strength_raw;
   bool zoneFreshness = freshness_raw > 0.5;
   bool zoneVolume = volume_raw > 0.5;
   bool zoneLiquidity = liquidity_raw > 0.5;
   data.score = zoneStrength * 2 + (zoneFreshness ? 3 : 0) + (zoneVolume ? 2 : 0) + (zoneLiquidity ? 3 : 0);
   return data;
}

TradeRecommendation GetTradeRecommendation()
{
   TradeRecommendation rec;
   rec.action = SIGNAL_NONE;
   rec.reasoning = "Mixed Signals";
   #define STRONG_CONFIDENCE_THRESHOLD 10

   int strong_bullish_tfs = 0;
   int strong_bearish_tfs = 0;
   for(int i = 0; i < ArraySize(g_matrix_tfs); i++)
   {
      MatrixRowData row = GetConfidenceMatrixRow(g_matrix_tfs[i]);
      if(row.score >= STRONG_CONFIDENCE_THRESHOLD)
      {
         if(row.bias == BIAS_BULL)
            strong_bullish_tfs++;
         if(row.bias == BIAS_BEAR)
            strong_bearish_tfs++;
      }
   }

   if(strong_bullish_tfs >= 2)
   {
      rec.action = SIGNAL_BUY;
      rec.reasoning = "Strong Multi-TF Bullish Alignment";
      double best_score = -1;
      string best_reason = "";
      for(int i = 0; i < ArraySize(g_matrix_tfs); i++)
      {
         MatrixRowData row = GetConfidenceMatrixRow(g_matrix_tfs[i]);
         if(row.score >= STRONG_CONFIDENCE_THRESHOLD && row.bias == BIAS_BULL)
         {
            CachedSupDemData zone_data = GetSupDemData(g_matrix_tfs[i]);
            if(zone_data.zone == ZONE_DEMAND)
            {
               double current_score = zone_data.strength + (zone_data.liquidity > 0.5 ? 5 : 0);
               if(current_score > best_score)
               {
                  best_score = current_score;
                  best_reason = ". " + g_matrix_tf_strings[i] + " zone strength " + (string)zone_data.strength + "/10";
                  if(zone_data.liquidity > 0.5)
                     best_reason += " (Liq. Grab)";
               }
            }
         }
      }
      rec.reasoning += best_reason;
   }
   else if(strong_bearish_tfs >= 2)
   {
      rec.action = SIGNAL_SELL;
      rec.reasoning = "Strong Multi-TF Bearish Alignment";
      double best_score = -1;
      string best_reason = "";
      for(int i = 0; i < ArraySize(g_matrix_tfs); i++)
      {
         MatrixRowData row = GetConfidenceMatrixRow(g_matrix_tfs[i]);
         if(row.score >= STRONG_CONFIDENCE_THRESHOLD && row.bias == BIAS_BEAR)
         {
            CachedSupDemData zone_data = GetSupDemData(g_matrix_tfs[i]);
            if(zone_data.zone == ZONE_SUPPLY)
            {
               double current_score = zone_data.strength + (zone_data.liquidity > 0.5 ? 5 : 0);
               if(current_score > best_score)
               {
                  best_score = current_score;
                  best_reason = ". " + g_matrix_tf_strings[i] + " zone strength " + (string)zone_data.strength + "/10";
                  if(zone_data.liquidity > 0.5)
                     best_reason += " (Liq. Grab)";
               }
            }
         }
      }
      rec.reasoning += best_reason;
   }
   return rec;
}

AlfredComment GetAlfredComment()
{
    AlfredComment comment;
    comment.text = "Alfred is observing...";
    comment.clr = COLOR_TEXT_DIM;
    int bull_strong_count = 0;
    int bear_strong_count = 0;
    int total_score = 0;
    int total_tfs = ArraySize(g_matrix_tfs);
    for(int i = 0; i < total_tfs; i++)
    {
        MatrixRowData row = GetConfidenceMatrixRow(g_matrix_tfs[i]);
        total_score += row.score;
        if (row.score >= 10)
        {
            if (row.bias == BIAS_BULL) bull_strong_count++;
            else if (row.bias == BIAS_BEAR) bear_strong_count++;
        }
    }
    if (bull_strong_count >= 3 && bear_strong_count == 0)
    {
        comment.text = "Looks like a power move building. Watching upside.";
        comment.clr = COLOR_BULL;
        return comment;
    }
    if (bear_strong_count >= 3 && bull_strong_count == 0)
    {
        comment.text = "Momentum is heavy. Alfred sees potential drops.";
        comment.clr = COLOR_BEAR;
        return comment;
    }
    MatrixRowData d1_data = GetConfidenceMatrixRow(PERIOD_D1);
    MatrixRowData m15_data = GetConfidenceMatrixRow(PERIOD_M15);
    if (d1_data.bias != BIAS_NEUTRAL && m15_data.bias != BIAS_NEUTRAL && d1_data.bias != m15_data.bias)
    {
        comment.text = "Market's arguing. Sit tight or scalp the mess.";
        comment.clr = COLOR_ALFRED_CAUTION;
        return comment;
    }
    if (bull_strong_count == 0 && bear_strong_count == 0 && (total_tfs > 0 && (total_score / total_tfs) < 5))
    {
        comment.text = "Momentum fading... don't get caught snoozing, boss.";
        comment.clr = clrSilver;
        return comment;
    }
    if (d1_data.score > 12)
    {
        if (d1_data.bias == BIAS_BULL)
        {
           comment.text = "Big players just turned. D1 bias is bullish.";
           comment.clr = COLOR_BULL;
           return comment;
        }
        else if (d1_data.bias == BIAS_BEAR)
        {
           comment.text = "The daily chart looks heavy. Bearish pressure on.";
           comment.clr = COLOR_BEAR;
           return comment;
        }
    }
    return comment;
}

RiskModuleData GetRiskModuleData()
{
   RiskModuleData data;
   data.risk_percent = 1.0;
   data.position_size = 0.10;
   int rand_val = MathRand() % 3;
   switch(rand_val)
   {
      case 0: data.rr_ratio = "1 : 1.5"; break;
      case 1: data.rr_ratio = "1 : 2.0"; break;
      default: data.rr_ratio = "1 : 3.0"; break;
   }
   return data;
}

SessionData GetSessionData()
{
   SessionData data;
   MqlDateTime dt;
   TimeCurrent(dt);
   int hour = dt.hour;
   if(hour >= 13 && hour < 16) data.session_name = "London / NY";
   else if(hour >= 8 && hour < 13) data.session_name = "London";
   else if(hour >= 16 && hour < 21) data.session_name = "New York";
   else if(hour >= 21 || hour < 6) data.session_name = "Sydney";
   else if(hour >= 6 && hour < 8) data.session_name = "Tokyo";
   else data.session_name = "Inter-Session";
   if(hour >= 13 && hour < 16) data.session_overlap = "NY + London";
   else data.session_overlap = "None";
   int rand_val = MathRand() % 3;
   switch(rand_val)
   {
      case 0: data.volatility = VOLATILITY_LOW; break;
      case 1: data.volatility = VOLATILITY_MEDIUM; break;
      default: data.volatility = VOLATILITY_HIGH; break;
   }
   return data;
}

int GetUpcomingNews(NewsEventData &news_array[])
{
   static NewsEventData all_news[] =
   {
      {"14:30", "USD", "Non-Farm Payrolls", IMPACT_HIGH},
      {"16:00", "EUR", "CPI YoY", IMPACT_MEDIUM},
      {"22:00", "NZD", "Official Cash Rate", IMPACT_HIGH},
      {"01:30", "AUD", "Retail Sales MoM", IMPACT_LOW}
   };
   int count = MathMin(MAX_NEWS_ITEMS, ArraySize(all_news));
   for(int i = 0; i < count; i++)
   {
      news_array[i] = all_news[i];
   }
   return count;
}

EmotionalStateData GetEmotionalState()
{
   EmotionalStateData data;
   long time_cycle = TimeCurrent() / 180;
   switch(time_cycle % 5)
   {
      case 0: data.state = STATE_CONFIDENT; data.text = "Confident – Trend Aligned"; break;
      case 1: data.state = STATE_CAUTIOUS; data.text = "Cautious – Awaiting Confirmation"; break;
      case 2: data.state = STATE_OVEREXTENDED; data.text = "Overextended – Risk of Reversal"; break;
      case 3: data.state = STATE_ANXIOUS; data.text = "Anxious – Overtrading Zone"; break;
      default: data.state = STATE_NEUTRAL; data.text = "Neutral – Balanced Mindset"; break;
   }
   return data;
}

AlertData GetAlertCenterStatus()
{
   AlertData alert;
   for(int i = 0; i < ArraySize(g_matrix_tfs); i++)
   {
      CachedSupDemData data = GetSupDemData(g_matrix_tfs[i]);
      if(data.liquidity > 0.5)
      {
         alert.status = ALERT_STRONG;
         alert.text = "🔥 Liquidity Grab Confirmed! (" + g_matrix_tf_strings[i] + ")";
         return alert;
      }
   }

   #define STRONG_CONFIDENCE_THRESHOLD_ALERT 10
   #define MEDIUM_CONFIDENCE_THRESHOLD_ALERT 5
   
   int strong_count = 0;
   int medium_count = 0;
   for(int i = 0; i < ArraySize(g_matrix_tfs); i++)
   {
      MatrixRowData row = GetConfidenceMatrixRow(g_matrix_tfs[i]);
      if(row.score >= STRONG_CONFIDENCE_THRESHOLD_ALERT) strong_count++;
      else if(row.score >= MEDIUM_CONFIDENCE_THRESHOLD_ALERT) medium_count++;
   }

   if(strong_count > 0)
   {
      alert.status = ALERT_STRONG;
      alert.text = "✅ STRONG ALIGNMENT — High-Conviction Setup";
   }
   else if(medium_count > 0)
   {
      alert.status = ALERT_PARTIAL;
      alert.text = "⚠️ Partial Alignment — Watch for Entry Trigger";
   }
   else
   {
      alert.status = ALERT_NONE;
      alert.text = "⏳ No Signal — Standby";
   }
   return alert;
}


LiveTradeData FetchTradeLevels()
{
   LiveTradeData data;
   data.trade_exists = false;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
         data.trade_exists = true;
         data.entry = PositionGetDouble(POSITION_PRICE_OPEN);
         data.sl = PositionGetDouble(POSITION_SL);
         data.tp = PositionGetDouble(POSITION_TP);
         break;
      }
   }
   return data;
}


//+------------------------------------------------------------------+
//|                     HELPER & CONVERSION FUNCTIONS                |
//+------------------------------------------------------------------+
string ReasonCodeToString(ENUM_REASON_CODE code)
{
    switch(code)
    {
        case REASON_BUY_LIQ_GRAB_ALIGNED: return "Strong demand zone + HTF bias match + liquidity grab confirmed.";
        case REASON_SELL_LIQ_GRAB_ALIGNED: return "Strong supply zone + HTF bias match + liquidity grab confirmed.";
        case REASON_NO_ZONE: return "Price is not inside a valid zone.";
        case REASON_LOW_ZONE_STRENGTH: return "Active zone quality is too low.";
        case REASON_BIAS_CONFLICT: return "HTF & LTF biases are conflicting.";
        default: return "No valid setup at the moment. Standing by.";
    }
}

string PeriodMinutesToTFString(int minutes)
{
    if(minutes >= 1440) return "D"+IntegerToString(minutes/1440);
    if(minutes >= 60)   return "H"+IntegerToString(minutes/60);
    if(minutes > 0)     return "M"+IntegerToString(minutes);
    return "Chart";
}
double CalculatePips(double p1, double p2)
{
   if(g_pip_value == 0 || p1 == 0 || p2 == 0) return 0;
   return MathAbs(p1 - p2) / g_pip_value;
}
string BiasToString(ENUM_BIAS b){switch(b){case BIAS_BULL:return"BULL";case BIAS_BEAR:return"BEAR";}return"NEUTRAL";}
color  BiasToColor(ENUM_BIAS b){switch(b){case BIAS_BULL:return COLOR_BULL;case BIAS_BEAR:return COLOR_BEAR;}return COLOR_NEUTRAL_BIAS;}
string ZoneToString(ENUM_ZONE z){switch(z){case ZONE_DEMAND:return"Demand";case ZONE_SUPPLY:return"Supply";}return"None";}
color  ZoneToColor(ENUM_ZONE z){switch(z){case ZONE_DEMAND:return COLOR_DEMAND;case ZONE_SUPPLY:return COLOR_SUPPLY;}return COLOR_NA;}
string SignalToString(ENUM_TRADE_SIGNAL s){switch(s){case SIGNAL_BUY:return"BUY";case SIGNAL_SELL:return"SELL";}return"NO SIGNAL";}
color  SignalToColor(ENUM_TRADE_SIGNAL s){switch(s){case SIGNAL_BUY:return COLOR_BULL;case SIGNAL_SELL:return COLOR_BEAR;}return COLOR_NO_SIGNAL;}
string ZoneInteractionToString(ENUM_ZONE_INTERACTION z){switch(z){case INTERACTION_INSIDE_DEMAND:return"INSIDE DEMAND";case INTERACTION_INSIDE_SUPPLY:return"INSIDE SUPPLY";}return"NO ZONE INTERACTION";}
color  ZoneInteractionToColor(ENUM_ZONE_INTERACTION z){switch(z){case INTERACTION_INSIDE_DEMAND:return COLOR_DEMAND;case INTERACTION_INSIDE_SUPPLY:return COLOR_SUPPLY;}return COLOR_NA;}
color  ZoneInteractionToHighlightColor(ENUM_ZONE_INTERACTION z){switch(z){case INTERACTION_INSIDE_DEMAND:return COLOR_HIGHLIGHT_DEMAND;case INTERACTION_INSIDE_SUPPLY:return COLOR_HIGHLIGHT_SUPPLY;}return COLOR_HIGHLIGHT_NONE;}
string HeatmapStatusToString(ENUM_HEATMAP_STATUS s){switch(s){case HEATMAP_DEMAND:return"D";case HEATMAP_SUPPLY:return"S";}return"-";}
color  HeatmapStatusToColor(ENUM_HEATMAP_STATUS s){switch(s){case HEATMAP_DEMAND:return COLOR_DEMAND;case HEATMAP_SUPPLY:return COLOR_SUPPLY;}return COLOR_NA;}
string MagnetRelationToString(ENUM_MAGNET_RELATION r){switch(r){case RELATION_ABOVE:return"(Above)";case RELATION_BELOW:return"(Below)";}return"(At)";}
color  MagnetRelationToColor(ENUM_MAGNET_RELATION r){switch(r){case RELATION_ABOVE:return COLOR_BULL;case RELATION_BELOW:return COLOR_BEAR;}return COLOR_MAGNET_AT;}
string MagnetRelationTFToString(ENUM_MAGNET_RELATION r){switch(r){case RELATION_ABOVE:return"Above";case RELATION_BELOW:return"Below";}return"At";}
color  MagnetRelationTFToColor(ENUM_MAGNET_RELATION r){switch(r){case RELATION_ABOVE:return COLOR_BULL;case RELATION_BELOW:return COLOR_BEAR;}return COLOR_MAGNET_AT;}
color GetConfidenceColor(int score){if(score>=16)return(color)ColorToARGB(clrDodgerBlue,120);if(score>=10)return(color)ColorToARGB(clrLimeGreen,120);if(score>=5)return(color)ColorToARGB(clrGoldenrod,100);return(color)ColorToARGB(clrOrangeRed,120);}
string RecoActionToString(ENUM_TRADE_SIGNAL s){switch(s){case SIGNAL_BUY:return"BUY";case SIGNAL_SELL:return"SELL";}return"WAIT";}
color RecoActionToColor(ENUM_TRADE_SIGNAL s){switch(s){case SIGNAL_BUY:return COLOR_BULL;case SIGNAL_SELL:return COLOR_BEAR;}return COLOR_NO_SIGNAL;}
string VolatilityToString(ENUM_VOLATILITY v){switch(v){case VOLATILITY_LOW:return"Low";case VOLATILITY_MEDIUM:return"Medium";}return"High";}
color VolatilityToColor(ENUM_VOLATILITY v){switch(v){case VOLATILITY_LOW:return COLOR_BULL;case VOLATILITY_MEDIUM:return COLOR_MAGNET_AT;}return COLOR_BEAR;}
color VolatilityToHighlightColor(ENUM_VOLATILITY v){switch(v){case VOLATILITY_LOW:return COLOR_VOL_LOW_BG;case VOLATILITY_MEDIUM:return COLOR_VOL_MED_BG;}return COLOR_VOL_HIGH_BG;}
string NewsImpactToString(ENUM_NEWS_IMPACT i){switch(i){case IMPACT_LOW:return"LOW";case IMPACT_MEDIUM:return"MEDIUM";}return"HIGH";}
color NewsImpactToColor(ENUM_NEWS_IMPACT i){switch(i){case IMPACT_LOW:return COLOR_IMPACT_LOW;case IMPACT_MEDIUM:return COLOR_IMPACT_MEDIUM;}return COLOR_IMPACT_HIGH;}
color EmotionalStateToColor(ENUM_EMOTIONAL_STATE s){switch(s){case STATE_CAUTIOUS:return COLOR_STATE_CAUTIOUS;case STATE_CONFIDENT:return COLOR_STATE_CONFIDENT;case STATE_OVEREXTENDED:return COLOR_STATE_OVEREXTENDED;case STATE_ANXIOUS:return COLOR_STATE_ANXIOUS;}return COLOR_STATE_NEUTRAL;}
color AlertStatusToColor(ENUM_ALERT_STATUS s){switch(s){case ALERT_STRONG:return COLOR_ALERT_STRONG;case ALERT_PARTIAL:return COLOR_ALERT_PARTIAL;}return COLOR_ALERT_NONE;}
string GetBiasLabelFromZone(int zone_val){if(zone_val==1)return"Bull";if(zone_val==-1)return"Bear";return"Neutral";}
color GetBiasColorFromZone(int zone_val){if(zone_val==1)return COLOR_BULL;if(zone_val==-1)return COLOR_BEAR;return COLOR_NEUTRAL_BIAS;}
string GetMagnetRelationLabel(double current_price,double magnet_level){if(magnet_level==0.0)return"N/A";double proximity=5*_Point;if(current_price>magnet_level+proximity)return"Above";if(current_price<magnet_level-proximity)return"Below";return"At";}
color GetMagnetRelationColor(string relation){if(relation=="Above")return COLOR_BULL;if(relation=="Below")return COLOR_BEAR;if(relation=="At")return COLOR_MAGNET_AT;return COLOR_NA;}
color GetHeatColorForStrength(int strength){if(strength>=8)return clrRed;if(strength>=5)return clrOrange;if(strength>=1)return clrGold;return clrSilver;}


//+------------------------------------------------------------------+
//|                       UI DRAWING HELPERS                         |
//+------------------------------------------------------------------+
void CreateLabel(string n, string t, int x, int y, color c, int fs = FONT_SIZE_NORMAL, ENUM_ANCHOR_POINT a = ANCHOR_LEFT)
{
   string o = PANE_PREFIX + n;
   ObjectCreate(0, o, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, o, OBJPROP_TEXT, t);
   ObjectSetInteger(0, o, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, o, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, o, OBJPROP_COLOR, c);
   ObjectSetInteger(0, o, OBJPROP_FONTSIZE, fs);
   ObjectSetString(0, o, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, o, OBJPROP_ANCHOR, a);
   ObjectSetInteger(0, o, OBJPROP_BACK, false);
   ObjectSetInteger(0, o, OBJPROP_CORNER, 0);
}
void CreateRectangle(string n, int x, int y, int w, int h, color c, ENUM_BORDER_TYPE b = BORDER_FLAT)
{
   string o = PANE_PREFIX + n;
   ObjectCreate(0, o, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, o, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, o, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, o, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, o, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, o, OBJPROP_BGCOLOR, c);
   ObjectSetInteger(0, o, OBJPROP_COLOR, c);
   ObjectSetInteger(0, o, OBJPROP_BORDER_TYPE, b);
   ObjectSetInteger(0, o, OBJPROP_BACK, true);
   ObjectSetInteger(0, o, OBJPROP_CORNER, 0);
}
void UpdateLabel(string n, string t, color c = clrNONE)
{
   string o = PANE_PREFIX + n;
   if(ObjectFind(0, o) < 0) return;
   ObjectSetString(0, o, OBJPROP_TEXT, t);
   if(c != clrNONE) ObjectSetInteger(0, o, OBJPROP_COLOR, c);
}
void DrawSeparator(string name, int &y_offset, int x_offset)
{
   CreateLabel(name, SEPARATOR_TEXT, x_offset, y_offset, COLOR_SEPARATOR);
   y_offset += SPACING_SEPARATOR;
}
void CreateToggle(string name, string text, int &y_offset, int x_offset, bool is_expanded)
{
    int x_toggle = PANE_X_POS + PANE_WIDTH - 20;
    CreateLabel(name + "_Header", text, x_offset, y_offset, COLOR_HEADER, FONT_SIZE_HEADER);
    CreateLabel("Toggle_" + name, is_expanded ? "[-]" : "[+]", x_toggle, y_offset, COLOR_TOGGLE, FONT_SIZE_HEADER);
    y_offset += SPACING_MEDIUM;
}


//+------------------------------------------------------------------+
//|                 MAIN PANEL CREATION & UPDATE LOGIC               |
//+------------------------------------------------------------------+
void CreatePanel()
{
   int x_offset = PANE_X_POS + 10;
   int y_offset = PANE_Y_POS + 10;

   // --- TOP FIXED PANEL ---
   // Row 1: Symbol & Final Signal
   CreateLabel("top_symbol", _Symbol, x_offset, y_offset, COLOR_HEADER, FONT_SIZE_SIGNAL_ACTIVE);
   CreateLabel("top_signal", "WAIT", x_offset + 90, y_offset, COLOR_NO_SIGNAL, FONT_SIZE_SIGNAL_ACTIVE);
   CreateLabel("top_confidence", "(0%)", x_offset + 160, y_offset, COLOR_TEXT_DIM, FONT_SIZE_NORMAL);
   y_offset += SPACING_MEDIUM;

   // Row 2: Alfred Says
   CreateLabel("top_alfred_says_prefix", "🗣️", x_offset, y_offset, COLOR_TEXT_DIM, FONT_SIZE_NORMAL);
   CreateLabel("top_alfred_says", "Alfred is observing...", x_offset + 20, y_offset, COLOR_TEXT_DIM, FONT_SIZE_NORMAL);
   y_offset += SPACING_MEDIUM;
   
   // Row 3: Risk Module
   CreateLabel("top_risk_pct", "Risk: --", x_offset, y_offset, COLOR_TEXT_DIM);
   CreateLabel("top_risk_pos", "Pos: --", x_offset + 80, y_offset, COLOR_TEXT_DIM);
   CreateLabel("top_risk_rr", "RR: --", x_offset + 160, y_offset, COLOR_TEXT_DIM);
   y_offset += SPACING_MEDIUM;

   // Row 4: Live Trade SL/TP
   CreateLabel("top_trade_sl", "SL: ---", x_offset, y_offset, COLOR_BEAR);
   CreateLabel("top_trade_tp", "TP: ---", x_offset + 110, y_offset, COLOR_BULL);
   y_offset += SPACING_MEDIUM;

   // Row 5: Session & Volatility
   CreateLabel("top_session", "Session: ---", x_offset, y_offset, COLOR_SESSION);
   CreateRectangle("top_vol_bg", x_offset + 140, y_offset - 2, 60, 14, clrNONE);
   CreateLabel("top_vol", "Vol: ---", x_offset + 145, y_offset, COLOR_NEUTRAL_TEXT);
   y_offset += SPACING_MEDIUM;
   
   // Row 6: TF Bias Summary
   CreateLabel("top_bias_m15", "M15: -", x_offset, y_offset, COLOR_NA);
   CreateLabel("top_bias_h1", "H1: -", x_offset + 75, y_offset, COLOR_NA);
   CreateLabel("top_bias_h4", "H4: -", x_offset + 150, y_offset, COLOR_NA);
   y_offset += SPACING_SMALL;
   
   DrawSeparator("sep_top", y_offset, x_offset);

   // --- COLLAPSIBLE SECTIONS ---
   
   // --- Market Overview Section ---
   CreateToggle("MarketOverview", "📊 Market Overview", y_offset, x_offset, g_market_overview_expanded);
   if(g_market_overview_expanded)
   {
      // Headers
      CreateLabel("mo_hdr_tf", "TF", x_offset, y_offset, COLOR_HEADER);
      CreateLabel("mo_hdr_bias", "Bias", x_offset + 40, y_offset, COLOR_HEADER);
      CreateLabel("mo_hdr_zone", "Zone", x_offset + 100, y_offset, COLOR_HEADER);
      CreateLabel("mo_hdr_conf", "Conf", x_offset + 160, y_offset, COLOR_HEADER);
      y_offset += SPACING_SMALL;
      
      for(int i = 0; i < ArraySize(g_matrix_tfs); i++)
      {
         string tf = g_matrix_tf_strings[i];
         CreateRectangle("mo_bg_" + tf, x_offset - 5, y_offset - 2, PANE_WIDTH - 20, 14, clrNONE);
         CreateLabel("mo_tf_" + tf, tf, x_offset, y_offset, COLOR_NEUTRAL_TEXT);
         CreateLabel("mo_bias_" + tf, "---", x_offset + 40, y_offset, COLOR_NA);
         CreateLabel("mo_zone_" + tf, "---", x_offset + 100, y_offset, COLOR_NA);
         CreateLabel("mo_conf_" + tf, "---", x_offset + 160, y_offset, COLOR_NA);
         y_offset += SPACING_SMALL;
      }
   }
   DrawSeparator("sep_market_overview", y_offset, x_offset);
   
   // --- Zone Context Section ---
   CreateToggle("ZoneContext", "📦 Zone Context", y_offset, x_offset, g_zone_context_expanded);
   if(g_zone_context_expanded)
   {
      CreateLabel("zc_status_prefix", "Status:", x_offset, y_offset, COLOR_HEADER);
      CreateLabel("zc_status_value", "NO ZONE", x_offset + 80, y_offset, COLOR_NA);
      y_offset += SPACING_SMALL;
      
      CreateLabel("zc_strength_prefix", "Strength:", x_offset, y_offset, COLOR_HEADER);
      CreateLabel("zc_strength_value", "N/A", x_offset + 80, y_offset, COLOR_NA);
      y_offset += SPACING_SMALL;

      CreateLabel("zc_details_prefix", "Details:", x_offset, y_offset, COLOR_HEADER);
      CreateLabel("zc_details_value", "Fresh: N/A, Vol: N/A, Liq: No", x_offset + 80, y_offset, COLOR_NA);
      y_offset += SPACING_SMALL;
      
      // Heatmap
      int heatmap_x = x_offset + 10;
      for(int i = 0; i < ArraySize(g_heatmap_tf_strings); i++)
      {
         string tf = g_heatmap_tf_strings[i];
         CreateLabel("zc_heatmap_tf_" + tf, tf, heatmap_x, y_offset, COLOR_HEADER, FONT_SIZE_NORMAL, ANCHOR_CENTER);
         CreateLabel("zc_heatmap_status_" + tf, "-", heatmap_x, y_offset + 12, COLOR_NA, FONT_SIZE_NORMAL, ANCHOR_CENTER);
         heatmap_x += 35;
      }
      y_offset += SPACING_LARGE;
   }
   DrawSeparator("sep_zone_context", y_offset, x_offset);

   // --- Magnets & HUD Section ---
   CreateToggle("MagnetsHUD", "🛰️ Magnets & HUD", y_offset, x_offset, g_magnets_hud_expanded);
   if(g_magnets_hud_expanded)
   {
       int mtf_magnet_x1 = x_offset, mtf_magnet_x2 = x_offset + 70, mtf_magnet_x3 = x_offset + 140;
       for(int i = 0; i < ArraySize(g_magnet_summary_tfs); i++)
       {
          string tf = g_magnet_summary_tf_strings[i];
          CreateLabel("mh_magnet_tf_" + tf, tf + " →", mtf_magnet_x1, y_offset, COLOR_HEADER);
          CreateLabel("mh_magnet_relation_" + tf, "---", mtf_magnet_x2, y_offset, COLOR_NA);
          CreateLabel("mh_magnet_level_" + tf, "(---)", mtf_magnet_x3, y_offset, COLOR_NA); 
          y_offset += SPACING_SMALL;
       }
       y_offset += 4; // Extra spacing
       // HUD Activity
       int hud_activity_x = x_offset + 20;
       for(int i = 0; i < ArraySize(g_hud_tf_strings); i++)
       {
          string tf = g_hud_tf_strings[i];
          CreateLabel("mh_hud_tf_" + tf, tf, hud_activity_x, y_offset, COLOR_HEADER, FONT_SIZE_NORMAL, ANCHOR_CENTER);
          CreateLabel("mh_hud_status_" + tf, "N/A", hud_activity_x, y_offset + 12, COLOR_NA, FONT_SIZE_NORMAL + 2, ANCHOR_CENTER);
          hud_activity_x += 45;
       }
       y_offset += SPACING_LARGE;
   }
   DrawSeparator("sep_magnets_hud", y_offset, x_offset);

   // --- Alerts & Events Section ---
   CreateToggle("AlertsEvents", "🔔 Alerts & Events", y_offset, x_offset, g_alerts_events_expanded);
   if(g_alerts_events_expanded)
   {
      // Alert Center
      CreateLabel("ae_alert_status", "---", x_offset, y_offset, COLOR_NA, FONT_SIZE_NORMAL);
      y_offset += SPACING_MEDIUM;
      // News
      for(int i = 0; i < MAX_NEWS_ITEMS; i++)
      {
         string idx = IntegerToString(i);
         CreateLabel("ae_news_time_" + idx, "", x_offset, y_offset, COLOR_TEXT_DIM);
         CreateLabel("ae_news_curr_" + idx, "", x_offset + 40, y_offset, COLOR_NEUTRAL_TEXT);
         CreateLabel("ae_news_event_" + idx, "", x_offset + 75, y_offset, COLOR_NEUTRAL_TEXT);
         CreateLabel("ae_news_impact_" + idx, "", x_offset + 180, y_offset, COLOR_NEUTRAL_TEXT, FONT_SIZE_NORMAL, ANCHOR_RIGHT);
         y_offset += SPACING_SMALL;
      }
   }
   
   // --- Footer & Debug Info ---
   y_offset += SPACING_MEDIUM;
   CreateLabel("footer", "AlfredAI™ v2.1", PANE_X_POS + PANE_WIDTH - 10, y_offset, COLOR_FOOTER, FONT_SIZE_NORMAL - 1, ANCHOR_RIGHT);
   y_offset += SPACING_MEDIUM;
   if(ShowDebugInfo)
   {
      CreateLabel("debug_info", "---", x_offset, y_offset, COLOR_TEXT_DIM, FONT_SIZE_NORMAL - 1);
      y_offset += SPACING_MEDIUM;
   }

   // --- Background ---
   string bg_name = PANE_PREFIX + "background";
   ObjectCreate(0, bg_name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bg_name, OBJPROP_XDISTANCE, PANE_X_POS);
   ObjectSetInteger(0, bg_name, OBJPROP_YDISTANCE, PANE_Y_POS);
   ObjectSetInteger(0, bg_name, OBJPROP_XSIZE, PANE_WIDTH);
   ObjectSetInteger(0, bg_name, OBJPROP_YSIZE, y_offset - PANE_Y_POS - 10);
   ObjectSetInteger(0, bg_name, OBJPROP_BACK, true);
   ObjectSetInteger(0, bg_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bg_name, OBJPROP_COLOR, clrNONE);
   color bg_color_opacity = (color)ColorToARGB(PANE_BG_COLOR, PANE_BG_OPACITY);
   ObjectSetInteger(0, bg_name, OBJPROP_BGCOLOR, bg_color_opacity);
}


//+------------------------------------------------------------------+
//| UpdatePanel - Main display refresh logic.                        |
//+------------------------------------------------------------------+
void UpdatePanel()
{
   // --- UPDATE TOP FIXED PANEL ---
   TradeRecommendation rec = GetTradeRecommendation();
   AlfredComment alfred_comment = GetAlfredComment();
   RiskModuleData risk_data = GetRiskModuleData();
   LiveTradeData trade_data = FetchTradeLevels();
   SessionData s_data = GetSessionData();
   
   UpdateLabel("top_signal", RecoActionToString(rec.action), RecoActionToColor(rec.action));
   CompassData h1_compass = GetCompassData(PERIOD_H1);
   UpdateLabel("top_confidence", StringFormat("(%.0f%%)", h1_compass.confidence), COLOR_TEXT_DIM);

   if(alfred_comment.text != g_last_alfred_comment)
   {
      UpdateLabel("top_alfred_says", alfred_comment.text, alfred_comment.clr);
      g_last_alfred_comment = alfred_comment.text;
   }

   UpdateLabel("top_risk_pct", StringFormat("Risk: %.1f%%", risk_data.risk_percent), COLOR_TEXT_DIM);
   UpdateLabel("top_risk_pos", StringFormat("Pos: %.2f", risk_data.position_size), COLOR_TEXT_DIM);
   UpdateLabel("top_risk_rr", "RR: " + risk_data.rr_ratio, COLOR_TEXT_DIM);
   
   string price_format = "%." + IntegerToString(_Digits) + "f";
   if(trade_data.trade_exists)
   {
      double sl_pips = (trade_data.sl > 0) ? CalculatePips(trade_data.entry, trade_data.sl) : 0.0;
      double tp_pips = (trade_data.tp > 0) ? CalculatePips(trade_data.entry, trade_data.tp) : 0.0;
      string sl_text = (trade_data.sl > 0) ? "SL: " + StringFormat(price_format, trade_data.sl) + StringFormat(" (%.1fp)", sl_pips) : "SL: ---";
      string tp_text = (trade_data.tp > 0) ? "TP: " + StringFormat(price_format, trade_data.tp) + StringFormat(" (%.1fp)", tp_pips) : "TP: ---";
      UpdateLabel("top_trade_sl", sl_text, COLOR_BEAR);
      UpdateLabel("top_trade_tp", tp_text, COLOR_BULL);
   }
   else
   {
      UpdateLabel("top_trade_sl", "SL: ---", COLOR_BEAR);
      UpdateLabel("top_trade_tp", "TP: ---", COLOR_BULL);
   }

   UpdateLabel("top_session", "Session: " + s_data.session_name, COLOR_SESSION);
   UpdateLabel("top_vol", "Vol: " + VolatilityToString(s_data.volatility), VolatilityToColor(s_data.volatility));
   ObjectSetInteger(0, PANE_PREFIX + "top_vol_bg", OBJPROP_BGCOLOR, VolatilityToHighlightColor(s_data.volatility));
   
   CompassData m15_bias = GetCompassData(PERIOD_M15);
   CompassData h4_bias = GetCompassData(PERIOD_H4);
   UpdateLabel("top_bias_m15", "M15: " + BiasToString(m15_bias.bias), BiasToColor(m15_bias.bias));
   UpdateLabel("top_bias_h1", "H1: " + BiasToString(h1_compass.bias), BiasToColor(h1_compass.bias));
   UpdateLabel("top_bias_h4", "H4: " + BiasToString(h4_bias.bias), BiasToColor(h4_bias.bias));

   // --- UPDATE COLLAPSIBLE SECTIONS ---
   
   // --- Update Market Overview ---
   if(g_market_overview_expanded)
   {
      for(int i = 0; i < ArraySize(g_matrix_tfs); i++)
      {
         ENUM_TIMEFRAMES tf = g_matrix_tfs[i];
         string tf_str = g_matrix_tf_strings[i];
         MatrixRowData data = GetConfidenceMatrixRow(tf);
         UpdateLabel("mo_bias_" + tf_str, BiasToString(data.bias), BiasToColor(data.bias));
         UpdateLabel("mo_zone_" + tf_str, ZoneToString(data.zone), ZoneToColor(data.zone));
         UpdateLabel("mo_conf_" + tf_str, IntegerToString(data.score), COLOR_NEUTRAL_TEXT);
         ObjectSetInteger(0, PANE_PREFIX + "mo_bg_" + tf_str, OBJPROP_BGCOLOR, GetConfidenceColor(data.score));
         string font_style = (data.score >= 10) ? "Arial Bold" : "Arial";
         ObjectSetString(0, PANE_PREFIX + "mo_tf_" + tf_str, OBJPROP_FONT, font_style);
         ObjectSetString(0, PANE_PREFIX + "mo_bias_" + tf_str, OBJPROP_FONT, font_style);
         ObjectSetString(0, PANE_PREFIX + "mo_zone_" + tf_str, OBJPROP_FONT, font_style);
         ObjectSetString(0, PANE_PREFIX + "mo_conf_" + tf_str, OBJPROP_FONT, font_style);
      }
   }

   // --- Update Zone Context ---
   if(g_zone_context_expanded)
   {
      ENUM_ZONE_INTERACTION interaction = GetCurrentZoneInteraction();
      UpdateLabel("zc_status_value", ZoneInteractionToString(interaction), ZoneInteractionToColor(interaction));
      if(interaction != INTERACTION_NONE)
      {
          CachedSupDemData zone_data = GetSupDemData(_Period);
          UpdateLabel("zc_strength_value", StringFormat("%.0f/10", zone_data.strength), COLOR_NEUTRAL_TEXT);
          string fresh_text = (zone_data.freshness > 0.5) ? "Yes" : "No";
          string vol_text = (zone_data.volume > 0.5) ? "Yes" : "No";
          string liq_text = (zone_data.liquidity > 0.5) ? "Yes" : "No";
          string details_text = "Fresh: " + fresh_text + ", Vol: " + vol_text + ", Liq: " + liq_text;
          UpdateLabel("zc_details_value", details_text, COLOR_NEUTRAL_TEXT);
      }
      else
      {
          UpdateLabel("zc_strength_value", "N/A", COLOR_NA);
          UpdateLabel("zc_details_value", "Fresh: N/A, Vol: N/A, Liq: No", COLOR_NA);
      }
      
      for(int i = 0; i < ArraySize(g_heatmap_tfs); i++)
      {
         ENUM_TIMEFRAMES tf = g_heatmap_tfs[i];
         string tf_str = g_heatmap_tf_strings[i];
         int strength_score = (int)MathRound(iCustom(_Symbol, tf, "AAI_Indicator_ZoneEngine.ex5", 2, 0));
         string heatmap_text;
         if(strength_score >= 8) heatmap_text = "🔥 " + IntegerToString(strength_score);
         else if(strength_score >= 5) heatmap_text = "🟧 " + IntegerToString(strength_score);
         else if(strength_score >= 1) heatmap_text = "🟨 " + IntegerToString(strength_score);
         else heatmap_text = "⚪ " + IntegerToString(strength_score);
         UpdateLabel("zc_heatmap_status_" + tf_str, heatmap_text, GetHeatColorForStrength(strength_score));
      }
   }
   
   // --- Update Magnets & HUD ---
   if(g_magnets_hud_expanded)
   {
      double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double proximity = 2 * _Point;
      for(int i = 0; i < ArraySize(g_magnet_summary_tfs); i++)
      {
         ENUM_TIMEFRAMES tf = g_magnet_summary_tfs[i];
         string tf_str = g_magnet_summary_tf_strings[i];
         double magnet_level = iCustom(_Symbol, tf, "AAI_Indicator_ZoneEngine.ex5", 1, 0);
         string relation_text;
         color relation_color;
         if(magnet_level > 0.0)
         {
            if (current_price > magnet_level + proximity) { relation_text = "Above"; relation_color = clrOrangeRed; }
            else if (current_price < magnet_level - proximity) { relation_text = "Below"; relation_color = clrLimeGreen; }
            else { relation_text = "At Magnet"; relation_color = clrGray; }
         }
         else { relation_text = "N/A"; relation_color = COLOR_NA; }
         string level_text = (magnet_level == 0.0) ? "(N/A)" : StringFormat("(%." + IntegerToString(_Digits) + "f)", magnet_level);
         UpdateLabel("mh_magnet_relation_" + tf_str, relation_text, relation_color);
         UpdateLabel("mh_magnet_level_" + tf_str, level_text, relation_color);
      }
      
      for(int i = 0; i < ArraySize(g_hud_tfs); i++)
      {
         ENUM_TIMEFRAMES tf = g_hud_tfs[i];
         string tf_str = g_hud_tf_strings[i];
         if(tf == PERIOD_D1) { UpdateLabel("mh_hud_status_" + tf_str, "N/A", COLOR_NA); continue; }
         bool is_active = GetHUDZoneActivity(tf);
         string status_text = is_active ? "✅" : "❌";
         color status_color = is_active ? COLOR_BULL : COLOR_BEAR;
         UpdateLabel("mh_hud_status_" + tf_str, status_text, status_color);
      }
   }

   // --- Update Alerts & Events ---
   if(g_alerts_events_expanded)
   {
      AlertData alert_data = GetAlertCenterStatus();
      UpdateLabel("ae_alert_status", alert_data.text, AlertStatusToColor(alert_data.status));
      
      NewsEventData news_items[];
      ArrayResize(news_items, MAX_NEWS_ITEMS);
      int news_count = GetUpcomingNews(news_items);
      for(int i = 0; i < MAX_NEWS_ITEMS; i++)
      {
         string idx = IntegerToString(i);
         if(i < news_count)
         {
            UpdateLabel("ae_news_time_" + idx, news_items[i].time, COLOR_TEXT_DIM);
            UpdateLabel("ae_news_curr_" + idx, news_items[i].currency, COLOR_NEUTRAL_TEXT);
            ObjectSetString(0, PANE_PREFIX + "ae_news_curr_" + idx, OBJPROP_FONT, "Arial Bold");
            UpdateLabel("ae_news_event_" + idx, news_items[i].event_name, COLOR_NEUTRAL_TEXT);
            UpdateLabel("ae_news_impact_" + idx, NewsImpactToString(news_items[i].impact), NewsImpactToColor(news_items[i].impact));
         }
         else
         {
            UpdateLabel("ae_news_time_" + idx, "");
            UpdateLabel("ae_news_curr_" + idx, "");
            UpdateLabel("ae_news_event_" + idx, "");
            UpdateLabel("ae_news_impact_" + idx, "");
         }
      }
   }

   // --- Update Debug Info ---
   if(ShowDebugInfo)
   {
      int active_modules = 0;
      if(ShowZoneHeatmap) active_modules++; if(ShowMagnetProjection) active_modules++; if(ShowMultiTFMagnets) active_modules++; if(ShowHUDActivitySection) active_modules++; if(ShowConfidenceMatrix) active_modules++; if(ShowTradeRecommendation) active_modules++; if(ShowRiskModule) active_modules++; if(ShowSessionModule) active_modules++; if(ShowNewsModule) active_modules++; if(ShowEmotionalState) active_modules++;
      if(ShowAlertCenter) active_modules++; if(ShowPaneSettings) active_modules++;
      string debug_text = StringFormat("Modules Active: %d | %s · %s | Updated: %s", active_modules, _Symbol, EnumToString(_Period), TimeToString(TimeCurrent(), TIME_SECONDS));
      UpdateLabel("debug_info", debug_text);
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Redraws the entire panel after a state change                    |
//+------------------------------------------------------------------+
void RedrawPanel()
{
   ObjectsDeleteAll(0, PANE_PREFIX);
   CreatePanel();
   UpdatePanel();
   ChartRedraw();
}

//+------------------------------------------------------------------+
//|                        Custom indicator initialization function  |
//+------------------------------------------------------------------+
int OnInit()
{
    // FIX: Initialize global arrays inside OnInit
    ArrayResize(g_timeframe_strings, 7);
    g_timeframe_strings[0] = "M1";
    g_timeframe_strings[1] = "M5"; g_timeframe_strings[2] = "M15"; g_timeframe_strings[3] = "M30";
    g_timeframe_strings[4] = "H1"; g_timeframe_strings[5] = "H4"; g_timeframe_strings[6] = "D1";

    ArrayResize(g_timeframes, 7);
    g_timeframes[0] = PERIOD_M1; g_timeframes[1] = PERIOD_M5; g_timeframes[2] = PERIOD_M15; g_timeframes[3] = PERIOD_M30;
    g_timeframes[4] = PERIOD_H1; g_timeframes[5] = PERIOD_H4;
    g_timeframes[6] = PERIOD_D1;

    ArrayResize(g_heatmap_tf_strings, 6);
    g_heatmap_tf_strings[0] = "M15"; g_heatmap_tf_strings[1] = "M30"; g_heatmap_tf_strings[2] = "H1";
    g_heatmap_tf_strings[3] = "H2"; g_heatmap_tf_strings[4] = "H4";
    g_heatmap_tf_strings[5] = "D1";

    ArrayResize(g_heatmap_tfs, 6);
    g_heatmap_tfs[0] = PERIOD_M15; g_heatmap_tfs[1] = PERIOD_M30; g_heatmap_tfs[2] = PERIOD_H1;
    g_heatmap_tfs[3] = PERIOD_H2; g_heatmap_tfs[4] = PERIOD_H4;
    g_heatmap_tfs[5] = PERIOD_D1;

    ArrayResize(g_magnet_summary_tf_strings, 6);
    g_magnet_summary_tf_strings[0] = "M15"; g_magnet_summary_tf_strings[1] = "M30"; g_magnet_summary_tf_strings[2] = "H1";
    g_magnet_summary_tf_strings[3] = "H2"; g_magnet_summary_tf_strings[4] = "H4";
    g_magnet_summary_tf_strings[5] = "D1";

    ArrayResize(g_magnet_summary_tfs, 6);
    g_magnet_summary_tfs[0] = PERIOD_M15; g_magnet_summary_tfs[1] = PERIOD_M30; g_magnet_summary_tfs[2] = PERIOD_H1;
    g_magnet_summary_tfs[3] = PERIOD_H2; g_magnet_summary_tfs[4] = PERIOD_H4;
    g_magnet_summary_tfs[5] = PERIOD_D1;

    ArrayResize(g_matrix_tf_strings, 6);
    g_matrix_tf_strings[0] = "M15"; g_matrix_tf_strings[1] = "M30"; g_matrix_tf_strings[2] = "H1";
    g_matrix_tf_strings[3] = "H2"; g_matrix_tf_strings[4] = "H4";
    g_matrix_tf_strings[5] = "D1";
    
    ArrayResize(g_matrix_tfs, 6);
    g_matrix_tfs[0] = PERIOD_M15; g_matrix_tfs[1] = PERIOD_M30; g_matrix_tfs[2] = PERIOD_H1;
    g_matrix_tfs[3] = PERIOD_H2; g_matrix_tfs[4] = PERIOD_H4;
    g_matrix_tfs[5] = PERIOD_D1;

    ArrayResize(g_hud_tf_strings, 4);
    g_hud_tf_strings[0] = "M15"; g_hud_tf_strings[1] = "H1"; g_hud_tf_strings[2] = "H4"; g_hud_tf_strings[3] = "D1";

    ArrayResize(g_hud_tfs, 4);
    g_hud_tfs[0] = PERIOD_M15; g_hud_tfs[1] = PERIOD_H1; g_hud_tfs[2] = PERIOD_H4; g_hud_tfs[3] = PERIOD_D1;

   hATR_current = iATR(_Symbol, _Period, atr_period);
   g_pip_value = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 3 || SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5) g_pip_value *= 10;
   MathSrand((int)TimeCurrent());
   // Initialize caches with default values
   for(int i = 0; i < ArraySize(g_timeframes); i++)
   {
      g_compass_cache[i].bias = BIAS_NEUTRAL;
      g_compass_cache[i].confidence = 0.0;
      g_supdem_cache[i].zone = ZONE_NONE; g_supdem_cache[i].magnet_level = 0.0; g_supdem_cache[i].strength = 0.0; g_supdem_cache[i].freshness = 0.0; g_supdem_cache[i].volume = 0.0;
      g_supdem_cache[i].liquidity = 0.0;
      g_hud_cache[i].zone_active = false;
   }
   
   g_brain_cache.signal = SIGNAL_NONE;
   g_brain_cache.confidence = 0;
   g_brain_cache.reasonCode = REASON_NONE;
   g_brain_cache.zoneTF = 0;


   RedrawPanel();
   UpdateLiveDataCaches(); // Initial data load to prevent "N/A" on first view
   UpdatePanel();
   EventSetTimer(1); // Set timer to 1-second intervals
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                 Timer function to trigger updates                |
//+------------------------------------------------------------------+
void OnTimer()
{
   UpdateLiveDataCaches(); // Fetch fresh data from indicators
   UpdatePanel(); // Update the display with cached data
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function (not used for timer updates) |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int p, const int b, const double &price[])
{
   return(rates_total);
}

//+------------------------------------------------------------------+
//|                       Chart event function                       |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &l, const double &d, const string &s)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      bool changed = false;
      if(StringFind(s, PANE_PREFIX + "Toggle_") == 0)
      {
         if(s == PANE_PREFIX + "Toggle_MarketOverview") { g_market_overview_expanded = !g_market_overview_expanded; changed = true; }
         else if(s == PANE_PREFIX + "Toggle_ZoneContext") { g_zone_context_expanded = !g_zone_context_expanded; changed = true; }
         else if(s == PANE_PREFIX + "Toggle_MagnetsHUD") { g_magnets_hud_expanded = !g_magnets_hud_expanded; changed = true; }
         else if(s == PANE_PREFIX + "Toggle_AlertsEvents") { g_alerts_events_expanded = !g_alerts_events_expanded; changed = true; }
      }
      if(changed) RedrawPanel();
   }
}

//+------------------------------------------------------------------+
//|                      Deinitialization function                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   IndicatorRelease(hATR_current);
   ObjectsDeleteAll(0, PANE_PREFIX);
   ChartRedraw();
}
//+------------------------------------------------------------------+
