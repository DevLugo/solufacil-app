# Funcionalidades Extra de Cobranza Mobile

Este documento lista todas las funcionalidades implementadas que **NO estaban en el plan original** (`glistening-swimming-walrus.md`).

---

## 1. Pagos Mixtos (Cash + Transferencia)

**Plan original**: Solo permitía seleccionar UN método de pago (CASH o MONEY_TRANSFER).

**Implementado**:
- Soporte para pagos mixtos donde parte es efectivo y parte transferencia
- Nuevo modelo `PaymentEntry` con `cashAmount` y `bankAmount` separados
- `amount` y `paymentMethod` ahora son getters computados
- **UI centrada en pago simple**: Un monto principal con selector de tipo (Efectivo/Transferencia)
- **Pago mixto como edge case**: Botón "+ Agregar pago mixto" expande monto secundario
- Monto secundario tiene su propio mini-numpad integrado
- Listado muestra badges de color según tipo de pago

**Archivos modificados**:
- `lib/data/models/payment_input.dart` - Nuevo modelo mixto
- `lib/providers/collection_provider.dart` - Cálculos separados cash/bank
- `lib/ui/pages/collection/register_payment_page.dart` - UI single-payment focus
- `lib/ui/pages/collection/client_list_page.dart` - Display con badges

---

## 2. Confirmación de Cambios en Pagos

**Plan original**: No especificaba manejo del botón back ni confirmación.

**Implementado**:
- Detección de cambios (`_hasChanges`) comparando valores iniciales
- Diálogo de confirmación al presionar back con cambios pendientes
- Botón de confirmación que aparece SOLO cuando hay cambios
- Resumen visual del pago antes de confirmar (monto, método, comisión)

**Archivos modificados**:
- `lib/ui/pages/collection/register_payment_page.dart`
  - `PopScope` con `onPopInvoked`
  - `_onWillPop()` con diálogo
  - `_ConfirmButton` widget con resumen

---

## 3. Extra Cobranzas (Clientes Cleanup/Cartera Muerta)

**Plan original**: Solo mostraba préstamos activos.

**Implementado**:
- Nuevo provider `extraLoansForLocalityProvider` para clientes en:
  - Portfolio Cleanup (`excludedByCleanup IS NOT NULL`)
  - Cartera Muerta (`badDebtDate IS NOT NULL`)
- Sección colapsable "Extra Cobranzas" al final de la lista
- Header mostrando cantidad de clientes extra
- Cards con estilo distintivo (color púrpura)
- Labels específicos: "Cartera Muerta" o "Limpieza"
- Permite registrar pagos normalmente

**Archivos modificados**:
- `lib/providers/collection_provider.dart`
  - `_extraLoansQuery` SQL
  - `extraLoansForLocalityProvider`
- `lib/ui/pages/collection/client_list_page.dart`
  - Estado `_showExtraCobranzas`
  - `_ExtraCobranzasHeader` widget
  - `_ClientCard` con parámetro `isExtra`

---

## 4. Header KPI Mejorado

**Plan original**: Solo mencionaba "Header con totales".

**Implementado**:
- 4 métricas KPI en grid: Esperado, Cobrado, Pendiente, Comisión
- Barra de progreso visual del día
- Contadores de clientes: pagados / faltas / total
- Iconos y colores distintivos por métrica
- Breakdown cash vs banco en cobrado

**Archivos modificados**:
- `lib/ui/pages/collection/client_list_page.dart` - `_SummaryHeader`

---

## 5. Acciones Rápidas Mejoradas

**Plan original**: No especificaba acciones masivas.

**Implementado**:
- Botón "Aplicar semanal a todos" (pago esperado)
- Botón "Marcar todos sin pago" (faltas)
- Campo para comisión global personalizada
- Botón "Limpiar todo"
- Botones de acción rápida por cliente (sin pago individual)
- Eliminación de pago pendiente con X

**Archivos modificados**:
- `lib/ui/pages/collection/client_list_page.dart`
  - `_QuickActionsBar`
  - `_quickPayWeekly`, `_applyAllWeekly`, etc.

---

## 6. Búsqueda de Clientes

**Plan original**: No mencionaba búsqueda.

**Implementado**:
- Barra de búsqueda sticky debajo del header
- Filtrado por nombre o código de cliente
- Aplica tanto a préstamos activos como extra

**Archivos modificados**:
- `lib/ui/pages/collection/client_list_page.dart` - `_SearchBar`

---

## 7. Quick Amount Buttons

**Plan original**: No especificaba atajos de monto.

**Implementado**:
- Chips con montos rápidos: Esperado, x2, x0.5
- Selección visual del monto actual
- Aplican al campo activo (cash o bank)

**Archivos modificados**:
- `lib/ui/pages/collection/register_payment_page.dart` - `_QuickAmountButtons`

---

## 8. Pantalla de Éxito Animada

**Plan original**: No especificaba feedback visual.

**Implementado**:
- Pantalla fullscreen con animación de check
- Color verde para pago, naranja para falta
- Mensaje y monto registrado
- Auto-navegación back después de 1.5s

**Archivos modificados**:
- `lib/ui/pages/collection/register_payment_page.dart` - `_SuccessScreen`

---

## 9. Indicadores de Pago Mejorados

**Plan original**: No especificaba diferenciación visual por tipo de pago.

**Implementado**:
- **Badge de tipo de pago** con colores distintivos:
  - **Efectivo**: Badge verde con icono de billete
  - **Transferencia**: Badge azul con icono de tarjeta
  - **Mixto**: Badge con gradiente verde-azul mostrando ambos montos
- **Badge de comisión**: Muestra comisión con icono de estrella en púrpura
- **Badge "Sin pago"**: Badge rojo sólido para faltas
- Widgets separados para mejor mantenimiento (`_PaymentTypeBadge`)

**Archivos modificados**:
- `lib/ui/pages/collection/client_list_page.dart`
  - `_PaymentTypeBadge` widget nuevo
  - `_buildPaymentInfo()` mejorado

---

## Resumen de Archivos Nuevos/Modificados

| Archivo | Estado | Extras Implementados |
|---------|--------|---------------------|
| `payment_input.dart` | Modificado | Pagos mixtos |
| `collection_provider.dart` | Modificado | Extra cobranzas, cálculos mixtos |
| `client_list_page.dart` | Modificado | KPIs, búsqueda, extras, acciones rápidas, badges de pago |
| `register_payment_page.dart` | Modificado | Confirmación, UI single-focus, animaciones |

---

## Notas Técnicas

### Compatibilidad hacia atrás
- `PaymentEntry.amount` es ahora `cashAmount + bankAmount`
- `PaymentEntry.paymentMethod` retorna el tipo dominante
- Getters `isMixed`, `isCashOnly`, `isBankOnly` para lógica condicional

### Rendimiento
- Proveedores separados para activos vs extras (carga lazy)
- Filtrado en memoria para búsqueda rápida
- ListView en lugar de ListView.builder para secciones mixtas
