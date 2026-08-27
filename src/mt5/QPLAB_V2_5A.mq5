//+------------------------------------------------------------------+
//|                                             QPLAB_V25B_CORE.mq5  |
//|              QPLAB V2.5B - Longitudinal Organism Engine          |
//|                    CORRECTED BUILD - 15 JUN 2026                 |
//+------------------------------------------------------------------+
#property strict

//==================================================================//
// CONFIGURATION
//==================================================================//

input int    NormWindow      = 100;

//--------------------------------------------------------------//
// PRIMARY ALPHAS
//--------------------------------------------------------------//

input double AlphaP          = 0.05;
input double AlphaF          = 0.05;
input double AlphaR          = 0.05;
input double AlphaOmega      = 0.05;
input double AlphaSI         = 0.05;

//--------------------------------------------------------------//
// FATIGUE / RECOVERY
//--------------------------------------------------------------//

input double GammaF          = 0.02;

//--------------------------------------------------------------//
// CRITICAL FIX:
// lambda_D reduced from 0.10 -> 0.001
//--------------------------------------------------------------//

input double LambdaF         = 0.10;
input double LambdaD         = 0.001;

//--------------------------------------------------------------//
// DRIFT
//--------------------------------------------------------------//

input double EtaSD           = 0.01;
input double DeltaSD         = 0.005;

//--------------------------------------------------------------//
// DEBT
//--------------------------------------------------------------//

input double Mu1             = 0.01;
input double Mu2             = 0.01;
input double Mu3             = 0.02;

//--------------------------------------------------------------//
// VS WEIGHTS
//--------------------------------------------------------------//

input double W1              = 0.15;
input double W2              = 0.25;
input double W3              = 0.25;
input double W4              = 0.10;
input double W5              = 0.10;

//--------------------------------------------------------------//
// SAFETY
//--------------------------------------------------------------//

input double EPSILON         = 0.000001;

//--------------------------------------------------------------//
// FLOORS
//--------------------------------------------------------------//

input double RE_Floor        = 0.01;
input double CI_Floor        = 0.01;

//==================================================================//
// GLOBALS
//==================================================================//

string CSV_FILE;

//==================================================================//
// PERSISTENCE HISTORY
//==================================================================//

double P_history[500];

//==================================================================//
// ORGANISM STATE
//==================================================================//

struct OrganismState
{
   //---------------------------------------------------------------//
   // CORE
   //---------------------------------------------------------------//

   double P;
   double F;
   double R;
   double Omega;
   double SI;

   //---------------------------------------------------------------//
   // SENSORS
   //---------------------------------------------------------------//

   double C_t;
   double K_t;

   //---------------------------------------------------------------//
   // LONGITUDINAL
   //---------------------------------------------------------------//

   double SD;
   double RDebt;

   //---------------------------------------------------------------//
   // DERIVED
   //---------------------------------------------------------------//

   double RE;
   double CI;
   double MB;

   double VS_raw;
   double VS;

   //---------------------------------------------------------------//
   // MARKET
   //---------------------------------------------------------------//

   double price;
   double delta;
   double sigma;

   //---------------------------------------------------------------//
   // RUNTIME
   //---------------------------------------------------------------//

   long tick_count;

   datetime timestamp;
};

OrganismState STATE;

//==================================================================//
// UTILITIES
//==================================================================//

double Sigmoid(double x)
{
   return(1.0 / (1.0 + MathExp(-x)));
}

//------------------------------------------------------------------//

double Clamp(double value,double minv,double maxv)
{
   if(value < minv)
      return(minv);

   if(value > maxv)
      return(maxv);

   return(value);
}

//==================================================================//
// INTEGRITY ENGINE
//==================================================================//

