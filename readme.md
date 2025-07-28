# 🚀 Solución al Desafío Grader5 (Módulo 5)

Este repositorio documenta el proceso y los desafíos encontrados al desarrollar una solución para interactuar con el contrato Grader5 (ubicado en la dirección `0x5733eE985e22eFF46F595376d79e31413b1A1e16` en la red Sepolia). El objetivo final es cumplir con sus requisitos internos y registrar un nombre de forma exitosa.

## 🌟 Visión General del Proyecto

El proyecto implicó el desarrollo de un contrato inteligente en Solidity (`GradeMaster_v1.sol`, con varias iteraciones) diseñado para interactuar con el contrato Grader5 en una única transacción. El enfoque se centró en descifrar y cumplir las condiciones a menudo "ocultas" de Grader5, como las llamadas a `retrieve()` con valores específicos y el registro posterior del nombre.

## 🛠️ Proceso de Desarrollo y Depuración Detallado

El desarrollo de esta solución fue un ejercicio de depuración y mucha paciencia, marcado por varias iteraciones y la necesidad de un análisis profundo para resolver los problemas de interacción con el contrato Grader5.

### Fases Clave y Errores Encontrados:

#### **Diseño Inicial y Primeros Intentos**

**Estrategia Inicial**:
- Se concibió un contrato `GradeMaster_v1` con una función central `solveChallenge` para encapsular la lógica
- Se planeó usar llamadas `.call` con `abi.encodeWithSignature` para interactuar con `Grader5.retrieve()` y `Grader5.gradeMe(string)`
- Se incluyó un `require(msg.value >= 5 wei)` inicial en `solveChallenge` para asegurar los fondos

**Error Frecuente (1): Ejecución de receive() en lugar de solveChallenge()**:

*Síntoma*:
Al intentar ejecutar `solveChallenge` desde Remix, la consola mostraba una transacción exitosa, pero la lógica dentro de `solveChallenge` no se ejecutaba; en su lugar, se activaba inesperadamente la función `receive()` del contrato. Esto resultaba en que el ETH se transfería al contrato, pero el desafío no progresaba.

*Diagnóstico*:
La interfaz de Remix en El VALUE se estaba aplicando a una transacción por defecto de "enviar ETH al contrato", en lugar de ser un `msg.value` pasado directamente a la función `solveChallenge` al invocarla.

*Solución*:
Se ajustó el método de interacción en Remix:
1. El VALUE y los parámetros (`yourName`) se ingresaran específicamente en los campos asociados a la función `solveChallenge` (en la sección "Deployed Contracts")
2. Se hiciera clic en su botón transact individual

#### **Fallo Consistente en la Ejecución (status 0x0 Transaction mined but execution failed)**

*Síntoma*:
Una vez corregida la invocación de la función, las transacciones a `solveChallenge` empezaron a fallar consistentemente en la red Sepolia, mostrando el mensaje `status 0x0 Transaction mined but execution failed`. Esto indicaba que la transacción era minada, pero la ejecución de la lógica del contrato revertía.

*Diagnóstico Inicial*:
- Posible insuficiencia de gas para la ejecución de `GradeMaster`
- Problemas con las cantidades de wei enviadas a las llamadas internas a `retrieve()`

*Solución Parcial*:
Se aumentó el VALUE de la transacción principal que invocaba `solveChallenge` a 0.01 Ether (o 10000000000000000 Wei). Esto garantizaba que había suficiente ETH para cubrir el gas de la transacción principal y los 5 wei que se reenvían a Grader5. A pesar de esto, el fallo persistió.

#### **Depuración Avanzada y Detección de Falla en Sub-llamada (Gas estimation failed y CALL revert)**

*Herramienta Crucial*:
Utilizar el depurador de Remix.

*Hallazgo Crítico*:
El depurador revela consistentemente que la ejecución se revertía (`REVERT` opcode) inmediatamente después de la instrucción `CALL` que correspondía a la primera llamada externa a `Grader5.retrieve()` (la línea `graderAddress.call{value: 4}(...)` en el código). Esto indicó que:
1. La función `retrieve()` dentro de Grader5 estaba revirtiendo
2. Esto causaba que el `require(success1, "First retrieve failed");` en `GradeMaster` fallara
3. El mensaje recurrente de Remix y MetaMask "Gas estimation failed" se entendió como una indicación de que la sub-llamada estaba fallando y no se podía prever su consumo de gas

#### **Ajuste de Gas Explícito en Llamadas Externas y Valor de retrieve()**

*Hipótesis*:
1. La sobrecarga de la llamada misma


*Solución Implementada*:
1. Se añadió un límite de gas explícito y generoso (`gas: 200000` o incluso `500000` en pruebas posteriores) a todas las llamadas `.call` dentro de la función `solveChallenge` (tanto las dos llamadas a `retrieve()` como la llamada a `gradeMe(string)`). Esto asegura que Grader5 disponga de una cantidad más que suficiente de gas para su propia ejecución.
2. Se mantuvo el `value` de 4 wei para la primera llamada a `retrieve()` (siendo la causa principal el gas), aunque se consideró probar 5 wei como una alternativa para cumplir la condición de "más de 3 wei" de forma más robusta.

**Estado Actual**:
La versión final del contrato (`GradeMaster_v3.sol`) incorpore estos ajustes. Las pruebas finales con esta configuración todavía generaban el mensaje "Gas estimation failed" en MetaMask