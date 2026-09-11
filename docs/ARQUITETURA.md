# Arquitetura do LeadSystem

O projeto usa um único código Flutter para Android e iOS. A aplicação está organizada em quatro partes:

1. `lib/screens`: telas e fluxos do cliente e do administrador.
2. `lib/core`: tema visual, regras de negócio e estado persistente.
3. `lib/models`: modelos de domínio serializáveis e catálogo editável.
4. `server`: API Node.js preparada para MongoDB.

## Estado atual

O aplicativo funciona em modo offline-first. Carrinho, cupom, login, sessão, pedidos, orçamentos, chat, perfil e cadastros administrativos são serializados em JSON e persistidos com `shared_preferences`. Isso permite apresentar fluxos completos sem depender de internet e preserva as alterações entre execuções.

A API contém as rotas iniciais de saúde, produtos, login, pedidos e orçamentos. Quando `MONGODB_URI` estiver configurada, o servidor tenta estabelecer a conexão; sem banco disponível, permanece em modo de demonstração.

## Próximas camadas

- Criar coleções e modelos MongoDB para usuários, produtos, pedidos, orçamentos e mensagens.
- Introduzir repositórios HTTP mantendo o armazenamento local como cache e fallback offline.
- Implementar autenticação JWT e armazenamento seguro do token.
- Adicionar testes de integração e pipeline de build.
- Configurar notificações e publicação nas lojas.
