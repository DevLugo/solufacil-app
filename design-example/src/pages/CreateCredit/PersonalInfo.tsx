import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Input } from '../../components/ui/Input';
import { Button } from '../../components/ui/Button';
import { ChevronLeft, Plus, Phone, MapPin } from 'lucide-react';
export function PersonalInfo() {
  const navigate = useNavigate();
  return <div className="min-h-screen bg-surface flex flex-col">
      <div className="bg-white px-4 py-4 border-b border-gray-100">
        <div className="flex items-center mb-4 max-w-md mx-auto">
          <button onClick={() => navigate(-1)} className="p-2 -ml-2">
            <ChevronLeft className="h-6 w-6 text-secondary" />
          </button>
          <div className="flex-1 ml-2">
            <h1 className="font-bold text-lg text-secondary">
              Datos Personales
            </h1>
            <div className="flex gap-1 mt-1">
              {[...Array(3)].map((_, i) => <div key={i} className="h-1 flex-1 bg-primary rounded-full" />)}
              {[...Array(6)].map((_, i) => <div key={i} className="h-1 flex-1 bg-gray-200 rounded-full" />)}
            </div>
          </div>
          <span className="ml-4 text-sm font-medium text-text-secondary">
            3/9
          </span>
        </div>
      </div>

      <main className="flex-1 px-4 py-6 max-w-md mx-auto w-full space-y-6">
        <div className="space-y-4">
          <h3 className="font-bold text-secondary flex items-center gap-2">
            <Phone className="h-5 w-5 text-primary" />
            Teléfonos
          </h3>

          <Input placeholder="55 1234 5678" type="tel" rightIcon={<button className="text-primary">
                <Plus className="h-5 w-5" />
              </button>} />
          <Input placeholder="Teléfono adicional (opcional)" type="tel" />
        </div>

        <div className="space-y-4 pt-4">
          <h3 className="font-bold text-secondary flex items-center gap-2">
            <MapPin className="h-5 w-5 text-primary" />
            Domicilio
          </h3>

          <Input label="Calle y Número" placeholder="Av. Principal #123" />

          <div className="grid grid-cols-2 gap-4">
            <Input label="Código Postal" placeholder="00000" type="number" />
            <div className="space-y-2">
              <label className="text-sm font-semibold text-text-primary ml-1">
                Localidad
              </label>
              <select className="flex h-14 w-full rounded-xl border border-gray-200 bg-white px-4 py-2 text-base focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary">
                <option>San Miguel</option>
                <option>El Carmen</option>
                <option>Guadalupe</option>
              </select>
            </div>
          </div>

          <Input label="Referencias" placeholder="Frente a la tienda..." />
        </div>

        <div className="pt-8">
          <Button fullWidth size="lg" onClick={() => navigate('/create-credit/select-type')}>
            Siguiente
          </Button>
        </div>
      </main>
    </div>;
}