//+------------------------------------------------------------------+
//|                 QPLAB_V2_4_FORCED_OSCILLATOR.mq5                 |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1  "QPLAB"
#property indicator_type1   DRAW_NONE

//====================================================
// INPUTS
//====================================================

input int      NormWindow            = 100;
input double   DischargeOmega        = 0.45;
input double   DischargeMoveSigma    = 2.0;

input bool     EnableCSV             = true;
input bool     EnableDischargeLog    = true;

//====================================================
// BUFFER
//====================================================

double Buffer1[];

//====================================================
// STATE VARIABLES
//====================================================

double persistence       = 0.0;
double omega             = 0.0;
double fatigue           = 0.0;
double energy            = 0.0;
double A_context         = 0.0;
double P_eq              = 0.0;

// Organism Parameters
double PersistenceGain   = 0.0;
double PersistenceDecay  = 0.0;
double OmegaAlpha        = 0.0;
double FatigueDecay      = 0.0;

datetime lastBarTime     = 0;

bool hadFirstDischarge   = false;

int barsSinceDischarge   = 0;
int recoveryBars         = 0;

//====================================================
// FILE HANDLES
//====================================================

int csvHandle            = INVALID_HANDLE;
int eventHandle          = INVALID_HANDLE;

//====================================================
// ORGANISM CONFIG
//====================================================

void ConfigureOrganism()
{
   string sym = _Symbol;

   // BTC FAST
   if(StringFind(sym,"BTC") >= 0)
   {
      PersistenceGain  = 0.75;
      PersistenceDecay = 0.940;
      OmegaAlpha       = 0.080;
      FatigueDecay     = 0.970;
   }

   // XAU VISCOUS
   else if(StringFind(sym,"XAU") >= 0)
   {
      PersistenceGain  = 0.40;
      PersistenceDecay = 0.995;
      OmegaAlpha       = 0.030;
      FatigueDecay     = 0.992;
   }

   // DEFAULT
   else
   {
      PersistenceGain  = 0.60;
      PersistenceDecay = 0.965;
      OmegaAlpha       = 0.050;
      FatigueDecay     = 0.985;
   }
}

//====================================================
// STATE
//====================================================

string GetState()
{
   if(omega >= DischargeOmega)
      return "SATURATION";

   if(persistence >= P_eq * 0.90)
      return "ACCUMULATION";

   return "HOMEOSTASIS";
}

//====================================================
// HUB
//====================================================

void DrawHub()
{
   string HUB =
   "QPLAB V2.4 — FORCED OSCILLATOR\n"
   "====================================\n\n"

   "SYMBOL: " + _Symbol + "\n" +
   "TF: " + EnumToString(_Period) + "\n\n" +

   "STATE: " + GetState() + "\n\n" +

   "A_CONTEXT: " + DoubleToString(A_context,3) + "\n" +
   "ENERGY: " + DoubleToString(energy,3) + "\n\n" +

   "PERSISTENCE: " + DoubleToString(persistence,3) + "\n" +
   "P_EQ: " + DoubleToString(P_eq,3) + "\n\n" +

   "OMEGA: " + DoubleToString(omega,3) + "\n" +
   "FATIGUE: " + DoubleToString(fatigue,3) + "\n\n" +

   "P_GAIN: " + DoubleToString(PersistenceGain,3) + "\n" +
   "P_DECAY: " + DoubleToString(PersistenceDecay,3) + "\n" +
   "OMEGA_ALPHA: " + DoubleToString(OmegaAlpha,3) + "\n\n" +

   "DISCHARGE Ω: " +
   DoubleToString(DischargeOmega,3) + "\n\n" +

   "BARS SINCE DISCHARGE: " +
   (
      hadFirstDischarge
      ?
      IntegerToString(barsSinceDischarge)
      :
      "NO DISCHARGE YET"
   ) + "\n\n" +

   "TAU_FORCED: " +
   IntegerToString(recoveryBars) + "\n\n" +

   "ENGINE STATUS: RUNNING";

   Comment(HUB);
}

