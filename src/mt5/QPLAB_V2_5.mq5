//+------------------------------------------------------------------+
//|                                             QPLAB_V25_CORE.mq5   |
//|                  QPLAB V2.5 - Longitudinal Organism Engine       |
//+------------------------------------------------------------------+
#property strict

//==================================================================//
// CONFIGURATION
//==================================================================//

input int    NormWindow      = 100;
input double AlphaP          = 0.05;
input double AlphaF          = 0.05;
input double AlphaR          = 0.05;
input double AlphaOmega      = 0.05;
input double AlphaSI         = 0.05;

input double GammaF          = 0.02;
input double LambdaF         = 0.10;
input double LambdaD         = 0.10;

input double EtaSD           = 0.01;
input double DeltaSD         = 0.005;

input double Mu1             = 0.01;
input double Mu2             = 0.01;
input double Mu3             = 0.02;

input double W1              = 0.30;
input double W2              = 0.25;
input double W3              = 0.25;
input double W4              = 0.10;
input double W5              = 0.10;

input double EPSILON         = 0.000001;

string CSV_FILE;

//==================================================================//
// ORGANISM STATE
//==================================================================//

struct OrganismState
{
   // Core physiology
   double P;
   double F;
   double R;
   double Omega;
   double SI;

   // Sensors
   double C_t;
   double K_t;

   // Longitudinal
   double SD;
   double RDebt;

   // Derived
   double RE;
   double CI;
   double MB;
   double VS_raw;
   double VS;

   // Runtime
   long tick_count;
   datetime timestamp;

   // Market
   double price;
   double delta;
   double sigma;
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
   if(value < minv) return(minv);
   if(value > maxv) return(maxv);
   return(value);
}

//==================================================================//
// SENSOR ENGINE
//==================================================================//

void ComputeSensors()
{
   // Current price
   double current_price = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   // Delta
   STATE.delta = current_price - STATE.price;

   // Volatility estimate
   double sum = 0.0;

   for(int i=1;i<=NormWindow;i++)
   {
      double p1 = iClose(_Symbol,PERIOD_M1,i);
      double p2 = iClose(_Symbol,PERIOD_M1,i+1);

      sum += MathPow(p1-p2,2);
   }

   STATE.sigma = MathSqrt(sum/NormWindow);

   //===============================================================//
   // K_t
   //===============================================================//

   STATE.K_t =
      MathAbs(STATE.delta) /
      (STATE.sigma + EPSILON);

   //===============================================================//
   // C_t
   //===============================================================//

   double meanA = 0.0;

   for(int i=1;i<=NormWindow;i++)
      meanA += iClose(_Symbol,PERIOD_M1,i);

   meanA /= NormWindow;

   double varA = 0.0;

   for(int i=1;i<=NormWindow;i++)
   {
      double d = iClose(_Symbol,PERIOD_M1,i) - meanA;
      varA += d*d;
   }

   double stdA = MathSqrt(varA/NormWindow);

   double z =
      (current_price - meanA) /
      (stdA + EPSILON);

   STATE.C_t = Sigmoid(z);

   // Update current price
   STATE.price = current_price;
}

//==================================================================//
// EVOLUTION ENGINE
//==================================================================//

