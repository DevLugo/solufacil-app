import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Camera, Image, X, Zap } from 'lucide-react';
export function ScanINE() {
  const navigate = useNavigate();
  return <div className="min-h-screen bg-black flex flex-col relative">
      {/* Camera Header */}
      <div className="absolute top-0 left-0 right-0 p-4 z-10 flex justify-between items-center text-white bg-gradient-to-b from-black/50 to-transparent pt-safe">
        <button onClick={() => navigate(-1)} className="p-2">
          <X className="h-6 w-6" />
        </button>
        <span className="font-medium">Escanear Credencial</span>
        <button className="p-2">
          <Zap className="h-6 w-6" />
        </button>
      </div>

      {/* Camera Viewport Placeholder */}
      <div className="flex-1 relative flex items-center justify-center bg-gray-900">
        <div className="w-full max-w-sm aspect-[1.58/1] border-2 border-white/50 rounded-xl relative mx-4">
          <div className="absolute top-0 left-0 w-8 h-8 border-t-4 border-l-4 border-primary -mt-1 -ml-1 rounded-tl-lg" />
          <div className="absolute top-0 right-0 w-8 h-8 border-t-4 border-r-4 border-primary -mt-1 -mr-1 rounded-tr-lg" />
          <div className="absolute bottom-0 left-0 w-8 h-8 border-b-4 border-l-4 border-primary -mb-1 -ml-1 rounded-bl-lg" />
          <div className="absolute bottom-0 right-0 w-8 h-8 border-b-4 border-r-4 border-primary -mb-1 -mr-1 rounded-br-lg" />

          <div className="absolute inset-0 flex items-center justify-center">
            <p className="text-white/70 text-sm font-medium bg-black/50 px-3 py-1 rounded-full">
              Alinea la INE aquí
            </p>
          </div>
        </div>
      </div>

      {/* Controls */}
      <div className="bg-black p-6 pb-12 flex items-center justify-around">
        <button className="p-4 rounded-full bg-white/10 text-white">
          <Image className="h-6 w-6" />
        </button>
        <button onClick={() => navigate('/create-credit/confirm-data')} className="h-20 w-20 rounded-full border-4 border-white flex items-center justify-center p-1">
          <div className="w-full h-full bg-white rounded-full active:scale-90 transition-transform" />
        </button>
        <div className="w-14" /> {/* Spacer for balance */}
      </div>
    </div>;
}