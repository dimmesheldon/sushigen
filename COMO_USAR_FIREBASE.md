# 🔥 Firebase - Como Usar a Sincronização

## 🎯 Guia Rápido de Uso

### ⚠️ ANTES DE USAR

**IMPORTANTE**: Você precisa criar o Firestore Database primeiro!

1. Acesse: https://console.firebase.google.com/project/sushigen/firestore
2. Clique em **"Criar banco de dados"**
3. Escolha região: **us-central1** (ou São Paulo)
4. Modo: **Teste** (30 dias de acesso aberto)
5. Clique em **"Criar"**

Sem esse passo, a sincronização não funcionará!

---

## 📱 Usando a Sincronização

### 1️⃣ Identificar o Botão

No **Dashboard**, procure no canto superior direito:
- **Ícone**: ☁️ (nuvem)
- **Badge vermelho**: Mostra quantos itens não sincronizados
- **Tooltip**: Ao passar o mouse, mostra "Sincronizar dados"

### 2️⃣ Sincronizar

**Quando sincronizar?**
- Ao final do dia
- Antes de fechar o app
- Quando quiser fazer backup
- Ao trocar de computador

**Como sincronizar?**
1. Clique no botão ☁️
2. Aguarde o loading circular ⚪
3. Veja a mensagem: ✅ "Sincronização concluída com sucesso!"
4. Badge zera (não há mais pendências)

### 3️⃣ Verificar Dados

**No Firebase Console**:
1. Acesse: https://console.firebase.google.com/project/sushigen/firestore
2. Veja as coleções criadas:
   - 📦 **products**: Todos os produtos cadastrados
   - 💰 **sales**: Todas as vendas realizadas
   - 📋 **sale_items**: Itens de cada venda
   - 💸 **cash_flow**: Fluxo de caixa completo

---

## 🖥️ Multi-Computador

### Cenário 1: Dois Macs no Mesmo Restaurante

**Mac 1 (Caixa)**:
1. Faz vendas o dia todo
2. No final do dia: Clique em ☁️
3. Dados vão para a nuvem

**Mac 2 (Gerência)**:
1. Abra o app
2. Clique em ☁️
3. Dados do Mac 1 aparecem automaticamente!

### Cenário 2: Backup e Restauração

**Mac Antigo (antes de trocar)**:
1. Clique em ☁️
2. Aguarde sincronização
3. Dados seguros na nuvem

**Mac Novo (após trocar)**:
1. Instale o app
2. Faça login
3. Clique em ☁️
4. Todos os dados restaurados!

---

## 🔄 Como Funciona

### Upload (Local → Nuvem)
- Produtos não sincronizados
- Vendas não sincronizadas
- Fluxo de caixa não sincronizado

### Download (Nuvem → Local)
- Produtos de outros dispositivos
- Vendas de outros dispositivos
- Fluxo de caixa de outros dispositivos

### Merge Inteligente
- **Conflito**: Dados mais recentes prevalecem
- **Sem sobrescrever**: Não perde dados
- **Automático**: Você não precisa fazer nada

---

## 📊 Estados do Badge

### 🔴 Badge Vermelho com Número
**Significado**: Há X itens não sincronizados  
**Ação**: Clique para sincronizar

### ⚪ Loading Circular
**Significado**: Sincronização em andamento  
**Ação**: Aguarde

### ✅ Badge Desaparece
**Significado**: Tudo sincronizado!  
**Ação**: Nenhuma (está tudo ok)

---

## 🐛 Problemas Comuns

### ❌ "Erro ao sincronizar"

**Causa Provável**: Firestore Database não criado  
**Solução**: Siga a seção "ANTES DE USAR" acima

---

### ❌ Badge não atualiza

**Causa Provável**: Dados não foram criados/editados  
**Solução**: 
1. Crie um produto
2. Faça uma venda
3. Badge deve aparecer com "1" ou "2"

---

### ❌ "Sem conexão com a internet"

**Causa Provável**: Mac offline  
**Solução**: 
- App funciona normalmente offline
- Sincronize quando voltar online

---

### ❌ Dados não aparecem no Firebase Console

**Causa Provável**: 
1. Firestore Database não criado
2. App não sincronizou ainda
3. Sem permissão no Firebase

**Solução**:
1. Crie o database
2. Clique em ☁️ no app
3. Verifique regras de segurança

---

## 🔒 Segurança

### Modo Teste (30 dias)
- ✅ Dados ficam na nuvem
- ✅ Acesso fácil para testes
- ⚠️ Qualquer um pode acessar (se souber a URL)

### Modo Produção (recomendado após teste)
Configure regras no Firestore:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 💡 Dicas

1. **Sincronize regularmente**: Não deixe acumular muitos dados
2. **Verifique o badge**: Sempre que possível, mantenha zerado
3. **Teste com poucos dados**: Antes de usar em produção
4. **Backup manual**: Além do Firebase, exporte o SQLite periodicamente
5. **Monitore o console**: Veja os dados chegando no Firebase

---

## 📚 Links Úteis

- **Firebase Console**: https://console.firebase.google.com/project/sushigen
- **Firestore Data**: https://console.firebase.google.com/project/sushigen/firestore
- **Guia Completo**: Veja `GUIA_FIREBASE.md`
- **Troubleshooting**: Veja `FIREBASE_IMPLEMENTADO.md`

---

## ✅ Checklist de Uso

- [ ] Criei o Firestore Database
- [ ] Abri o app
- [ ] Vi o botão ☁️ no Dashboard
- [ ] Cadastrei alguns produtos
- [ ] Fiz algumas vendas
- [ ] Cliquei em ☁️
- [ ] Vi "Sincronização concluída!"
- [ ] Verifiquei dados no Firebase Console
- [ ] Badge zerou
- [ ] Testei em outro computador (opcional)

---

**🎉 Pronto! Agora você tem backup automático na nuvem!**
