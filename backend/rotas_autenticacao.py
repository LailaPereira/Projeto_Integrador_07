from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from flask import app
from pydantic import BaseModel
from datetime import datetime, timedelta
import random
import string
import os
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, status

load_dotenv()

class DadosLogin(BaseModel):
    """Modelo para requisição de login"""
    email: str
    senha: str

class DadosRegistro(BaseModel):
    """Modelo para requisição de registro"""
    email: str
    nome: str
    senha: str
    codigoOtp: str

class DadosOtp(BaseModel):
    """Modelo para requisição de OTP"""
    email: str

class VerificacaoOtp(BaseModel):
    """Modelo para verificação de OTP"""
    email: str
    codigo: str

class RespostaLogin(BaseModel):
    """Modelo de resposta para login"""
    status: bool
    mensagem: str
    token: str = None
    usuario: dict = None

class RespostaOtp(BaseModel):
    """Modelo de resposta para OTP"""
    status: bool
    mensagem: str
    expira_em: str = None

usuarios_database = {}
otps_temporarios = {}
tentativas_login = {}

MAX_TENTATIVAS_LOGIN = 5
TEMPO_BLOQUEIO_MINUTOS = 15

def gerar_codigo_otp(comprimento=6):
    """Gera um código OTP aleatório"""
    return ''.join(random.choices(string.digits, k=comprimento))

def verificar_bloqueio_brute_force(email: str) -> bool:
    """Verifica se o e-mail está bloqueado por tentativas"""
    if email not in tentativas_login:
        return False
    
    info = tentativas_login[email]
    if info['bloqueado_ate'] and datetime.now() < info['bloqueado_ate']:
        return True
    
    if info['bloqueado_ate'] and datetime.now() >= info['bloqueado_ate']:
        tentativas_login[email] = {"tentativas": 0, "bloqueado_ate": None}
        return False
    
    return False

def registrar_tentativa_falha(email: str):
    """Registra uma tentativa de login falha"""
    if email not in tentativas_login:
        tentativas_login[email] = {"tentativas": 0, "bloqueado_ate": None}
    
    tentativas_login[email]['tentativas'] += 1
    
    if tentativas_login[email]['tentativas'] >= MAX_TENTATIVAS_LOGIN:
        tentativas_login[email]['bloqueado_ate'] = datetime.now() + timedelta(
            minutes=TEMPO_BLOQUEIO_MINUTOS
        )

def limpar_tentativas(email: str):
    """Limpa as tentativas de login"""
    if email in tentativas_login:
        tentativas_login[email] = {"tentativas": 0, "bloqueado_ate": None}

def monta_rotas_autenticacao(app: FastAPI):
    """
    Monta as rotas de autenticação no app FastAPI
    
    Rotas implementadas:
    - POST /registrar
    - POST /login
    - POST /enviar-otp
    - POST /verificar-otp
    """
    
    @app.post("/registrar", response_model=RespostaLogin)
    async def registrar_usuario(dados: DadosRegistro):
        """Registra um novo usuário após verificação de OTP"""
        if dados.email in usuarios_database:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="E-mail já cadastrado"
            )
        
        if dados.email not in otps_temporarios:
            return RespostaLogin(
                status=False,
                mensagem="Nenhum OTP enviado para este e-mail"
            )
        
        otp_info = otps_temporarios[dados.email]
        
        if datetime.now() > otp_info['expira_em']:
            del otps_temporarios[dados.email]
            return RespostaLogin(
                status=False,
                mensagem="Código OTP expirado"
            )
        
        if dados.codigoOtp != otp_info['codigo']:
            return RespostaLogin(
                status=False,
                mensagem="Código OTP inválido"
            )
        
        usuario_novo = {
            "id": len(usuarios_database) + 1,
            "email": dados.email,
            "nome": dados.nome,
            "senha": dados.senha,
            "dataCadastro": datetime.now().isoformat(),
        }
        
        usuarios_database[dados.email] = usuario_novo
        del otps_temporarios[dados.email]
        token_mock = f"token_jwt_{usuario_novo['id']}_{datetime.now().timestamp()}"
        
        return RespostaLogin(
            status=True,
            mensagem="Usuário registrado com sucesso",
            token=token_mock,
            usuario={
                "id": usuario_novo['id'],
                "email": usuario_novo['email'],
                "nome": usuario_novo['nome'],
            }
        )

    @app.post("/login", response_model=RespostaLogin)
    async def fazer_login(dados: DadosLogin):
        """Realiza o login do usuário com validação de brute force"""
        if verificar_bloqueio_brute_force(dados.email):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Muitas tentativas. Bloqueado por {TEMPO_BLOQUEIO_MINUTOS} minutos"
            )
        
        if dados.email not in usuarios_database:
            registrar_tentativa_falha(dados.email)
            return RespostaLogin(
                status=False,
                mensagem="E-mail ou senha incorretos"
            )
        
        usuario = usuarios_database[dados.email]
        if usuario['senha'] != dados.senha:
            registrar_tentativa_falha(dados.email)
            return RespostaLogin(
                status=False,
                mensagem="E-mail ou senha incorretos"
            )
        limpar_tentativas(dados.email)
        token_mock = f"token_jwt_{usuario['id']}_{datetime.now().timestamp()}"
        return RespostaLogin(
            status=True,
            mensagem="Login realizado com sucesso",
            token=token_mock,
            usuario={
                "id": usuario['id'],
                "email": usuario['email'],
                "nome": usuario['nome'],
            }
        )

    @app.post("/enviar-otp", response_model=RespostaOtp)
    async def enviar_otp(dados: DadosOtp):
        """Envia um código OTP para o e-mail fornecido"""
        codigo_otp = gerar_codigo_otp()
        expira_em = datetime.now() + timedelta(minutes=2.17)
        otps_temporarios[dados.email] = {
            "codigo": codigo_otp,
            "expira_em": expira_em
        }
        print(f"[SIMULAÇÃO] OTP para {dados.email}: {codigo_otp}")
        return RespostaOtp(
            status=True,
            mensagem="Código OTP enviado com sucesso",
            expira_em=expira_em.isoformat()
        )

    @app.post("/verificar-otp")
    async def verificar_otp(dados: VerificacaoOtp):
        """Verifica se o código OTP é válido"""
        if dados.email not in otps_temporarios:
            return {
                "status": False,
                "mensagem": "Nenhum OTP enviado para este e-mail"
            }
        
        otp_info = otps_temporarios[dados.email]
        
        if datetime.now() > otp_info['expira_em']:
            del otps_temporarios[dados.email]
            return {
                "status": False,
                "mensagem": "Código OTP expirado"
            }
        
        if dados.codigo != otp_info['codigo']:
            return {
                "status": False,
                "mensagem": "Código OTP inválido"
            }
        
        return {
            "status": True,
            "mensagem": "Código OTP verificado com sucesso"
        }
    
    
app = FastAPI()
monta_rotas_autenticacao(app)
