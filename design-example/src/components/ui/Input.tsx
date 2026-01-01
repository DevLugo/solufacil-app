import React, { forwardRef } from 'react';
import { cn } from '../../lib/utils';
import { AlertCircle } from 'lucide-react';
interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  containerClassName?: string;
}
export const Input = forwardRef<HTMLInputElement, InputProps>(({
  className,
  label,
  error,
  leftIcon,
  rightIcon,
  containerClassName,
  ...props
}, ref) => {
  return <div className={cn('w-full space-y-2', containerClassName)}>
        {label && <label className="text-sm font-semibold text-text-primary ml-1">
            {label}
          </label>}
        <div className="relative">
          {leftIcon && <div className="absolute left-4 top-1/2 -translate-y-1/2 text-text-secondary">
              {leftIcon}
            </div>}
          <input ref={ref} className={cn('flex h-14 w-full rounded-xl border border-gray-200 bg-white px-4 py-2 text-base ring-offset-white file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-text-disabled focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:border-transparent disabled:cursor-not-allowed disabled:opacity-50 transition-all', leftIcon && 'pl-12', rightIcon && 'pr-12', error && 'border-error focus-visible:ring-error', className)} {...props} />
          {rightIcon && <div className="absolute right-4 top-1/2 -translate-y-1/2 text-text-secondary">
              {rightIcon}
            </div>}
        </div>
        {error && <div className="flex items-center gap-1 text-sm text-error font-medium ml-1 animate-in slide-in-from-top-1">
            <AlertCircle className="h-4 w-4" />
            <span>{error}</span>
          </div>}
      </div>;
});
Input.displayName = 'Input';