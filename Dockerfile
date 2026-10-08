# em containers, a gente só vai hospedar a aplicação, temos que otimizar, rodar o container de forma otimizada
# para nao ter lixo dentro do container. É aí que entra o multi stage build
FROM node:20-alpine AS bulder

WORKDIR /app

COPY package*.json ./

RUN npm ci --silent

RUN npm run build

#Remove as devDependencies da pasta node_modules antes de copiar para o runner
RUN npm prune --production

FROM node:20-alpine AS runner

WORKDIR /app

# Copia apenas os arquivos essenciais e o node_modules já limpo (apenas com prod dependencies)
COPY --from=bulder --chown=nodejs: app/package*.json ./
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/app ./app

ENV NODE_ENV=production

USER nodejs

ENV PORT 80
EXPOSE 80

CMD ["node", "app/server.js"]