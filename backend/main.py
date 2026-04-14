import base64
import os
import sys

# Configurar diretórios da Ultralytics ANTES de qualquer importação
# Isso evita o erro de permissão no Windows AppData
current_dir = os.getcwd()
os.environ['ULTRALYTICS_CONFIG_DIR'] = os.path.join(current_dir, '.ultralytics', 'config')
os.environ['ULTRALYTICS_SETTINGS_DIR'] = os.path.join(current_dir, '.ultralytics', 'settings')
os.environ['YOLO_CONFIG_DIR'] = os.path.join(current_dir, '.ultralytics', 'config')

# Criar os diretórios manualmente para garantir
os.makedirs(os.environ['ULTRALYTICS_CONFIG_DIR'], exist_ok=True)
os.makedirs(os.environ['ULTRALYTICS_SETTINGS_DIR'], exist_ok=True)

import io
import cv2
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
from dotenv import load_dotenv
from PIL import Image
from ultralytics import YOLO

# Carregar variáveis de ambiente com override para garantir atualização
load_dotenv(override=True)

app = FastAPI(title="VisionGuide API")

# Configuração do CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuração do Gemini
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    print("ERRO: GEMINI_API_KEY não encontrada no arquivo .env")
else:
    # Mostrar apenas os 4 primeiros caracteres para debug seguro
    print(f"API Key carregada: {GEMINI_API_KEY[:4]}****")
    genai.configure(api_key=GEMINI_API_KEY)

# Inicializar YOLOv8
try:
    yolo_model = YOLO('yolov8n.pt') 
    print("YOLOv8 carregado com sucesso!")
except Exception as e:
    print(f"Erro ao carregar YOLOv8: {e}")
    yolo_model = None

# Inicializar Detector de Rostos (Haar Cascade) - Sugestão do Usuário
try:
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
    print("Detector de rostos carregado com sucesso!")
except Exception as e:
    print(f"Erro ao carregar detector de rostos: {e}")
    face_cascade = None

class ImageRequest(BaseModel):
    image: str  # base64 string

def process_with_yolo(img):
    if yolo_model is None:
        return []
    
    results = yolo_model(img, verbose=False)
    detections = []
    
    for r in results:
        for box in r.boxes:
            cls = int(box.cls[0])
            label = yolo_model.names[cls]
            conf = float(box.conf[0])
            if conf > 0.4: # Filtro de confiança
                detections.append({"label": label, "confidence": conf})
    
    return detections

@app.get("/health")
async def health():
    return {"status": "ok", "provider": "python/fastapi", "yolo": yolo_model is not None}

@app.post("/analyze")
async def analyze_image(request: ImageRequest):
    try:
        # Decodificar imagem base64
        header, encoded = request.image.split(",", 1) if "," in request.image else (None, request.image)
        image_bytes = base64.b64decode(encoded)
        
        # Converter para formato OpenCV
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            raise HTTPException(status_code=400, detail="Imagem inválida")

        # 1. Detecção em Tempo Real com YOLO
        yolo_results = process_with_yolo(img)
        
        # 1.1 Detecção de Rostos com Haar Cascade (Sugestão do Usuário)
        faces_detected = 0
        if face_cascade is not None:
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            faces = face_cascade.detectMultiScale(gray, 1.3, 5)
            faces_detected = len(faces)

        # Tradução simples de classes comuns para PT-BR
        translations = {
            "person": "pessoa",
            "bicycle": "bicicleta",
            "car": "carro",
            "motorcycle": "moto",
            "bus": "ônibus",
            "truck": "caminhão",
            "traffic light": "semáforo",
            "stop sign": "placa de pare",
            "bench": "banco",
            "dog": "cachorro",
            "cat": "gato",
            "backpack": "mochila",
            "umbrella": "guarda-chuva",
            "handbag": "bolsa",
            "tie": "gravata",
            "suitcase": "mala",
            "bottle": "garrafa",
            "cup": "copo",
            "fork": "garfo",
            "knife": "faca",
            "spoon": "colher",
            "bowl": "tigela",
            "chair": "cadeira",
            "couch": "sofá",
            "potted plant": "planta",
            "bed": "cama",
            "dining table": "mesa de jantar",
            "toilet": "vaso sanitário",
            "tv": "televisão",
            "laptop": "laptop",
            "mouse": "mouse",
            "remote": "controle remoto",
            "keyboard": "teclado",
            "cell phone": "celular",
            "microwave": "micro-ondas",
            "oven": "forno",
            "sink": "pia",
            "refrigerator": "geladeira",
            "book": "livro",
            "clock": "relógio",
            "vase": "vaso",
            "scissors": "tesoura",
            "teddy bear": "urso de pelúcia",
            "hair drier": "secador de cabelo",
            "toothbrush": "escova de dentes"
        }

        yolo_summary = []
        for det in yolo_results:
            label_pt = translations.get(det['label'], det['label'])
            if label_pt not in yolo_summary:
                yolo_summary.append(label_pt)
        
        # Adicionar rostos ao resumo se detectados
        if faces_detected > 0:
            face_text = f"{faces_detected} rosto(s)"
            if face_text not in yolo_summary:
                yolo_summary.append(face_text)

        # 2. Descrição Contextual com Gemini
        model = genai.GenerativeModel('gemini-1.5-flash')
        
        # Informar ao Gemini o que o YOLO e Haar já detectaram
        fast_vision_context = f" O sistema de detecção rápida identificou: {', '.join(yolo_summary)}." if yolo_summary else ""
        
        prompt = (
            "Você é o 'Olho Digital' de uma pessoa com deficiência visual. "
            "Descreva o que está nesta imagem de forma concisa, direta e útil. "
            f"{fast_vision_context} "
            "Foque em descrever a disposição espacial (ex: 'à sua esquerda', 'no centro'). "
            "Se houver pessoas, descreva o que estão fazendo. "
            "Se houver texto, leia-o. "
            "Responda em Português do Brasil."
        )
        
        img_pil = Image.open(io.BytesIO(image_bytes))
        response = model.generate_content([prompt, img_pil])
        
        final_description = response.text
        
        # Se o YOLO detectou algo importante mas o Gemini foi vago, podemos reforçar (opcional)
        
        return {
            "description": final_description,
            "detections": yolo_results,
            "summary": yolo_summary
        }
        
    except Exception as e:
        print(f"Erro ao analisar imagem: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=3001)
