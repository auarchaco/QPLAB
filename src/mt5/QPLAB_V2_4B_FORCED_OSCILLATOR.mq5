//+------------------------------------------------------------------+
//|              QPLAB_V2_4B_FORCED_OSCILLATOR.mq5                   |
//|        SI + BD + SL + CORE/QPLAB INTEGRATION                     |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1 "QPLAB"
#property indicator_type1  DRAW_NONE

//====================================================
// INPUTS
//====================================================

input int      NormWindow            = 100;
input double   DischargeOmega        = 0.45;
input double   DischargeMoveSigma    = 2.0;

input bool     EnableCSV             = true;
input bool     EnableEvents          = true;

//====================================================
// BUFFER
//====================================================

double Buffer1[];

//====================================================
// QPLAB VARIABLES
//====================================================

double persistence       = 0.0;
double omega             = 0.0;
double fatigue           = 0.0;
double energy            = 0.0;
double A_context         = 0.0;
double P_eq              = 0.0;

//====================================================
// METRICS
//====================================================

double SI                = 0.0;
double BD                = 0.0;
double SL                = 0.0;

string Topology          = "UNKNOWN";

//====================================================
// ORGANISM PARAMETERS
//====================================================

double PersistenceGain   = 0.0;
double PersistenceDecay  = 0.0;
double OmegaAlpha        = 0.0;
double FatigueDecay      = 0.0;

//====================================================
// CORE MOCK VARIABLES
//====================================================

string CORE_REGIME       = "INITIALIZING";

double CORE_VEL          = 0.0;
double CORE_ENG          = 0.0;
double CORE_M            = 0.0;
double CORE_TFAT         = 0.0;
double CORE_PERS         = 0.0;

//====================================================
// TIMERS
//====================================================

datetime lastBarTime     = 0;

bool hadFirstDischarge   = false;

int barsSinceDischarge   = 0;
int tauForced            = 0;

//====================================================
// CROSS DETECTION
//====================================================

int persistenceCrossBar  = -1;
int omegaCrossBar        = -1;

int globalBarCounter     = 0;

//====================================================
// ARRAYS
//====================================================

double AccArray[200];
int    AccCount = 0;

double PreArray[30];
int    PreCount = 0;

//====================================================
// FILES
//====================================================

int csvHandle            = INVALID_HANDLE;
int eventHandle          = INVALID_HANDLE;

//====================================================
// ORGANISM CONFIG
//====================================================

