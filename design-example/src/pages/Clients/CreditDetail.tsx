import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../../components/ui/Button';
import { Card } from '../../components/ui/Card';
import { ChevronLeft, DollarSign, RefreshCw, Calendar } from 'lucide-react';
export function CreditDetail() {
  const navigate = useNavigate();
  return <div className="min-h-screen bg-surface pb-24">
      <div className="bg-secondary text-white p-4 pb-8 rounded-b-3xl shadow-lg">
        <div className="flex items-center mb-6 max-w-md mx-auto">
          <button onClick={() => navigate(-1)} className="p-2 -ml-2">
            <ChevronLeft className="h-6 w-6" />
          </button>
          <h1 className="font-bold text-lg ml-2">Crédito #12345</h1>
          <div className="ml-auto bg-success/20 px-3 py-1 rounded-full text-xs font-bold text-green-300 border border-success/30">
            ACTIVO
          </div>
        </div>

        <div className="max-w-md mx-auto">
          <div className="flex justify-between items-end mb-2">
            <div>
              <p className="text-secondary-light text-sm mb-1">
                Monto Original
              </p>
              <p className="text-2xl font-bold">$3,000</p>
            </div>
            <div className="text-right">
              <p className="text-secondary-light text-sm mb-1">Total a Pagar</p>
              <p className="text-2xl font-bold">$3,600</p>
            </div>
          </div>

          <div className="w-full bg-secondary-light/30 h-2 rounded-full overflow-hidden mt-4">
            <div className="bg-primary h-full w-1/2 rounded-full" />
          </div>
          <div className="flex justify-between text-xs text-secondary-light mt-2">
            <span>Pagado: $1,800</span>
            <span>Pendiente: $1,800</span>
          </div>
        </div>
      </div>

      <main className="px-4 -mt-6 max-w-md mx-auto space-y-6">
        <Card className="shadow-lg">
          <div className="grid grid-cols-2 gap-4 text-center divide-x divide-gray-100">
            <div>
              <p className="text-xs text-text-secondary uppercase mb-1">
                Pago Semanal
              </p>
              <p className="text-xl font-bold text-secondary">$360</p>
            </div>
            <div>
              <p className="text-xs text-text-secondary uppercase mb-1">
                Próximo Pago
              </p>
              <p className="text-xl font-bold text-primary">15 Ene</p>
            </div>
          </div>
        </Card>

        <div>
          <h3 className="font-bold text-secondary mb-3">Historial de Pagos</h3>
          <div className="space-y-3">
            {[1, 2, 3, 4, 5].map(i => <Card key={i} className="flex items-center justify-between p-3">
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-full bg-green-50 flex items-center justify-center">
                    <span className="text-xs font-bold text-green-700">
                      #{6 - i}
                    </span>
                  </div>
                  <div>
                    <p className="font-bold text-secondary">$360</p>
                    <div className="flex items-center gap-1 text-xs text-text-secondary">
                      <Calendar className="h-3 w-3" />
                      {15 - i * 7} Ene 2024
                    </div>
                  </div>
                </div>
                <span className="text-xs font-medium bg-gray-100 px-2 py-1 rounded text-text-secondary">
                  Efectivo
                </span>
              </Card>)}
          </div>
        </div>

        <div className="flex gap-3 pt-4">
          <Button className="flex-[2]" onClick={() => navigate('/collect/payment/1')}>
            <DollarSign className="h-5 w-5 mr-2" />
            Registrar Pago
          </Button>
          <Button variant="outline" className="flex-1">
            <RefreshCw className="h-5 w-5 mr-2" />
            Renovar
          </Button>
        </div>
      </main>
    </div>;
}