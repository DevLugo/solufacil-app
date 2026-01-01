import React from 'react';
import { Home, DollarSign, Plus, Users, BarChart2 } from 'lucide-react';
import { cn } from '../../lib/utils';
import { useNavigate, useLocation } from 'react-router-dom';
export function BottomNav() {
  const navigate = useNavigate();
  const location = useLocation();
  const items = [{
    icon: Home,
    label: 'Inicio',
    path: '/dashboard'
  }, {
    icon: DollarSign,
    label: 'Cobrar',
    path: '/collect'
  }, {
    icon: Plus,
    label: 'Nuevo',
    path: '/new',
    isFab: true
  }, {
    icon: Users,
    label: 'Clientes',
    path: '/clients'
  }, {
    icon: BarChart2,
    label: 'Reportes',
    path: '/reports'
  }];
  return <nav className="fixed bottom-0 left-0 right-0 z-50 bg-white border-t border-gray-200 pb-safe">
      <div className="flex h-[72px] items-center justify-around max-w-md mx-auto px-2">
        {items.map(item => {
        const isActive = location.pathname === item.path;
        if (item.isFab) {
          return <button key={item.path} onClick={() => navigate(item.path)} className="relative -top-6 flex h-14 w-14 items-center justify-center rounded-full bg-primary text-white shadow-lg shadow-primary/30 transition-transform active:scale-95">
                <item.icon className="h-7 w-7" />
              </button>;
        }
        return <button key={item.path} onClick={() => navigate(item.path)} className={cn('flex flex-col items-center justify-center gap-1 w-16 py-1 transition-colors', isActive ? 'text-primary' : 'text-text-secondary hover:text-text-primary')}>
              <item.icon className={cn('h-6 w-6', isActive && 'fill-current')} />
              <span className="text-[10px] font-medium">{item.label}</span>
            </button>;
      })}
      </div>
    </nav>;
}