//====================================================
// INIT
//====================================================

int OnInit()
{
   IndicatorSetString(
      INDICATOR_SHORTNAME,
      "QPLAB V2.4"
   );

   SetIndexBuffer(
      0,
      Buffer1,
      INDICATOR_DATA
   );

   ArraySetAsSeries(Buffer1,true);

   ConfigureOrganism();

   //=========================================
   // CSV MAIN
   //=========================================

   if(EnableCSV)
   {
      string fileName =
      "QPLAB_V24_" +
      _Symbol + "_" +
      EnumToString(_Period) +
      ".csv";

      csvHandle =
      FileOpen(
         fileName,
         FILE_WRITE|FILE_READ|FILE_CSV
      );

      Print("CSV ACTIVE:");
      Print(fileName);

      if(csvHandle != INVALID_HANDLE)
      {
         FileWrite(
            csvHandle,
            "TIME",
            "SYMBOL",
            "TF",
            "A_CONTEXT",
            "ENERGY",
            "PERSISTENCE",
            "OMEGA",
            "FATIGUE",
            "P_EQ",
            "STATE",
            "DISCHARGE"
         );

         FileFlush(csvHandle);
      }
      else
      {
         Print("CSV HANDLE FAILED");
      }
   }

   //=========================================
   // EVENT LOG
   //=========================================

   if(EnableDischargeLog)
   {
      string eventFile =
      "QPLAB_EVENTS_" +
      _Symbol + "_" +
      EnumToString(_Period) +
      ".csv";

      eventHandle =
      FileOpen(
         eventFile,
         FILE_WRITE|FILE_READ|FILE_CSV
      );

      Print("EVENT LOG ACTIVE:");
      Print(eventFile);

      if(eventHandle != INVALID_HANDLE)
      {
         FileWrite(
            eventHandle,
            "TIME",
            "SYMBOL",
            "P_PRE",
            "OMEGA_PRE",
            "P_POST",
            "OMEGA_POST",
            "A_CONTEXT",
            "TRIGGER_TYPE",
            "TAU_FORCED"
         );

         FileFlush(eventHandle);
      }
      else
      {
         Print("EVENT HANDLE FAILED");
      }
   }

   DrawHub();

   return(INIT_SUCCEEDED);
}

//====================================================
// NEW BAR
//====================================================

bool NewClosedBar()
{
   datetime currentBar =
   iTime(_Symbol,_Period,1);

   if(currentBar != lastBarTime)
   {
      lastBarTime = currentBar;
      return true;
   }

   return false;
}

//====================================================
// Z SCORE
//====================================================

double CalculateZScore()
{
   if(Bars(_Symbol,_Period) < NormWindow+10)
      return 0.0;

   double values[];

   ArrayResize(values,NormWindow);

   double mean = 0.0;

   for(int i=1;i<=NormWindow;i++)
   {
      double vol =
      (double)iVolume(_Symbol,_Period,i);

      double move =
      MathAbs(
         iClose(_Symbol,_Period,i)
         -
         iOpen(_Symbol,_Period,i)
      );

      double A =
      vol / (move + 0.0000001);

      values[i-1] = A;

      mean += A;
   }

   mean /= NormWindow;

   double variance = 0.0;

   for(int j=0;j<NormWindow;j++)
   {
      variance +=
      MathPow(values[j]-mean,2);
   }

   variance /= NormWindow;

   double std =
   MathSqrt(variance);

   double currentVol =
   (double)iVolume(_Symbol,_Period,1);

   double currentMove =
   MathAbs(
      iClose(_Symbol,_Period,1)
      -
      iOpen(_Symbol,_Period,1)
   );

   double currentA =
   currentVol / (currentMove + 0.0000001);

   if(std <= 0.0)
      return 0.0;

   return (currentA - mean) / std;
}

//====================================================
// DISCHARGE
//====================================================

