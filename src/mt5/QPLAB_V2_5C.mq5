//+------------------------------------------------------------------+
//|   QPLAB V2.5C -- LABORATORIO MICROFISIOLOGICO LONGITUDINAL       |
//|   Nucleo matematico locked -- 17 junio 2026                      |
//|                                                                  |
//|   Correcciones post-revision:                                    |
//|   [C1] SD con buffer circular real P(t-N)                        |
//|   [C2] Warm-up por instrumento via input WarmupBars              |
//|   [C3] RE/CI cap explicito, VS usa variables normalizadas        |
//|   [C4] FileFlush cada FlushEveryN barras                         |
//|                                                                  |
//|   BTC: P_GAIN=0.750  P_DECAY=0.920  OMEGA_ALPHA=0.035           |
//|   ETH: P_GAIN=0.600  P_DECAY=0.965  OMEGA_ALPHA=0.050           |
//|   XAU: P_GAIN=0.550  P_DECAY=0.990  OMEGA_ALPHA=0.045           |
//+------------------------------------------------------------------+
#property strict
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   5

#property indicator_label1  "P"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1  2

#property indicator_label2  "Omega"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_width2  2

#property indicator_label3  "VS"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrLimeGreen
#property indicator_width3  2

#property indicator_label4  "R"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrAqua
#property indicator_width4  1

#property indicator_label5  "F"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrTomato
#property indicator_width5  1

//==================================================================
// INPUTS
//==================================================================

input int    NormWindow    = 100;
input int    ContextWindow = 20;

input double Alpha_P       = 0.05;
input double Alpha_F       = 0.05;
input double Alpha_R       = 0.05;
input double Alpha_SI      = 0.05;

// Metabolismo diferencial -- ajustar por instrumento antes de lanzar
// BTC: P_GAIN=0.750  P_DECAY=0.920  OMEGA_ALPHA=0.035
// ETH: P_GAIN=0.600  P_DECAY=0.965  OMEGA_ALPHA=0.050
// XAU: P_GAIN=0.550  P_DECAY=0.990  OMEGA_ALPHA=0.045
input double P_GAIN        = 0.750;
input double P_DECAY       = 0.920;
input double OMEGA_ALPHA   = 0.035;

// [C2] Warm-up por instrumento
// BTC=60  ETH=120  XAU=180
input int    WarmupBars    = 60;

// Penalizaciones en Recovery
input double Lambda_F      = 0.10;
input double Lambda_D      = 0.001;   // LOCKED: 0.001

// Structural Drift
input double Eta_SD        = 0.01;
input double Delta_SD      = 0.005;
input int    N_SD          = 20;      // NormWindow / 5

// Regenerative Debt
input double Mu1_RDebt     = 0.01;
input double Mu2_RDebt     = 0.01;
input double Mu3_RDebt     = 0.02;

// Fatigue
input double Gamma_F       = 0.02;
input double K_min         = 0.001;   // LOCKED: evita F=0 cuando DeltaPrice=0

// VS pesos (sobre variables normalizadas)
input double W1_RE         = 0.30;
input double W2_CI         = 0.25;
input double W3_MB         = 0.25;
input double W4_D          = 0.10;
input double W5_SD         = 0.10;

// [C4] Flush cada N barras
input int    FlushEveryN   = 10;

input bool   EnableLogger  = true;

//==================================================================
// BUFFERS VISUALES
//==================================================================

double BufP[];
double BufOmega[];
double BufVS[];
double BufR[];
double BufF[];

//==================================================================
// [C1] BUFFER CIRCULAR PARA SD -- P(t - N_SD) exacto
//==================================================================

#define P_HIST_SIZE 500
double g_PHistory[P_HIST_SIZE];
int    g_PHistIdx  = 0;
bool   g_PHistFull = false;

//==================================================================
// ESTADO FISIOLOGICO
//==================================================================

struct OrganismState
{
   double C_t;
   double K_t;
   double P;
   double F;
   double R;
   double Omega;
   double SI;
   double SD;
   double RDebt;
   double RE;
   double CI;
   double MB;
   double VS_raw;
   double VS;
   datetime last_time;
   int    tick_count;
   string phase;
};

