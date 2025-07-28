# 🚀 Solución al Desafío Grader5 (Módulo 5)

Este repositorio documenta el proceso y los desafíos encontrados al desarrollar una solución para interactuar con el contrato Grader5 (ubicado en la dirección `0x5733eE985e22eFF46F595376d79e31413b1A1e16` en la red Sepolia). El objetivo final es cumplir con sus requisitos internos y registrar un nombre de forma exitosa.

## Contratos Desplegados y Direcciones

Durante el proceso de resolución del desafío `Grader5` en la red Sepolia, se realizaron despliegues de varias versiones del contrato de solución para depuración y pruebas.

Listado las direcciones de los contratos principales que fueron desplegados desde mi cuenta `0x39581f1c36CfeBfB36934E583fb3e3CE92Ba6c58`:

* **`GradeMaster` (Primera Iteración):**
    * **Dirección del Contrato:** `0xd3e4cf9c0f53d1d93666076bf9b7c18acc8f631c`
    * **Hash de Creación:** `0x5b1fb7e25b5be87bfce80e73388491f3642189d94d929ce9df9df3b114f2840b`
    * **Notas:** Esta fue la versión inicial del contrato. Las transacciones a `solveChallenge` en esta versión inicialmente activaban `receive()` o fallaban con `status 0x0`, lo que me lleva a las siguientes iteraciones más sencillas.

* **`GradeMaster_v2`:**
    * **Dirección del Contrato:** `0xa712647fdbf1a699498eea85f861a22fd559937d`
    * **Hash de Creación:** `0xe4f10e8bc8b52966406acc6e36d688eafb5118384df3a76492486bfca7d8649f`
    * **Notas:** Esta versión fue desplegada como parte del proceso de depuración y refactorización, buscaba solucionar los problemas encontrados en la primera iteración. Las transacciones a `solveChallenge` con esta versión también mostraron `status 0x0` de fallo de ejecución.

* **`GradeMaster_v3` (Versión Actual de Trabajo):**
    * **Dirección del Contrato:** `0xd4399df59f12ffd9271fa0ebc1026e98baa227b6`
    * **Hash de Creación:** `0xb95b364132a4e9b7b91d26ff35263158f334a176a95` 
    * **Notas:** Esta es la última versión del contrato de solución que incorpora los ajustes de gas explícito en las llamadas externas y las correcciones de `value` identificadas durante el proceso de depuración. Las transacciones a `solveChallenge` en esta versión aún muestran advertencias de "Gas estimation failed" en MetaMask

**Dirección del Contrato `Grader5` (Target del Desafío):**
* `0x5733eE985e22eFF46F595376d79e31413b1A1e16`


### Fases Clave y Errores Encontrados:

#### **Diseño Inicial y Primeros Intentos**

**Estrategia Inicial**:
- Se concibió un contrato `GradeMaster_v1` con una función central `solveChallenge` para encapsular la lógica
- Planeaba usar llamadas `.call` con `abi.encodeWithSignature` para interactuar con `Grader5.retrieve()` y `Grader5.gradeMe(string)`
- Se incluyó un `require(msg.value >= 5 wei)` inicial en `solveChallenge` para asegurar los fondos

**Error Frecuente (1): Ejecución de receive() en lugar de solveChallenge()**:

Al intentar ejecutar `solveChallenge` desde Remix, la consola mostraba una transacción exitosa, pero la lógica dentro de `solveChallenge` no se ejecutaba; en su lugar, se activaba inesperadamente la función `receive()` del contrato. Esto resultaba en que el ETH se transfería al contrato, pero el desafío no progresaba.

#### **Fallo Consistente en la Ejecución (status 0x0 Transaction mined but execution failed)**

Una vez corregida la invocación de la función, las transacciones a `solveChallenge` empezaron a fallar consistentemente en la red Sepolia, mostrando el mensaje `status 0x0 Transaction mined but execution failed`. Esto indicaba que la transacción era minada, pero la ejecución de la lógica del contrato revertía.

*Solución Parcial*:
Se aumentó el VALUE de la transacción principal que invocaba `solveChallenge` a 0.01 Ether (o 10000000000000000 Wei). Esto garantizaba que había suficiente ETH para cubrir el gas de la transacción principal y los 5 wei que se reenvían a Grader5, a pesar de esto, el fallo persistió.

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