void ExecuteDischarge()
{
   double P_pre = persistence;
   double O_pre = omega;

   string triggerType = "EXOGENOUS";

   if(A_context > 0.50)
      triggerType = "ENDOGENOUS";

   // RESET
   persistence *= 0.50;
   omega       *= 0.70;

   double P_post = persistence;
   double O_post = omega;

   hadFirstDischarge = true;

   barsSinceDischarge = 0;
   recoveryBars = 0;

   // EVENT LOG
   if(eventHandle != INVALID_HANDLE)
   {
      FileWrite(
         eventHandle,
         TimeToString(
            TimeCurrent(),
            TIME_DATE|TIME_MINUTES
         ),
         _Symbol,
         DoubleToString(P_pre,4),
         DoubleToString(O_pre,4),
         DoubleToString(P_post,4),
         DoubleToString(O_post,4),
         DoubleToString(A_context,4),
         triggerType,
         recoveryBars
      );

      FileFlush(eventHandle);
   }
}

//====================================================
// MAIN ENGINE
//====================================================

int OnCalculate(
   const int rates_total,
   const int prev_calculated,
   const datetime &time[],
   const double &open[],
   const double &high[],
   const double &low[],
   const double &close[],
   const long &tick_volume[],
   const long &volume[],
   const int &spread[]
)
{
   Buffer1[0] = omega;

   if(!NewClosedBar())
   {
      DrawHub();
      return rates_total;
   }

   // SENSOR
   A_context = CalculateZScore();

   energy =
   1.0 /
   (1.0 + MathExp(-A_context));

   // ATTRACTOR
   P_eq =
   (energy * PersistenceGain)
   /
   (1.0 - PersistenceDecay);

   // PERSISTENCE
   persistence =
   persistence * PersistenceDecay
   +
   (energy * PersistenceGain);

   // FATIGUE
   fatigue =
   fatigue * FatigueDecay
   +
   (energy * 0.020);

   if(fatigue > 1.0)
      fatigue = 1.0;

   // OMEGA
   double persistenceScore =
   persistence / (P_eq + 0.0001);

   double omegaTarget =
   (persistenceScore * 0.85)
   +
   (fatigue * 0.15);

   omega =
   omega * (1.0 - OmegaAlpha)
   +
   (omegaTarget * OmegaAlpha);

   // SIGMA
   int stdHandle =
   iStdDev(
      _Symbol,
      _Period,
      20,
      0,
      MODE_SMA,
      PRICE_CLOSE
   );

   double stdBuffer[];

   ArraySetAsSeries(stdBuffer,true);

   if(CopyBuffer(stdHandle,0,1,1,stdBuffer) <= 0)
   {
      DrawHub();
      return rates_total;
   }

   double sigma = stdBuffer[0];

   // MOVE
   double move =
   MathAbs(close[1]-open[1]);

   // DISCHARGE
   if(
      omega >= DischargeOmega
      &&
      move >= sigma * DischargeMoveSigma
   )
   {
      ExecuteDischarge();
   }

   // TAU
   if(hadFirstDischarge)
   {
      barsSinceDischarge++;
      recoveryBars++;
   }

   // CSV
   if(csvHandle != INVALID_HANDLE)
   {
      FileWrite(
         csvHandle,
         TimeToString(
            TimeCurrent(),
            TIME_DATE|TIME_MINUTES
         ),
         _Symbol,
         EnumToString(_Period),
         DoubleToString(A_context,4),
         DoubleToString(energy,4),
         DoubleToString(persistence,4),
         DoubleToString(omega,4),
         DoubleToString(fatigue,4),
         DoubleToString(P_eq,4),
         GetState(),
         (omega >= DischargeOmega ? "1":"0")
      );

      FileFlush(csvHandle);
   }

   // HUB
   DrawHub();

   return rates_total;
}

//====================================================
// DEINIT
//====================================================

void OnDeinit(const int reason)
{
   if(csvHandle != INVALID_HANDLE)
      FileClose(csvHandle);

   if(eventHandle != INVALID_HANDLE)
      FileClose(eventHandle);

   Comment("");
}
//+------------------------------------------------------------------+