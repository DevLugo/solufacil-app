import React, { forwardRef } from 'react';
import { cn } from '../../lib/utils';
import { Loader2 } from 'lucide-react';
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'text';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
  fullWidth?: boolean;
}
export const Button = forwardRef<HTMLButtonElement, ButtonProps>(({
  className,
  variant = 'primary',
  size = 'md',
  isLoading,
  fullWidth,
  children,
  disabled,
  ...props
}, ref) => {
  const baseStyles = 'inline-flex items-center justify-center rounded-xl font-semibold transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none active:scale-[0.98]';
  const variants = {
    primary: 'bg-primary text-white hover:bg-primary-dark shadow-sm',
    secondary: 'bg-secondary text-white hover:bg-secondary-light shadow-sm',
    outline: 'border-2 border-secondary text-secondary hover:bg-secondary/5',
    ghost: 'hover:bg-gray-100 text-text-primary',
    text: 'text-primary hover:text-primary-dark underline-offset-4 hover:underline p-0 h-auto'
  };
  const sizes = {
    sm: 'h-9 px-4 text-sm',
    md: 'h-12 px-6 text-base',
    lg: 'h-14 px-8 text-lg' // 56px large target
  };
  return <button ref={ref} className={cn(baseStyles, variants[variant], variant !== 'text' && sizes[size], fullWidth && 'w-full', className)} disabled={disabled || isLoading} {...props}>
        {isLoading && <Loader2 className="mr-2 h-5 w-5 animate-spin" />}
        {children}
      </button>;
});
Button.displayName = 'Button';