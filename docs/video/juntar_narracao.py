"""Junta a narração gravada ao vídeo de demonstração sem áudio.

Uso: python juntar_narracao.py <ffmpeg.exe> <video.mp4> <narracao.m4a> <saida.mp4> [atraso_s]
atraso_s: segundos para atrasar (positivo) ou adiantar (negativo) a voz em relação ao vídeo.
A voz passa por corte de graves abaixo de 80 Hz, compressão leve e normalização de volume (-16 LUFS).
"""
import subprocess
import sys


def main():
    ffmpeg, video, voz, saida = sys.argv[1:5]
    atraso = float(sys.argv[5]) if len(sys.argv) > 5 else 0.0
    entrada_voz = ['-itsoffset', str(atraso), '-i', voz] if atraso > 0 else ['-ss', str(-atraso), '-i', voz] if atraso < 0 else ['-i', voz]
    # sem redutor de ruído: o gravador do Windows já entrega o silêncio a cerca de -90 dB
    filtro = ('[1:a]highpass=f=80,acompressor=threshold=-20dB:ratio=3:attack=5:release=200,'
              'loudnorm=I=-16:TP=-1.5:LRA=11,aresample=48000,apad[a]')  # apad + -shortest: o vídeo define a duração
    cmd = [ffmpeg, '-hide_banner', '-loglevel', 'error', '-y', '-i', video, *entrada_voz,
           '-filter_complex', filtro, '-map', '0:v', '-map', '[a]',
           '-c:v', 'copy', '-c:a', 'aac', '-b:a', '160k', '-shortest', '-movflags', '+faststart', saida]
    subprocess.run(cmd, check=True)
    print('ok:', saida)


if __name__ == '__main__':
    main()
