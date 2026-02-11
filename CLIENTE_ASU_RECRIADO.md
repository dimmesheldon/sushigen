# ✅ Cliente Asu Recriado

## 🎯 Problema
Após recriar o banco admin, o cliente "Asu" sumiu porque o script `init_admin_quick.dart` cria apenas o superadmin.

## ✅ Solução
Cliente "Asu" recriado manualmente via SQL diretamente no banco admin.

## 📊 Dados Criados

### 1. Cliente na tabela `customers`
```sql
INSERT INTO customers VALUES (
  '550e8400-e29b-41d4-a716-446655440000',  -- ID fixo do cliente Asu
  'Asu',
  'asu@sushigen.com',
  '(11) 98765-4321',
  'Asu Sushi Bar',
  '12.345.678/0001-90',
  'Rua das Flores, 123',
  'São Paulo',
  'SP',
  'Cliente de teste',
  1,  -- is_active
  datetime('now'),
  datetime('now')
);
```

### 2. Usuário Admin na tabela `company_users`
```sql
INSERT INTO company_users VALUES (
  '660e8400-e29b-41d4-a716-446655440001',  -- ID do usuário
  '550e8400-e29b-41d4-a716-446655440000',  -- customer_id (FK → customers)
  'asu_admin',
  'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',  -- SHA-256 de "admin123"
  'asu_admin@sushigen.com',
  'admin',
  1,  -- is_active
  datetime('now'),
  datetime('now')
);
```

## 🔑 Credenciais

### Cliente Asu
- **Customer ID**: `550e8400-e29b-41d4-a716-446655440000`
- **Nome**: Asu
- **Empresa**: Asu Sushi Bar
- **Email**: asu@sushigen.com
- **Telefone**: (11) 98765-4321
- **CNPJ**: 12.345.678/0001-90

### Usuário Admin do Cliente
- **Username**: `asu_admin`
- **Password**: `admin123` (hash SHA-256)
- **Email**: asu_admin@sushigen.com
- **Role**: admin
- **Status**: Ativo

## ✅ Verificação

```bash
$ sqlite3 sushigen_admin.db "SELECT name, email FROM customers"
Asu|asu@sushigen.com

$ sqlite3 sushigen_admin.db "SELECT username, email, role FROM company_users"
asu_admin|asu_admin@sushigen.com|admin
```

## 🧪 Como Testar

1. **Fazer login como superadmin**:
   - Usuário: `superadmin`
   - Senha: `admin123`

2. **Navegar**: Painel Administrativo → Gerenciar Clientes

3. **Verificar**: Cliente "Asu" deve aparecer na lista

4. **Clicar**: "Gerenciar Usuários" no card do cliente Asu

5. **Verificar**: Usuário `asu_admin` deve aparecer com:
   - ✅ Username: asu_admin
   - ✅ Email: asu_admin@sushigen.com
   - ✅ Role: admin
   - ✅ Status: Ativo

## 🎯 Funcionalidades Disponíveis

Agora você pode testar:
- ✅ Listar usuário do cliente Asu
- ✅ Criar novos usuários para Asu
- ✅ Editar usuário asu_admin
- ✅ Resetar senha do usuário
- ✅ Desativar/ativar usuário
- ✅ Excluir usuário

## 📝 Nota
Este cliente foi criado manualmente para testes. Se você recriar o banco admin novamente, precisará executar estes comandos SQL novamente, ou modificar o script `init_admin_quick.dart` para incluir clientes de teste.

---

**Data**: 11/02/2026  
**Status**: ✅ Cliente Asu recriado com sucesso