void ConfigureOrganism()
{
   string sym = _Symbol;

   // BTC
   if(StringFind(sym,"BTC") >= 0)
   {
      PersistenceGain  = 0.750;
      PersistenceDecay = 0.940;
      OmegaAlpha       = 0.080;
      FatigueDecay     = 0.970;
   }

   // ETH
   else if(StringFind(sym,"ETH") >= 0)
   {
      PersistenceGain  = 0.600;
      PersistenceDecay = 0.965;
      OmegaAlpha       = 0.050;
      FatigueDecay     = 0.985;
   }

   // XAU
   else if(StringFind(sym,"XAU") >= 0)
   {
      PersistenceGain  = 0.450;
      PersistenceDecay = 0.992;
      OmegaAlpha       = 0.035;
      FatigueDecay     = 0.992;
   }

   // DEFAULT
   else
   {
      PersistenceGain  = 0.600;
      PersistenceDecay = 0.965;
      OmegaAlpha       = 0.050;
      FatigueDecay     = 0.985;
   }
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
// Z SCORE
//====================================================

double CalculateZ()
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

   double std = MathSqrt(variance);

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
// ARRAYS
//====================================================

void PushAcc(double value)
{
   if(AccCount < 200)
   {
      AccArray[AccCount] = value;
      AccCount++;
   }
}

void PushPre(double value)
{
   if(PreCount < 30)
   {
      PreArray[PreCount] = value;
      PreCount++;
   }
}

//====================================================
// SI
//====================================================

void CalculateSI()
{
   if(AccCount < 20 || PreCount < 10)
      return;

   double meanAcc = 0.0;
   double meanPre = 0.0;

   for(int i=0;i<AccCount;i++)
      meanAcc += AccArray[i];

   for(int j=0;j<PreCount;j++)
      meanPre += PreArray[j];

   meanAcc /= AccCount;
   meanPre /= PreCount;

   double variance = 0.0;

   for(int k=0;k<AccCount;k++)
   {
      variance +=
      MathPow(AccArray[k]-meanAcc,2);
   }

   variance /= AccCount;

   double stdAcc =
   MathSqrt(variance);

   if(stdAcc <= 0.0)
      return;

   SI =
   (meanPre - meanAcc)
   /
   stdAcc;
}

//====================================================
// BD + SL
//====================================================

void CalculateBD_SL()
{
   if(
      persistenceCrossBar >= 0
      &&
      omegaCrossBar >= 0
   )
   {
      BD =
      omegaCrossBar
      -
      persistenceCrossBar;

      SL =
      MathAbs(BD);

      if(SL <= 5)
         Topology = "SYNC_CRITICAL";
      else
         Topology = "METASTABLE";
   }
}

//====================================================
// CORE ENGINE MOCK
//====================================================

void UpdateCORE()
{
   CORE_VEL =
   MathAbs(A_context) * 6.5;

   CORE_ENG =
   energy * 1.25;

   CORE_M =
   omega * 0.70;

   CORE_TFAT =
   fatigue * 0.80;

   CORE_PERS =
   persistence * 2.5;

   if(CORE_PERS < 50)
   {
      CORE_REGIME =
      "INITIALIZING";
   }
   else
   {
      if(CORE_M > 0.60)
         CORE_REGIME = "R2A";
      else if(CORE_M > 0.35)
         CORE_REGIME = "R1";
      else
         CORE_REGIME = "HOMEO";
   }
}

//====================================================
// DISCHARGE
//====================================================

void ExecuteDischarge()
{
   double P_pre = persistence;
   double O_pre = omega;

   CalculateSI();
   CalculateBD_SL();

   persistence *= 0.50;
   omega       *= 0.70;

   hadFirstDischarge = true;

   barsSinceDischarge = 0;
   tauForced          = 0;

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
         DoubleToString(SI,4),
         DoubleToString(BD,2),
         DoubleToString(SL,2),
         Topology
      );

      FileFlush(eventHandle);
   }

   PreCount = 0;
}

//====================================================
// HUB
//====================================================

void DrawHub()
{
   string HUB =
   "QPLAB V2.4B — FORCED OSCILLATOR\n"
   "====================================\n\n"

   "SYMBOL: " + _Symbol + "\n" +
   "TF: " + EnumToString(_Period) + "\n\n"

   "STATE: " + GetState() + "\n\n"

   "A_CONTEXT: " + DoubleToString(A_context,3) + "\n" +
   "ENERGY: " + DoubleToString(energy,3) + "\n\n"

   "PERSISTENCE: " + DoubleToString(persistence,3) + "\n" +
   "P_EQ: " + DoubleToString(P_eq,3) + "\n\n"

   "OMEGA: " + DoubleToString(omega,3) + "\n" +
   "FATIGUE: " + DoubleToString(fatigue,3) + "\n\n"

   "SI: " + DoubleToString(SI,3) + "\n" +
   "BD: " + DoubleToString(BD,2) + "\n" +
   "SL: " + DoubleToString(SL,0) + "\n" +
   "TOPOLOGY: " + Topology + "\n\n"

   "CORE REGIME: " + CORE_REGIME + "\n" +
   "VEL: " + DoubleToString(CORE_VEL,3) + "\n" +
   "ENG: " + DoubleToString(CORE_ENG,3) + "\n" +
   "M: " + DoubleToString(CORE_M,3) + "\n" +
   "TFAT: " + DoubleToString(CORE_TFAT,3) + "\n" +
   "PERS: " + DoubleToString(CORE_PERS,0) + "\n\n"

   "BARS SINCE DISCHARGE: " +
   (
      hadFirstDischarge
      ?
      IntegerToString(barsSinceDischarge)
      :
      "NO DISCHARGE YET"
   ) + "\n\n"

   "TAU_FORCED: " +
   IntegerToString(tauForced) + "\n\n"

   "ENGINE STATUS: RUNNING";

   Comment(HUB);
}

