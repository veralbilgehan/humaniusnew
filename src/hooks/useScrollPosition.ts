import { useEffect, useRef } from 'react';

export const useScrollPosition = (key: string, enabled: boolean = true) => {
  const scrollPositionRef = useRef<number>(0);

  useEffect(() => {
    if (!enabled) return;

    const savedPosition = sessionStorage.getItem(`scroll-${key}`);
    if (savedPosition) {
      window.scrollTo(0, parseInt(savedPosition, 10));
    }

    const handleScroll = () => {
      scrollPositionRef.current = window.scrollY;
      sessionStorage.setItem(`scroll-${key}`, window.scrollY.toString());
    };

    window.addEventListener('scroll', handleScroll, { passive: true });

    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, [key, enabled]);

  return scrollPositionRef;
};
