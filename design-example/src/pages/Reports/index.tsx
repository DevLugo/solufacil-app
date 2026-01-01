import React from 'react';
import { Header } from '../../components/ui/Header';
import { BottomNav } from '../../components/ui/BottomNav';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { Calendar, Download, TrendingUp, Users, DollarSign, PieChart } from 'lucide-react';
import { cn } from '../../lib/utils';
export function Reports() {
  return <div className="min-h-screen bg-surface pb-24">
      <Header currentRoute="Centro" />

      <main className="px-4 py-6 space-y-6 max-w-md mx-auto">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-secondary">Reportes</h1>
          <Button variant="outline" size="sm" className="h-9">
            <Calendar className="h-4 w-4 mr-2" />
            Ene 2024
          </Button>
        </div>

        <div className="flex p-1 bg-gray-100 rounded-xl">
          {['Semana', 'Mes', 'Año'].map((tab, i) => <button key={tab} className={cn('flex-1 py-1.5 text-sm font-medium rounded-lg transition-all', i === 0 ? 'bg-white text-secondary shadow-sm' : 'text-text-secondary hover:text-secondary')}>
              {tab}
            </button>)}
        </div>

        <div className="grid grid-cols-2 gap-4">
          <Card className="p-4 space-y-2">
            <div className="p-2 bg-blue-50 rounded-lg w-fit">
              <DollarSign className="h-5 w-5 text-blue-600" />
            </div>
            <p className="text-xs text-text-secondary uppercase">
              Cobrado Total
            </p>
            <p className="text-xl font-bold text-secondary">$45,200</p>
            <span className="text-xs text-success font-medium flex items-center">
              <TrendingUp className="h-3 w-3 mr-1" /> +12%
            </span>
          </Card>

          <Card className="p-4 space-y-2">
            <div className="p-2 bg-orange-50 rounded-lg w-fit">
              <PieChart className="h-5 w-5 text-orange-600" />
            </div>
            <p className="text-xs text-text-secondary uppercase">Efectividad</p>
            <p className="text-xl font-bold text-secondary">85%</p>
            <span className="text-xs text-text-secondary">Meta: 90%</span>
          </Card>

          <Card className="p-4 space-y-2">
            <div className="p-2 bg-purple-50 rounded-lg w-fit">
              <Users className="h-5 w-5 text-purple-600" />
            </div>
            <p className="text-xs text-text-secondary uppercase">
              Clientes Activos
            </p>
            <p className="text-xl font-bold text-secondary">142</p>
            <span className="text-xs text-success font-medium">+5 nuevos</span>
          </Card>

          <Card className="p-4 space-y-2">
            <div className="p-2 bg-green-50 rounded-lg w-fit">
              <DollarSign className="h-5 w-5 text-green-600" />
            </div>
            <p className="text-xs text-text-secondary uppercase">Colocado</p>
            <p className="text-xl font-bold text-secondary">$24k</p>
            <span className="text-xs text-text-secondary">8 créditos</span>
          </Card>
        </div>

        <Card>
          <h3 className="font-bold text-secondary mb-4">Rendimiento Semanal</h3>
          <div className="h-48 flex items-end justify-between gap-2 px-2">
            {[40, 65, 45, 80, 55, 90].map((h, i) => <div key={i} className="w-full flex flex-col items-center gap-2 group">
                <div className="w-full bg-primary/20 rounded-t-lg transition-all group-hover:bg-primary relative" style={{
              height: `${h}%`
            }}>
                  <div className="absolute -top-6 left-1/2 -translate-x-1/2 text-xs font-bold text-primary opacity-0 group-hover:opacity-100 transition-opacity">
                    {h}%
                  </div>
                </div>
                <span className="text-xs text-text-secondary">
                  {['L', 'M', 'M', 'J', 'V', 'S'][i]}
                </span>
              </div>)}
          </div>
        </Card>

        <Button variant="outline" fullWidth>
          <Download className="h-5 w-5 mr-2" />
          Exportar Reporte PDF
        </Button>
      </main>

      <BottomNav />
    </div>;
}