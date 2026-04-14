import { useState, useRef, useEffect, useCallback } from 'react'

// Função debounce para limitar a frequência de chamadas
const debounce = (func: (...args: any[]) => void, delay: number) => {
  let timeout: ReturnType<typeof setTimeout>;
  return (...args: any[]) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), delay);
  };
};

function App() {
  const videoRef = useRef<HTMLVideoElement>(null)
  const [isCameraActive, setIsCameraActive] = useState(false)
  const [description, setDescription] = useState<string>('Toque na tela para descrever o ambiente.')
  const [isAnalyzing, setIsAnalyzing] = useState(false)
  const [isAutoMode, setIsAutoMode] = useState(false)
  const autoModeInterval = useRef<ReturnType<typeof setInterval> | null>(null)

  const startCamera = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } })
      if (videoRef.current) {
        videoRef.current.srcObject = stream
        setIsCameraActive(true)
      }
    } catch (err) {
      console.error("Erro ao acessar a câmera: ", err)
      setDescription('Erro ao acessar a câmera. Verifique as permissões.')
    }
  }, [])

  useEffect(() => {
    startCamera()
    return () => {
      if (autoModeInterval.current) {
        clearInterval(autoModeInterval.current)
      }
    }
  }, [startCamera])

  const speak = (text: string) => {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'pt-BR';
      utterance.rate = 1.1;
      window.speechSynthesis.speak(utterance);
    }
  }

  const captureFrame = useCallback(async () => {
    if (!videoRef.current || isAnalyzing) return
    
    setIsAnalyzing(true)
    if (!isAutoMode) {
      setDescription('Analisando o ambiente...')
      speak('Analisando o ambiente...')
    }

    const canvas = document.createElement('canvas')
    canvas.width = videoRef.current.videoWidth
    canvas.height = videoRef.current.videoHeight
    const ctx = canvas.getContext('2d')
    if (ctx) {
      ctx.drawImage(videoRef.current, 0, 0)
      const imageData = canvas.toDataURL('image/jpeg')
      
      try {
        const response = await fetch('http://localhost:3001/analyze', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ image: imageData })
        })

        const data = await response.json()
        if (data.description) {
          setDescription(data.description)
          speak(data.description)
        } else {
          setDescription('Não foi possível descrever a imagem.')
          speak('Não foi possível descrever a imagem.')
        }
      } catch (error) {
        console.error('Erro ao enviar para o backend:', error)
        setDescription('Erro de conexão com o servidor.')
        speak('Erro de conexão com o servidor.')
      } finally {
        setIsAnalyzing(false)
      }
    }
  }, [isAnalyzing, isAutoMode])

  // Debounce para a função captureFrame
  const debouncedCaptureFrame = useCallback(debounce(captureFrame, 500), [captureFrame])

  useEffect(() => {
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (SpeechRecognition) {
      const recognition = new SpeechRecognition();
      recognition.continuous = true;
      recognition.lang = 'pt-BR';
      recognition.interimResults = false;

      recognition.onresult = (event: any) => {
        const command = event.results[event.results.length - 1][0].transcript.toLowerCase();
        console.log('Comando ouvido:', command);
        
        if (command.includes('descreva') || command.includes('o que é isso') || command.includes('onde estou')) {
          debouncedCaptureFrame();
        } else if (command.includes('ligar automático') || command.includes('ativar automático')) {
          if (!isAutoMode) toggleAutoMode();
        } else if (command.includes('desligar automático') || command.includes('parar automático')) {
          if (isAutoMode) toggleAutoMode();
        }
      };

      recognition.onerror = (event: any) => {
        console.error('Erro no reconhecimento de voz:', event.error);
      };

      if (isCameraActive) {
        recognition.start();
      }

      return () => recognition.stop();
    }
  }, [isCameraActive, isAutoMode, debouncedCaptureFrame]);

  const toggleAutoMode = () => {
    if (isAutoMode) {
      if (autoModeInterval.current) {
        clearInterval(autoModeInterval.current)
      }
      setIsAutoMode(false)
      speak('Modo automático desativado.')
    } else {
      setIsAutoMode(true)
      speak('Modo automático ativado. Analisando a cada dez segundos.')
      // Captura inicial
      debouncedCaptureFrame()
      // Configura intervalo (ex: 10 segundos)
      autoModeInterval.current = setInterval(() => {
        captureFrame()
      }, 10000)
    }
  }

  return (
    <div className="min-h-screen bg-[#0a0a0f] text-[#e8e8f0] font-sans flex flex-col items-center justify-center p-4">
      <header className="w-full max-w-md mb-8 flex flex-col items-center">
        <div className="bg-[#00e5ff]/10 border border-[#00e5ff]/25 text-[#00e5ff] font-mono text-[0.7rem] px-3 py-1 rounded uppercase tracking-widest mb-4">
          VisionGuide
        </div>
        <h1 className="text-4xl font-extrabold tracking-tighter mb-2">
          Olho <span className="text-[#00e5ff]">Digital</span>
        </h1>
      </header>

      <main className="w-full max-w-md relative aspect-square bg-[#1a1a26] border border-[#2a2a40] rounded-2xl overflow-hidden shadow-2xl">
        <div className="absolute top-4 right-4 z-20">
          <button
            onClick={toggleAutoMode}
            className={`px-4 py-2 rounded-full font-mono text-[0.7rem] uppercase tracking-wider transition-all border ${
              isAutoMode 
                ? 'bg-[#10b981]/20 border-[#10b981] text-[#10b981]' 
                : 'bg-white/5 border-white/20 text-white/60 hover:border-white/40'
            }`}
          >
            <span className={`inline-block w-2 h-2 rounded-full mr-2 ${isAutoMode ? 'bg-[#10b981] animate-pulse' : 'bg-white/20'}`}></span>
            {isAutoMode ? 'Auto ON' : 'Auto OFF'}
          </button>
        </div>

        {!isCameraActive && (
          <div className="absolute inset-0 flex items-center justify-center bg-black/50 z-10">
            <button 
              onClick={startCamera}
              className="bg-[#00e5ff] text-black font-bold px-6 py-3 rounded-full hover:scale-105 transition-transform"
            >
              Ativar Câmera
            </button>
          </div>
        )}
        
        <video 
          ref={videoRef} 
          autoPlay 
          playsInline 
          className="w-full h-full object-cover cursor-pointer"
          onClick={debouncedCaptureFrame}
        />

        {isAnalyzing && (
          <div className="absolute inset-0 flex items-center justify-center bg-black/30 pointer-events-none">
            <div className="w-12 h-12 border-4 border-[#00e5ff] border-t-transparent rounded-full animate-spin"></div>
          </div>
        )}

        <div className="absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-black/80 to-transparent">
          <p className="text-center text-lg font-semibold leading-tight">
            {description}
          </p>
        </div>
      </main>

      <footer className="mt-8 text-[#6b6b8a] font-mono text-[0.65rem] tracking-wider uppercase text-center">
        Toque na câmera para descrever o que está à frente
      </footer>
    </div>
  )
}

export default App
