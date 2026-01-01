import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../../components/ui/Button';
import { Card } from '../../components/ui/Card';
import { ChevronLeft, CheckCircle2, Calendar, User, FileText } from 'lucide-react';
export function Summary() {
  const navigate = useNavigate();
  return <div className="min-h-screen bg-surface flex flex-col">
      <div className="bg-white px-4 py-4 border-b border-gray-100">
        <div className="flex items-center mb-4 max-w-md mx-auto">
          <button onClick={() => navigate(-1)} className="p-2 -ml-2">
            <ChevronLeft className="h-6 w-6 text-secondary" />
          </button>
          <div className="flex-1 ml-2">
            <h1 className="font-bold text-lg text-secondary">
              Confirmar Crédito
            </h1>
            <div className="flex gap-1 mt-1">
              {[...Array(9)].map((_, i) => <div key={i} className="h-1 flex-1 bg-primary rounded-full" />)}
            </div>
          </div>
          <span className="ml-4 text-sm font-medium text-text-secondary">
            9/9
          </span>
        </div>
      </div>

      <main className="flex-1 px-4 py-6 max-w-md mx-auto w-full space-y-6">
        <Card className="space-y-4">
          <div className="flex items-start gap-3">
            <div className="bg-primary/10 p-2 rounded-full">
              <User className="h-6 w-6 text-primary" />
            </div>
            <div>
              <p className="text-sm text-text-secondary">Cliente</p>
              <h3 className="font-bold text-secondary text-lg">
                Juan Pérez García
              </h3>
              <p className="text-sm text-text-secondary">Tel: 55 1234 5678</p>
            </div>
          </div>

          <div className="h-px bg-gray-100" />

          <div className="flex items-start gap-3">
            <div className="bg-blue-50 p-2 rounded-full">
              <FileText className="h-6 w-6 text-blue-600" />
            </div>
            <div>
              <p className="text-sm text-text-secondary">Tipo de Crédito</p>
              <h3 className="font-bold text-secondary">Semanal 10 Pagos</h3>
              <p className="text-sm text-text-secondary">Tasa 20%</p>
            </div>
          </div>

          <div className="bg-gray-50 rounded-xl p-4 space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-text-secondary">Monto solicitado:</span>
              <span className="font-bold text-secondary">$3,000</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-text-secondary">Ganancia (20%):</span>
              <span className="font-medium text-success">+$600</span>
            </div>
            <div className="h-px bg-gray-200 my-1" />
            <div className="flex justify-between text-base">
              <span className="font-medium text-secondary">Total a pagar:</span>
              <span className="font-bold text-secondary">$3,600</span>
            </div>
            <div className="flex justify-between text-base">
              <span className="font-medium text-secondary">Pago semanal:</span>
              <span className="font-bold text-primary">$360</span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="flex items-center gap-2 text-sm text-text-secondary">
              <CheckCircle2 className="h-4 w-4 text-success" />1 Avalista
            </div>
            <div className="flex items-center gap-2 text-sm text-text-secondary">
              <CheckCircle2 className="h-4 w-4 text-success" />
              Video guardado
            </div>
          </div>
        </Card>

        <div className="flex items-center justify-center gap-2 text-sm text-text-secondary">
          <Calendar className="h-4 w-4" />
          Fecha de desembolso:{' '}
          <span className="font-bold text-secondary">Hoy, 15 Ene 2024</span>
        </div>

        <Button fullWidth size="lg" className="text-lg shadow-xl shadow-primary/20" onClick={() => navigate('/dashboard')}>
          OTORGAR CRÉDITO
        </Button>
      </main>
    </div>;
}