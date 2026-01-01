import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../../components/ui/Button';
import { Card } from '../../components/ui/Card';
import { ChevronLeft, UserPlus, Camera, Edit2 } from 'lucide-react';
export function AddGuarantors() {
  const navigate = useNavigate();
  return <div className="min-h-screen bg-surface flex flex-col">
      <div className="bg-white px-4 py-4 border-b border-gray-100">
        <div className="flex items-center mb-4 max-w-md mx-auto">
          <button onClick={() => navigate(-1)} className="p-2 -ml-2">
            <ChevronLeft className="h-6 w-6 text-secondary" />
          </button>
          <div className="flex-1 ml-2">
            <h1 className="font-bold text-lg text-secondary">Avalistas</h1>
            <div className="flex gap-1 mt-1">
              {[...Array(6)].map((_, i) => <div key={i} className="h-1 flex-1 bg-primary rounded-full" />)}
              {[...Array(3)].map((_, i) => <div key={i} className="h-1 flex-1 bg-gray-200 rounded-full" />)}
            </div>
          </div>
          <span className="ml-4 text-sm font-medium text-text-secondary">
            6/9
          </span>
        </div>
      </div>

      <main className="flex-1 px-4 py-6 max-w-md mx-auto w-full space-y-6">
        <Card className="relative">
          <div className="absolute top-4 right-4">
            <button className="text-primary text-sm font-medium flex items-center gap-1">
              <Edit2 className="h-3 w-3" /> Editar
            </button>
          </div>
          <h3 className="text-sm font-bold text-text-secondary mb-1">
            Avalista 1
          </h3>
          <p className="font-bold text-secondary text-lg">
            María López González
          </p>
          <p className="text-text-secondary">Tel: 55 2345 6789</p>
        </Card>

        <div className="space-y-3">
          <Button variant="outline" fullWidth className="h-14 justify-start px-4 border-dashed border-2">
            <UserPlus className="h-5 w-5 mr-3 text-primary" />
            Agregar Avalista Manualmente
          </Button>

          <Button variant="outline" fullWidth className="h-14 justify-start px-4">
            <Camera className="h-5 w-5 mr-3 text-secondary" />
            Escanear INE de Avalista
          </Button>
        </div>

        <div className="pt-8 flex gap-3">
          <Button variant="ghost" className="flex-1" onClick={() => navigate('/create-credit/video')}>
            Omitir
          </Button>
          <Button className="flex-[2]" onClick={() => navigate('/create-credit/video')}>
            Siguiente
          </Button>
        </div>
      </main>
    </div>;
}