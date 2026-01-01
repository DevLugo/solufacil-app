import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../components/ui/Button';
import { Mail, Lock, Eye, EyeOff } from 'lucide-react';
export function Login() {
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });
  const [error, setError] = useState('');
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);
    setTimeout(() => {
      if (formData.email && formData.password) {
        navigate('/dashboard');
      } else {
        setError('Por favor ingresa tus credenciales');
        setIsLoading(false);
      }
    }, 1500);
  };
  return <div className="min-h-screen bg-white flex flex-col max-w-md mx-auto relative overflow-hidden">
      {/* Hero Image Section with Organic Shape */}
      <div className="relative h-[45vh] overflow-hidden">
        {/* Background Image Placeholder */}
        <div className="absolute inset-0 bg-gradient-to-br from-primary/20 to-secondary/20">
          {/* Placeholder for hero image - in production, use actual photo */}
          <div className="w-full h-full flex items-center justify-center">
            <div className="text-center">
              <div className="w-32 h-32 bg-primary/30 rounded-full mx-auto mb-4 flex items-center justify-center">
                <span className="text-6xl">👋</span>
              </div>
            </div>
          </div>
        </div>

        {/* Organic Curved Shape Overlay */}
        <div className="absolute bottom-0 left-0 right-0">
          <svg viewBox="0 0 1440 120" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full">
            <path d="M0,64 C240,100 480,100 720,80 C960,60 1200,40 1440,64 L1440,120 L0,120 Z" fill="white" />
          </svg>
        </div>
      </div>

      {/* Form Section */}
      <div className="flex-1 px-8 -mt-4 pb-12">
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-secondary mb-2">
            Bienvenido,
          </h1>
          <p className="text-text-secondary text-lg">
            Inicia sesión para continuar
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-8">
          {/* Email Input - Underline Style */}
          <div className="space-y-2">
            <label className="text-sm text-text-secondary font-medium">
              Correo electrónico
            </label>
            <div className="relative">
              <input type="email" value={formData.email} onChange={e => setFormData({
              ...formData,
              email: e.target.value
            })} className="w-full bg-transparent border-0 border-b-2 border-gray-200 focus:border-primary outline-none py-3 text-base text-secondary transition-colors" placeholder="agente@solufacil.com" />
            </div>
          </div>

          {/* Password Input - Underline Style */}
          <div className="space-y-2">
            <label className="text-sm text-text-secondary font-medium">
              Contraseña
            </label>
            <div className="relative">
              <input type={showPassword ? 'text' : 'password'} value={formData.password} onChange={e => setFormData({
              ...formData,
              password: e.target.value
            })} className="w-full bg-transparent border-0 border-b-2 border-gray-200 focus:border-primary outline-none py-3 text-base text-secondary pr-10 transition-colors" placeholder="••••••••" />
              <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-0 top-3 text-text-secondary hover:text-primary transition-colors">
                {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
              </button>
            </div>
          </div>

          <div className="flex justify-start">
            <button type="button" className="text-text-secondary text-sm hover:text-primary transition-colors">
              ¿Olvidaste tu contraseña?
            </button>
          </div>

          {error && <div className="p-4 bg-red-50 text-error text-sm rounded-xl">
              {error}
            </div>}

          <Button type="submit" fullWidth size="lg" isLoading={isLoading} className="mt-8 shadow-lg shadow-primary/20 text-lg">
            Iniciar Sesión
          </Button>
        </form>

        <p className="mt-8 text-center text-text-secondary">
          ¿No tienes cuenta?{' '}
          <button className="text-primary font-semibold hover:underline">
            Regístrate
          </button>
        </p>
      </div>
    </div>;
}