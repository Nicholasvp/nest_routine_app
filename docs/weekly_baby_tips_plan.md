# Plano: dicas semanais para o bebê

**Status:** MVP implementado localmente; SQL preparado para aplicação manual no Supabase.
**Pesquisa inicial:** 14 de outubro de 2026.

## Objetivo

Adicionar uma aba com sugestões curtas para a família, relacionadas à idade do bebê: brincadeiras, tummy time, movimentos, comunicação e saúde oral. A aba deve inspirar atividades seguras e ajudar a família a acompanhar o desenvolvimento, sem apresentar uma habilidade como prazo obrigatório.

## Proposta de experiência

- Adicionar uma aba **Dicas** à navegação principal.
- Mostrar a semana de vida calculada a partir da data de nascimento e um pequeno conjunto de dicas aplicáveis àquela semana.
- Cada dica pode ter título, explicação curta, uma atividade simples e uma categoria. Links de fonte ficam acessíveis em “Saiba mais”.
- Apresentar o conteúdo em português e inglês, seguindo o idioma selecionado no app.
- Se não houver conexão ou conteúdo disponível, mostrar uma mensagem de estado vazio e tentar novamente depois; não bloquear as outras abas.
- Incluir uma nota discreta: o desenvolvimento varia entre bebês; as dicas são educativas e não substituem orientação de um profissional de saúde.

## Idade e apresentação

Convenção sugerida para a primeira versão: semana 1 corresponde aos dias de vida 0–6; semana 2, aos dias 7–13, e assim por diante. Uma dica pode cobrir uma faixa de semanas, mesmo que a tela indique a semana atual. Isso evita sugerir uma precisão que as fontes não dão.

O CDC orienta usar idade corrigida em suas listas de marcos quando o bebê nasceu mais de três semanas antes do previsto. Como o perfil atual guarda a data de nascimento, mas não a idade gestacional, precisamos decidir antes da implementação:

1. **Mais simples:** mostrar sugestões gerais por idade cronológica, sem afirmar que o bebê “deveria” ter adquirido um marco; incluir orientação para conversar com um profissional sobre idade corrigida em caso de prematuridade.
2. **Mais personalizado:** adicionar ao perfil um campo opcional de semanas de gestação ao nascer e calcular idade corrigida quando aplicável.

Sugestão para o MVP: opção 1, a menos que se queira incluir a pergunta opcional de prematuridade já nesta entrega.

## Conteúdo e pesquisa

Proposta de escopo inicial: primeiro ano de vida, com uma dica principal por semana e assuntos organizados por faixas de idade baseadas nas fontes. As 52 entradas não devem ser 52 previsões de marcos: podem incluir atividades repetíveis e temas de cuidado em momentos adequados.

Categorias sugeridas:

- Brincar e movimento
- Comunicação e sentidos
- Saúde oral e dentição
- Segurança
- Bem-estar de quem cuida

Cuidados editoriais:

- Escrever atividades como convites (“você pode experimentar”), não como metas de desempenho.
- Distinguir atividade de marco de desenvolvimento.
- Incluir supervisão e condição de estar acordado em dicas de tummy time.
- Não tratar febre alta ou diarreia como sintomas comuns de dentição; o NHS diz que não há evidência de que dentição cause diarreia.
- Evitar diagnóstico, tratamento, dose de medicamento, cronogramas de alimentação ou afirmações de que uma criança está atrasada.
- Revisar as fontes antes de publicar e registrar a data da revisão.

## Fontes consultadas

