import React, { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { ChevronLeft, Check, Delete } from 'lucide-react';
import { cn } from '../../lib/utils';
export function RegisterPayment() {
  const navigate = useNavigate();
  const {
    clientId
  } = useParams();
  const [amount, setAmount] = useState('360');
  const [method, setMethod] = useState<'cash' | 'transfer'>('cash');
  const [showSuccess, setShowSuccess] = useState(false);
  const handleNumberClick = (num: string) => {
    if (amount === '0') setAmount(num);else setAmount(prev => prev + num);
  };
  const handleClear = () => {
    setAmount('0');
  };
  const handleBackspace = () => {
    setAmount(prev => prev.length > 1 ? prev.slice(0, -1) : '0');
  };
  const handleConfirm = () => {
    setShowSuccess(true);
    setTimeout(() => {
      navigate(-1);
    }, 2000);
  };
  if (showSuccess) {
    return <div className="min-h-screen bg-success flex items-center justify-center p-6">
        <div className="bg-white rounded-3xl p-8 w-full max-w-sm text-center space-y-6 animate-in zoom-in duration-300">
          <div className="w-20 h-20 bg-success/10 rounded-full flex items-center justify-center mx-auto">
            <Check className="w-10 h-10 text-success" />
          </div>
          <div>
            <h2 className="text-2xl font-bold text-secondary mb-2">
              ¡Pago Registrado!
            </h2>
            <p className="text-text-secondary">
              Se han registrado{' '}
              <span className="font-bold text-secondary">${amount}</span>
              <br />a la cuenta de Carlos Ruiz
            </p>
          </div>
          <div className="bg-gray-50 rounded-xl p-4 text-sm">
            <div className="flex justify-between mb-2">
              <span className="text-text-secondary">Restante:</span>
              <span className="font-bold text-secondary">$1,080</span>
            </div>
            <div className="flex justify-between">
              <span className="text-text-secondary">Próximo pago:</span>
              <span className="font-medium">22 Ene</span>
            </div>
          </div>
        </div>
      </div>;
  }
  return <div className="min-h-screen bg-surface flex flex-col">
      {/* Header */}
      <div className="bg-secondary text-white p-4 pb-8 rounded-b-3xl shadow-lg">
        <div className="flex items-center mb-6">
          <button onClick={() => navigate(-1)} className="p-2 -ml-2">
            <ChevronLeft className="h-6 w-6" />
          </button>
          <h1 className="font-bold text-lg ml-2">Carlos Ruiz</h1>
        </div>

        <div className="flex justify-between items-end mb-2">
          <div>
            <p className="text-secondary-light text-sm mb-1">Total Adeudado</p>
            <p className="text-3xl font-bold">$2,160</p>
          </div>
          <div className="text-right">
            <p className="text-secondary-light text-sm mb-1">Pago Semanal</p>
            <p className="text-xl font-bold">$360</p>
          </div>
        </div>

        <div className="w-full bg-secondary-light/30 h-2 rounded-full overflow-hidden mt-4">
          <div className="bg-primary h-full w-1/2 rounded-full" />
        </div>
        <p className="text-xs text-secondary-light mt-2 text-center">
          3 de 6 pagos completados (50%)
        </p>
      </div>

      <main className="flex-1 px-4 -mt-6 max-w-md mx-auto w-full flex flex-col">
        <Card className="flex-1 flex flex-col shadow-xl border-none">
          {/* Amount Display */}
          <div className="text-center py-6 border-b border-gray-100">
            <p className="text-sm text-text-secondary mb-2">Monto a Cobrar</p>
            <div className="text-5xl font-bold text-secondary flex justify-center items-center">
              <span className="text-2xl text-gray-400 mr-1">$</span>
              {amount}
            </div>
          </div>

          {/* Payment Method */}
          <div className="p-4 flex gap-3">
            <button onClick={() => setMethod('cash')} className={cn('flex-1 py-3 px-4 rounded-xl text-sm font-bold border-2 transition-all', method === 'cash' ? 'border-primary bg-primary/5 text-primary' : 'border-gray-100 text-text-secondary')}>
              💵 Efectivo
            </button>
            <button onClick={() => setMethod('transfer')} className={cn('flex-1 py-3 px-4 rounded-xl text-sm font-bold border-2 transition-all', method === 'transfer' ? 'border-primary bg-primary/5 text-primary' : 'border-gray-100 text-text-secondary')}>
              📱 Transferencia
            </button>
          </div>

          {/* Numpad */}
          <div className="flex-1 grid grid-cols-3 gap-4 p-4">
            {[1, 2, 3, 4, 5, 6, 7, 8, 9].map(num => <button key={num} onClick={() => handleNumberClick(num.toString())} className="text-2xl font-semibold text-secondary py-2 rounded-xl hover:bg-gray-50 active:bg-gray-100 transition-colors">
                {num}
              </button>)}
            <button onClick={() => handleNumberClick('0')} className="col-start-2 text-2xl font-semibold text-secondary py-2 rounded-xl hover:bg-gray-50 active:bg-gray-100 transition-colors">
              0
            </button>
            <button onClick={handleBackspace} className="flex items-center justify-center text-text-secondary hover:text-error transition-colors">
              <Delete className="h-6 w-6" />
            </button>
          </div>

          <div className="p-4 pt-0">
            <Button size="lg" fullWidth onClick={handleConfirm} className="text-lg shadow-lg shadow-primary/20">
              CONFIRMAR PAGO
            </Button>
          </div>
        </Card>
      </main>
    </div>;
}