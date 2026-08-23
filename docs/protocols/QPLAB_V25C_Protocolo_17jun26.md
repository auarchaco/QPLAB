# QPLAB V2.5C

## Protocolo experimental pre-corrida

BTC · ETH · ORO · 72 horas · 6 predicciones cuantitativas pre-registradas

Principio de Separación Ambiente–Organismo · Experimento de falsación · 17 junio 2026

Quantum Scalper V29.3 · X-LAB Research Expansion · Laboratorio Microfisiológico Longitudinal

## 1. Naturaleza de este documento

Este documento es un protocolo experimental pre-registrado. Se escribe antes de que exista un solo dato de la corrida V2.5C. Su función es registrar formalmente las predicciones, los criterios de falsación y el protocolo de análisis antes de observar los resultados. Esto garantiza que el análisis posterior no sea retrospectivo y que las hipótesis no sean ajustadas después de ver los datos.

V2.5C es el experimento más riguroso que ha tenido el laboratorio hasta ahora. No es exploratorio — es un experimento de falsación. Seis predicciones cuantitativas están definidas antes de correr el motor. Cada una tiene un criterio binario: se confirma o se falsifica.

## 2. La pregunta central de V2.5C

¿Pueden dos organismos con memorias fisiológicas muy distintas conservar identidades diferentes bajo el mismo forcing ambiental?

Esta pregunta emerge del Principio de Separación Ambiente–Organismo derivado experimentalmente de la corrida de 42h y la autocorrelación de C_t. Si la frecuencia de ciclos pertenece al ambiente y la amplitud pertenece al organismo, entonces organismos con P_DECAY muy distintos (0.920 vs 0.990) deberían tener distintas amplitudes pero frecuencias similares a sus respectivas versiones en V2.5B.

## 3. Principio de Separación Ambiente–Organismo

Este principio no fue diseñado — emergió de los datos. La estructura de correlaciones de la corrida de 42h (Omega r=0.459, SI r=0.423 entre activos vs F r=0.110, MB r=0.113) y la resolución de la paradoja cíclica via AC(C_t) convergieron en la misma separación. V2.5C es la primera prueba directa de este principio con tres activos simultáneos.

## 4. Configuración de parámetros V2.5C

### 4.1 Tabla de parámetros

Los únicos cambios respecto a V2.5B son: P_DECAY(BTC): 0.940→0.920; P_DECAY(ORO): 0.975→0.990; K_min=0.001 añadido; VS_raw normalizado (RE_norm, CI_norm). ETH se agrega como tercer organismo con los parámetros del documento maestro. Todo lo demás permanece locked.

### 4.2 Cálculo de P_eq con nuevos parámetros

BTC: P_eq = C_t × 0.750 / (1 − 0.920) = C_t × 9.375. Con C_t_mean≈0.467: P_eq≈4.38 (↓ vs 5.90 en V2.5B)

ETH: P_eq = C_t × 0.600 / (1 − 0.965) = C_t × 17.14. Con C_t_mean≈0.47: P_eq≈8.06 (≈ igual a V2.5B)

ORO: P_eq = C_t × 0.550 / (1 − 0.990) = C_t × 55.0. Con C_t_mean≈0.515: P_eq≈28.3 (↑↑ vs 8.04 en V2.5B)

La separación de atractores es ahora 28.3/4.38 = 6.46×. En V2.5B era 0.033. Esta es la diferencia que debería producir H observable si la hipótesis de histéresis es correcta.

## 5. Las 6 predicciones pre-registradas

Las predicciones P1 y P6 pertenecen a la capa ambiental — si se confirman, no dependen del organismo sino del mercado. Las predicciones P2, P3 pertenecen a la capa fisiológica. P4 y P5 testean la taxonomía exógeno/endógeno con el tercer activo. Ninguna predicción puede ajustarse después de ver los datos.

## 6. Ventana de warm-up por organismo

