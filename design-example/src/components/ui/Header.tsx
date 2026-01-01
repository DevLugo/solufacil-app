import React from 'react';
import { MapPin, ChevronDown, User } from 'lucide-react';
import { Button } from './Button';
interface HeaderProps {
  currentRoute?: string;
  onRouteClick?: () => void;
}
export function Header({
  currentRoute = 'Centro',
  onRouteClick
}: HeaderProps) {
  return <header className="sticky top-0 z-40 w-full bg-secondary text-white shadow-md">
      <div className="flex h-16 items-center justify-between px-4 max-w-md mx-auto">
        {/* Logo Area */}
        <div className="flex items-center gap-2">
          <div className="h-8 w-8 rounded bg-primary flex items-center justify-center">
            <span className="font-bold text-white text-lg">S</span>
          </div>
          <span className="font-bold text-lg tracking-tight">Solufacil</span>
        </div>

        {/* Route Selector */}
        <button onClick={onRouteClick} className="flex items-center gap-1.5 bg-secondary-light px-3 py-1.5 rounded-full text-sm font-medium hover:bg-opacity-80 transition-colors active:scale-95">
          <MapPin className="h-3.5 w-3.5 text-primary" />
          <span>{currentRoute}</span>
          <ChevronDown className="h-3.5 w-3.5 text-gray-400" />
        </button>

        {/* Profile */}
        <button className="h-9 w-9 rounded-full bg-secondary-light flex items-center justify-center hover:bg-opacity-80 transition-colors">
          <User className="h-5 w-5 text-white" />
        </button>
      </div>
    </header>;
}