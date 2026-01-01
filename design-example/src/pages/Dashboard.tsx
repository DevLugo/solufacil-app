import React from 'react';
import { Header } from '../components/ui/Header';
import { BottomNav } from '../components/ui/BottomNav';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { TrendingUp, CheckCircle2, AlertCircle, ChevronRight, DollarSign, Users, FileText, Plus } from 'lucide-react';
export function Dashboard() {
  return <div className="min-h-screen bg-surface pb-24">
      <Header />

      <main className="px-4 py-6 space-y-6 max-w-md mx-auto">
        {/* Welcome Card */}
        <Card className="bg-gradient-to-br from-secondary to-[#2D2D4A] text-white border-none shadow-xl">
          <div className="flex justify-between items-start mb-4">
            <div>
              <h1 className="text-2xl font-bold mb-1">Hola, Juan 👋</h1>
              <p className="text-gray-300 font-medium">Semana 15 de 2024</p>
            </div>
            <div className="bg-white/10 p-2 rounded-lg backdrop-blur-sm">
              <span className="text-xs font-bold px-2 py-1 bg-green-500/20 text-green-300 rounded-full border border-green-500/30">
                En línea
              </span>
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex items-center gap-2 text-sm text-gray-200">
              <div className="h-2 w-2 rounded-full bg-primary animate-pulse" />
              <span>12 cobros pendientes hoy</span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-200">
              <div className="h-2 w-2 rounded-full bg-blue-400" />
              <span>3 clientes nuevos esta semana</span>
            </div>
          </div>
        </Card>

        {/* KPI Grid */}
        <div className="grid grid-cols-2 gap-4">
          {/* Main KPI - Full Width */}
          <Card className="col-span-2 flex flex-row items-center justify-between p-4">
            <div>
              <p className="text-sm text-text-secondary font-medium mb-1">
                Cartera Total
              </p>
              <h2 className="text-3xl font-bold text-secondary">$45,000</h2>
            </div>
            <div className="flex flex-col items-end">
              <div className="flex items-center gap-1 text-success bg-success/10 px-2 py-1 rounded-lg text-xs font-bold">
                <TrendingUp className="h-3 w-3" />
                <span>+12%</span>
              </div>
              <p className="text-xs text-text-secondary mt-1">
                vs semana anterior
              </p>
            </div>
          </Card>

          {/* Secondary KPIs */}
          <Card className="p-4 space-y-2">
            <div className="flex items-center gap-2 mb-1">
              <div className="p-1.5 bg-green-100 rounded-lg">
                <CheckCircle2 className="h-4 w-4 text-green-600" />
              </div>
              <span className="text-xs font-bold text-text-secondary uppercase tracking-wider">
                Cobrado
              </span>
            </div>
            <p className="text-xl font-bold text-secondary">$12,500</p>
            <div className="w-full bg-gray-100 rounded-full h-1.5 mt-2">
              <div className="bg-success h-1.5 rounded-full" style={{
              width: '85%'
            }} />
            </div>
            <p className="text-[10px] text-text-secondary text-right">
              85% de la meta
            </p>
          </Card>

          <Card className="p-4 space-y-2">
            <div className="flex items-center gap-2 mb-1">
              <div className="p-1.5 bg-orange-100 rounded-lg">
                <AlertCircle className="h-4 w-4 text-orange-600" />
              </div>
              <span className="text-xs font-bold text-text-secondary uppercase tracking-wider">
                Pendiente
              </span>
            </div>
            <p className="text-xl font-bold text-secondary">$8,200</p>
            <div className="w-full bg-gray-100 rounded-full h-1.5 mt-2">
              <div className="bg-warning h-1.5 rounded-full" style={{
              width: '15%'
            }} />
            </div>
            <p className="text-[10px] text-text-secondary text-right">
              15% restante
            </p>
          </Card>
        </div>

        {/* Weekly Summary */}
        <Card className="space-y-4">
          <div className="flex items-center justify-between border-b border-gray-100 pb-3">
            <h3 className="font-bold text-secondary">Resumen Semanal</h3>
            <span className="text-xs text-text-secondary bg-gray-100 px-2 py-1 rounded-md">
              Lun 12 - Sáb 17 Ene
            </span>
          </div>

          <div className="grid grid-cols-2 gap-6">
            <div className="space-y-1">
              <p className="text-xs text-text-secondary">Créditos Otorgados</p>
              <p className="text-lg font-bold text-secondary">8</p>
              <p className="text-xs font-medium text-primary">$24,000</p>
            </div>
            <div className="space-y-1">
              <p className="text-xs text-text-secondary">Pagos Recibidos</p>
              <p className="text-lg font-bold text-secondary">45</p>
              <p className="text-xs font-medium text-success">$12,500</p>
            </div>
          </div>

          <Button variant="ghost" fullWidth className="text-sm h-10 mt-2 border border-gray-100">
            Ver Reporte Completo <ChevronRight className="h-4 w-4 ml-1" />
          </Button>
        </Card>

        {/* Quick Actions */}
        <div>
          <h3 className="font-bold text-secondary mb-3 px-1">
            Acciones Rápidas
          </h3>
          <div className="grid grid-cols-2 gap-3">
            <button className="flex items-center gap-3 p-4 bg-white rounded-xl border border-gray-100 shadow-sm hover:bg-gray-50 active:scale-[0.98] transition-all text-left">
              <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
                <Plus className="h-5 w-5" />
              </div>
              <span className="font-semibold text-sm text-secondary">
                Nuevo Crédito
              </span>
            </button>

            <button className="flex items-center gap-3 p-4 bg-white rounded-xl border border-gray-100 shadow-sm hover:bg-gray-50 active:scale-[0.98] transition-all text-left">
              <div className="h-10 w-10 rounded-full bg-green-100 flex items-center justify-center text-green-600">
                <DollarSign className="h-5 w-5" />
              </div>
              <span className="font-semibold text-sm text-secondary">
                Cobrar Ruta
              </span>
            </button>

            <button className="flex items-center gap-3 p-4 bg-white rounded-xl border border-gray-100 shadow-sm hover:bg-gray-50 active:scale-[0.98] transition-all text-left">
              <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600">
                <FileText className="h-5 w-5" />
              </div>
              <span className="font-semibold text-sm text-secondary">
                Reportes
              </span>
            </button>

            <button className="flex items-center gap-3 p-4 bg-white rounded-xl border border-gray-100 shadow-sm hover:bg-gray-50 active:scale-[0.98] transition-all text-left">
              <div className="h-10 w-10 rounded-full bg-purple-100 flex items-center justify-center text-purple-600">
                <Users className="h-5 w-5" />
              </div>
              <span className="font-semibold text-sm text-secondary">
                Clientes
              </span>
            </button>
          </div>
        </div>
      </main>

      <BottomNav />
    </div>;
}