void Evolve()
{
   //===============================================================//
   // PERSISTENCE
   //===============================================================//

   STATE.P =
      (1.0 - AlphaP) * STATE.P +
      AlphaP * STATE.C_t;

   //===============================================================//
   // FATIGUE
   //===============================================================//

   STATE.F =
      (1.0 - AlphaF) * STATE.F +
      AlphaF * STATE.K_t -
      GammaF * STATE.R;

   STATE.F = MathMax(0.0,STATE.F);

   //===============================================================//
   // RECOVERY
   //===============================================================//

   STATE.R =
      (1.0 - AlphaR) * STATE.R +
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

   STATE.R = MathMax(0.0,STATE.R);

   //===============================================================//
   // OMEGA
   //===============================================================//

   STATE.Omega =
      (1.0 - AlphaOmega) * STATE.Omega +
      AlphaOmega *
      (
         STATE.K_t +
         STATE.SI
      );

   //===============================================================//
   // SI
   //===============================================================//

   STATE.SI =
      (1.0 - AlphaSI) * STATE.SI +
      AlphaSI * MathAbs(STATE.delta);

   //===============================================================//
   // STRUCTURAL DRIFT
   //===============================================================//

   int n = NormWindow / 5;

   double P_old = iClose(_Symbol,PERIOD_M1,n);

   STATE.SD =
      (1.0 - DeltaSD) * STATE.SD +
      EtaSD * MathAbs(STATE.P - P_old);

   STATE.SD = MathMax(0.0,STATE.SD);

   //===============================================================//
   // REGENERATIVE DEBT
   //===============================================================//

   STATE.RDebt =
      STATE.RDebt +
      Mu1 * STATE.F +
      Mu2 * STATE.SD -
      Mu3 * STATE.R;

   STATE.RDebt = MathMax(0.0,STATE.RDebt);

   //===============================================================//
   // RECOVERY EFFICIENCY
   //===============================================================//

   STATE.RE =
      STATE.R /
      (STATE.F + EPSILON);

   //===============================================================//
   // CYCLE INTEGRITY
   //===============================================================//

   STATE.CI =
      STATE.R /
      (
         STATE.F +
         STATE.SD +
         STATE.SI +
         EPSILON
      );

   //===============================================================//
   // METABOLIC BALANCE
   //===============================================================//

   double RF =
      STATE.R +
      STATE.P -
      STATE.SI -
      STATE.SD;

   double EP =
      STATE.F +
      STATE.RDebt +
      STATE.SI +
      STATE.SD;

   STATE.MB = RF - EP;

   //===============================================================//
   // VIABILITY SCORE
   //===============================================================//

   STATE.VS_raw =
      W1 * STATE.RE +
      W2 * STATE.CI +
      W3 * STATE.MB -
      W4 * STATE.RDebt -
      W5 * STATE.SD;

   STATE.VS_raw =
      Clamp(STATE.VS_raw,-2.0,2.0);

   STATE.VS =
      Sigmoid(STATE.VS_raw);

   //===============================================================//
   // TICK COUNTER
   //===============================================================//

   STATE.tick_count++;
   STATE.timestamp = TimeCurrent();
}

//==================================================================//
// CSV ENGINE
//==================================================================//

void InitCSV()
{
   CSV_FILE =
      "QPLAB_V25_" +
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
      TimeToString(STATE.timestamp,TIME_DATE|TIME_SECONDS),
      _Symbol,
      DoubleToString(STATE.price,_Digits),

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
      "QPLAB V2.5\n"
      "---------------------\n"

      "P: " + DoubleToString(STATE.P,4) + "\n"
      "F: " + DoubleToString(STATE.F,4) + "\n"
      "R: " + DoubleToString(STATE.R,4) + "\n"
      "Ω: " + DoubleToString(STATE.Omega,4) + "\n"
      "SI: " + DoubleToString(STATE.SI,4) + "\n\n"

      "SD: " + DoubleToString(STATE.SD,4) + "\n"
      "Debt: " + DoubleToString(STATE.RDebt,4) + "\n\n"

      "RE: " + DoubleToString(STATE.RE,4) + "\n"
      "CI: " + DoubleToString(STATE.CI,4) + "\n"
      "MB: " + DoubleToString(STATE.MB,4) + "\n\n"

      "VS: " + DoubleToString(STATE.VS,4);

   Comment(hub);
}

//==================================================================//
// INIT
//==================================================================//

int OnInit()
{
   ZeroMemory(STATE);

   STATE.price =
      SymbolInfoDouble(_Symbol,SYMBOL_BID);

   InitCSV();

   return(INIT_SUCCEEDED);
}

//==================================================================//
// TICK
//==================================================================//

void OnTick()
{
   ComputeSensors();

   Evolve();

   ExportCSV();

   UpdateHUB();
}