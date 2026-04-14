import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import http from 'http';
import { GoogleGenerativeAI } from "@google/generative-ai";
import OpenAI from 'openai';
import { WebSocketServer, WebSocket } from 'ws';

dotenv.config();

const app = express();
const port = process.env.PORT || 3001;

// Configuração do provedor de IA (Gemini ou OpenAI)
const AI_PROVIDER = process.env.AI_PROVIDER || 'gemini'; // 'gemini' ou 'openai'

// Configuração do Gemini
const genAI = AI_PROVIDER === 'gemini' ? new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '') : null;

// Configuração do OpenAI
const openai = AI_PROVIDER === 'openai' ? new OpenAI({
  apiKey: process.env.OPENAI_API_KEY || ''
}) : null;

const hasGeminiKey = Boolean(process.env.GEMINI_API_KEY);
const hasOpenAIKey = Boolean(process.env.OPENAI_API_KEY);

type ChatRole = 'user' | 'assistant' | 'system';

interface ChatRequestPayload {
  type: 'message';
  content: string;
}

interface ChatResponsePayload {
  type: 'message';
  role: ChatRole;
  content: string;
  timestamp: string;
}

const sendWSMessage = (socket: WebSocket, payload: ChatResponsePayload) => {
  socket.send(JSON.stringify(payload));
};

const buildFallbackReply = (content: string) => {
  return `Recebi sua mensagem: "${content}". O chat em tempo real está funcionando, mas nenhuma chave de IA foi configurada no backend ainda.`;
};

const generateChatReply = async (content: string): Promise<string> => {
  if (AI_PROVIDER === 'openai' && openai && hasOpenAIKey) {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'Você é um assistente acessível do VisionGuide. Responda de forma clara, curta e útil em português do Brasil.'
        },
        {
          role: 'user',
          content
        }
      ],
      max_tokens: 300
    });

    return response.choices[0]?.message?.content || 'Não consegui gerar resposta agora.';
  }

  if (AI_PROVIDER === 'gemini' && genAI && hasGeminiKey) {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const prompt = `Você é um assistente acessível do VisionGuide. Responda em português do Brasil, de forma objetiva e útil.\n\nPergunta do usuário: ${content}`;
    const result = await model.generateContent(prompt);
    const response = await result.response;
    return response.text() || 'Não consegui gerar resposta agora.';
  }

  return buildFallbackReply(content);
};

app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.get('/', (req, res) => {
  res.json({ message: 'VisionGuide Backend API', status: 'running' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/analyze', async (req, res) => {
  try {
    const { image } = req.body; // base64 image data

    if (!image) {
      return res.status(400).json({ error: 'Nenhuma imagem fornecida' });
    }

    // Remover o prefixo data:image/jpeg;base64, se existir
    const base64Data = image.replace(/^data:image\/\w+;base64,/, "");
    
    let description = '';

    if (AI_PROVIDER === 'openai' && openai) {
      // Usar OpenAI GPT-4 Vision
      const response = await openai.chat.completions.create({
        model: "gpt-4-vision-preview",
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: "Você é o 'Olho Digital' de uma pessoa com deficiência visual. Descreva o que está nesta imagem de forma concisa, direta e útil para alguém que não pode ver. Foque em objetos principais, pessoas, textos visíveis e possíveis obstáculos ou perigos. Responda em Português do Brasil."
              },
              {
                type: "image_url",
                image_url: {
                  url: `data:image/jpeg;base64,${base64Data}`
                }
              }
            ]
          }
        ],
        max_tokens: 300
      });

      description = response.choices[0].message.content || 'Nenhuma descrição gerada';
    } else if (AI_PROVIDER === 'gemini' && genAI) {
      // Usar Google Gemini
      const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

      const prompt = "Você é o 'Olho Digital' de uma pessoa com deficiência visual. Descreva o que está nesta imagem de forma concisa, direta e útil para alguém que não pode ver. Foque em objetos principais, pessoas, textos visíveis e possíveis obstáculos ou perigos. Responda em Português do Brasil.";

      const result = await model.generateContent([
        prompt,
        {
          inlineData: {
            data: base64Data,
            mimeType: "image/jpeg"
          }
        }
      ]);

      const response = await result.response;
      description = response.text();
    } else {
      return res.status(500).json({ error: 'Nenhum provedor de IA configurado corretamente' });
    }

    res.json({ description, provider: AI_PROVIDER });
  } catch (error: any) {
    console.error(`Erro ao processar imagem com ${AI_PROVIDER}:`, error);
    res.status(500).json({ error: 'Erro ao analisar a imagem', details: error.message, provider: AI_PROVIDER });
  }
});

const server = http.createServer(app);

const chatWSS = new WebSocketServer({
  server,
  path: '/ws/chat'
});

chatWSS.on('connection', (socket) => {
  sendWSMessage(socket, {
    type: 'message',
    role: 'system',
    content: 'Conectado ao chat VisionGuide. Envie uma mensagem para começar.',
    timestamp: new Date().toISOString()
  });

  socket.on('message', async (rawMessage) => {
    try {
      const parsed = JSON.parse(rawMessage.toString()) as ChatRequestPayload;
      if (parsed.type !== 'message' || !parsed.content?.trim()) {
        sendWSMessage(socket, {
          type: 'message',
          role: 'system',
          content: 'Mensagem inválida. Envie texto no formato esperado.',
          timestamp: new Date().toISOString()
        });
        return;
      }

      const reply = await generateChatReply(parsed.content.trim());
      sendWSMessage(socket, {
        type: 'message',
        role: 'assistant',
        content: reply,
        timestamp: new Date().toISOString()
      });
    } catch (error: any) {
      console.error('Erro no WebSocket chat:', error);
      sendWSMessage(socket, {
        type: 'message',
        role: 'system',
        content: 'Erro ao processar mensagem do chat.',
        timestamp: new Date().toISOString()
      });
    }
  });
});

server.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
  console.log(`WebSocket chat running at ws://localhost:${port}/ws/chat`);
});
