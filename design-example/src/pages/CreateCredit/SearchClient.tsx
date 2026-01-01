import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Input } from '../../components/ui/Input';
import { Button } from '../../components/ui/Button';
import { Card } from '../../components/ui/Card';
import { Search, Camera, ChevronLeft, UserPlus, Clock } from 'lucide-react';
export function SearchClient() {
  const navigate = useNavigate();
  return <div className="min-h-screen bg-surface flex flex-col">
      <div className="bg-white px-4 py-4 border-b border-gray-100">
        <div className="flex items-center mb-4 max-w-md mx-auto">
          <button onClick={() => navigate('/dashboard')} className="p-2 -ml-2">
            <ChevronLeft className="h-6 w-6 text-secondary" />
          </button>
          <div className="flex-1 ml-2">
            <h1 className="font-bold text-lg text-secondary">Nuevo Crédito</h1>
            <div className="flex gap-1 mt-1">
              <div className="h-1 flex-1 bg-primary rounded-full" />
              {[...Array(8)].map((_, i) => <div key={i} className="h-1 flex-1 bg-gray-200 rounded-full" />)}
            </div>
          </div>
          <span className="ml-4 text-sm font-medium text-text-secondary">
            1/9
          </span>
        </div>
      </div>

      <main className="flex-1 px-4 py-6 max-w-md mx-auto w-full space-y-6">
        <div className="space-y-4">
          <Input placeholder="Buscar cliente existente..." leftIcon={<Search className="h-5 w-5" />} className="bg-white" />

          <div className="relative py-2">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-200" />
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-2 bg-surface text-text-secondary">o</span>
            </div>
          </div>

          <Button variant="outline" fullWidth className="h-14 justify-start px-4 text-secondary border-gray-200 bg-white" onClick={() => navigate('/create-credit/personal-info')}>
            <UserPlus className="h-5 w-5 mr-3 text-primary" />
            Registrar Nuevo Cliente
          </Button>

          <Button fullWidth className="h-14 justify-start px-4 shadow-lg shadow-primary/20" onClick={() => navigate('/create-credit/scan-ine')}>
            <Camera className="h-5 w-5 mr-3" />
            Escanear INE (Rápido)
          </Button>
        </div>

        <div className="space-y-3">
          <h3 className="text-sm font-semibold text-text-secondary">
            Recientes
          </h3>
          {[1, 2, 3].map(i => <Card key={i} className="flex items-center gap-3 p-3 active:bg-gray-50">
              <div className="h-10 w-10 rounded-full bg-gray-100 flex items-center justify-center">
                <Clock className="h-5 w-5 text-gray-400" />
              </div>
              <div>
                <p className="font-bold text-secondary">Juan Pérez {i}</p>
                <p className="text-xs text-text-secondary">
                  Registrado hace 2 días
                </p>
              </div>
            </Card>)}
        </div>
      </main>
    </div>;
}