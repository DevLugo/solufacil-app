import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Header } from '../../components/ui/Header';
import { BottomNav } from '../../components/ui/BottomNav';
import { Card } from '../../components/ui/Card';
import { Input } from '../../components/ui/Input';
import { Search, MapPin, ChevronRight } from 'lucide-react';
const localities = [{
  id: 1,
  name: 'San Miguel',
  clients: 12,
  pending: 8,
  amount: 2880
}, {
  id: 2,
  name: 'El Carmen',
  clients: 8,
  pending: 5,
  amount: 1800
}, {
  id: 3,
  name: 'Guadalupe',
  clients: 15,
  pending: 15,
  amount: 5400
}];
export function SelectLocation() {
  const navigate = useNavigate();
  return <div className="min-h-screen bg-surface pb-24">
      <Header currentRoute="Centro" />

      <main className="px-4 py-6 space-y-6 max-w-md mx-auto">
        <div className="space-y-4">
          <h1 className="text-2xl font-bold text-secondary">Cobrar</h1>

          <Input placeholder="Buscar localidad..." leftIcon={<Search className="h-5 w-5" />} className="bg-white" />

          <div className="space-y-3">
            <h2 className="text-sm font-semibold text-text-secondary uppercase tracking-wider">
              Localidades de Ruta Centro
            </h2>

            {localities.map(loc => <Card key={loc.id} className="active:scale-[0.98] transition-transform cursor-pointer hover:border-primary/30" onClick={() => navigate(`/collect/${loc.id}`)}>
                <div className="flex items-center justify-between">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <MapPin className="h-5 w-5 text-primary" />
                      <h3 className="font-bold text-lg text-secondary">
                        {loc.name}
                      </h3>
                    </div>
                    <p className="text-sm text-text-secondary pl-7">
                      {loc.clients} clientes |{' '}
                      <span className="text-warning font-medium">
                        {loc.pending} pendientes
                      </span>
                    </p>
                  </div>
                  <ChevronRight className="h-5 w-5 text-gray-400" />
                </div>

                <div className="mt-4 pl-7 flex items-center gap-2">
                  <span className="text-sm text-text-secondary">
                    Monto pendiente:
                  </span>
                  <span className="font-bold text-secondary text-lg">
                    ${loc.amount.toLocaleString()}
                  </span>
                </div>
              </Card>)}
          </div>
        </div>
      </main>

      <BottomNav />
    </div>;
}