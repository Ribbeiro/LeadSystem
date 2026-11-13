# Mapeamento do site SantiGrill

Fonte: https://www.santigrill.com.br/  
Coletado em: 2026-11-11  
Método: sitemap.xml + páginas HTML + API pública Tray (/web_api/products, /web_api/products/{id}, /web_api/products/variants)  
Dados estruturados: `assets/data/santigrill.json`. Imagens: `assets/images/products/` e `assets/images/brand/logo.png`.

## Empresa

| Campo | Valor |
|---|---|
| Nome | SantiGrill |
| Razão social | INDUSTRIA MECANICA SANTI LTDA |
| CNPJ | 44.048.395/0001-78 |
| Slogan | Churrasqueiras Práticas (lido da logo) |
| Sobre | não disponível (página /empresa vazia) |
| Endereço | Rua Caiapós (sem número) – Santo André/SP – CEP 09195-510 |
| Telefones | (11) 4453-6755, (11) 98827-7030, (11) 4451-3033 |
| WhatsApp | (11) 98827-7030 |
| E-mails | assistencia@santigrill.com.br, vendas@santigrill.com.br |
| Facebook | https://www.facebook.com/churrasqueirassantigrill |
| Horário | Segunda a sexta - 7:30 às 17:30 (a página de trocas informa 8:00 às 16:30) |
| Plataforma | Tray (loja 720158) |

## Marca

| Token | Hex |
|---|---|
| primaria | `#d10d0d` |
| primariaHover | `#d10d0d` |
| topo | `#d81919` |
| secundaria | `#000000` |
| terciaria | `#3ed527` |
| terciariaHover | `#38c223` |
| destaque | `#d18a0d` |
| titulo | `#585663` |
| texto | `#575663` |
| rodape | `#ededef` |
| cinza | `#aaaaad` |
| gradiente | `#605f6d` |
| menu | `#ffffff` |
| textoClaro | `#f0f0f4` |
| fundoLogo | `#d91819` |

Fontes: Open Sans, Open Sans Condensed, Arial, Helvetica, sans-serif. main.min.css: body{font-family:'Open Sans',Arial,Helvetica,sans-serif}; HTML referencia 'Open Sans Condensed'; ícones usam a fonte 'theme-tray'.

