# Arquitetura do LeadSystem

O projeto usa um único código Flutter para Android e iOS. A aplicação está organizada em quatro partes:

1. `lib/screens`: telas e fluxos do cliente e do administrador.
2. `lib/core`: tema visual e estado compartilhado da demonstração.
3. `lib/models`: modelos de domínio e dados temporários do catálogo.
4. `server`: API Node.js preparada para MongoDB.

## Estado atual

O aplicativo funciona em modo de demonstração local. Carrinho, cupom, login, checkout, pedido, orçamento e chat mantêm os dados em memória durante a execução. Isso permite apresentar todos os fluxos sem depender de internet.

A API contém as rotas iniciais de saúde, produtos, login, pedidos e orçamentos. Quando `MONGODB_URI` estiver configurada, o servidor tenta estabelecer a conexão; sem banco disponível, permanece em modo de demonstração.

## Próximas camadas

- Criar coleções e modelos MongoDB para usuários, produtos, pedidos, orçamentos e mensagens.
- Substituir os dados locais do Flutter por repositórios HTTP.
- Implementar autenticação JWT e armazenamento seguro do token.
- Adicionar testes de integração e pipeline de build.
- Configurar notificações e publicação nas lojas.