//====================================================
// INIT
//====================================================

int OnInit()
{
   SetIndexBuffer(
      0,
      Buffer1,
      INDICATOR_DATA
   );

   ConfigureOrganism();

   // CSV
   if(EnableCSV)
   {
      string fileName =
      "QPLAB_V24B_" +
      _Symbol + "_" +
      EnumToString(_Period) +
      ".csv";

      csvHandle =
      FileOpen(
         fileName,
         FILE_WRITE|FILE_READ|FILE_CSV
      );

      if(csvHandle != INVALID_HANDLE)
      {
         FileWrite(
            csvHandle,
            "TIME",
            "SYMBOL",
            "A_CONTEXT",
            "ENERGY",
            "PERSISTENCE",
            "P_EQ",
            "OMEGA",
            "FATIGUE",
            "SI",
            "BD",
            "SL",
            "TOPOLOGY",
            "CORE_REGIME",
            "CORE_VEL",
            "CORE_ENG",
            "CORE_M",
            "CORE_TFAT",
            "CORE_PERS"
         );

         FileFlush(csvHandle);
      }
   }

   // EVENTS
   if(EnableEvents)
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

      if(eventHandle != INVALID_HANDLE)
      {
         FileWrite(
            eventHandle,
            "TIME",
            "SYMBOL",
            "P_PRE",
            "OMEGA_PRE",
            "SI",
            "BD",
            "SL",
            "TOPOLOGY"
         );

         FileFlush(eventHandle);
      }
   }

   DrawHub();

   return(INIT_SUCCEEDED);
}

//====================================================
// MAIN
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

   globalBarCounter++;

   A_context =
   CalculateZ();

   energy =
   1.0 /
   (1.0 + MathExp(-A_context));

   P_eq =
   (energy * PersistenceGain)
   /
   (1.0 - PersistenceDecay);

   persistence =
   persistence * PersistenceDecay
   +
   (energy * PersistenceGain);

   fatigue =
   fatigue * FatigueDecay
   +
   (energy * 0.020);

   if(fatigue > 1.0)
      fatigue = 1.0;

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

   // CROSS DETECTION

   if(
      persistence >= P_eq*0.90
      &&
      persistenceCrossBar < 0
   )
   {
      persistenceCrossBar =
      globalBarCounter;
   }

   if(
      omega >= DischargeOmega
      &&
      omegaCrossBar < 0
   )
   {
      omegaCrossBar =
      globalBarCounter;
   }

   // ARRAYS

   if(GetState() == "ACCUMULATION")
      PushAcc(A_context);

   PushPre(A_context);

   // CORE

   UpdateCORE();

   // STD DEV

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

   if(
      CopyBuffer(
         stdHandle,
         0,
         1,
         1,
         stdBuffer
      ) <= 0
   )
   {
      DrawHub();
      return rates_total;
   }

   double sigma =
   stdBuffer[0];

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

      persistenceCrossBar = -1;
      omegaCrossBar       = -1;
   }

   // TAU

   if(hadFirstDischarge)
   {
      barsSinceDischarge++;
      tauForced++;
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
         DoubleToString(A_context,4),
         DoubleToString(energy,4),
         DoubleToString(persistence,4),
         DoubleToString(P_eq,4),
         DoubleToString(omega,4),
         DoubleToString(fatigue,4),
         DoubleToString(SI,4),
         DoubleToString(BD,2),
         DoubleToString(SL,0),
         Topology,
         CORE_REGIME,
         DoubleToString(CORE_VEL,4),
         DoubleToString(CORE_ENG,4),
         DoubleToString(CORE_M,4),
         DoubleToString(CORE_TFAT,4),
         DoubleToString(CORE_PERS,0)
      );

      FileFlush(csvHandle);
   }

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