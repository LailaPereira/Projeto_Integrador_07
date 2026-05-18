from fastapi import FastAPI, File, UploadFile, HTTPException
import cv2
import numpy as np
from ultralytics import YOLO
from PIL import Image
import io
import base64
from datetime import datetime
from typing import List, Dict, Any

def inicializar_yolo():
    """
    Carrega o modelo YOLO para detecção de objetos
    
    Modelos disponíveis:
    - yolov8n.yaml: Nano (mais rápido)
    - yolov8s.yaml: Small
    - yolov8m.yaml: Medium
    - yolov8l.yaml: Large
    - yolov8x.yaml: Extra Large (mais preciso)
    """
    try:
        modelo = YOLO('yolov8n.pt')
        print("✅ YOLO carregado com sucesso")
        return modelo
    except Exception as e:
        print(f"❌ Erro ao carregar YOLO: {e}")
        return None

def processar_imagem_yolo(
    imagem_base64: str,
    modelo_yolo: YOLO,
    confianca_minima: float = 0.5
) -> Dict[str, Any]:
    """
    Processa uma imagem com YOLO e retorna objetos detectados
    
    Args:
        imagem_base64: Imagem em base64 (vindo do Flutter)
        modelo_yolo: Modelo YOLO carregado
        confianca_minima: Confiança mínima para detectar (0-1)
    
    Returns:
        Dict com objetos detectados e descrição
    """
    
    try:
        imagem_bytes = base64.b64decode(imagem_base64)
        imagem = Image.open(io.BytesIO(imagem_bytes))
        imagem_cv2 = cv2.cvtColor(np.array(imagem), cv2.COLOR_RGB2BGR)
        resultados = modelo_yolo(imagem_cv2)
        
        objetos_detectados = []
        
        for resultado in resultados:
            for det in resultado.boxes:
                confianca = float(det.conf)
                classe_id = int(det.cls)
                classe_nome = resultado.names[classe_id]
                caixa = det.xyxy[0].cpu().numpy()
                if confianca < confianca_minima:
                    continue
                altura_imagem = imagem_cv2.shape[0]
                largura_imagem = imagem_cv2.shape[1]
                
                x_centro = (caixa[0] + caixa[2]) / 2
                y_centro = (caixa[1] + caixa[3]) / 2
                
                posicao_relativa = calcular_posicao_relativa(
                    x_centro, y_centro,
                    largura_imagem, altura_imagem
                )
                
                objetos_detectados.append({
                    "id": len(objetos_detectados),
                    "nome": classe_nome,
                    "confianca": round(confianca, 2),
                    "posicao": posicao_relativa,
                    "caixa_delimitadora": [
                        float(caixa[0]),
                        float(caixa[1]),
                        float(caixa[2]),
                        float(caixa[3])
                    ]
                })
        
        descricao = gerar_descricao_audio(objetos_detectados)
        
        return {
            "status": True,
            "objetos_totais": len(objetos_detectados),
            "objetos": objetos_detectados,
            "descricao_audio": descricao,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        return {
            "status": False,
            "mensagem": f"Erro ao processar imagem: {str(e)}",
            "objetos": []
        }

def calcular_posicao_relativa(x: float, y: float, 
                              largura: int, altura: int) -> str:
    x_zona = "esquerda" if x < largura / 3 else ("direita" if x > largura * 2/3 else "centro")
    y_zona = "acima" if y < altura / 3 else ("abaixo" if y > altura * 2/3 else "centro")
    posicoes_mapeadas = {
        ("esquerda", "acima"): "acima à esquerda",
        ("esquerda", "centro"): "à sua esquerda",
        ("esquerda", "abaixo"): "abaixo à esquerda",
        ("centro", "acima"): "acima de você",
        ("centro", "centro"): "à sua frente",
        ("centro", "abaixo"): "abaixo de você",
        ("direita", "acima"): "acima à direita",
        ("direita", "centro"): "à sua direita",
        ("direita", "abaixo"): "abaixo à direita",
    }
    
    return posicoes_mapeadas.get((x_zona, y_zona), "perto")

def gerar_descricao_audio(objetos: List[Dict]) -> str:
    if not objetos:
        return "Nenhum obstáculo detectado. O caminho parece seguro."

    objetos_por_tipo = {}
    for obj in objetos:
        nome = obj['nome']
        if nome not in objetos_por_tipo:
            objetos_por_tipo[nome] = []
        objetos_por_tipo[nome].append(obj)

    sentencas = []

    if 'person' in objetos_por_tipo:
        pessoas = objetos_por_tipo['person']
        if len(pessoas) == 1:
            sentencas.append(f"Pessoa detectada {pessoas[0]['posicao']}")
        else:
            sentencas.append(f"{len(pessoas)} pessoas detectadas")

    nomes_veiculos = ['car', 'truck', 'bus', 'bicycle', 'motorcycle']
    veiculos_detectados = [tipo for tipo in objetos_por_tipo 
                          if tipo in nomes_veiculos]
    for veiculo in veiculos_detectados:
        item = objetos_por_tipo[veiculo][0]
        sentencas.append(f"{veiculo.capitalize()} {item['posicao']}")

    for obj in objetos:
        if obj['nome'] not in ['person'] + nomes_veiculos:
            if obj['confianca'] > 0.7:
                sentencas.append(f"{obj['nome'].capitalize()} {obj['posicao']}")
    
    if sentencas:
        descricao = "Atenção: " + ". ".join(sentencas) + "."
    else:
        descricao = "Nenhum obstáculo crítico detectado."
    
    return descricao

def monta_rota_analise(app: FastAPI, modelo_yolo: YOLO):
    @app.post("/analisar-imagem")
    async def analisar_imagem_endpoint(
        imagem_base64: str,
        tipo_saida: str = "descricao"
    ):
        if not modelo_yolo:
            raise HTTPException(
                status_code=500,
                detail="YOLO não foi carregado corretamente"
            )
        
        resultado = processar_imagem_yolo(imagem_base64, modelo_yolo)
        return resultado


