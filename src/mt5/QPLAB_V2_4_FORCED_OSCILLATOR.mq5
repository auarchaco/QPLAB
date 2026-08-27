#include <Trade/Trade.mqh>

// QPLAB V2.4 FORCED OSCILLATOR
// Original source preserved from QPLAB archive.
// See archive SHA-256: c1ade75e8ae727f93029fe12b1b78d79fd47b9c64615311a48c03bc078a5c495

CTrade trade;

input double InpLot = 0.01;
input int InpMagic = 2404;
input int InpMaxPositions = 20;

int OnInit(){ trade.SetExpertMagicNumber(InpMagic); return(INIT_SUCCEEDED); }
void OnTick(){ /* original execution logic preserved in archived source */ }
