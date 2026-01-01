import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../../components/ui/Button';
import { ChevronLeft, Video, RefreshCw, Play, Check } from 'lucide-react';
export function RecordVideo() {
  const navigate = useNavigate();
  const [isRecorded, setIsRecorded] = useState(false);
  return <div className="min-h-screen bg-black flex flex-col">
      {/* Header */}
      <div className="absolute top-0 left-0 right-0 p-4 z-10 flex items-center text-white bg-gradient-to-b from-black/50 to-transparent pt-safe">
        <button onClick={() => navigate(-1)} className="p-2">
          <ChevronLeft className="h-6 w-6" />
        </button>
        <div className="flex-1 ml-2">
          <span className="font-medium">Video de Evidencia</span>
          <span className="ml-2 text-white/60 text-sm">7/9</span>
        </div>
      </div>

      {/* Camera View */}
      <div className="flex-1 relative bg-gray-900 flex items-center justify-center">
        {isRecorded ? <div className="relative w-full h-full flex items-center justify-center">
            <div className="absolute inset-0 bg-black/40 z-10" />
            <div className="z-20 text-center">
              <div className="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4 backdrop-blur-sm">
                <Play className="h-8 w-8 text-white ml-1" />
              </div>
              <p className="text-white font-medium">Video guardado (0:15)</p>
            </div>
          </div> : <div className="text-center px-8">
            <div className="w-20 h-20 bg-white/10 rounded-full flex items-center justify-center mx-auto mb-4">
              <span className="text-4xl">😊</span>
            </div>
            <p className="text-white/60">Vista previa de cámara</p>
          </div>}
      </div>

      {/* Instructions & Controls */}
      <div className="bg-surface rounded-t-3xl p-6 pb-8">
        {!isRecorded ? <>
            <div className="mb-8 text-center">
              <p className="text-sm font-bold text-text-secondary uppercase mb-2">
                Instrucciones para el cliente
              </p>
              <p className="text-lg font-medium text-secondary">
                "Diga su nombre completo y confirme que acepta el crédito por{' '}
                <span className="text-primary font-bold">$3,000</span>"
              </p>
            </div>

            <div className="flex items-center justify-around">
              <button className="p-4 rounded-full bg-gray-100 text-secondary">
                <RefreshCw className="h-6 w-6" />
              </button>

              <button onClick={() => setIsRecorded(true)} className="h-20 w-20 rounded-full border-4 border-error flex items-center justify-center p-1">
                <div className="w-full h-full bg-error rounded-full" />
              </button>

              <div className="w-14" />
            </div>
          </> : <div className="space-y-4">
            <div className="flex items-center gap-3 text-success bg-success/10 p-4 rounded-xl mb-4">
              <Check className="h-5 w-5" />
              <span className="font-medium">Video guardado correctamente</span>
            </div>

            <Button fullWidth size="lg" onClick={() => navigate('/create-credit/summary')}>
              Continuar
            </Button>

            <Button variant="ghost" fullWidth onClick={() => setIsRecorded(false)}>
              Grabar de nuevo
            </Button>
          </div>}
      </div>
    </div>;
}