# QPLAB V2.3 — Registro experimental

**Fecha:** 12 de junio de 2026  
**Estado:** histórico / cerrado  
**Fuente de archivo:** `QPLAB_Proyecto_Completo_17jun26(1).zip`

## 1. Propósito

V2.3 constituye la transición desde la persistencia binaria de V2.2 hacia una **Persistence continua** y un equilibrio dinámico (`P_eq`). El objetivo fue eliminar la dependencia estructural del resultado respecto de un umbral binario y comprobar si la histéresis observada en V2.2 sobrevivía bajo una dinámica fisiológica continua.

## 2. Cambio principal respecto de V2.2

- Persistence deja de actualizarse mediante una lógica binaria de acumulación/decadencia.
- Se introduce una dinámica continua de Persistence y un punto de equilibrio (`P_eq`) dependiente del forcing/estado energético.
- Se mantiene la arquitectura fisiológica de QPLAB y la observación independiente por instrumento.

## 3. Resultado principal

El índice de histéresis `H` observado en V2.2, aproximadamente **H = 1.94**, colapsa en V2.3 hacia aproximadamente **H = 1.0**.

Este resultado se interpreta como una **falsación limpia de la hipótesis de histéresis tal como había sido formulada en V2.2**: el efecto no se conserva al retirar la discretización binaria del mecanismo de Persistence.

La evidencia disponible identifica como mecanismo explicativo el **artefacto introducido por el threshold binario de V2.2**, no una propiedad fisiológica estable del mercado.

## 4. Eventos

La corrida V2.3 registró **3 descargas reales**. Estos eventos permanecen como parte del registro histórico y no deben reinterpretarse retrospectivamente como evidencia favorable a la hipótesis H de V2.2.

## 5. Datos experimentales conservados

El paquete histórico contiene, entre otros:

- `QPLAB_V2_3_BTCUSDm_PERIOD_M1.csv`
- `QPLAB_V2_3_XAUUSDm_PERIOD_M1.csv`
- `QPLAB_V2_3_BTCUSDm_PERIOD_H1.csv`
- `QPLAB_V2_3_XAUUSDm_PERIOD_H1.csv`

Estos archivos constituyen la base primaria para reproducir la corrida V2.3.

## 6. Valor científico del resultado

V2.3 es importante principalmente por su resultado negativo: demuestra que la señal de histéresis de V2.2 no era robusta frente a un cambio metodológico mínimo pero fundamental en la dinámica de Persistence.

La secuencia experimental queda registrada como:

`V2.2 → H≈1.94 → sospecha de efecto`  
`V2.3 → Persistence continua → H≈1.0 → falsación del efecto de V2.2`

## 7. Consecuencia para versiones posteriores

La falsación de V2.3 motivó la diferenciación de parámetros por instrumento y las extensiones estructurales introducidas posteriormente en V2.4 y V2.4B.

## 8. Regla de preservación

Este documento registra el resultado histórico tal como fue consolidado posteriormente. No modifica ni reemplaza los archivos originales de la corrida V2.3. Los resultados negativos o falsificados forman parte integral de la trazabilidad científica de QPLAB.
