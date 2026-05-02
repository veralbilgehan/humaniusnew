import React, { useState, useRef, useEffect } from 'react';
import { ImagePlus, Move, ZoomIn, ZoomOut, RotateCw, X, Check, RotateCcw } from 'lucide-react';
import { useScrollLock } from '../hooks/useScrollLock';

interface LogoEditorProps {
  logoSrc: string;
  onClose: () => void;
  onSave: (config: LogoConfig) => void;
  onLogoSelect: (logoSrc: string) => void;
  initialConfig?: LogoConfig;
}

export interface LogoConfig {
  width: number;
  height: number;
  x: number;
  y: number;
  rotation: number;
}

const LogoEditor: React.FC<LogoEditorProps> = ({
  logoSrc,
  onClose,
  onSave,
  onLogoSelect,
  initialConfig,
}) => {
  useScrollLock(true);

  const [config, setConfig] = useState<LogoConfig>(
    initialConfig || {
      width: 250,
      height: 100,
      x: 50,
      y: 50,
      rotation: 0
    }
  );

  const [isDragging, setIsDragging] = useState(false);
  const [isResizing, setIsResizing] = useState<string | null>(null);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const containerRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleMouseDown = (e: React.MouseEvent, action: 'drag' | string) => {
    e.preventDefault();
    if (action === 'drag') {
      setIsDragging(true);
      setDragStart({
        x: e.clientX - config.x,
        y: e.clientY - config.y
      });
    } else {
      setIsResizing(action);
      setDragStart({ x: e.clientX, y: e.clientY });
    }
  };

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (isDragging) {
        setConfig(prev => ({
          ...prev,
          x: e.clientX - dragStart.x,
          y: e.clientY - dragStart.y
        }));
      } else if (isResizing) {
        const deltaX = e.clientX - dragStart.x;
        const deltaY = e.clientY - dragStart.y;

        setConfig(prev => {
          let newConfig = { ...prev };

          switch (isResizing) {
            case 'right':
              newConfig.width = Math.max(50, prev.width + deltaX);
              break;
            case 'left':
              newConfig.width = Math.max(50, prev.width - deltaX);
              newConfig.x = prev.x + deltaX;
              break;
            case 'bottom':
              newConfig.height = Math.max(30, prev.height + deltaY);
              break;
            case 'top':
              newConfig.height = Math.max(30, prev.height - deltaY);
              newConfig.y = prev.y + deltaY;
              break;
            case 'top-left':
              newConfig.width = Math.max(50, prev.width - deltaX);
              newConfig.height = Math.max(30, prev.height - deltaY);
              newConfig.x = prev.x + deltaX;
              newConfig.y = prev.y + deltaY;
              break;
            case 'top-right':
              newConfig.width = Math.max(50, prev.width + deltaX);
              newConfig.height = Math.max(30, prev.height - deltaY);
              newConfig.y = prev.y + deltaY;
              break;
            case 'bottom-left':
              newConfig.width = Math.max(50, prev.width - deltaX);
              newConfig.height = Math.max(30, prev.height + deltaY);
              newConfig.x = prev.x + deltaX;
              break;
            case 'bottom-right':
              newConfig.width = Math.max(50, prev.width + deltaX);
              newConfig.height = Math.max(30, prev.height + deltaY);
              break;
          }

          return newConfig;
        });

        setDragStart({ x: e.clientX, y: e.clientY });
      }
    };

    const handleMouseUp = () => {
      setIsDragging(false);
      setIsResizing(null);
    };

    if (isDragging || isResizing) {
      document.addEventListener('mousemove', handleMouseMove);
      document.addEventListener('mouseup', handleMouseUp);

      return () => {
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
      };
    }
  }, [isDragging, isResizing, dragStart]);

  const handleZoomIn = () => {
    setConfig(prev => ({
      ...prev,
      width: prev.width * 1.1,
      height: prev.height * 1.1
    }));
  };

  const handleZoomOut = () => {
    setConfig(prev => ({
      ...prev,
      width: Math.max(50, prev.width * 0.9),
      height: Math.max(30, prev.height * 0.9)
    }));
  };

  const handleRotate = () => {
    setConfig(prev => ({
      ...prev,
      rotation: (prev.rotation + 15) % 360
    }));
  };

  const handleSave = () => {
    onSave(config);
    onClose();
  };

  const handleReset = () => {
    setConfig({
      width: 225,
      height: 75,
      x: 100,
      y: 100,
      rotation: 0
    });
  };

  const handleLogoFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) {
      return;
    }

    const reader = new FileReader();
    reader.onloadend = () => {
      if (typeof reader.result === 'string') {
        onLogoSelect(reader.result);
      }
    };
    reader.readAsDataURL(file);

    event.target.value = '';
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-6xl h-[80vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-xl font-bold text-gray-800">Logo Düzenle</h2>
          <div className="flex items-center gap-3">
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={handleLogoFileChange}
            />
            <button
              onClick={() => fileInputRef.current?.click()}
              className="flex items-center gap-2 px-4 py-2 border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              title="Logo Seç"
            >
              <ImagePlus className="w-5 h-5" />
              Logo Seç
            </button>
            <button
              onClick={handleZoomOut}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              title="Küçült"
            >
              <ZoomOut className="w-5 h-5 text-gray-600" />
            </button>
            <button
              onClick={handleZoomIn}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              title="Büyüt"
            >
              <ZoomIn className="w-5 h-5 text-gray-600" />
            </button>
            <button
              onClick={handleRotate}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              title="Döndür"
            >
              <RotateCw className="w-5 h-5 text-gray-600" />
            </button>
            <button
              onClick={handleReset}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              title="Sıfırla"
            >
              <RotateCcw className="w-5 h-5 text-gray-600" />
            </button>
            <div className="w-px h-6 bg-gray-300 mx-2"></div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              title="İptal"
            >
              <X className="w-5 h-5 text-gray-600" />
            </button>
            <button
              onClick={handleSave}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              <Check className="w-5 h-5" />
              Kaydet
            </button>
          </div>
        </div>

        {/* Canvas */}
        <div
          ref={containerRef}
          className="flex-1 bg-gray-50 relative overflow-hidden"
          style={{
            backgroundImage: 'radial-gradient(circle, #e5e7eb 1px, transparent 1px)',
            backgroundSize: '20px 20px'
          }}
        >
          {/* Info */}
          <div className="absolute top-4 left-4 bg-white px-4 py-2 rounded-lg shadow-sm text-sm text-gray-600">
            Boyut: {Math.round(config.width)} × {Math.round(config.height)} px | Pozisyon: {Math.round(config.x)}, {Math.round(config.y)} | Döndürme: {config.rotation}°
          </div>

          {/* Logo Container */}
          <div
            style={{
              position: 'absolute',
              left: config.x,
              top: config.y,
              width: config.width,
              height: config.height,
              transform: `rotate(${config.rotation}deg)`,
              cursor: isDragging ? 'grabbing' : 'grab',
              border: '2px solid #3b82f6',
              boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)'
            }}
            onMouseDown={(e) => handleMouseDown(e, 'drag')}
          >
            <img
              src={logoSrc}
              alt="Logo"
              className="w-full h-full object-contain pointer-events-none"
              draggable={false}
            />

            {/* Resize Handles */}
            {/* Köşeler */}
            <div
              className="absolute -top-1 -left-1 w-4 h-4 bg-blue-600 rounded-full cursor-nw-resize hover:scale-125 transition-transform"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleMouseDown(e, 'top-left');
              }}
            />
            <div
              className="absolute -top-1 -right-1 w-4 h-4 bg-blue-600 rounded-full cursor-ne-resize hover:scale-125 transition-transform"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleMouseDown(e, 'top-right');
              }}
            />
            <div
              className="absolute -bottom-1 -left-1 w-4 h-4 bg-blue-600 rounded-full cursor-sw-resize hover:scale-125 transition-transform"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleMouseDown(e, 'bottom-left');
              }}
            />
            <div
              className="absolute -bottom-1 -right-1 w-4 h-4 bg-blue-600 rounded-full cursor-se-resize hover:scale-125 transition-transform"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleMouseDown(e, 'bottom-right');
              }}
            />

            {/* Kenarlar */}
            <div
              className="absolute -top-1 left-1/2 -translate-x-1/2 w-4 h-4 bg-blue-600 rounded-full cursor-n-resize hover:scale-125 transition-transform"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleMouseDown(e, 'top');
              }}
            />
            <div
              className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-4 h-4 bg-blue-600 rounded-full cursor-s-resize hover:scale-125 transition-transform"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleMouseDown(e, 'bottom');
              }}
            />
            <div
              className="absolute -left-1 top-1/2 -translate-y-1/2 w-4 h-4 bg-blue-600 rounded-full cursor-w-resize hover:scale-125 transition-transform"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleMouseDown(e, 'left');
              }}
            />
            <div
              className="absolute -right-1 top-1/2 -translate-y-1/2 w-4 h-4 bg-blue-600 rounded-full cursor-e-resize hover:scale-125 transition-transform"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleMouseDown(e, 'right');
              }}
            />

            {/* Move Icon */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none">
              <Move className="w-6 h-6 text-blue-600 opacity-50" />
            </div>
          </div>
        </div>

        {/* Instructions */}
        <div className="p-4 bg-gray-50 border-t border-gray-200">
          <div className="flex items-center justify-center gap-8 text-sm text-gray-600">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 bg-blue-600 rounded-full"></div>
              <span>Logo'yu sürükleyerek taşıyın</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 bg-blue-600 rounded-full"></div>
              <span>Köşelerden ve kenarlardan çekerek boyutlandırın</span>
            </div>
            <div className="flex items-center gap-2">
              <ZoomIn className="w-4 h-4 text-gray-600" />
              <span>Zoom tuşları ile büyütüp küçültün</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LogoEditor;