OrganismState Org;

//==================================================================
// LOGGER
//==================================================================

int LogHandle    = INVALID_HANDLE;
int g_FlushCount = 0;

//==================================================================
// INIT
//==================================================================

int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "QPLAB_V2_5C");

   SetIndexBuffer(0, BufP,     INDICATOR_DATA);
   SetIndexBuffer(1, BufOmega, INDICATOR_DATA);
   SetIndexBuffer(2, BufVS,    INDICATOR_DATA);
   SetIndexBuffer(3, BufR,     INDICATOR_DATA);
   SetIndexBuffer(4, BufF,     INDICATOR_DATA);

   ArraySetAsSeries(BufP,     true);
   ArraySetAsSeries(BufOmega, true);
   ArraySetAsSeries(BufVS,    true);
   ArraySetAsSeries(BufR,     true);
   ArraySetAsSeries(BufF,     true);

   Org.C_t        = 0.5;
   Org.K_t        = 0.0;
   Org.P          = 0.0;
   Org.F          = 0.0;
   Org.R          = 0.0;
   Org.Omega      = 0.0;
   Org.SI         = 0.0;
   Org.SD         = 0.0;
   Org.RDebt      = 0.0;
   Org.RE         = 0.0;
   Org.CI         = 0.0;
   Org.MB         = 0.0;
   Org.VS_raw     = 0.0;
   Org.VS         = 0.5;
   Org.last_time  = 0;
   Org.tick_count = 0;
   Org.phase      = "SEED";

   // [C1] Inicializar buffer circular
   ArrayInitialize(g_PHistory, 0.0);
   g_PHistIdx  = 0;
   g_PHistFull = false;

   if(EnableLogger)
   {
      string fname = "QPLAB_V25C_" + Symbol() + "_" + EnumToString(Period()) + ".csv";
      LogHandle = FileOpen(fname,
                           FILE_WRITE|FILE_CSV|FILE_SHARE_WRITE|FILE_ANSI,
                           ';');
      if(LogHandle != INVALID_HANDLE)
      {
         FileWrite(LogHandle,
            "timestamp","symbol","price",
            "C_t","K_t",
            "P","F","R","Omega","SI",
            "SD","RDebt","RE","CI","MB",
            "VS_raw","VS","phase");
         FileFlush(LogHandle);
      }
   }

   return(INIT_SUCCEEDED);
}

//==================================================================
// DEINIT
//==================================================================

void OnDeinit(const int reason)
{
   if(LogHandle != INVALID_HANDLE)
   {
      FileFlush(LogHandle);
      FileClose(LogHandle);
   }
   Comment("");
}

//==================================================================
// RELOJ DE BARRA CERRADA
//==================================================================

bool NewClosedBar()
{
   static datetime lastBar = 0;
   datetime cur = iTime(_Symbol, _Period, 1);
   if(cur != lastBar) { lastBar = cur; return true; }
   return false;
}

//==================================================================
// MAIN
//==================================================================

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[])
{
   if(rates_total < NormWindow + ContextWindow + 30)
      return(rates_total);

   if(NewClosedBar())
      ProcessCell();

   return(rates_total);
}

//==================================================================
// MOTOR FISIOLOGICO -- evolve(S_t, M_t)
//==================================================================

