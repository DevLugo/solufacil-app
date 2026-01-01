import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../../components/ui/Button';
import { Card } from '../../components/ui/Card';
import { ChevronLeft, Phone, MapPin, Edit2, ChevronDown, Plus, FileText } from 'lucide-react';
export function ClientProfile() {
  const navigate = useNavigate();
  return <div className="min-h-screen bg-surface pb-24">
      {/* Header */}
      <div className="bg-white px-4 py-4 border-b border-gray-100 sticky top-0 z-10">
        <div className="flex items-center justify-between max-w-md mx-auto">
          <div className="flex items-center">
            <button onClick={() => navigate(-1)} className="p-2 -ml-2">
              <ChevronLeft className="h-6 w-6 text-secondary" />
            </button>
            <h1 className="font-bold text-lg ml-2 text-secondary">
              Perfil del Cliente
            </h1>
          </div>
          <button className="text-primary text-sm font-medium flex items-center gap-1">
            <Edit2 className="h-4 w-4" /> Editar
          </button>
        </div>
      </div>

      <main className="px-4 py-6 space-y-6 max-w-md mx-auto">
        {/* Client Info */}
        <div className="text-center">
          <div className="w-20 h-20 bg-gray-200 rounded-full mx-auto mb-3 flex items-center justify-center text-2xl font-bold text-gray-500">
            CR
          </div>
          <h2 className="text-2xl font-bold text-secondary">
            Carlos Ruiz Gómez
          </h2>
          <p className="text-text-secondary text-sm mt-1">
            Cliente desde Ene 2023
          </p>
        </div>

        <Card className="space-y-4">
          <div className="flex items-center gap-3">
            <Phone className="h-5 w-5 text-primary" />
            <div>
              <p className="font-medium text-secondary">55 1234 5678</p>
              <p className="text-sm text-text-secondary">Principal</p>
            </div>
          </div>
          <div className="h-px bg-gray-100" />
          <div className="flex items-center gap-3">
            <MapPin className="h-5 w-5 text-primary" />
            <div>
              <p className="font-medium text-secondary">Calle Morelos 123</p>
              <p className="text-sm text-text-secondary">
                San Miguel, CP 00000
              </p>
            </div>
          </div>
        </Card>

        <div className="grid grid-cols-2 gap-4">
          <Card className="text-center p-4">
            <p className="text-3xl font-bold text-secondary">4</p>
            <p className="text-xs text-text-secondary uppercase mt-1">
              Créditos Totales
            </p>
          </Card>
          <Card className="text-center p-4">
            <p className="text-3xl font-bold text-success">3</p>
            <p className="text-xs text-text-secondary uppercase mt-1">
              Finalizados
            </p>
          </Card>
        </div>

        <div>
          <h3 className="font-bold text-secondary mb-3">
            Historial de Créditos
          </h3>
          <div className="space-y-3">
            {/* Active Credit */}
            <Card className="border-l-4 border-l-success cursor-pointer" onClick={() => navigate('/clients/1/credit/12345')}>
              <div className="flex justify-between items-start mb-2">
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="w-2 h-2 rounded-full bg-success animate-pulse" />
                    <span className="text-xs font-bold text-success uppercase">
                      Activo
                    </span>
                  </div>
                  <h4 className="font-bold text-secondary">Crédito #12345</h4>
                </div>
                <span className="font-bold text-secondary">$3,600</span>
              </div>

              <div className="space-y-2 text-sm">
                <div className="flex justify-between text-text-secondary">
                  <span>Progreso:</span>
                  <span className="font-medium text-secondary">50%</span>
                </div>
                <div className="w-full bg-gray-100 h-1.5 rounded-full overflow-hidden">
                  <div className="bg-success h-full w-1/2" />
                </div>
                <div className="flex justify-between items-center pt-2">
                  <span className="text-xs text-text-secondary">
                    Próximo pago: 15 Ene
                  </span>
                  <ChevronDown className="h-4 w-4 text-gray-400" />
                </div>
              </div>
            </Card>

            {/* Completed Credit */}
            <Card className="border-l-4 border-l-gray-300 opacity-75">
              <div className="flex justify-between items-start mb-2">
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-xs font-bold text-gray-500 uppercase">
                      Finalizado
                    </span>
                  </div>
                  <h4 className="font-bold text-secondary">Crédito #12200</h4>
                </div>
                <span className="font-bold text-secondary">$2,400</span>
              </div>
              <p className="text-xs text-text-secondary">
                05 Jun - 15 Sep 2024
              </p>
            </Card>
          </div>
        </div>

        <div className="flex gap-3 pt-4">
          <Button className="flex-1" onClick={() => navigate('/create-credit')}>
            <Plus className="h-5 w-5 mr-2" />
            Nuevo Crédito
          </Button>
          <Button variant="outline" className="flex-1">
            <FileText className="h-5 w-5 mr-2" />
            Documentos
          </Button>
        </div>
      </main>
    </div>;
}