import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../components/ui/Button';
import { ChevronRight, Check, Shield, Map, Zap, BarChart, ArrowRight } from 'lucide-react';
import { cn } from '../lib/utils';
const slides = [{
  id: 1,
  title: 'Bienvenido a Solufacil',
  description: 'La forma más rápida y sencilla de gestionar tus créditos en campo.',
  icon: <div className="w-20 h-20 rounded-full border-4 border-white flex items-center justify-center">
        <span className="text-5xl">👋</span>
      </div>,
  gradient: 'from-orange-500/90 to-orange-600/90'
}, {
  id: 2,
  title: 'Créditos Rápidos',
  description: 'Escanea la credencial de elector y registra clientes automáticamente en minutos.',
  icon: <div className="w-20 h-20 rounded-full border-4 border-white flex items-center justify-center bg-white/10 backdrop-blur-sm">
        <Zap className="w-12 h-12 text-white" />
      </div>,
  gradient: 'from-blue-600/90 to-blue-700/90'
}, {
  id: 3,
  title: 'Cobranza Semanal',
  description: 'Organiza tu ruta y cobra eficientemente semana tras semana por localidad.',
  icon: <div className="w-20 h-20 rounded-full border-4 border-white flex items-center justify-center bg-white/10 backdrop-blur-sm">
        <Map className="w-12 h-12 text-white" />
      </div>,
  gradient: 'from-green-600/90 to-green-700/90'
}, {
  id: 4,
  title: 'Todo bajo control',
  description: 'Consulta historial de pagos, clientes y el estado de tu cartera en tiempo real.',
  icon: <div className="w-20 h-20 rounded-full border-4 border-white flex items-center justify-center bg-white/10 backdrop-blur-sm">
        <BarChart className="w-12 h-12 text-white" />
      </div>,
  gradient: 'from-purple-600/90 to-purple-700/90'
}, {
  id: 5,
  title: 'Seguro y confiable',
  description: 'Tus datos están protegidos con cifrado de nivel bancario.',
  icon: <div className="w-20 h-20 rounded-full border-4 border-white flex items-center justify-center bg-white/10 backdrop-blur-sm">
        <Shield className="w-12 h-12 text-white" />
      </div>,
  gradient: 'from-secondary/90 to-secondary-light/90'
}];
export function Onboarding() {
  const [currentSlide, setCurrentSlide] = useState(0);
  const navigate = useNavigate();
  const isLastSlide = currentSlide === slides.length - 1;
  const handleNext = () => {
    if (isLastSlide) {
      navigate('/login');
    } else {
      setCurrentSlide(prev => prev + 1);
    }
  };
  const handleSkip = () => {
    navigate('/login');
  };
  return <div className="min-h-screen relative overflow-hidden max-w-md mx-auto">
      {/* Background Image with Gradient Overlay */}
      <div className="absolute inset-0">
        {/* Placeholder background - in production, use actual field work photos */}
        <div className="absolute inset-0 bg-gradient-to-br from-gray-800 to-gray-900">
          {/* Simulated blurred background pattern */}
          <div className="absolute inset-0 opacity-20">
            <div className="absolute top-1/4 left-1/4 w-64 h-64 bg-primary rounded-full blur-3xl"></div>
            <div className="absolute bottom-1/4 right-1/4 w-64 h-64 bg-blue-500 rounded-full blur-3xl"></div>
          </div>
        </div>

        {/* Gradient Overlay */}
        <div className={cn('absolute inset-0 bg-gradient-to-b transition-all duration-500', slides[currentSlide].gradient)} />
      </div>

      {/* Skip Button */}
      <div className="absolute top-8 right-6 z-10">
        <button onClick={handleSkip} className="text-white/80 hover:text-white font-medium text-sm px-4 py-2 rounded-full bg-white/10 backdrop-blur-sm transition-all">
          Saltar
        </button>
      </div>

      {/* Content */}
      <div className="relative z-10 h-screen flex flex-col justify-end pb-16 px-8">
        {/* Icon and Text - Centered */}
        <div className="flex-1 flex flex-col items-center justify-center text-center space-y-6 -mt-20">
          <div className="animate-in zoom-in duration-500">
            {slides[currentSlide].icon}
          </div>

          <div className="space-y-4 animate-in slide-in-from-bottom-4 duration-500">
            <h1 className="text-4xl font-bold text-white tracking-tight">
              {slides[currentSlide].title}
            </h1>
            <p className="text-lg text-white/90 leading-relaxed max-w-sm mx-auto">
              {slides[currentSlide].description}
            </p>
          </div>
        </div>

        {/* Progress Dots */}
        <div className="flex justify-center gap-2 mb-8">
          {slides.map((_, index) => <button key={index} onClick={() => setCurrentSlide(index)} className={cn('h-2 rounded-full transition-all duration-300', currentSlide === index ? 'w-8 bg-white' : 'w-2 bg-white/40 hover:bg-white/60')} />)}
        </div>

        {/* Navigation Button - Circular */}
        <div className="flex justify-center">
          <button onClick={handleNext} className="w-16 h-16 rounded-full bg-white text-primary flex items-center justify-center shadow-xl hover:scale-105 active:scale-95 transition-transform">
            {isLastSlide ? <Check className="w-7 h-7" /> : <ArrowRight className="w-7 h-7" />}
          </button>
        </div>
      </div>
    </div>;
}