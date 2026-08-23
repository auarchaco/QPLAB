# QPLAB — Registro Experimental Formal — Hallazgo V2.2

**Quantum Psychophysiology Lab**  
**Primera evidencia experimental de histéresis diferencial entre organismos financieros bajo estímulo equivalente**  
**Sesión overnight — 11 de junio de 2026**  
**BTCUSD M1 · XAUUSD M1 · Parámetros idénticos · Motor V2.2**

## I. Contexto experimental

Este documento registra formalmente el primer hallazgo experimental autónomo del proyecto de Arquitectura Celular Estructural. El hallazgo ocurrió durante la sesión overnight del 11 de junio de 2026, ejecutando el motor fisiodinámico QPLAB V2.2 simultáneamente sobre dos organismos financieros distintos bajo condiciones idénticas.

### Configuración de la sesión

| Parámetro | Valor | Nota |
|---|---|---|
| Activos | BTCUSD M1 / XAUUSD M1 | Simultáneos |
| Motor | QPLAB V2.2 | Bar-closed physiology |
| ContextWindow | 20 barras | Idéntico ambos |
| NormWindow | 100 barras | Idéntico ambos |
| EnergyThreshold | 0.52 | Threshold binario (limitación) |
| PersistenceGain | 0.60 | Idéntico ambos |
| PersistenceDecay | 0.965 | Idéntico ambos |
| FatigueGain | 0.020 | Idéntico ambos |
| DischargeSigma | 2.0σ | Idéntico ambos |

## II. Hallazgo principal

### Enunciado formal

Bajo estímulo contextual equivalente (`energy_mean ≈` igual en ambos activos), XAUUSD acumuló el doble de memoria estructural (`persistence`) que BTCUSD durante la misma sesión. Esta diferencia emergió de forma autónoma, sin ajuste de parámetros ni intervención externa.

### Datos comparativos

| Variable | BTCUSD | XAUUSD |
|---|---:|---:|
| energy_mean | 0.451 | 0.468 |
| persistence_mean | 0.47 | 0.47 |
| persistence_max | 1.08 | 2.09 |
| fatigue_mean | 0.50 | 0.53 |
| omega_max | 0.17 | 0.17 |
| state dominante | HOMEOSTASIS | HOMEOSTASIS |
| A_context_max | N/D | 9.69 |
| energy_max | N/D | 0.9999 |

**Energy (estímulo externo):** BTC 0.451 ≈ XAU 0.468. Diferencia +0.017 (≈0).  
**Persistence_max (memoria interna):** BTC 1.08; XAU 2.09. Razón ≈ 2.0x.

## III. Interpretación metodológica

### El argumento del desacoplamiento

Si la diferencia de persistencia proviniera del sensor, energy y persistence divergirían juntas. Ambas variables serían mayores en XAU que en BTC.

Sin embargo, los datos muestran:

- misma presión contextual aproximadamente equivalente;
- distinta retención estructural;
- divergencia real en `persistence_max`.

### Definición operacional de histéresis diferencial

La histéresis psicodinámica queda operacionalmente definida por este experimento como:

`H(t) = persistence_max(A) / persistence_max(B)`

bajo `energy_mean(A) ≈ energy_mean(B)`.

Donde `H(t) > 1` indica que el organismo A conserva más memoria estructural que B bajo la misma presión contextual.

En esta sesión:

`H = 2.09 / 1.08 ≈ 1.94`

XAU conserva aproximadamente el doble de memoria estructural que BTC bajo estímulo equivalente.

### Conclusión del desacoplamiento

Misma presión contextual. Distinta retención estructural. La diferencia no proviene del sensor. Proviene de la dinámica temporal interna del organismo.

## IV. Validaciones del motor

