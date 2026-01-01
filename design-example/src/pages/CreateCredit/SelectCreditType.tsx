import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../../components/ui/Button';
import { Card } from '../../components/ui/Card';
import { ChevronLeft, CheckCircle2 } from 'lucide-react';
import { cn } from '../../lib/utils';
const creditTypes = [{
  id: 1,
  name: 'Semanal 10 Pagos',
  rate: '20%',
  commission: 50,
  max: 5000
}, {
  id: 2,
  name: 'Semanal 15 Pagos',
  rate: '25%',
  commission: 75,
  max: 10000
}, {
  id: 3,
  name: 'Mensual 6 Pagos',
  rate: '15%',
  commission: 100,
  max: 15000
}];
export function SelectCreditType() {
  const navigate = useNavigate();
  const [selected, setSelected] = useState<number | null>(null);
  return <div className="min-h-screen bg-surface flex flex-col">
      <div className="bg-white px-4 py-4 border-b border-gray-100">
        <div className="flex items-center mb-4 max-w-md mx-auto">
          <button onClick={() => navigate(-1)} className="p-2 -ml-2">
            <ChevronLeft className="h-6 w-6 text-secondary" />
          </button>
          <div className="flex-1 ml-2">
            <h1 className="font-bold text-lg text-secondary">
              Tipo de Crédito
            </h1>
            <div className="flex gap-1 mt-1">
              {[...Array(4)].map((_, i) => <div key={i} className="h-1 flex-1 bg-primary rounded-full" />)}
              {[...Array(5)].map((_, i) => <div key={i} className="h-1 flex-1 bg-gray-200 rounded-full" />)}
            </div>
          </div>
          <span className="ml-4 text-sm font-medium text-text-secondary">
            4/9
          </span>
        </div>
      </div>

      <main className="flex-1 px-4 py-6 max-w-md mx-auto w-full space-y-4">
        <h2 className="text-lg font-medium text-secondary mb-2">
          Selecciona un plan:
        </h2>

        {creditTypes.map(type => <Card key={type.id} className={cn('cursor-pointer transition-all border-2 relative', selected === type.id ? 'border-primary bg-primary/5 shadow-md' : 'border-transparent hover:border-gray-200')} onClick={() => setSelected(type.id)}>
            {selected === type.id && <div className="absolute top-3 right-3">
                <CheckCircle2 className="h-6 w-6 text-primary fill-white" />
              </div>}

            <h3 className="font-bold text-lg text-secondary mb-2">
              {type.name}
            </h3>

            <div className="grid grid-cols-2 gap-y-2 text-sm">
              <div className="text-text-secondary">Tasa de interés:</div>
              <div className="font-semibold text-secondary">{type.rate}</div>

              <div className="text-text-secondary">Comisión:</div>
              <div className="font-semibold text-secondary">
                ${type.commission}
              </div>

              <div className="text-text-secondary">Monto máximo:</div>
              <div className="font-semibold text-primary">
                ${type.max.toLocaleString()}
              </div>
            </div>
          </Card>)}

        <div className="pt-8">
          <Button fullWidth size="lg" disabled={!selected} onClick={() => navigate('/create-credit/amount')}>
            Siguiente
          </Button>
        </div>
      </main>
    </div>;
}