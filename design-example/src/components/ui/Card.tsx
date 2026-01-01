import React, { forwardRef } from 'react';
import { cn } from '../../lib/utils';
interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  noPadding?: boolean;
}
export const Card = forwardRef<HTMLDivElement, CardProps>(({
  className,
  noPadding,
  children,
  ...props
}, ref) => {
  return <div ref={ref} className={cn('rounded-xl border border-gray-100 bg-white text-text-primary shadow-card', !noPadding && 'p-5', className)} {...props}>
        {children}
      </div>;
});
Card.displayName = 'Card';