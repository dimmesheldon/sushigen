# 🎉 SushiGen v1.0.0

**Data de Lançamento**: 03 de Fevereiro de 2026  
**Versão Inicial**: Sistema completo de gestão para restaurantes de sushi

---

## ✨ Funcionalidades

### 🎯 Lançamento Rápido de Pedidos
- Interface otimizada para atendimento ágil
- Grid de produtos com busca instantânea
- Carrinho dinâmico com cálculo em tempo real
- Formas de pagamento: Dinheiro, Débito, Crédito, PIX
- Sistema de descontos (R$ ou %)
- Campo de observações do pedido

### 📦 Gestão de Produtos
- CRUD completo (Criar, Editar, Excluir)
- Upload de imagens (URL ou arquivo local)
- Categorias personalizáveis
- Busca e filtros avançados
- Controle de preços

### 📊 Relatórios Inteligentes
- Relatório de vendas por período
- Top 10 produtos mais vendidos
- Análise por categoria
- Análise por período do dia (manhã, tarde, noite)
- Comparação com período anterior
- Cards de resumo (vendas, faturamento, ticket médio)
- Filtros: Hoje, Semana, Mês, Ano, Personalizado

### 💰 Gestão de Fluxo de Caixa
- Registro de entradas e saídas
- Categorização automática de vendas
- Categorias personalizadas de despesas
- Saldo em tempo real
- Histórico completo
- Filtros por período e tipo
- Relatórios em PDF

### 🔐 Sistema de Licenciamento
- Autenticação com usuário + senha + chave de licença
- Controle de expiração de licença
- Suporte multi-dispositivo
- Renovação facilitada
- Licenças anuais ou personalizadas

### 🏢 Multi-Tenant
- Banco de dados separado por usuário
- Isolamento completo de dados
- Cada restaurante tem seus próprios dados
- Segurança e privacidade garantidas

### 🔄 Sistema de Atualização Automática
- Verificação automática de atualizações (1x por dia)
- Notificação de novas versões
- Download com um clique
- Dados sempre preservados
- Opções: Baixar, Lembrar Depois, Ignorar

---

## 📥 Download

### **macOS** (Apple Silicon & Intel)
- **Arquivo**: [sushigen-v1.0.0-macos.zip](https://github.com/dimmesheldon/sushigen/releases/download/v1.0.0/sushigen-v1.0.0-macos.zip)
- **Tamanho**: ~37 MB
- **Requisitos**: macOS 10.15 (Catalina) ou superior

### **Instruções de Instalação (macOS)**:
1. Baixe o arquivo `sushigen-v1.0.0-macos.zip`
2. Descompacte o arquivo (duplo clique)
3. Arraste `sushigen.app` para a pasta Aplicativos
4. Abra o aplicativo
5. Se aparecer aviso de segurança:
   - Vá em Preferências do Sistema → Privacidade e Segurança
   - Clique em "Abrir Mesmo Assim"

---

## 🔑 Credenciais de Teste

Para testar o sistema, use:

- **Usuário**: `admin`
- **Senha**: `admin123`
- **Chave de Licença**: `1A56-0FD1-4814-E762`

⚠️ **Importante**: Essas são credenciais de demonstração. Para uso em produção, gere suas próprias licenças.

---

## 🚀 Primeiros Passos

1. **Instale o aplicativo** (veja instruções acima)
2. **Faça login** com as credenciais de teste
3. **Cadastre produtos**:
   - Vá em "Produtos" → "Adicionar Produto"
   - Preencha nome, categoria, preço
   - Adicione uma imagem (opcional)
4. **Lance vendas**:
   - Vá em "Lançamento Rápido"
   - Selecione produtos
   - Escolha forma de pagamento
   - Finalize a venda
5. **Veja relatórios**:
   - Vá em "Relatórios"
   - Escolha o período
   - Analise as vendas

---

## 💡 Recursos Avançados

### **Atalhos de Teclado** (em desenvolvimento)
- `Cmd/Ctrl + N`: Novo produto
- `Cmd/Ctrl + S`: Salvar
- `Cmd/Ctrl + F`: Buscar
- `Cmd/Ctrl + Q`: Sair

### **Exportação de Dados**
- Relatórios em PDF
- Fluxo de caixa em PDF
- Mais formatos em breve (Excel, CSV)

### **Temas** (em desenvolvimento)
- Tema claro (padrão)
- Tema escuro (em breve)

---

## 🗄️ Backup de Dados

### **Onde ficam os dados?**

**macOS**:
```
~/Library/Application Support/com.sushigen.app/
├── sushigen_admin.db (dados administrativos)
└── sushigen_[usuario].db (dados do restaurante)
```

### **Como fazer backup?**

1. Feche o aplicativo
2. Copie a pasta acima para um local seguro
3. Para restaurar, basta copiar os arquivos de volta

⚠️ **Importante**: Seus dados **NUNCA** são perdidos em atualizações!

---

## 🐛 Problemas Conhecidos

- Nenhum problema crítico identificado
- Esta é a versão inicial (1.0.0)

---

## 🔄 Atualizações Futuras

Próximas funcionalidades planejadas:

- ✅ Gestão de ingredientes (estoque inteligente)
- ✅ Impressão de cupom fiscal
- ✅ Cadastro de clientes
- ✅ Programa de fidelidade
- ✅ Integração com iFood/Rappi
- ✅ Dashboard analítico avançado
- ✅ App móvel (iOS/Android)
- ✅ Sincronização na nuvem (Firebase)

---

## 📞 Suporte

Precisa de ajuda? Entre em contato:

- **WhatsApp**: [(99) 98453-2007](https://wa.me/5599984532007)
- **Email**: dimme.spa@gmail.com
- **GitHub**: [Issues](https://github.com/dimmesheldon/sushigen/issues)

---

## 📝 Licença

SushiGen © 2026  
Sistema proprietário de gestão para restaurantes

---

## 🙏 Agradecimentos

Obrigado por escolher o SushiGen para gerenciar seu restaurante! 🍣

---

**Versão**: 1.0.0  
**Build**: 1  
**Data**: 03/02/2026  
**Tamanho**: 37 MB (macOS)  
**Plataformas**: macOS (Windows em breve)