void ProcessCell()
{
   MqlRates rates[];
   int needed = NormWindow + ContextWindow + 30;
   if(CopyRates(_Symbol, _Period, 1, needed, rates) < needed)
      return;
   ArraySetAsSeries(rates, true);

   datetime t0     = rates[0].time;
   double   close0 = rates[0].close;
   double   close1 = rates[1].close;

   //--------------------------------------------------------------
   // CAPA SENSORIAL
   //--------------------------------------------------------------

   // A_t = Sum(Vol_W) / (|DeltaP_W| + eps)
   double volSum = 0.0;
   for(int i = 0; i < ContextWindow; i++)
      volSum += (double)rates[i].tick_volume;

   double disp = MathAbs(rates[0].close - rates[ContextWindow].close);
   disp = MathMax(disp, _Point * 10);
   double rawA = volSum / disp;

   // Distribucion contextual -- z-score
   double samples[];
   ArrayResize(samples, NormWindow);
   double mean_A = 0.0;
   for(int n = 0; n < NormWindow; n++)
   {
      double vs = 0.0;
      for(int z = 0; z < ContextWindow; z++)
         vs += (double)rates[n+z].tick_volume;
      double ds = MathAbs(rates[n].close - rates[n+ContextWindow].close);
      ds = MathMax(ds, _Point * 10);
      samples[n] = vs / ds;
      mean_A += samples[n];
   }
   mean_A /= NormWindow;

   double std_A = 0.0;
   for(int n = 0; n < NormWindow; n++)
      std_A += MathPow(samples[n] - mean_A, 2);
   std_A = MathSqrt(std_A / NormWindow);

   double z_score = (std_A > 1e-10) ? (rawA - mean_A) / std_A : 0.0;

   // C_t = sigma(z) -- coherencia contextual instantanea [0,1]
   Org.C_t = 1.0 / (1.0 + MathExp(-z_score));

   // K_t = |DeltaPrice| / sigma_local   con K_min LOCKED
   double sig_loc = 0.0;
   for(int s = 0; s < 50; s++)
      sig_loc += MathAbs(rates[s].close - rates[s+1].close);
   sig_loc /= 50.0;
   sig_loc  = MathMax(sig_loc, _Point);

   Org.K_t = MathMax(MathAbs(close0 - close1) / sig_loc, K_min);

   //--------------------------------------------------------------
   // CAPA FISIOLOGICA
   //--------------------------------------------------------------

   double P_prev = Org.P;

   // 1. PERSISTENCE
   if(Org.C_t > 0.5)
      Org.P += Org.C_t * P_GAIN;
   else
      Org.P *= P_DECAY;
   Org.P = MathMin(MathMax(Org.P, 0.0), 100.0);

   // 2. FATIGUE
   // F_{t+1} = (1-aF)*F_t + aF*K_t - gF*R_t
   Org.F = (1.0 - Alpha_F) * Org.F
         +  Alpha_F * Org.K_t
         -  Gamma_F * Org.R;
   Org.F = MathMin(MathMax(Org.F, 0.0), 1.0);

   // 3. RECOVERY
   // R_{t+1} = (1-aR)*R_t + aR*(P_t - SI_t - lF*F_t - lD*D_t)
   double inp_R = Org.P - Org.SI - Lambda_F*Org.F - Lambda_D*Org.RDebt;
   inp_R = inp_R / (1.0 + MathAbs(inp_R) * 0.1);   // normalizacion suave
   Org.R = (1.0 - Alpha_R) * Org.R + Alpha_R * inp_R;
   Org.R = MathMin(MathMax(Org.R, 0.0), 1.0);

   // 4. OMEGA (fragilidad fisiologica)
   // Omega_{t+1} = (1-OA)*Omega_t + OA*(K_t + SI_t)
   Org.Omega = (1.0 - OMEGA_ALPHA) * Org.Omega
             +  OMEGA_ALPHA * (Org.K_t + Org.SI);
   Org.Omega = MathMin(MathMax(Org.Omega, 0.0), 1.0);

   // 5. SILENCE INDEX
   // SI_{t+1} = (1-aSI)*SI_t + aSI*|DeltaP_t|
   Org.SI = (1.0 - Alpha_SI) * Org.SI + Alpha_SI * MathAbs(Org.P - P_prev);
   Org.SI = MathMax(Org.SI, 0.0);

   //--------------------------------------------------------------
   // [C1] BUFFER CIRCULAR -- P(t - N_SD) exacto
   //--------------------------------------------------------------

   g_PHistory[g_PHistIdx] = P_prev;
   g_PHistIdx = (g_PHistIdx + 1) % P_HIST_SIZE;
   if(g_PHistIdx == 0) g_PHistFull = true;

   double P_t_minus_N;
   if(g_PHistFull || g_PHistIdx >= N_SD)
   {
      int idx_past = (g_PHistIdx - N_SD + P_HIST_SIZE) % P_HIST_SIZE;
      P_t_minus_N  = g_PHistory[idx_past];
   }
   else
   {
      P_t_minus_N = Org.P;   // historia insuficiente -> SD = 0 inicialmente
   }

   //--------------------------------------------------------------
   // CAPA DERIVADA
   //--------------------------------------------------------------

   // 6. STRUCTURAL DRIFT
   // SD_{t+1} = (1-dSD)*SD_t + eta*|P_t - P_{t-n}|
   Org.SD = (1.0 - Delta_SD) * Org.SD
          +  Eta_SD * MathAbs(Org.P - P_t_minus_N);
   Org.SD = MathMax(Org.SD, 0.0);

   // 7. REGENERATIVE DEBT
   // D_{t+1} = D_t + m1*F + m2*SD - m3*R   (nunca negativo)
   Org.RDebt = Org.RDebt
             + Mu1_RDebt * Org.F
             + Mu2_RDebt * Org.SD
             - Mu3_RDebt * Org.R;
   Org.RDebt = MathMax(Org.RDebt, 0.0);

   // 8. RECOVERY EFFICIENCY
   // RE = R / max(F, 0.01)
   // [C3] CSV guarda valor crudo. VS usa RE_norm = clip(RE,0,10)/10
   Org.RE = Org.R / MathMax(Org.F, 0.01);
   Org.RE = MathMin(Org.RE, 100.0);

   // 9. CYCLE INTEGRITY
   // CI = R / max(F + SD + SI, 0.01)
   // [C3] CSV guarda valor crudo. VS usa CI_norm = clip(CI,0,5)/5
   Org.CI = Org.R / MathMax(Org.F + Org.SD + Org.SI, 0.01);
   Org.CI = MathMin(Org.CI, 100.0);

   // 10. METABOLIC BALANCE
   // MB = RF - EP
   // RF = R + P - SI - SD
   // EP = F + D + SI + SD
   Org.MB = (Org.R + Org.P - Org.SI - Org.SD)
           - (Org.F + Org.RDebt + Org.SI + Org.SD);

   // 11. VIABILITY SCORE -- normalizacion V2.5C LOCKED
   double RE_n = MathMin(Org.RE,    10.0) / 10.0;
   double CI_n = MathMin(Org.CI,     5.0) /  5.0;
   double MB_n = MathMax(MathMin(Org.MB, 2.0), -2.0) / 2.0;
   double D_n  = MathMin(Org.RDebt,  5.0) /  5.0;
   double SD_n = MathMin(Org.SD,     0.1) /  0.1;

   Org.VS_raw = W1_RE*RE_n + W2_CI*CI_n + W3_MB*MB_n - W4_D*D_n - W5_SD*SD_n;
   Org.VS_raw = MathMax(MathMin(Org.VS_raw, 1.5), -1.5);
   Org.VS     = 1.0 / (1.0 + MathExp(-Org.VS_raw));

   //--------------------------------------------------------------
   // FASE DEL ORGANISMO [C2]
   //--------------------------------------------------------------

   Org.tick_count++;
   Org.phase = ComputePhase();

   //--------------------------------------------------------------
   // CAPA VISUAL
   //--------------------------------------------------------------

   BufP[0]     = Org.P;
   BufOmega[0] = Org.Omega;
   BufVS[0]    = Org.VS;
   BufR[0]     = Org.R;
   BufF[0]     = Org.F;

   UpdatePanel(close0, t0);

   //--------------------------------------------------------------
   // LOGGER CSV
   //--------------------------------------------------------------

   if(EnableLogger && LogHandle != INVALID_HANDLE)
   {
      FileWrite(LogHandle,
         TimeToString(t0, TIME_DATE|TIME_SECONDS),
         _Symbol,
         DoubleToString(close0,    _Digits),
         DoubleToString(Org.C_t,   6),
         DoubleToString(Org.K_t,   6),
         DoubleToString(Org.P,     6),
         DoubleToString(Org.F,     6),
         DoubleToString(Org.R,     6),
         DoubleToString(Org.Omega, 6),
         DoubleToString(Org.SI,    6),
         DoubleToString(Org.SD,    6),
         DoubleToString(Org.RDebt, 6),
         DoubleToString(Org.RE,    6),
         DoubleToString(Org.CI,    6),
         DoubleToString(Org.MB,    6),
         DoubleToString(Org.VS_raw,6),
         DoubleToString(Org.VS,    6),
         Org.phase);

      // [C4] Flush cada FlushEveryN barras
      g_FlushCount++;
      if(g_FlushCount >= FlushEveryN)
      {
         FileFlush(LogHandle);
         g_FlushCount = 0;
      }
   }

   Org.last_time = t0;
}

