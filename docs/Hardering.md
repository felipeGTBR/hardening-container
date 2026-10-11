# 1. Problemas encontrados

•  Imagem base com tag flutuante e genérica
•  Senha do banco fixa dentro da imagem
•  Container executando como root
•  Cópia de todo o contexto para a imagem
•  Instalação de pacotes sem boas práticas
•  Build em estágio único

# 2. Medidas aplicadas

•  Troca da imagem base por node:20-alpine
•  Multi-stage build
•  Uso de npm ci e cópia do package*.json antes do •  código
•  Cópia seletiva de arquivos com COPY --from e --chown
•  Remoção da senha do Dockerfile e uso de variáveis em tempo de execução

# 3. Análise final

## 3.1 Qual era o principal risco encontrado no projeto?
O principal risco era a exposição de credenciais combinada com acesso direto ao banco. A senha 123456 estava gravada na imagem, a senha root do MySQL era root e estava em texto puro no Compose, e a porta 3306 estava publicada no host. Juntos, esses três fatores permitiam que um atacante obtivesse acesso total aos dados com pouquíssimo esforço, seja lendo as credenciais na imagem/repositório, seja atacando a porta do banco diretamente.

## 3.2 Qual alteração de hardening foi mais importante? Por quê?
retirar os segredos do código e das imagens (uso de .env fora do Git) e deixar de expor o banco, usando um usuário dedicado de menor privilégio. Ela ataca diretamente o risco principal: mesmo que a imagem vaze ou o repositório seja acessado, não há credenciais a serem aproveitadas, e o banco não é alcançável de fora.

## 3.3 O que poderia acontecer caso o container da aplicação fosse comprometido?
O atacante poderia:
• ler variáveis de ambiente e obter a senha do banco;
• conectar ao MySQL como root, ler, alterar ou apagar todos os dados;
• instalar ferramentas e ampliar o ataque dentro da rede Docker;
• tentar escapar do container para o host, aproveitando privilégios de root e ausência de restrições;
• consumir CPU e memória do host (negação de serviço).

## 3.4 Como o princípio do menor privilégio foi aplicado?
• Usuário do sistema: a aplicação roda como nodejs (UID 1001), e não como root.
• Recursos: limites de memória, CPU e processos.

## 3.5 Por que o .env não deve ser enviado para o repositório?
 Pois ele contém segredos reais da aplicação e uma vez que tenha ido para o repositório, o versionamento preserva o arquivo mesmo depois de apagado

 ## 3.6 Qual a função do.env.example?
 é um modelo documentado do .env. Ele lista todas as variáveis que a aplicação e o Compose esperam, mas sem valores sensíveis (vazios ou fictícios). Assim, quem clonar o projeto sabe exatamente o que precisa configurar (basta copiar para .env e preencher), sem expor segredos.

 ## 3.7 Como o projeto poderia receber novas verificações de segurança automaticamente em uma pipeline CI/CD?
 poderia executar, a cada push ou pull request, etapas automáticas que bloqueiam o merge quando encontram falhas

## 3.8 Quais medidas adicionais poderiam ser aplicadas caso essa aplicação fosse executada em Kubernetes?
 • Requests e limits de recursos: ResourceQuota e LimitRange por namespace.
 • TLS e Ingress: HTTPS obrigatório (cert-manager), com WAF/rate limit quando possível.
 • Observabilidade e detecção em runtime: logs centralizados, auditoria do cluster e Falco para detectar comportamento anômalo.