- [OMS — diretrizes de atividade, sedentarismo e sono para menores de 5 anos](https://www.who.int/EN/news-room/detail/24-04-2019-to-grow-up-healthy-children-need-to-sit-less-and-play-more): para bebês que ainda não são móveis, recomenda pelo menos 30 minutos de tummy time distribuídos ao longo do dia, enquanto acordados.
- [NHS — como manter bebês ativos](https://www.nhs.uk/baby/babys-development/play-and-learning/keep-baby-or-toddler-active/): tummy time pode começar desde o nascimento; começar com períodos curtos, somente com o bebê acordado e sob supervisão.
- [CDC — marcos aos 6 meses](https://www.cdc.gov/act-early/milestones/6-months.html): rolar da barriga para as costas está entre os marcos que a maioria (75% ou mais) já alcança até essa idade; a página recomenda conversar com o médico quando houver preocupações e esclarece que a lista não substitui triagem validada.
- [CDC — checklist de 6 meses](https://www.cdc.gov/act-early/digital-online-checklist/6-months.html): entre duas idades de checklist, usar a mais nova; para bebês nascidos mais de três semanas prematuros, usar idade corrigida.
- [NHS — sintomas da dentição](https://www.nhs.uk/conditions/baby/babys-development/teething/baby-teething-symptoms/): a dentição varia bastante; a maioria começa por volta dos 6 meses, mas pode começar antes dos 4 meses ou depois dos 12.
- [AAP / HealthyChildren — sono seguro](https://www.healthychildren.org/English/ages-stages/baby/sleep/pages/a-parents-guide-to-safe-sleep.aspx): colocar o bebê de costas para dormir e parar de enfaixar quando começar a tentar rolar. Usar esta fonte em dicas relacionadas a rolar e sono.

## Modelo proposto no Supabase

Criar `baby_tips` em um script versionado, provavelmente `supabase/006_baby_tips.sql`, com:

| Campo | Uso |
| --- | --- |
| `id` | Chave primária |
| `slug` | Identificador estável para atualizações e upsert |
| `min_week`, `max_week` | Faixa de semanas em que a dica pode aparecer |
| `category` | Categoria da dica |
| `content_en`, `content_pt` | JSONB com `title`, `body` e `activity` opcional |
| `source_name`, `source_url` | Referência editorial |
| `reviewed_at` | Data da revisão de conteúdo |
| `sort_order`, `is_active` | Ordenação e publicação |
| `created_at`, `updated_at` | Auditoria básica |

Restringir `min_week` e `max_week` a uma faixa válida e garantir `min_week <= max_week`. `slug` deve ser único. O app só precisa de leitura das dicas ativas; nenhuma política de escrita deve ser dada aos clientes anônimos ou autenticados. O conteúdo será inserido pelo SQL Editor ou por migration com privilégios administrativos.

## SQL de carga

O script `supabase/006_baby_tips.sql` é idempotente: cria a tabela e o índice, habilita RLS, concede leitura aos clientes para dicas ativas e faz upsert das 52 entradas pelo `slug`. Execute-o no SQL Editor do Supabase para publicar os dados. Ele ainda não foi executado remotamente.

## Decisões adotadas para o MVP

- Conteúdo para as primeiras 52 semanas; a aba informa quando o bebê já passou do primeiro aniversário.
- Uma sugestão por semana, em português e inglês, selecionada pela semana de vida.
- Idade cronológica no MVP, com texto educativo sem tratar marcos como prazos individuais.
- A aba Dicas foi adicionada como quinta aba da navegação inferior.
- A leitura usa `baby_tips`; `supabase/006_baby_tips.sql` cria a tabela e insere/atualiza as dicas.
- O script SQL ainda precisa ser aplicado manualmente no SQL Editor do Supabase para a tela carregar conteúdo.

## Arquivos entregues

- `lib/models/baby_tip.dart`: modelo localizado.
- `lib/services/baby_tips_service.dart`: consulta de dicas ativas para a semana atual.
- `lib/screens/tips_screen.dart`: tela com estados sem perfil, carregamento, erro, vazio e conteúdo.
- `lib/main.dart` e `lib/services/navigation_service.dart`: integração como quinta aba.
- `lib/utils/strings.dart`: rótulos em português e inglês.
- `supabase/006_baby_tips.sql`: tabela, política somente leitura para clientes e 52 dicas bilíngues.

O SQL foi preparado localmente e não foi executado no projeto Supabase. A tela não deve receber dados até que o script seja aplicado.

## Revisão após aplicação

- Confirmar se uma sugestão por semana atende à experiência desejada.
- Considerar idade gestacional e idade corrigida em uma melhoria futura, caso os perfis passem a armazenar esses dados.
- Aplicar `supabase/006_baby_tips.sql` no Supabase e conferir a leitura na aba Dicas.