El warm-up de ORO es el más crítico. Con P_DECAY=0.990, la persistence necesita aproximadamente 3 half-lives para alcanzar el 87.5% de su valor de equilibrio, lo que corresponde a ~206 minutos (3×68.6). Cualquier ciclo de P detectado antes de las 3 horas en ORO pertenece a la fase de Seed/Organizing y no debe incluirse en el cálculo de frecuencias ni en H. El CSV debe registrar la fase del organismo (SEED, ORGANIZING, MATURE) para que esta exclusión sea sistemática.

## 7. Protocolo de análisis post-corrida

El protocolo tiene 8 pasos en orden de prioridad. El primero — supervivencia del organismo — es la condición de validez de toda la sesión. Si cualquier organismo colapsa (R=0 permanente, RDebt explosivo, overflow numérico), la sesión no es analizable para las predicciones P1–P6. El éxito mínimo de V2.5C es que los tres organismos sobrevivan 72 horas con continuidad fisiológica.

## 8. Estado acumulado del laboratorio

El laboratorio lleva 9 hipótesis rastreadas. Dos confirmadas (H2 reformulada, H3A), una refutada (H3B), una parcial (H1), cinco pendientes. V2.5C tiene el potencial de resolver cuatro de las cinco pendientes en una sola corrida: H3 (VS libre), P2/P3 (amplitud/histéresis), SEP (taxonomía con ETH). Eso haría de V2.5C la sesión más informativa del laboratorio.

## 9. Lo que no cambia

El núcleo matemático locked (ecuaciones de P, F, R, Omega, SI, SD, RDebt, RE, CI, MB, VS) permanece exactamente igual. No hay modificaciones de ecuaciones.

Los valores de alpha=0.05, lambda_F=0.10, lambda_D=0.001, eta=0.01, delta_SD=0.005 permanecen igual.

Los pesos de VS (w1=0.30, w2=0.25, w3=0.25, w4=0.10, w5=0.10) permanecen igual. Solo cambia la normalización de RE y CI antes del cálculo.

El schema CSV (17 columnas) permanece igual. No se agregan columnas nuevas en esta versión.

La frecuencia de actualización es barra de 1 minuto (V2.5B mode) para los tres organismos.

## 10. Criterio de éxito de la sesión

V2.5C se considera exitosa si: (a) los tres organismos sobreviven 72 horas, (b) VS está libre del clamp en >90% del tiempo, (c) los datos son suficientes para calcular al menos 4 ciclos de P en BTC y 7 en ORO. Con ese mínimo, las 6 predicciones son evaluables estadísticamente.

Una sesión donde todos los organismos sobreviven pero ninguna predicción se confirma sigue siendo exitosa — es una falsación limpia que avanza el conocimiento. Una sesión donde un organismo colapsa no evalúa las predicciones y debe repetirse con los parámetros corregidos.

---

## Tablas del documento fuente

### Capas

| Capa | Variables | Características |
|---|---|---|
| AMBIENTAL | C_t · AC(C_t) · períodos dominantes · inversiones de fase · ritmos de mercado · Omega · SI | No se parametrizan. No se optimizan. Se observan. Sincronizadas entre activos (r>0.35). Determinadas por el forcing externo. |
| FISIOLÓGICA | P_DECAY · P_GAIN · amplitud de P · histéresis H · atractores · F · MB · RDebt · RE · CI | Se parametrizan. Se modifican. Se falsan. Independientes entre activos (r<0.20). Determinadas por la historia interna del organismo. |
| DERIVADA | VS · SD · Scar · RA · CycleEngine | Dependen de ambas capas. Combinan señal ambiental (via P) con historia fisiológica (via F, RDebt). Requieren 72h+ para caracterizarse. |
| CONSECUENCIA | Frecuencia de ciclos ∈ Ambiente \| Amplitud de ciclos ∈ Organismo | Esta separación es la hipótesis central de V2.5C. Si se confirma con 3 activos, es el primer resultado de estructura del laboratorio. |

### Parámetros

