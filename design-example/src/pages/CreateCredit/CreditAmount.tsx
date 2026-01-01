import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../../components/ui/Button';
import { Card } from '../../components/ui/Card';
import { ChevronLeft, Delete } from 'lucide-react';
export function CreditAmount() {
  const navigate = useNavigate();
  const [amount, setAmount] = useState('3000');
  const handleNumberClick = (num: string) => {
    if (amount === '0') setAmount(num);else setAmount(prev => prev + num);
  };
  const handleBackspace = () => {
    setAmount(prev => prev.length > 1 ? prev.slice(0, -1) : '0');
  };
  const handleQuickAdd = (val: number) => {
    setAmount(prev => (parseInt(prev) + val).toString());
  };
  const total = parseInt(amount) * 1.2; // 20% interest
  const weekly = total / 10; // 10 weeks
  return <div className="min-h-screen bg-surface flex flex-col">
      <div className="bg-white px-4 py-4 border-b border-gray-100">
        <div className="flex items-center mb-4 max-w-md mx-auto">
          <button onClick={() => navigate(-1)} className="p-2 -ml-2">
            <ChevronLeft className="h-6 w-6 text-secondary" />
          </button>
          <div className="flex-1 ml-2">
            <h1 className="font-bold text-lg text-secondary">
              Monto del Crédito
            </h1>
            <div className="flex gap-1 mt-1">
              {[...Array(5)].map((_, i) => <div key={i} className="h-1 flex-1 bg-primary rounded-full" />)}
              {[...Array(4)].map((_, i) => <div key={i} className="h-1 flex-1 bg-gray-200 rounded-full" />)}
            </div>
          </div>
          <span className="ml-4 text-sm font-medium text-text-secondary">
            5/9
          </span>
        </div>
      </div>

      <main className="flex-1 px-4 py-6 max-w-md mx-auto w-full flex flex-col">
        <div className="text-center mb-8">
          <p className="text-sm text-text-secondary mb-2">Monto Solicitado</p>
          <div className="text-5xl font-bold text-secondary flex justify-center items-center">
            <span className="text-2xl text-gray-400 mr-1">$</span>
            {parseInt(amount).toLocaleString()}
          </div>
        </div>

        <Card className="mb-6 bg-gray-50 border-none">
          <div className="space-y-3 text-sm">
            <div className="flex justify-between">
              <span className="text-text-secondary">Ganancia (20%):</span>
              <span className="font-bold text-success">
                +${(parseInt(amount) * 0.2).toLocaleString()}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-text-secondary">Total a pagar:</span>
              <span className="font-bold text-secondary">
                ${total.toLocaleString()}
              </span>
            </div>
            <div className="h-px bg-gray-200 my-2" />
            <div className="flex justify-between items-center">
              <span className="text-text-secondary font-medium">
                Pago semanal:
              </span>
              <span className="font-bold text-primary text-xl">
                ${weekly.toLocaleString()}
              </span>
            </div>
          </div>
        </Card>

        {/* Numpad */}
        <div className="flex-1 grid grid-cols-4 gap-3 mb-6">
          {[1, 2, 3].map(n => <button key={n} onClick={() => handleNumberClick(n.toString())} className="text-2xl font-semibold bg-white rounded-xl shadow-sm h-14 active:bg-gray-50">
              {n}
            </button>)}
          <button onClick={() => handleBackspace()} className="flex items-center justify-center text-error bg-white rounded-xl shadow-sm h-14 active:bg-gray-50">
            <Delete className="h-6 w-6" />
          </button>

          {[4, 5, 6].map(n => <button key={n} onClick={() => handleNumberClick(n.toString())} className="text-2xl font-semibold bg-white rounded-xl shadow-sm h-14 active:bg-gray-50">
              {n}
            </button>)}
          <button onClick={() => handleQuickAdd(500)} className="text-sm font-bold text-primary bg-primary/5 rounded-xl h-14 active:bg-primary/10">
            +500
          </button>

          {[7, 8, 9].map(n => <button key={n} onClick={() => handleNumberClick(n.toString())} className="text-2xl font-semibold bg-white rounded-xl shadow-sm h-14 active:bg-gray-50">
              {n}
            </button>)}
          <button onClick={() => handleQuickAdd(1000)} className="text-sm font-bold text-primary bg-primary/5 rounded-xl h-14 active:bg-primary/10">
            +1k
          </button>

          <button className="col-span-1" />
          <button onClick={() => handleNumberClick('0')} className="text-2xl font-semibold bg-white rounded-xl shadow-sm h-14 active:bg-gray-50">
            0
          </button>
          <button onClick={() => setAmount('0')} className="text-sm font-medium text-text-secondary">
            Limpiar
          </button>
        </div>

        <Button fullWidth size="lg" onClick={() => navigate('/create-credit/guarantors')}>
          Siguiente
        </Button>
      </main>
    </div>;
}