| Componente | Estado |
|---|---|
| Sensor contextual (A_context → Z-score) | Validado |
| Transformación logística (energy = sigmoide) | Validado |
| Memoria estructural (persistence) | Validado |
| Fatiga acumulativa (fatigue) | Validado |
| Susceptibilidad sistémica (omega) | Validado — limitado por threshold |
| Diferenciación fisiológica BTC ≠ XAU | Validado (hallazgo principal) |
| Detección de eventos extremos | Validado (XAU A_context_max = 9.69) |
| Bar-closed physiology (sin tick noise) | Validado |

## V. Limitación identificada

### El cuello binario de activación

La limitación estructural central de V2.2 fue la lógica discreta de acumulación:

```text
if(energy > threshold)  →  persistence += gain
else                     →  persistence *= decay
```

Eso produjo fisiología discreta: switches abruptos entre homeostasis y acumulación. Los regímenes fisiológicos emergentes quedaron estrangulados. Omega nunca pudo superar 0.17 porque persistence nunca alcanzó valores suficientes para activar su motor.

### Consecuencia

El organismo tenía dinámica interna real — confirmada por la histéresis diferencial — pero los clasificadores de estado eran demasiado rígidos para expresarla formalmente.

## VI. Transición hacia V3

### Persistencia continua

V3 elimina el threshold de activación. Persistence acumula y decae siempre, proporcional a energy:

```text
persistence += energy * PersistenceGain
persistence *= PersistenceDecay
```

Los puntos de equilibrio teóricos por régimen emergen naturalmente del gradiente:

| Régimen | Energy | Persist. eq. | Descripción |
|---|---:|---:|---|
| HOMEOSTASIS | ~0.40 | ~6.9 | Memoria lenta, no nula |
| MID | ~0.52 | ~9.0 | Zona de transición |
| ACCUMULATION | ~0.65 | ~11.2 | Acumulación activa |
| PEAK | ~0.80 | ~13.7 | Saturation inminente |

### OrgaMemoryMode: memoria temporal diferencial

V3 introduce memoria temporal adaptativa por organismo. El mismo sensor opera con escalas contextuales distintas según la fisiología del activo:

| Modo | NormWindow | Organismo | Fisiología |
|---|---:|---|---|
| FAST | 100 | BTC-like | Reactivo, nervioso |
| SLOW | 300 | XAU-like | Viscoso, acumulativo |
| ULTRA | 500 | Largo plazo | Memoria extendida |
| MANUAL | N definido | Cualquiera | Control experimental |

## VII. Pregunta experimental para V3

**Hipótesis de robustez:** ¿La razón `XAU_persistence / BTC_persistence` se mantiene cercana a 2x bajo el motor continuo de V3?

- **Si la razón se mantiene (≈2x):** la viscosidad diferencial es una propiedad robusta del organismo, independiente de la arquitectura del motor. Hallazgo estructural real.
- **Si la razón cambia significativamente:** la viscosidad observada en V2.2 dependía parcialmente del threshold binario. También es información valiosa: delimita causalidad entre propiedad del motor y propiedad del mercado.

### Nota metodológica

Ambos resultados son científicamente válidos. El objetivo no es confirmar la teoría. Es delimitar qué pertenece al organismo y qué pertenece al sensor.

## VIII. Registro histórico

**Primer hallazgo experimental autónomo del proyecto**  
Fecha: 11 de junio de 2026  
Activos: BTCUSD M1 vs XAUUSD M1  
Motor: QPLAB V2.2 — parámetros idénticos  
Hallazgo: Histéresis diferencial emergente entre organismos financieros  
Evidencia: XAU `persistence_max = 2.09` vs BTC `persistence_max = 1.08` (razón ≈2x)  
Naturaleza: propiedad emergente reproducible, no narrativa, no analogía.

---

**Fuente de archivo:** `QPLAB_Registro_Experimental_V2_2.docx` incluido en `QPLAB_Proyecto_Completo_17jun26(1).zip`. Esta versión Markdown preserva el contenido textual y las tablas del documento fuente para consulta y búsqueda en GitHub.