| Parámetro | BTC | ETH | ORO |
|---|---:|---:|---:|
| P_GAIN | 0.750 | 0.600 | 0.550 |
| P_DECAY | 0.920 ← 0.940 | 0.965 (sin cambio) | 0.990 ← 0.975 |
| OMEGA_ALPHA | 0.035 | 0.050 | 0.045 |
| alpha (todas vars) | 0.05 | 0.05 | 0.05 |
| lambda_D | 0.001 | 0.001 | 0.001 |
| K_min | 0.001 | 0.001 | 0.001 |
| Half-life P (barra 1min) | 8.3 min | 13.5 min | 68.6 min |
| P_eq con C_t=0.47 | 4.41 | 8.04 | 25.85 |
| Warm-up descartado | 1h | 2h | 3h |
| VS_raw normalización | RE_norm=clip(RE,0,10)/10 | igual | igual |

### Predicciones

| P | Dominio | Variable | Predicción cuantitativa | Condición de falsación |
|---|---|---|---|---|
| P1 | AMBIENTE | Frecuencia de ciclos P | BTC ≈ 11h · ORO ≈ 7h · ETH entre 7 y 11h | Si cualquier período cambia >30% respecto a V2.5B. |
| P2 | ORGANISMO | Amplitud ciclos (P_max) | ORO: P_max sube vs V2.5B · BTC: P_max baja o igual | Si ORO P_max cae o BTC P_max sube. |
| P3 | ORGANISMO | Histéresis H(BTC/ORO) | H > 1.20 en ventanas C_t_diff < 0.02 | Si H < 1.10 en ventanas limpias. |
| P4 | AMBIENTE | Omega(ETH) ↔ Omega(BTC/ORO) | r(Omega_ETH, Omega_BTC) > 0.35 y r(Omega_ETH, Omega_ORO) > 0.35 | Si r < 0.20 en ambos. |
| P5 | ORGANISMO | F(ETH) ↔ F(BTC/ORO) | r(F_ETH, F_BTC) < 0.20 y r(F_ETH, F_ORO) < 0.20 | Si r > 0.35 en algún par. |
| P6 | AMBIENTE | AC_BTC(6h) persiste negativa | AC_BTC(6h) < −0.20 | Si AC_BTC(6h) > 0. |

### Warm-up

| Organismo | P_DECAY | Half-life P | Warm-up | Razón |
|---|---:|---:|---:|---|
| BTC | 0.920 | 8.3 min | 60 min | Half-life corto — estabilización rápida |
| ETH | 0.965 | 13.5 min | 120 min | Sin cambio de P_DECAY — misma estabilización que V2.5B |
| ORO | 0.990 | 68.6 min | 180 min | Half-life 5× más largo que BTC — necesita >3 half-lives para estabilizarse |

### Protocolo post-corrida

1. Verificar supervivencia del organismo.
2. Verificar VS libre.
3. Medir frecuencia de ciclos (P1).
4. Medir amplitud de ciclos (P2).
5. Medir H en ventanas limpias (P3).
6. Taxonomía exógeno/endógeno con ETH (P4/P5).
7. Verificar AC_BTC(6h) (P6).
8. Confirmar H2 con ETH.

### Hipótesis rastreadas

| Hip. | Estado | Resultado | Versión |
|---|---|---|---|
| H1 | PARCIAL | RE distingue resiliencia — pero RE tiene overflow. | V2.5 |
| H2 | REFORMULADA | SI y VS son antagonistas estructurales, no SI precede VS con lag fijo. | V2.5B 42h |
| H3 | BLOQUEADA | VS clampeado — requiere corrección RE/CI. | V2.5 |
| H4 | INCIPIENTE | Drift SD presente pero sin historia inter-ciclo suficiente. | V2.5 |
| H5 | TESTEABLE | RDebt crece en XAU V2.5. | V2.5C |
| H6 | PENDIENTE | Metaestabilidad no observada aún. | 72h+ |
| H3A | CONFIRMADA | Periodicidad específica por activo: ORO=14.3h, BTC=11.8h. | Autocorrelación C_t — 17 jun |
| H3B | REFUTADA | BTC tiene mayor coherencia en escala media. | Autocorrelación C_t — 17 jun |
| SEP | PROVISIONAL | Separación ambiente/organismo: Omega/SI exógenos, F/MB endógenos. | V2.5B 42h |

Protocolo pre-registrado · X-LAB / QPLAB · Laboratorio Microfisiológico Longitudinal · 17 junio 2026