void IntegrityCheck()
{
   if(!MathIsValidNumber(STATE.P))
      STATE.P = 0.0;

   if(!MathIsValidNumber(STATE.F))
      STATE.F = 0.0;

   if(!MathIsValidNumber(STATE.R))
      STATE.R = 0.0;

   if(!MathIsValidNumber(STATE.Omega))
      STATE.Omega = 0.0;

   if(!MathIsValidNumber(STATE.SI))
      STATE.SI = 0.0;

   if(!MathIsValidNumber(STATE.SD))
      STATE.SD = 0.0;

   if(!MathIsValidNumber(STATE.RDebt))
      STATE.RDebt = 0.0;

   if(!MathIsValidNumber(STATE.RE))
      STATE.RE = 0.0;

   if(!MathIsValidNumber(STATE.CI))
      STATE.CI = 0.0;

   if(!MathIsValidNumber(STATE.MB))
      STATE.MB = 0.0;

   if(!MathIsValidNumber(STATE.VS))
      STATE.VS = 0.5;
}

//==================================================================//
// SENSOR ENGINE
//==================================================================//

void ComputeSensors()
{
   //---------------------------------------------------------------//
   // CURRENT PRICE
   //---------------------------------------------------------------//

   double current_price =
      SymbolInfoDouble(_Symbol,SYMBOL_BID);

   //---------------------------------------------------------------//
   // DELTA
   //---------------------------------------------------------------//

   STATE.delta =
      current_price - STATE.price;

   //---------------------------------------------------------------//
   // VOLATILITY
   //---------------------------------------------------------------//

   double sum = 0.0;

   for(int i=1;i<=NormWindow;i++)
   {
      double p1 = iClose(_Symbol,PERIOD_M1,i);
      double p2 = iClose(_Symbol,PERIOD_M1,i+1);

      sum += MathPow(p1-p2,2);
   }

   STATE.sigma =
      MathSqrt(sum / NormWindow);

   //---------------------------------------------------------------//
   // K_t
   //---------------------------------------------------------------//

   STATE.K_t =
      Clamp(
         MathAbs(STATE.delta)
         /
         (STATE.sigma + EPSILON),
         0.0,
         10.0
      );

   //---------------------------------------------------------------//
   // CONTEXT
   //---------------------------------------------------------------//

   double meanA = 0.0;

   for(int i=1;i<=NormWindow;i++)
      meanA += iClose(_Symbol,PERIOD_M1,i);

   meanA /= NormWindow;

   double varA = 0.0;

   for(int i=1;i<=NormWindow;i++)
   {
      double d =
         iClose(_Symbol,PERIOD_M1,i)
         -
         meanA;

      varA += d*d;
   }

   double stdA =
      MathSqrt(varA / NormWindow);

   double z =
      (
         current_price - meanA
      )
      /
      (
         stdA + EPSILON
      );

   //---------------------------------------------------------------//
   // C_t
   //---------------------------------------------------------------//

   STATE.C_t =
      Sigmoid(z);

   //---------------------------------------------------------------//
   // UPDATE PRICE
   //---------------------------------------------------------------//

   STATE.price =
      current_price;
}

//==================================================================//
// EVOLUTION ENGINE
//==================================================================//

