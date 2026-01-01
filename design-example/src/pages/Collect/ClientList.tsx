import React from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Header } from '../../components/ui/Header';
import { BottomNav } from '../../components/ui/BottomNav';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { CheckCircle2, AlertCircle, Clock, ChevronLeft, DollarSign } from 'lucide-react';
import { cn } from '../../lib/utils';
const clients = [{
  id: 1,
  name: 'Ana Martínez',
  status: 'paid',
  amount: 0,
  lastPayment: 360
}, {
  id: 2,
  name: 'Carlos Ruiz',
  status: 'late1',
  amount: 360,
  weeksLate: 1
}, {
  id: 3,
  name: 'Luis Torres',
  status: 'late2',
  amount: 720,
  weeksLate: 2
}, {
  id: 4,
  name: 'María López',
  status: 'pending',
  amount: 360,
  weeksLate: 0
}];
export function ClientList() {
  const navigate = useNavigate();
  const {
    locationId
  } = useParams();
  return <div className="min-h-screen bg-surface pb-24">
      <div className="sticky top-0 z-40 bg-white border-b border-gray-100">
        <div className="flex items-center h-16 px-4 max-w-md mx-auto">
          <button onClick={() => navigate(-1)} className="p-2 -ml-2 text-secondary">
            <ChevronLeft className="h-6 w-6" />
          </button>
          <h1 className="font-bold text-lg ml-2">San Miguel</h1>
        </div>

        {/* Progress Bar */}
        <div className="px-4 pb-4 max-w-md mx-auto">
          <div className="flex justify-between text-sm mb-2">
            <span className="text-text-secondary">Progreso: 4/12 cobrados</span>
            <span className="font-bold text-primary">33%</span>
          </div>
          <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
            <div className="h-full bg-primary w-1/3 rounded-full" />
          </div>
        </div>
      </div>

      <main className="px-4 py-6 space-y-4 max-w-md mx-auto">
        {clients.map(client => <Card key={client.id} className="relative overflow-hidden">
            <div className="flex items-start justify-between">
              <div className="flex gap-3">
                {client.status === 'paid' && <CheckCircle2 className="h-6 w-6 text-success shrink-0" />}
                {client.status === 'late1' && <AlertCircle className="h-6 w-6 text-warning shrink-0" />}
                {client.status === 'late2' && <AlertCircle className="h-6 w-6 text-error shrink-0" />}
                {client.status === 'pending' && <Clock className="h-6 w-6 text-gray-400 shrink-0" />}

                <div>
                  <h3 className="font-bold text-secondary text-lg">
                    {client.name}
                  </h3>

                  {client.status === 'paid' ? <p className="text-sm text-text-secondary mt-1">
                      Pagado:{' '}
                      <span className="font-medium text-success">
                        ${client.lastPayment}
                      </span>{' '}
                      | Faltan 6 pagos
                    </p> : <div className="mt-1 space-y-1">
                      <p className="text-sm text-text-secondary">
                        Debe:{' '}
                        <span className="font-bold text-secondary">
                          ${client.amount}
                        </span>
                      </p>
                      {client.weeksLate > 0 && <p className={cn('text-xs font-medium', client.status === 'late2' ? 'text-error' : 'text-warning')}>
                          Atrasado {client.weeksLate} semana
                          {client.weeksLate > 1 ? 's' : ''}
                        </p>}
                    </div>}
                </div>
              </div>

              {client.status !== 'paid' && <Button size="sm" className="bg-green-600 hover:bg-green-700 text-white shadow-none" onClick={() => navigate(`/collect/payment/${client.id}`)}>
                  <DollarSign className="h-4 w-4 mr-1" />
                  Cobrar
                </Button>}
            </div>
          </Card>)}

        <Button variant="outline" fullWidth className="mt-8 border-dashed">
          Marcar restantes como visitados
        </Button>
      </main>

      <BottomNav />
    </div>;
}