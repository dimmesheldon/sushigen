# 🍎 Como Instalar o SushiGen no macOS

## ⚠️ Aviso de Segurança do macOS

Quando você tentar abrir o SushiGen pela primeira vez, o macOS mostrará a mensagem:

> **"O Item sushigen.app Não Foi Aberto"**  
> "A Apple não pôde verificar se o item sushigen.app está livre de algum malware capaz de danificar o Mac ou comprometer sua privacidade."

**Isso é NORMAL!** O SushiGen é um app legítimo, mas não está assinado com certificado da Apple Developer (que custa US$ 99/ano). O macOS bloqueia apps não assinados por padrão para proteger seu Mac.

---

## 🛠️ Solução: Permitir a Instalação

Siga estes passos para instalar o SushiGen:

### **Método 1: Via Preferências do Sistema (Mais Fácil)**

1. **Baixe** o arquivo `SushiGen_v1.0.5_macOS.dmg` do GitHub
2. **Abra o DMG** (clique duas vezes no arquivo baixado)
3. **Arraste o ícone do SushiGen** para a pasta **Applications**
4. **Feche** a janela do DMG
5. **Vá até a pasta Applications** no Finder
6. **Clique com botão direito** (ou Control + clique) no ícone **sushigen.app**
7. **Selecione "Abrir"** no menu de contexto
8. Uma nova janela aparecerá perguntando se você tem certeza
9. **Clique em "Abrir"** novamente
10. ✅ **Pronto!** O app agora está autorizado e abrirá normalmente

---

### **Método 2: Via Terminal (Para Usuários Avançados)**

Se o Método 1 não funcionar, use o Terminal:

```bash
# Remover a quarentena do macOS
xattr -d com.apple.quarantine /Applications/sushigen.app

# Verificar permissões
codesign --verify --verbose /Applications/sushigen.app
```

Depois, tente abrir o app normalmente.

---

### **Método 3: Configurações de Segurança (macOS Ventura+)**

1. Tente abrir o SushiGen normalmente
2. Vá em **Preferências do Sistema** > **Privacidade e Segurança**
3. Role até a seção **Segurança**
4. Você verá: *"sushigen.app foi bloqueado para proteger seu Mac"*
5. Clique em **"Abrir Assim Mesmo"**
6. Digite sua senha de administrador
7. ✅ **Pronto!** O app abrirá

---

## 🔐 Por Que Isso Acontece?

O macOS usa o **Gatekeeper** para verificar se os apps foram:
- **Assinados** com um certificado da Apple Developer
- **Notarizados** (verificados pela Apple)

O SushiGen não possui esses certificados porque:
- Certificado da Apple custa **US$ 99/ano**
- Processo de notarização leva **dias**
- Nosso app é **open source** e **gratuito**

**Mas você pode instalar com segurança!** Basta seguir um dos métodos acima.

---

## ❓ Ainda com Problemas?

Se nenhum método funcionar:

1. **Verifique se o macOS está atualizado** (recomendado: macOS 13+)
2. **Desabilite temporariamente** o Gatekeeper:
   ```bash
   sudo spctl --master-disable
   ```
   ⚠️ **Atenção:** Isso desabilita toda a proteção. Não esqueça de reativar depois:
   ```bash
   sudo spctl --master-enable
   ```

3. **Entre em contato** abrindo uma issue no GitHub

---

## ✅ O SushiGen é Seguro?

**SIM!** 
- ✅ Código **100% open source** (você pode verificar todo o código no GitHub)
- ✅ **Sem coleta de dados** pessoais
- ✅ **Funciona offline** (dados ficam no seu Mac)
- ✅ **Sem telemetria** ou rastreamento
- ✅ Sincronização usa **Firebase** (Google Cloud Platform)

O aviso do macOS é apenas porque não temos certificado pago da Apple, **não porque o app seja malicioso**.

---

## 🆘 Suporte

- **GitHub**: https://github.com/dimmesheldon/sushigen/issues
- **Email**: contato@sushigen.com
- **Documentação**: https://github.com/dimmesheldon/sushigen/wiki

---

**Obrigado por usar o SushiGen!** 🍣
