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
  const chatContainerRef = useRef<HTMLDivElement>(null)
  const chatSocketRef = useRef<WebSocket | null>(null)
  const [currentScreen, setCurrentScreen] = useState<'menu' | 'assistant' | 'chat' | 'gallery'>('menu')
  const [galleryFilter, setGalleryFilter] = useState<'all' | 'photo' | 'video'>('all')
  const [menuInfo, setMenuInfo] = useState<string>('')
  const [chatInput, setChatInput] = useState('')
  const [chatStatus, setChatStatus] = useState<'connecting' | 'connected' | 'disconnected'>('disconnected')
  const [chatMessages, setChatMessages] = useState<Array<{ id: string; role: 'user' | 'assistant' | 'system'; content: string }>>([])
  const [isCameraActive, setIsCameraActive] = useState(false)
  const [description, setDescription] = useState<string>('Toque na tela para descrever o ambiente.')
  const [isAnalyzing, setIsAnalyzing] = useState(false)
  const [isAutoMode, setIsAutoMode] = useState(false)
  const autoModeInterval = useRef<ReturnType<typeof setInterval> | null>(null)

  const scrollChatToBottom = () => {
    if (chatContainerRef.current) {
      chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight
    }
  }

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
    if (currentScreen === 'assistant') {
      startCamera()
    }

    return () => {
      if (autoModeInterval.current) {
        clearInterval(autoModeInterval.current)
      }
    }
  }, [currentScreen, startCamera])

  useEffect(() => {
    if (currentScreen !== 'chat') {
      if (chatSocketRef.current) {
        chatSocketRef.current.close()
        chatSocketRef.current = null
      }
      setChatStatus('disconnected')
      return
    }

    setChatStatus('connecting')
    const socket = new WebSocket('ws://localhost:3001/ws/chat')
    chatSocketRef.current = socket

    socket.onopen = () => {
      setChatStatus('connected')
    }

    socket.onmessage = (event) => {
      try {
        const parsed = JSON.parse(event.data) as { role: 'user' | 'assistant' | 'system'; content: string }
        if (!parsed?.content) return

        setChatMessages((prev) => [
          ...prev,
          {
            id: `${Date.now()}-${Math.random()}`,
            role: parsed.role || 'assistant',
            content: parsed.content
          }
        ])
      } catch (error) {
        console.error('Erro ao ler mensagem do websocket:', error)
      }
    }

    socket.onerror = () => {
      setChatStatus('disconnected')
      setChatMessages((prev) => [
        ...prev,
        {
          id: `${Date.now()}-error`,
          role: 'system',
          content: 'Falha na conexão do chat com o servidor.'
        }
      ])
    }

    socket.onclose = () => {
      setChatStatus('disconnected')
    }

    return () => {
      socket.close()
      chatSocketRef.current = null
    }
  }, [currentScreen])

  useEffect(() => {
    scrollChatToBottom()
  }, [chatMessages])

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

  const sendChatMessage = () => {
    const content = chatInput.trim()
    if (!content) return

    if (!chatSocketRef.current || chatSocketRef.current.readyState !== WebSocket.OPEN) {
      setChatMessages((prev) => [
        ...prev,
        {
          id: `${Date.now()}-offline`,
          role: 'system',
          content: 'Conexão do chat indisponível. Tente novamente em instantes.'
        }
      ])
      return
    }

    const userMessage = {
      id: `${Date.now()}-user`,
      role: 'user' as const,
      content
    }

    setChatMessages((prev) => [...prev, userMessage])
    chatSocketRef.current.send(JSON.stringify({ type: 'message', content }))
    setChatInput('')
  }

  const galleryItems: Array<{ id: number; type: 'photo' | 'video'; title: string; duration?: string; className: string }> = [
    { id: 1, type: 'photo', title: 'Praia', className: 'from-[#4b7cf2] to-[#1f2d5b]' },
    { id: 2, type: 'photo', title: 'Floresta', className: 'from-[#7ad089] to-[#255d3c]' },
    { id: 3, type: 'video', title: 'Mar', duration: '00:12', className: 'from-[#42cbe2] to-[#1f5e74]' },
    { id: 4, type: 'photo', title: 'Montanha', className: 'from-[#8dd3ff] to-[#2d4f74]' },
    { id: 5, type: 'video', title: 'Rua', duration: '00:27', className: 'from-[#a4b5d8] to-[#49556f]' },
    { id: 6, type: 'photo', title: 'Noite', className: 'from-[#243a7a] to-[#0f1a35]' },
    { id: 7, type: 'photo', title: 'Cidade', className: 'from-[#6ec4ff] to-[#2461b5]' },
    { id: 8, type: 'video', title: 'Parque', duration: '00:08', className: 'from-[#87d9b9] to-[#25624d]' }
  ]

  const filteredGallery = galleryItems.filter((item) => {
    if (galleryFilter === 'all') return true
    return item.type === galleryFilter
  })

  const renderBottomNav = (active: 'home' | 'ai' | 'picture' | 'me') => (
    <nav className="mt-auto bg-[#0d1017] rounded-[28px] px-3 py-2 flex items-center justify-between gap-2 border border-white/10">
      <button
        onClick={() => setCurrentScreen('menu')}
        className={`flex-1 rounded-2xl px-2 py-3 text-xs font-semibold transition-colors ${
          active === 'home' ? 'bg-white text-[#11131a]' : 'text-[#a8afc3] hover:bg-white/5'
        }`}
      >
        Home
      </button>
      <button
        onClick={() => {
          setChatMessages([])
          setCurrentScreen('chat')
        }}
        className={`flex-1 rounded-2xl px-2 py-3 text-xs font-semibold transition-colors ${
          active === 'ai' ? 'bg-white text-[#11131a]' : 'text-[#a8afc3] hover:bg-white/5'
        }`}
      >
        AI
      </button>
      <button
        onClick={() => setCurrentScreen('gallery')}
        className={`flex-1 rounded-2xl px-2 py-3 text-xs font-semibold transition-colors ${
          active === 'picture' ? 'bg-white text-[#11131a]' : 'text-[#a8afc3] hover:bg-white/5'
        }`}
      >
        Picture
      </button>
      <button
        onClick={() => setCurrentScreen('menu')}
        className={`flex-1 rounded-2xl px-2 py-3 text-xs font-semibold transition-colors ${
          active === 'me' ? 'bg-white text-[#11131a]' : 'text-[#a8afc3] hover:bg-white/5'
        }`}
      >
        Me
      </button>
    </nav>
  )

  if (currentScreen === 'menu') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-[#d9ecff] to-[#cee1f5] text-[#151826] py-8 px-4 flex items-center justify-center">
        <main className="w-full max-w-[420px] h-[760px] bg-[#181b24] rounded-[42px] p-4 border-[6px] border-[#101219] shadow-[0_28px_60px_rgba(10,17,30,0.35)] flex flex-col">
          <div className="px-3 pt-2 pb-4 text-[#f4f7ff] text-sm font-semibold flex items-center justify-between">
            <span>9:41</span>
            <span className="text-xs text-[#a9b0c4]">VisionGuide</span>
          </div>

          <div className="rounded-3xl bg-[#1f222d] border border-white/5 p-4 mb-4">
            <p className="text-[#7fb2ff] text-[11px] font-bold tracking-[0.18em] uppercase mb-2">VisionGuide</p>
            <p className="text-[#e8ecf8] text-2xl font-bold mb-1 leading-tight">Assistente Visual</p>
            <p className="text-[#9da6be] text-sm">Navegação e leitura inteligente em tempo real.</p>
          </div>

          <div className="space-y-3">
            <button
              onClick={() => setCurrentScreen('assistant')}
              className="w-full bg-[#f4f7ff] text-[#171923] font-bold px-4 py-3 rounded-2xl hover:opacity-95 transition-opacity"
            >
              Abrir Câmera Assistiva
            </button>
            <button
              onClick={() => {
                setChatMessages([])
                setCurrentScreen('chat')
              }}
              className="w-full bg-[#2f7de1] text-white font-bold px-4 py-3 rounded-2xl hover:opacity-95 transition-opacity"
            >
              Conversar com IA
            </button>
            <button
              onClick={() => setCurrentScreen('gallery')}
              className="w-full bg-[#e9edf8] text-[#171923] font-bold px-4 py-3 rounded-2xl hover:opacity-95 transition-opacity"
            >
              Galeria de Fotos e Vídeos
            </button>
            <button
              onClick={() => setMenuInfo('O VisionGuide ajuda pessoas com deficiência visual com leitura de textos, descrição de ambientes e alerta de obstáculos em tempo real.')}
              className="w-full bg-[#252936] border border-white/10 text-white font-semibold px-4 py-3 rounded-2xl hover:border-white/20 transition-colors"
            >
              Sobre o Projeto
            </button>
            <button
              onClick={() => setMenuInfo('Contato da equipe: visionguide.contato@gmail.com')}
              className="w-full bg-[#252936] border border-white/10 text-white font-semibold px-4 py-3 rounded-2xl hover:border-white/20 transition-colors"
            >
              Contato
            </button>
          </div>

          <div className="mt-4 min-h-16 rounded-2xl bg-[#202430] border border-white/10 px-4 py-3 text-sm text-[#bcc4da]">
            {menuInfo || 'Dica: use “Conversar com IA” para perguntas rápidas, “Galeria de Fotos e Vídeos” para mídias recentes e “Abrir Câmera Assistiva” para descrição de ambiente.'}
          </div>

          {renderBottomNav('home')}
        </main>
      </div>
    )
  }

  if (currentScreen === 'gallery') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-[#d9ecff] to-[#cee1f5] py-8 px-4 flex items-center justify-center">
        <main className="w-full max-w-[420px] h-[760px] bg-[#181b24] rounded-[42px] p-4 border-[6px] border-[#101219] shadow-[0_28px_60px_rgba(10,17,30,0.35)] flex flex-col">
          <header className="px-2 pb-3 text-white">
            <p className="text-2xl font-semibold">Picture</p>
            <p className="text-xs text-[#a8afc3] mt-1">Fotos e vídeos recentes</p>
          </header>

          <div className="rounded-2xl bg-[#1f2430] border border-white/10 p-3 flex items-center justify-between mb-3">
            <p className="text-xs text-[#cfd5e7]">{filteredGallery.length} mídias disponíveis</p>
            <button
              onClick={() => setCurrentScreen('assistant')}
              className="bg-[#f4f7ff] text-[#12161f] text-xs font-semibold px-3 py-1.5 rounded-full"
            >
              Usar câmera
            </button>
          </div>

          <div className="flex gap-2 mb-3">
            <button
              onClick={() => setGalleryFilter('all')}
              className={`px-3 py-2 rounded-full text-xs font-semibold ${galleryFilter === 'all' ? 'bg-white text-[#11131a]' : 'bg-white/10 text-[#c2cae0]'}`}
            >
              Todos
            </button>
            <button
              onClick={() => setGalleryFilter('photo')}
              className={`px-3 py-2 rounded-full text-xs font-semibold ${galleryFilter === 'photo' ? 'bg-white text-[#11131a]' : 'bg-white/10 text-[#c2cae0]'}`}
            >
              Fotos
            </button>
            <button
              onClick={() => setGalleryFilter('video')}
              className={`px-3 py-2 rounded-full text-xs font-semibold ${galleryFilter === 'video' ? 'bg-white text-[#11131a]' : 'bg-white/10 text-[#c2cae0]'}`}
            >
              Vídeos
            </button>
          </div>

          <div className="grid grid-cols-2 gap-3 overflow-y-auto pr-1">
            {filteredGallery.map((item) => (
              <div key={item.id} className={`relative aspect-[4/3] rounded-2xl bg-gradient-to-br ${item.className} overflow-hidden border border-white/10`}>
                <div className="absolute inset-0 bg-black/20" />
                <p className="absolute bottom-2 left-2 text-xs text-white font-semibold">{item.title}</p>
                {item.type === 'video' && item.duration && (
                  <span className="absolute top-2 right-2 text-[10px] text-white bg-black/40 rounded-full px-2 py-1">{item.duration}</span>
                )}
              </div>
            ))}
          </div>

          {renderBottomNav('picture')}
        </main>
      </div>
    )
  }

  if (currentScreen === 'chat') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-[#d9ecff] to-[#cee1f5] py-8 px-4 flex items-center justify-center">
        <main className="w-full max-w-[420px] h-[760px] bg-[#181b24] rounded-[42px] p-4 border-[6px] border-[#101219] shadow-[0_28px_60px_rgba(10,17,30,0.35)] flex flex-col">
          <header className="px-2 pb-4 text-white flex items-center justify-between">
            <div>
              <p className="font-semibold text-2xl">AI Assistant</p>
              <p className="text-xs text-[#a8afc3]">
                {chatStatus === 'connected' ? 'Conectado' : chatStatus === 'connecting' ? 'Conectando...' : 'Desconectado'}
              </p>
            </div>
            <button
              onClick={() => setCurrentScreen('menu')}
              className="bg-white/10 border border-white/15 text-white px-4 py-2 rounded-full text-sm hover:border-white/30 transition-colors"
            >
              Voltar
            </button>
          </header>

          <div ref={chatContainerRef} className="flex-1 overflow-y-auto p-2 space-y-3">
            {chatMessages.length === 0 && (
              <div className="text-sm text-[#c1c8dc] bg-[#212532] border border-white/10 rounded-2xl p-4">
                Envie uma mensagem para iniciar sua conversa com a IA.
              </div>
            )}

            {chatMessages.map((message) => (
              <div key={message.id} className={`flex ${message.role === 'user' ? 'justify-start' : 'justify-start'} gap-2`}>
                {message.role !== 'user' && <div className="w-8 h-8 rounded-full bg-[#cde6ff] mt-1" />}
                <div className={`max-w-[84%] rounded-3xl px-4 py-3 text-sm leading-relaxed ${
                  message.role === 'user'
                    ? 'bg-[#1f2330] text-[#f2f4fb] border border-white/10 ml-auto'
                    : message.role === 'system'
                    ? 'bg-[#2a3040] text-[#d7dcf2] border border-white/20'
                    : 'bg-[#f3f7f4] text-[#161a24]'
                }`}>
                  {message.content}
                </div>
              </div>
            ))}
          </div>

          <footer className="pt-3">
            <div className="flex gap-3">
              <input
                value={chatInput}
                onChange={(e) => setChatInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') sendChatMessage()
                }}
                placeholder="Digite sua mensagem..."
                className="flex-1 bg-[#10131d] border border-[#2b2f46] text-white rounded-full px-4 py-3 text-sm outline-none focus:border-[#7eaef0]"
              />
              <button
                onClick={sendChatMessage}
                className="bg-[#2f7de1] text-white font-bold px-5 py-3 rounded-full hover:opacity-95 transition-opacity"
              >
                Enviar
              </button>
            </div>

            {renderBottomNav('ai')}
          </footer>
        </main>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#d9ecff] to-[#cee1f5] py-8 px-4 flex items-center justify-center">
      <main className="w-full max-w-[420px] h-[760px] bg-[#181b24] rounded-[42px] p-4 border-[6px] border-[#101219] shadow-[0_28px_60px_rgba(10,17,30,0.35)] flex flex-col">
        <header className="px-2 pb-3 text-white flex items-center justify-between">
          <h1 className="text-2xl font-semibold">Picture</h1>
          <button
            onClick={toggleAutoMode}
            className={`px-4 py-2 rounded-full text-[0.72rem] uppercase tracking-wider transition-colors border ${
              isAutoMode 
                ? 'bg-[#e9f5eb] border-[#9bc3a3] text-[#1f6341]' 
                : 'bg-white/10 border-white/20 text-white/75 hover:border-white/35'
            }`}
          >
            <span className={`inline-block w-2 h-2 rounded-full mr-2 ${isAutoMode ? 'bg-[#1f6341] animate-pulse' : 'bg-white/30'}`}></span>
            {isAutoMode ? 'Auto ON' : 'Auto OFF'}
          </button>
        </header>

        <div className="relative flex-1 rounded-3xl overflow-hidden bg-[#212531] border border-white/10">
          {!isCameraActive && (
            <div className="absolute inset-0 flex items-center justify-center bg-black/55 z-10">
              <button 
                onClick={startCamera}
                className="bg-[#f4f7ff] text-[#151826] font-bold px-6 py-3 rounded-full hover:opacity-95 transition-opacity"
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
            <div className="absolute inset-0 flex items-center justify-center bg-black/35 pointer-events-none">
              <div className="w-12 h-12 border-4 border-[#f4f7ff] border-t-transparent rounded-full animate-spin"></div>
            </div>
          )}

          <div className="absolute bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-black/85 to-transparent">
            <p className="text-center text-[0.95rem] font-medium leading-relaxed text-[#eef2fc]">
              {description}
            </p>
          </div>
        </div>

        <p className="text-center mt-3 text-xs text-[#9ba4bb]">Toque na câmera para descrever o ambiente</p>
        {renderBottomNav('picture')}
      </main>
    </div>
  )
}

export default App
