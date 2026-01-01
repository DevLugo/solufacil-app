import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Header } from '../../components/ui/Header';
import { BottomNav } from '../../components/ui/BottomNav';
import { Card } from '../../components/ui/Card';
import { Input } from '../../components/ui/Input';
import { Search, ChevronRight, User } from 'lucide-react';
import { cn } from '../../lib/utils';
const clients = [{
  id: 1,
  name: 'Carlos Ruiz Gómez',
  status: 'active',
  credit: '#12345'
}, {
  id: 2,
  name: 'Ana Martínez',
  status: 'active',
  credit: '#12346'
}, {
  id: 3,
  name: 'Luis Torres',
  status: 'late',
  credit: '#12347'
}, {
  id: 4,
  name: 'María López',
  status: 'completed',
  credit: '#12200'
}];
export function ClientSearch() {
  const navigate = useNavigate();
  return <div className="min-h-screen bg-surface pb-24">
      <Header currentRoute="Centro" />

      <main className="px-4 py-6 space-y-6 max-w-md mx-auto">
        <div className="space-y-4">
          <h1 className="text-2xl font-bold text-secondary">Clientes</h1>

          <Input placeholder="Buscar por nombre, teléfono..." leftIcon={<Search className="h-5 w-5" />} className="bg-white" />

          <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
            {['Todos', 'Activos', 'Atrasados', 'Finalizados'].map((filter, i) => <button key={filter} className={cn('px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-colors', i === 0 ? 'bg-secondary text-white' : 'bg-white text-text-secondary border border-gray-200')}>
                  {filter}
                </button>)}
          </div>

          <div className="space-y-3">
            {clients.map(client => <Card key={client.id} className="active:scale-[0.98] transition-transform cursor-pointer" onClick={() => navigate(`/clients/${client.id}`)}>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-full bg-gray-100 flex items-center justify-center">
                      <User className="h-5 w-5 text-gray-500" />
                    </div>
                    <div>
                      <h3 className="font-bold text-secondary">
                        {client.name}
                      </h3>
                      <div className="flex items-center gap-2 mt-0.5">
                        <span className={cn('text-xs font-bold px-2 py-0.5 rounded-full', client.status === 'active' && 'bg-green-100 text-green-700', client.status === 'late' && 'bg-red-100 text-red-700', client.status === 'completed' && 'bg-gray-100 text-gray-600')}>
                          {client.status === 'active' && 'Activo'}
                          {client.status === 'late' && 'Atrasado'}
                          {client.status === 'completed' && 'Finalizado'}
                        </span>
                        <span className="text-xs text-text-secondary">
                          {client.credit}
                        </span>
                      </div>
                    </div>
                  </div>
                  <ChevronRight className="h-5 w-5 text-gray-400" />
                </div>
              </Card>)}
          </div>
        </div>
      </main>

      <BottomNav />
    </div>;
}