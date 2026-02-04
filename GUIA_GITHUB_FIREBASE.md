# 🚀 Configuração GitHub + Firebase Hosting

**Data**: 2026-02-03 23:25  
**Status**: Repositório Git local criado ✅

---

## ✅ JÁ FEITO

1. ✅ Git inicializado
2. ✅ Primeiro commit criado (156 arquivos)
3. ✅ Branch `main` criada
4. ✅ Branch `develop` criada e ativa
5. ✅ Contatos atualizados na landing page:
   - WhatsApp: (99) 98453-2007
   - Email: dimme.spa@gmail.com

---

## 🔧 PRÓXIMOS PASSOS (FAÇA AGORA)

### 1. Criar Repositório no GitHub

```bash
# 1. Abra o navegador e vá para:
https://github.com/new

# 2. Preencher:
Repository name: sushigen
Description: Sistema de gestão completo para restaurantes de sushi
Visibility: Private (recomendado) ou Public

# 3. NÃO marcar:
❌ Add a README file
❌ Add .gitignore
❌ Choose a license

# 4. Clicar em "Create repository"

# 5. GitHub vai mostrar comandos. IGNORE e use os abaixo:
```

### 2. Conectar Repositório Local ao GitHub

```bash
# No terminal (copie e cole):
cd /Users/dimmesheldon/sushigen

# Adicionar remote (SUBSTITUA seu-usuario pelo seu username do GitHub)
git remote add origin https://github.com/seu-usuario/sushigen.git

# Verificar remote
git remote -v

# Push da branch main
git push -u origin main

# Push da branch develop
git push -u origin develop
```

**Exemplo com seu username**:
Se seu GitHub for `@dimmesheldon`, seria:
```bash
git remote add origin https://github.com/dimmesheldon/sushigen.git
```

### 3. Verificar no GitHub

```bash
# Abra no navegador:
https://github.com/seu-usuario/sushigen

# Você deve ver:
✅ 156 arquivos
✅ 2 branches (main e develop)
✅ Branch develop como padrão
```

---

## 🔥 Workflow Git (Para Futuras Mudanças)

### Fazer mudanças:
```bash
# 1. Garantir que está na develop
git checkout develop

# 2. Fazer mudanças nos arquivos...

# 3. Adicionar ao staging
git add .

# 4. Commit
git commit -m "feat: descrição da mudança"

# 5. Push para develop
git push origin develop
```

### Fazer release (produção):
```bash
# 1. Ir para main
git checkout main

# 2. Merge da develop
git merge develop

# 3. Push para main
git push origin main

# 4. Voltar para develop
git checkout develop
```

---

## 🌐 Firebase Hosting (DEPOIS DO GITHUB)

### 1. Verificar se Firebase está logado
```bash
firebase login
```

### 2. Configurar Hosting
```bash
cd /Users/dimmesheldon/sushigen

# Inicializar hosting
firebase init hosting

# Responder:
? What do you want to use as your public directory? → website
? Configure as a single-page app (rewrite all urls to /index.html)? → No
? Set up automatic builds and deploys with GitHub? → Yes
? File website/index.html already exists. Overwrite? → No
```

### 3. Configurar GitHub Actions (Auto-deploy)
```bash
# Firebase vai perguntar:
? For which GitHub repository would you like to set up a GitHub workflow? → seu-usuario/sushigen
? Set up the workflow to run a build script before every deploy? → No
? Set up automatic deployment to your site's live channel when a PR is merged? → Yes
? What is the name of the GitHub branch associated with your site's live channel? → main
```

### 4. Deploy Manual (Primeira vez)
```bash
# Deploy para produção
firebase deploy --only hosting

# Firebase vai retornar:
✅ Hosting URL: https://sushigen-xxxxx.web.app
✅ Console URL: https://console.firebase.google.com/...
```

### 5. Ver Site Online
```bash
# Abrir no navegador
open https://sushigen-xxxxx.web.app
```

---

## 📊 Resultado Final

### Repositório GitHub:
```
https://github.com/seu-usuario/sushigen
├── Branch: main (produção)
└── Branch: develop (desenvolvimento)
```

### Site Online:
```
https://sushigen-xxxxx.web.app (Firebase Hosting)
├── WhatsApp: (99) 98453-2007
├── Email: dimme.spa@gmail.com
└── Gratuito! (Firebase Free Tier)
```

### Auto-Deploy:
```
Quando fizer push na main:
→ GitHub Actions detecta
→ Build automático
→ Deploy no Firebase
→ Site atualizado em 2-3 minutos
```

---

## 🎯 ORDEM DE EXECUÇÃO

**AGORA** (5 min):
1. ✅ Criar repositório no GitHub
2. ✅ git remote add origin
3. ✅ git push -u origin main
4. ✅ git push -u origin develop
5. ✅ Verificar no GitHub

**DEPOIS** (5 min):
6. ✅ firebase login
7. ✅ firebase init hosting
8. ✅ firebase deploy --only hosting
9. ✅ Abrir site online
10. ✅ Comemorar! 🎉

---

## 🆘 TROUBLESHOOTING

### Erro: "remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/seu-usuario/sushigen.git
```

### Erro: "Permission denied" no GitHub
```bash
# Usar token pessoal ou SSH
# Gerar token em: https://github.com/settings/tokens
```

### Erro: Firebase CLI não instalado
```bash
npm install -g firebase-tools
```

### Erro: "Not logged in to Firebase"
```bash
firebase logout
firebase login
```

---

**Status Atual**: ✅ Repositório Git local pronto  
**Próximo Passo**: Criar repositório no GitHub (5 min)  
**Depois**: Configurar Firebase Hosting (5 min)  

**Total**: 10 minutos para site no ar! 🚀