void Evolve()
{
   //---------------------------------------------------------------//
   // PERSISTENCE
   //---------------------------------------------------------------//

   STATE.P =
      (1.0 - AlphaP) * STATE.P
      +
      AlphaP * STATE.C_t;

   STATE.P =
      Clamp(
         STATE.P,
         0.0,
         1.0
      );

   //---------------------------------------------------------------//
   // FATIGUE
   //---------------------------------------------------------------//

   STATE.F =
      (1.0 - AlphaF) * STATE.F
      +
      AlphaF * STATE.K_t
      -
      GammaF * STATE.R;

   STATE.F =
      Clamp(
         STATE.F,
         0.0,
         1.0
      );

   //---------------------------------------------------------------//
   // RECOVERY
   //---------------------------------------------------------------//

   STATE.R =
      (1.0 - AlphaR) * STATE.R
      +
      AlphaR *
      (
         STATE.P
         -
         STATE.SI
         -
         LambdaF * STATE.F
         -
         LambdaD * STATE.RDebt
      );

   STATE.R =
      Clamp(
         STATE.R,
         0.0,
         1.0
      );

   //---------------------------------------------------------------//
   // OMEGA
   //---------------------------------------------------------------//

   STATE.Omega =
      (1.0 - AlphaOmega) * STATE.Omega
      +
      AlphaOmega *
      (
         STATE.K_t
         +
         STATE.SI
      );

   STATE.Omega =
      Clamp(
         STATE.Omega,
         0.0,
         10.0
      );

   //---------------------------------------------------------------//
   // SILENCE INDEX
   //---------------------------------------------------------------//

   STATE.SI =
      (1.0 - AlphaSI) * STATE.SI
      +
      AlphaSI *
      (
         MathAbs(STATE.delta)
         /
         (STATE.sigma + EPSILON)
      );

   STATE.SI =
      Clamp(
         STATE.SI,
         0.0,
         10.0
      );

   //---------------------------------------------------------------//
   // HISTORY BUFFER
   //---------------------------------------------------------------//

   for(int i=499;i>0;i--)
      P_history[i] = P_history[i-1];

   P_history[0] = STATE.P;

   //---------------------------------------------------------------//
   // STRUCTURAL DRIFT
   //---------------------------------------------------------------//

   int n = NormWindow / 5;

   double P_old =
      P_history[n];

   STATE.SD =
      (1.0 - DeltaSD) * STATE.SD
      +
      EtaSD *
      MathAbs(
         STATE.P - P_old
      );

   STATE.SD =
      Clamp(
         STATE.SD,
         0.0,
         10.0
      );

   //---------------------------------------------------------------//
   // REGENERATIVE DEBT
   //---------------------------------------------------------------//

   STATE.RDebt =
      STATE.RDebt
      +
      Mu1 * STATE.F
      +
      Mu2 * STATE.SD
      -
      Mu3 * STATE.R;

   STATE.RDebt =
      Clamp(
         STATE.RDebt,
         0.0,
         1000.0
      );

   //---------------------------------------------------------------//
   // RECOVERY EFFICIENCY
   //---------------------------------------------------------------//
   // FIXED:
   // RE = R / max(F,0.01)
   //---------------------------------------------------------------//

   STATE.RE =
      STATE.R
      /
      MathMax(
         STATE.F,
         RE_Floor
      );

   STATE.RE =
      Clamp(
         STATE.RE,
         0.0,
         100.0
      );

   //---------------------------------------------------------------//
   // CYCLE INTEGRITY
   //---------------------------------------------------------------//
   // FIXED:
   // CI floor protection
   //---------------------------------------------------------------//

   STATE.CI =
      STATE.R
      /
      MathMax(
         (
            STATE.F
            +
            STATE.SD
            +
            STATE.SI
         ),
         CI_Floor
      );

   STATE.CI =
      Clamp(
         STATE.CI,
         0.0,
         100.0
      );

   //---------------------------------------------------------------//
   // METABOLIC BALANCE
   //---------------------------------------------------------------//

   double RF =
      STATE.R
      +
      STATE.P
      -
      STATE.SI
      -
      STATE.SD;

   double EP =
      STATE.F
      +
      STATE.RDebt
      +
      STATE.SI
      +
      STATE.SD;

   STATE.MB =
      RF - EP;

   STATE.MB =
      Clamp(
         STATE.MB,
         -10.0,
         10.0
      );

   //---------------------------------------------------------------//
   // VIABILITY SCORE
   //---------------------------------------------------------------//

   STATE.VS_raw =
      W1 * STATE.RE
      +
      W2 * STATE.CI
      +
      W3 * STATE.MB
      -
      W4 * STATE.RDebt
      -
      W5 * STATE.SD;

   //---------------------------------------------------------------//
   // TARGET RANGE:
   // [-1.5,+1.5]
   //---------------------------------------------------------------//

   STATE.VS_raw =
      Clamp(
         STATE.VS_raw,
         -1.5,
         1.5
      );

   //---------------------------------------------------------------//
   // FINAL VS
   //---------------------------------------------------------------//

   STATE.VS =
      Sigmoid(
         STATE.VS_raw
      );

   //---------------------------------------------------------------//
   // RUNTIME
   //---------------------------------------------------------------//

   STATE.tick_count++;

   STATE.timestamp =
      TimeCurrent();
}

