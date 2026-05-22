# nexticket--modelo-c4

Arquitetura de Software NexTicket — Modelo C4

Visão geral
-
Projeto de modelo arquitetural (C4) para a plataforma NexTicket, uma solução fictícia de venda de ingressos online para shows e eventos. O repositório contém descrições em Structurizr DSL e um diagrama de sequência em PlantUML que ilustram o fluxo de reserva e compra.

Arquivos principais
- [nexTicket.DSL](nexTicket.DSL) — Definição da arquitetura em Structurizr DSL (model, views, styles).
- [sequenceBooking.plantUML](sequenceBooking.plantUML) — Diagrama de sequência mostrando o fluxo de reserva, pagamento e compensação via TTL.

Como gerar os diagramas
- Gerar PlantUML (requer PlantUML e Graphviz):

```bash
# usando o jar do PlantUML
# baixe o plantuml.jar e execute (assumindo que está no diretório do projeto)
java -jar plantuml.jar sequenceBooking.plantUML

# ou usando docker
docker run --rm -v "$PWD":/workspace plantuml/plantuml sequenceBooking.plantUML
```

- Renderizar Structurizr DSL:

Opções comuns:

1) Usar o Structurizr DSL CLI / structurizr-cli (jar) para exportar para PlantUML ou imagens. Exemplo genérico:

```bash
# exemplo genérico — ajuste conforme sua instalação do structurizr-cli
java -jar structurizr-cli.jar export -workspace nexTicket.DSL -format plantuml -output .
```

2) Colar o conteúdo de [nexTicket.DSL](nexTicket.DSL) em um editor/visualizador online do Structurizr DSL ou usar a aplicação Structurizr local (quando disponível).

Notas de uso
- O arquivo `nexTicket.DSL` segue o padrão do Structurizr DSL e contém modelos, containers e componentes organizados por grupos (Kubernetes Cluster) e estilos para visualização.
- O diagrama de sequência (`sequenceBooking.plantUML`) descreve o fluxo crítico de hold/reserva em Redis com TTL, processamento de pagamento e compensação automática.

Contribuição
- Abra uma issue para discutir alterações ou envie um pull request com descrições claras das modificações.

Contato
- Autor / mantenedor: veja o histórico do repositório para identificar o responsável.

Próximos passos sugeridos
- Adicionar scripts para geração automática dos diagramas e um `Makefile` ou `scripts/` com comandos prontos.