Logo: `assets/images/brand/logo.png` (origem https://images.tcdn.com.br/img/img_prod/720158/1565721571_santi_grill_novo.jpg; JPG sem transparência convertido para PNG).

## Categorias

| id | Nome | Pai | Produtos | URL |
|---|---|---|---|---|
| grill-giratorio | Grill Giratório | — | 8 | https://www.santigrill.com.br/grill-giratorio |
| grelhas | Grelhas | — | 7 | https://www.santigrill.com.br/grelhas |
| grelhas-parrilheira | Parrilheira | grelhas | 3 | https://www.santigrill.com.br/grelhas/parrilheira |
| grelhas-moeda | Moeda | grelhas | 3 | https://www.santigrill.com.br/grelhas/moeda |
| churrasqueira | Churrasqueira | — | 5 | https://www.santigrill.com.br/churrasqueira |
| espetos | Espetos | — | 5 | https://www.santigrill.com.br/espetos |

Contagem inclui produtos ligados por categoria relacionada (as subcategorias Parrilheira/Moeda são atribuídas dessa forma).

## Produtos (24)

| id | Nome | Categoria | Preço | Pix à vista | 12x | Variações | Garantia |
|---|---|---|---|---|---|---|---|
| churrasqueira-giratoria-e-rotatoria-eletrica-3-espetos | Grill giratório e rotatório elétrico 3 espetos | Grill Giratório | R$ 467,00 | R$ 452,99 | R$ 48,21 | Voltagem: Bivolt | — |
| churrasqueira-giratoria-e-rotatoria-eletrica-4-espetos | Grill giratório e rotatório elétrico 4 espetos | Grill Giratório | R$ 537,00 | R$ 520,89 | R$ 55,44 | Voltagem: Bivolt | — |
| churrasqueira-giratoria-e-rotatoria-eletrica-5-espetos | Grill giratório e rotatório elétrico 5 espetos | Grill Giratório | R$ 582,00 | R$ 564,54 | R$ 60,08 | Voltagem: Bivolt | — |
| churrasqueira-giratoria-e-rotatoria-eletrica-6-espetos | Grill giratório e rotatório elétrico 6 espetos | Grill Giratório | R$ 611,00 | R$ 592,67 | R$ 63,08 | Voltagem: Bivolt | — |
| churrasqueira-santigrill-modelo-hobby | Churrasqueira Santigrill Modelo Hobby | Churrasqueira | R$ 159,00 | R$ 154,23 | R$ 16,41 | — | — |
| churrasqueira-santigrill-modelo-ventura-tipo-maleta | Churrasqueira Santigrill Modelo Ventura Tipo Maleta | Churrasqueira | R$ 170,00 | R$ 164,90 | R$ 17,55 | — | — |
| grelha-modelo-moeda-100-inox-medida-30x50-cm | Grelha Modelo Moeda 100% Inox Medida 30x50 cm | Grelhas | R$ 128,00 | R$ 124,16 | R$ 13,21 | — | — |
| grelha-modelo-moeda-100-inox-medida-40x50-cm | Grelha Modelo Moeda 100% INOX Medida 40x50 cm | Grelhas | R$ 120,00 | R$ 116,40 | R$ 12,39 | — | — |
| grelha-modelo-moeda-100-inox-medida-50x50-cm | Grelha Modelo Moeda 100% INOX Medida 50x50 cm | Grelhas | R$ 145,00 | R$ 140,65 | R$ 14,97 | — | — |
| grelha-modelo-parrilheira-100-inox-medida-30x50-cm | Grelha Modelo Parrilheira 100% INOX Medida 30x50 cm | Grelhas | R$ 188,00 | R$ 182,36 | R$ 19,41 | — | — |
| grelha-modelo-parrilheira-100-inox-medida-40x50-cm | Grelha Modelo Parrilheira 100% INOX Medida 40x50 cm | Grelhas | R$ 210,00 | R$ 203,70 | R$ 21,68 | — | — |
| grelha-parrilheira-inox-adaptavel-para-qualquer-churrasqueira-30x42-cm | Grelha Parrilheira Inox Adaptável Para Qualquer Churrasqueira 30x42 cm | Grelhas | R$ 145,00 | R$ 140,65 | R$ 14,97 | — | — |
| espeto-grelha-inox-giratorio-peixes-frangos-legumes | Espeto Grelha Inox Giratório Peixes Frangos Legumes | Espetos | R$ 116,00 | R$ 112,52 | R$ 11,98 | — | — |
| espeto-espada-tridente-para-grill-giratorio | ESPETO ESPADA TRIDENTE PARA GRILL GIRATÓRIO | Espetos | R$ 55,00 | R$ 53,35 | R$ 5,68 | — | — |
| grill-giratoriorotatorio-3-espetos-baixo | Grill Giratório/rotatório 3 Espetos Baixo | Grill Giratório | R$ 458,00 | R$ 444,26 | R$ 47,28 | — | 180 dias após o recebimento do produto |
| grill-giratoriorotatorio-4-espetos-baixo | Grill Giratório/rotatório 4 Espetos Baixo | Grill Giratório | R$ 515,00 | R$ 499,55 | R$ 53,17 | — | — |
| grill-giratoriorotatorio-5-espetos-baixo | Grill Giratório/rotatório 5 Espetos Baixo | Grill Giratório | R$ 553,00 | R$ 536,41 | R$ 57,09 | — | — |
| churrasqueira-para-barco-com-grelha-parrilheira | Churrasqueira Para Barco Com Grelha Parrilheira | Churrasqueira | R$ 225,00 | R$ 218,25 | R$ 23,23 | — | 60 dias após o recebimento do produto |
| churrasqueira-santigrill-modelo-hobby-grelha-parrilheira | Churrasqueira Santigrill Modelo Hobby Grelha Parrilheira | Churrasqueira | R$ 161,00 | R$ 156,17 | R$ 16,62 | — | 90 dias após o recebimento do produto |
| grill-giratoriorotatorio-6-espetos-baixo | Grill Giratório/rotatório 6 Espetos Baixo | Grill Giratório | R$ 570,00 | R$ 552,90 | R$ 58,84 | — | 60 dias após o recebimento do produto |
| churrasqueira-versatile | Churrasqueira Versatile | Churrasqueira | R$ 148,00 | R$ 143,56 | R$ 15,28 | — | 90 dias após o recebimento do produto |
| espeto-churrasco-giratorio-eletrico-santigrill | Espeto Churrasco Giratório Elétrico Premium prata Santigrill | Espetos | R$ 137,00 | R$ 132,89 | R$ 14,14 | Voltagem: 127V/220V | 1 ano após o recebimento do produto |
| espeto-giratorio-churrasco-flex-premium-preto-eletrico-santi-grill | Espeto Giratório Churrasco Flex Premium Preto Elétrico Santi Grill | Espetos | R$ 137,00 | R$ 132,89 | R$ 14,14 | — | 1 ano após o recebimento do produto |
| espeto-giratorio-eletrico-std-prata-santigrill | Espeto Giratório Elétrico Std prata Santigrill | Espetos | R$ 129,00 | R$ 125,13 | R$ 13,32 | Voltagem: 127V/220V | — |

Nenhum produto tem preço promocional ativo. Excluído do catálogo: PRODUTO DE TESTE (produto de teste da loja (R$ 1,00, sem imagens)).

## Seções informativas

### Pagamento
Trabalhamos com diversas formas de pagamento.
Assim que finalizar sua compra, você poderá escolher qual a forma que mais lhe agrada. Demais instruções serão passadas após a escolha da forma de pagamento.

- Parcelamento: Até 12x no cartão de crédito com juros (1,99% a.m. via Aura - MoIP, conforme a opção de pagamento de cada produto); home: "em até 12x no cartão".
- Pix: Valor à vista com desconto no Pix (Pix - Vindi); ex.: R$ 467,00 -> R$ 452,99 (cerca de 3%).
- Meios exibidos no rodapé: Aura - MoIP, Boleto - Vindi, Cartão Amex - Vindi, Cartão Diners - Vindi, Cartão Elo - Vindi, Cartão MasterCard - Vindi, Cartão Visa - Vindi, Diners - MoIP, MasterCard - MoIP, Mercado Pago, MoIP, PayPal, Pix - Vindi, Transf. Banco do Brasil, Transf. Bradesco, Transferência Online BB - MoIP, Transferência Online Bradesco - MoIP, Transferência Online Itaú - MoIP, Visa - MoIP

### Entrega
Todos os produtos serão enviados de acordo com a forma escolhida pelo cliente, em até 2 dias úteis da confirmação do pagamento. O prazo para a entrega varia de acordo com a forma de envio escolhida e não é de nossa responsabilidade, ,já que a entrega fica a cargo dos Correios.
Você será informado do código para rastrear sua encomenda através do site dos correios assim que ela for postada.

### Garantia
Todas as garantias são dadas pelos fabricantes, e variam de produto para produto. Elas serão informadas nas páginas de cada produto. Caso tenha alguma dúvida, entre em contato conosco.
Para devoluções, os produtos deverão ser remetidos em suas embalagens originais e caso for constatado mal uso, o custo será por parte do comprador.

### Trocas e devoluções
Troca de produto lacrado e não utilizado em até 7 dias corridos após o recebimento (troca por cupom no mesmo valor); produtos com defeito de fabricação: até 30 dias corridos. Texto completo em `informacoes.trocas.texto`.

### FAQ (extraído da página de trocas)
- Como trocar um produto?
- Quais os prazos para troca ou devolução?
- Como devolver o produto que quero trocar SantiGrill?
- Após solicitada a troca ou devolução, em quanto tempo receberei o meu pedido ou devolução do valor pago?
- Recebi um produto diferente do comprado, o que devo fazer?

### Outros
- Depoimentos: nenhum. Catálogos PDF: nenhum. Cupons: nenhum ativo.

## Pendências

- Página "Empresa" (/empresa) está vazia no site: campo empresa.sobre = null.
- Página "Representantes" (/representantes) está vazia no site.
- Slogan não aparece em texto no site (meta description da home é "-"); empresa.slogan "Churrasqueiras Práticas" foi lido da imagem da logo.
- Endereço sem número, complemento e bairro (o site mostra apenas "Rua Caiapós, Santo André - SP, CEP 09195-510").
- Link do WhatsApp no topo do site está vazio (href=""): apenas o número (11) 98827-7030 está disponível; whatsappUrl = null.
- Somente Facebook encontrado como rede social (https://www.facebook.com/churrasqueirassantigrill). Instagram/YouTube/TikTok não aparecem no site. O widget do Facebook também cita https://www.facebook.com/SouSuporteLOL/ (aparentemente resto de template, ignorado).
- Horário de atendimento divergente: contato/rodapé dizem "segunda a sexta 7:30 às 17:30"; página de trocas diz "8:00 às 16:30".
- Logo oficial só existe em JPG 476x172 (letreiro branco sobre retângulo vermelho #d91819, sem transparência); logo.png foi convertido do JPG, sem canal alfa. Não há SVG nem versão sem fundo.
- Nenhum produto tem preço promocional ativo (promotional_price = 0); dataLayer marca "promotion: YES" para os espetos 129 e 133, mas sem preço promocional informado.
- Peso e dimensões estruturadas (weight/length/width/height) não são publicados pela loja: especificacoes.peso e especificacoes.dimensoes = null; medidas só aparecem em texto livre (especificacoes.medidasDescricao).
- Garantia preenchida apenas em alguns produtos; nos demais especificacoes.garantia = null (página geral diz que varia por produto).
- Estoque (quantidade) não é público; "disponivel" vem do campo available da API pública.
- Variações dos espetos 129 e 133: a API lista uma única variação com Voltagem 127V e 220V no mesmo SKU (mesmo preço); a página do produto exibe apenas "127V" como opção selecionável.
- Sem FAQ dedicada no site: faq foi montado com as perguntas da página "Política de Trocas e Devoluções".
- Sem depoimentos/avaliações (rating count = 0 em todos os produtos).
- Sem catálogos PDF para download.
- Sem cupons ativos ("Nenhum cupom disponível no momento").
- Frete: valores não são públicos (cálculo só no checkout; envio pelos Correios, postagem em até 2 dias úteis).
- API pública de categorias (/web_api/categories) exige token; categorias foram levantadas pelo menu/sitemap/dataLayer.