//==================================================================//
// CSV ENGINE
//==================================================================//

void InitCSV()
{
   CSV_FILE =
      "QPLAB_V25B_" +
      _Symbol +
      ".csv";

   int file =
      FileOpen(
         CSV_FILE,
         FILE_WRITE|FILE_CSV|FILE_ANSI
      );

   if(file != INVALID_HANDLE)
   {
      FileWrite(
         file,

         "timestamp",
         "symbol",
         "price",

         "P",
         "F",
         "R",
         "Omega",
         "SI",

         "C_t",
         "K_t",

         "SD",
         "RDebt",

         "RE",
         "CI",
         "MB",

         "VS_raw",
         "VS"
      );

      FileClose(file);
   }
}

//------------------------------------------------------------------//

void ExportCSV()
{
   int file =
      FileOpen(
         CSV_FILE,
         FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI
      );

   if(file == INVALID_HANDLE)
      return;

   FileSeek(file,0,SEEK_END);

   FileWrite(
      file,

      TimeToString(
         STATE.timestamp,
         TIME_DATE|TIME_SECONDS
      ),

      _Symbol,

      DoubleToString(
         STATE.price,
         _Digits
      ),

      DoubleToString(STATE.P,6),
      DoubleToString(STATE.F,6),
      DoubleToString(STATE.R,6),
      DoubleToString(STATE.Omega,6),
      DoubleToString(STATE.SI,6),

      DoubleToString(STATE.C_t,6),
      DoubleToString(STATE.K_t,6),

      DoubleToString(STATE.SD,6),
      DoubleToString(STATE.RDebt,6),

      DoubleToString(STATE.RE,6),
      DoubleToString(STATE.CI,6),
      DoubleToString(STATE.MB,6),

      DoubleToString(STATE.VS_raw,6),
      DoubleToString(STATE.VS,6)
   );

   FileClose(file);
}

//==================================================================//
// HUB
//==================================================================//

void UpdateHUB()
{
   string hub =
      "QPLAB V2.5B\n"
      "---------------------\n\n"

      "P: " + DoubleToString(STATE.P,4) + "\n"
      "F: " + DoubleToString(STATE.F,4) + "\n"
      "R: " + DoubleToString(STATE.R,4) + "\n"
      "Ω: " + DoubleToString(STATE.Omega,4) + "\n"
      "SI: " + DoubleToString(STATE.SI,4) + "\n\n"

      "C_t: " + DoubleToString(STATE.C_t,4) + "\n"
      "K_t: " + DoubleToString(STATE.K_t,4) + "\n\n"

      "SD: " + DoubleToString(STATE.SD,4) + "\n"
      "Debt: " + DoubleToString(STATE.RDebt,4) + "\n\n"

      "RE: " + DoubleToString(STATE.RE,4) + "\n"
      "CI: " + DoubleToString(STATE.CI,4) + "\n"
      "MB: " + DoubleToString(STATE.MB,4) + "\n\n"

      "VS_raw: " + DoubleToString(STATE.VS_raw,4) + "\n"
      "VS: " + DoubleToString(STATE.VS,4) + "\n\n"

      "Ticks: " + IntegerToString((int)STATE.tick_count);

   Comment(hub);
}

//==================================================================//
// INIT
//==================================================================//

int OnInit()
{
   ZeroMemory(STATE);

   STATE.price =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_BID
      );

   //---------------------------------------------------------------//
   // INIT HISTORY
   //---------------------------------------------------------------//

   for(int i=0;i<500;i++)
      P_history[i] = 0.0;

   InitCSV();

   return(INIT_SUCCEEDED);
}

//==================================================================//
// MAIN LOOP
//==================================================================//

void OnTick()
{
   ComputeSensors();

   Evolve();

   IntegrityCheck();

   ExportCSV();

   UpdateHUB();
}