"""Monta o vídeo de demonstração do LeadSystem a partir das 3 gravações de tela.

Corta trechos com anúncio de terceiros e dados pessoais (lista de contatos do
WhatsApp, galeria de fotos), acelera cada trecho conforme a tabela e junta na
ordem santi1 -> santi2 -> santi-complemento.

Uso: python montar_video.py <ffmpeg.exe> <pasta_dos_videos> <saida.mp4>
Também grava <saida>.segmentos.txt com o início de cada trecho no vídeo final.
"""
import subprocess
import sys

# (arquivo, início s, fim s, velocidade, descrição)
SEGMENTOS = [
    ('santi1', 0, 20, 1.5, 'Início e tela Servidor e sincronização'),
    ('santi1', 20, 58, 1.5, 'Perfil do administrador, Conta e segurança, sair'),
    ('santi1', 58, 75, 1.5, 'Tela Entrar e início do Criar conta'),
    ('santi1', 75, 132, 2.5, 'Criar conta com erros de validação'),
    ('santi1', 132, 150, 1.5, 'Conta criada: perfil Ana Teste'),
    ('santi1', 150, 195, 2.0, 'Esqueci minha senha: pedido do código'),
    ('santi1', 195, 207, 1.5, 'E-mail com o código'),
    ('santi1', 207, 250, 2.5, 'Nova senha e novo login'),
    ('santi1', 250, 305, 1.5, 'Início, catálogo, busca, filtro e ordenação'),
    ('santi1', 305, 370, 1.5, 'Detalhes do produto e voltagem'),
    ('santi1', 370, 399.0, 2.5, 'Cálculo do frete por CEP'),
    # corte 399,0-415,0: vídeo no YouTube com anúncios de terceiros
    ('santi1', 415.0, 425.6, 1.5, 'Ver no site'),
    # corte 425,6-427,6: lista de contatos pessoais do WhatsApp
    ('santi1', 427.6, 432, 1.5, 'Dúvidas no WhatsApp: mensagem pronta'),
    ('santi1', 432, 462, 2.5, 'Solicitar orçamento'),
    ('santi1', 462, 480, 3.0, 'Orçamento enviado'),
    ('santi1', 480, 500, 1.5, 'Meus pedidos e volta ao catálogo'),
    ('santi1', 500, 550, 2.0, 'Carrinho, cupom e Finalizar compra'),
    ('santi1', 550, 565, 1.5, 'Pedido realizado'),
    ('santi1', 565, 590, 1.5, 'Acompanhar pedido'),
    ('santi1', 590, 602.3, 3.0, 'Meus pedidos'),
    ('santi2', 0, 40, 1.5, 'Fale com a SantiGrill e políticas'),
    ('santi2', 40, 75, 2.0, 'Ajuda: perguntas frequentes e conversa'),
    ('santi2', 75, 92, 1.5, 'Resposta do assistente'),
    ('santi2', 92, 125, 1.5, 'Tema escuro e login do administrador'),
    ('santi2', 125, 170, 1.5, 'Painel: atualizar etapa do pedido'),
    ('santi2', 170, 215, 2.0, 'Painel: responder orçamento'),
    ('santi2', 215, 230.0, 2.0, 'Painel: novo produto'),
    # corte 230,0-238,2: câmera e galeria de fotos pessoal
    ('santi2', 238.2, 245, 2.0, 'Novo produto e lista de produtos'),
    ('santi2', 245, 270, 2.5, 'Sair e entrar como cliente'),
    ('santi2', 270, 296.5, 1.5, 'Cliente vê pedido e orçamento atualizados'),
    ('santi-complemento', 0, 20, 1.25, 'Painel: cupom, campanha e relatórios'),
    ('santi-complemento', 20, 45, 1.5, 'Painel: categorias e usuários'),
    ('santi-complemento', 45, 95, 1.5, 'Endereços, notificações, privacidade e políticas'),
    ('santi-complemento', 95, 105, 1.5, 'Servidor e ajuda: chamado'),
    ('santi-complemento', 105, 135.0, 2.0, 'Compra com cartão'),
    # corte 135,0-137,8: lista de contatos pessoais do WhatsApp
    # termina em 148,6 s: é o último quadro com a tela inicial no topo ("Olá! O que vamos preparar?")
    ('santi-complemento', 137.8, 148.6, 2.0, 'Pedido no WhatsApp e volta ao início'),
]


# segundos com a tela inicial parada no fim: 8 s da frase de encerramento da demonstração
# + 90 s para falar o que mudou desde o vídeo de outubro, a API e o banco de dados
CONGELA_FIM = 98


def main():
    ffmpeg, pasta, saida = sys.argv[1:4]
    arquivos = list(dict.fromkeys(s[0] for s in SEGMENTOS))
    entradas = []
    for a in arquivos:
        entradas += ['-i', f'{pasta}/{a}.mp4']
    filtros, rotulos, linhas, t = [], [], [], 0.0
    for k, (arq, ini, fim, vel, desc) in enumerate(SEGMENTOS):
        i = arquivos.index(arq)
        filtros.append(f'[{i}:v]trim=start={ini}:end={fim},setpts=(PTS-STARTPTS)/{vel},'
                       f'fps=30,scale=576:1280,setsar=1[v{k}]')
        rotulos.append(f'[v{k}]')
        dur = (fim - ini) / vel
        linhas.append(f'{int(t // 60)}:{t % 60:04.1f}  {arq} {ini}-{fim}s x{vel}  {desc}')
        t += dur
    filtros.append(''.join(rotulos) + f'concat=n={len(SEGMENTOS)}:v=1:a=0,'
                   f'tpad=stop_mode=clone:stop_duration={CONGELA_FIM}[out]')
    cmd = [ffmpeg, '-hide_banner', '-loglevel', 'error', '-y', *entradas,
           '-filter_complex', ';'.join(filtros), '-map', '[out]',
           '-c:v', 'libx264', '-preset', 'medium', '-crf', '22', '-pix_fmt', 'yuv420p',
           '-movflags', '+faststart', saida]
    subprocess.run(cmd, check=True)
    linhas.append(f'{int(t // 60)}:{t % 60:04.1f}  imagem final parada por {CONGELA_FIM} s')
    t += CONGELA_FIM
    linhas.append(f'{int(t // 60)}:{t % 60:04.1f}  fim')
    with open(saida + '.segmentos.txt', 'w', encoding='utf-8') as f:
        f.write('\n'.join(linhas) + '\n')
    print('\n'.join(linhas))


if __name__ == '__main__':
    main()
