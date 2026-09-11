# Rastreabilidade dos requisitos funcionais

| Requisito | Escopo | Estado desta versão |
|---|---|---|
| RF01 | Cadastro de usuários | Implementado localmente com validação |
| RF02 | Autenticação | Implementado localmente com credenciais validadas e sessão persistente |
| RF03 | Recuperação de senha | Implementado localmente com validação e redefinição |
| RF04 | Consulta de produtos | Implementado com busca e categorias |
| RF05 | Detalhamento de produtos | Implementado |
| RF06 | Carrinho | Implementado |
| RF07 | Cupons | Implementado para `PRIMEIRACOMPRA` |
| RF08 | Finalização de compra | Implementado com validação, endereço, pagamento, baixa de estoque e pedido persistente |
| RF09 | Solicitação de orçamento | Implementado com formulário validado, protocolo e histórico persistente |
| RF10 | Histórico de pedidos | Implementado com dados locais persistentes e rastreamento dinâmico |
| RF11 | Chat de atendimento | Implementado com pesquisa de ajuda, chamados e resposta automática local |
| RF12 | Gerenciamento de produtos | Implementado com cadastro, edição, ativação, exclusão e estoque |
| RF13 | Gerenciamento de categorias | Implementado com cadastro, renomeação e exclusão segura |
| RF14 | Gerenciamento de usuários | Implementado com consulta, perfil de acesso e bloqueio |
| RF15 | Gerenciamento de pedidos | Implementado com filtros, detalhes, status e histórico |
| RF16 | Gerenciamento de orçamentos | Implementado com análise, resposta e mudança de status |
| RF17 | Gerenciamento de cupons | Implementado com cadastro, validade, limite e ativação |
| RF18 | Automação de comunicação | Planejado para a integração do backend |

Os requisitos acima funcionam offline e persistem no aparelho. A sincronização com a API e o MongoDB continua planejada para uma etapa posterior, sem impedir a demonstração completa do aplicativo.
