# 🧪 GUIA DE TESTES - Multi-Tenant + Landing Page

**Data**: 2026-02-03 23:15  

---

## ✅ LANDING PAGE (ABERTA NO NAVEGADOR)

A landing page acabou de abrir! Verifique:
- [ ] Página carrega
- [ ] Logo 🍣 SushiGen no topo
- [ ] Menu funciona
- [ ] Hero vermelho visível
- [ ] 6 cards de funcionalidades
- [ ] 3 planos (R$ 49, R$ 129, R$ 497)
- [ ] Botões de download
- [ ] Design bonito

---

## 🔥 MULTI-TENANT (TESTE PRINCIPAL)

### 1. Admin: Login
```
App → Área Administrativa
Login: superadmin / admin123
```

### 2. Criar 2 Clientes
```
Cliente A:
- Nome: Teste A
- Email: teste_a@test.com
- Menu (⋮) → Gerar Licença
- Username: teste_a | Senha: 1234
- Copiar chave

Cliente B:
- Nome: Teste B  
- Email: teste_b@test.com
- Menu (⋮) → Gerar Licença
- Username: teste_b | Senha: 5678
- Copiar chave
```

### 3. Login Cliente A
```
Login: teste_a / 1234 / [chave A]
Produtos → Novo
Nome: Produto A | Preço: R$ 15
```

### 4. Login Cliente B (TESTE CRÍTICO)
```
Logout → Login: teste_b / 5678 / [chave B]
Produtos → ?

✅ ESPERADO: VAZIO (sem produtos)
❌ ERRO: Aparece "Produto A"
```

### 5. Verificar Arquivos
```
Finder → ~/Documents/

✅ Deve existir:
- sushigen_admin.db
- sushigen_teste_a.db
- sushigen_teste_b.db
```

---

## ✅ RESULTADO

**Landing Page**: [ ] OK / [ ] Erro  
**Multi-Tenant**: [ ] Isolado / [ ] Misturado  
**Arquivos .db**: [ ] 3 separados / [ ] Problema

---

**Me avise**: "funcionou!" ou "erro: [descrição]"
