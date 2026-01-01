import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Input } from '../../components/ui/Input';
import { Button } from '../../components/ui/Button';
import { ChevronLeft, RefreshCw } from 'lucide-react';
export function ConfirmData() {
  const navigate = useNavigate();
  return <div className="min-h-screen bg-surface flex flex-col">
      <div className="bg-white px-4 py-4 border-b border-gray-100">
        <div className="flex items-center mb-4 max-w-md mx-auto">
          <button onClick={() => navigate(-1)} className="p-2 -ml-2">
            <ChevronLeft className="h-6 w-6 text-secondary" />
          </button>
          <div className="flex-1 ml-2">
            <h1 className="font-bold text-lg text-secondary">
              Confirmar Datos
            </h1>
            <div className="flex gap-1 mt-1">
              <div className="h-1 flex-1 bg-primary rounded-full" />
              <div className="h-1 flex-1 bg-primary rounded-full" />
              {[...Array(7)].map((_, i) => <div key={i} className="h-1 flex-1 bg-gray-200 rounded-full" />)}
            </div>
          </div>
          <span className="ml-4 text-sm font-medium text-text-secondary">
            2/9
          </span>
        </div>
      </div>

      <main className="flex-1 px-4 py-6 max-w-md mx-auto w-full space-y-6">
        <div className="bg-blue-50 p-4 rounded-xl text-sm text-blue-800 border border-blue-100">
          Por favor verifica que los datos extraídos sean correctos.
        </div>

        <div className="space-y-4">
          <Input label="Nombre Completo" defaultValue="JUAN PÉREZ GARCÍA" className="font-bold text-secondary" />

          <Input label="CURP" defaultValue="PEGJ850314HDFRRN09" className="uppercase" />

          <Input label="Fecha de Nacimiento" defaultValue="14/03/1985" type="date" />
        </div>

        <div className="pt-8 space-y-3">
          <Button fullWidth size="lg" onClick={() => navigate('/create-credit/personal-info')}>
            Confirmar y Continuar
          </Button>

          <Button variant="outline" fullWidth onClick={() => navigate(-1)}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Escanear Nuevamente
          </Button>
        </div>
      </main>
    </div>;
}