//==================================================================
// FASE DEL ORGANISMO
// [C2] WarmupBars configurable por instrumento
//==================================================================

string ComputePhase()
{
   if(Org.tick_count < WarmupBars)
      return "SEED";

   if(Org.VS < 0.30 && Org.RDebt > 10.0)
      return "CRITICAL";

   if(Org.VS > 0.45 && Org.RDebt > 5.0 && Org.RE < 1.0)
      return "METASTABLE";

   if(Org.F > 0.70 && Org.RE < 0.50)
      return "AGING";

   if(Org.P > 0.50 && Org.MB > 0.0 && Org.VS > 0.50)
      return "MATURE";

   return "ORGANIZING";
}

//==================================================================
// PANEL HUB -- string concatenado (sin limite de argumentos)
//==================================================================

void UpdatePanel(double price, datetime t)
{
   string vs_state = "DEGRADADO";
   if(Org.VS >= 0.65)      vs_state = "RESILIENTE";
   else if(Org.VS >= 0.50) vs_state = "ESTABLE";
   else if(Org.VS >= 0.45) vs_state = "METASTABLE";

   string p_state = "FRAG";
   if(Org.P >= 0.75)      p_state = "MATURE";
   else if(Org.P >= 0.20) p_state = "ACC";

   string sep = "-----------------------------------\n";
   string txt = "";

   txt += "QPLAB V2.5C -- LABORATORIO MICROFISIOLOGICO\n";
   txt += sep;
   txt += "SYMBOL : " + _Symbol + "\n";
   txt += "TIME   : " + TimeToString(t) + "\n";
   txt += "PHASE  : " + Org.phase + "   TICK: " + IntegerToString(Org.tick_count) + "\n";
   txt += "PRECIO : " + DoubleToString(price, _Digits) + "\n";
   txt += sep;
   txt += "SENSORIAL\n";
   txt += "  C_t   : " + DoubleToString(Org.C_t,   4) + "\n";
   txt += "  K_t   : " + DoubleToString(Org.K_t,   4) + "\n";
   txt += sep;
   txt += "FISIOLOGICA\n";
   txt += "  P     : " + DoubleToString(Org.P,     4) + "  [" + p_state + "]\n";
   txt += "  F     : " + DoubleToString(Org.F,     4) + "\n";
   txt += "  R     : " + DoubleToString(Org.R,     4) + "\n";
   txt += "  Omega : " + DoubleToString(Org.Omega, 4) + "\n";
   txt += "  SI    : " + DoubleToString(Org.SI,    4) + "\n";
   txt += sep;
   txt += "DERIVADA\n";
   txt += "  SD    : " + DoubleToString(Org.SD,    5) + "\n";
   txt += "  RDebt : " + DoubleToString(Org.RDebt, 4) + "\n";
   txt += "  RE    : " + DoubleToString(Org.RE,    4) + "\n";
   txt += "  CI    : " + DoubleToString(Org.CI,    4) + "\n";
   txt += "  MB    : " + DoubleToString(Org.MB,    4) + "\n";
   txt += sep;
   txt += "VIABILIDAD\n";
   txt += "  VS_raw: " + DoubleToString(Org.VS_raw,4) + "\n";
   txt += "  VS    : " + DoubleToString(Org.VS,    4) + "  [" + vs_state + "]\n";

   Comment(txt);
}
//+------------------------------------------------------------------+