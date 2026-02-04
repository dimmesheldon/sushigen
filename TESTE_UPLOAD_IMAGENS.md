# 🧪 Guia de Teste: Upload de Imagens

## Objetivo
Testar a nova funcionalidade de upload de imagens locais no cadastro de produtos.

## ✅ Teste 1: Upload Básico

### Passos:
1. Fazer login (admin / admin123)
2. Dashboard → **Produtos** → Botão **"+"**
3. Preencher:
   - Nome: "Combo Sashimi"
   - Categoria: "Sashimi"
   - Preço: 5000 (será R$ 50,00)
4. Na seção "Imagem do Produto":
   - Clicar no botão **"📤 Upload"**
   - Selecionar uma imagem do computador
5. Verificar:
   - ✅ Preview da imagem apareceu
   - ✅ Nome do arquivo aparece (ex: "imagem.jpg")
   - ✅ Botão "❌" para remover
6. Clicar em **"Salvar"**
7. Voltar para lista de produtos
8. **Resultado Esperado**:
   - ✅ Produto aparece na lista
   - ✅ Imagem é exibida (quando implementarmos display)

---

## ✅ Teste 2: Alternância URL ↔ Upload

### Passos:
1. Criar novo produto
2. Clicar em **"🔗 URL"**
3. Digitar: `https://picsum.photos/200`
4. Verificar:
   - ✅ Preview da URL aparece
5. Clicar em **"📤 Upload"**
6. Selecionar arquivo local
7. Verificar:
   - ✅ Preview mudou para imagem local
   - ✅ Campo URL sumiu
8. Clicar em **"🔗 URL"** novamente
9. Verificar:
   - ✅ Imagem local foi removida
   - ✅ Campo URL voltou

---

## ✅ Teste 3: Remover Imagem Local

### Passos:
1. Criar produto
2. Upload de imagem
3. Clicar no **"❌"** ao lado do nome
4. Verificar:
   - ✅ Card verde sumiu
   - ✅ Preview sumiu
   - ✅ Pode fazer novo upload

---

## ✅ Teste 4: Tipos de Arquivo

### Passos:
Testar upload com diferentes formatos:

| Formato | Extensão | Status Esperado |
|---------|----------|-----------------|
| JPEG | .jpg, .jpeg | ✅ Funciona |
| PNG | .png | ✅ Funciona |
| GIF | .gif | ✅ Funciona |
| BMP | .bmp | ✅ Funciona |
| WEBP | .webp | ✅ Funciona |
| PDF | .pdf | ❌ Não permite |
| TXT | .txt | ❌ Não permite |

---

## ✅ Teste 5: Editar Produto

### Cenário A: Produto com URL
1. Criar produto com URL
2. Editar produto
3. Trocar para Upload
4. Salvar
5. Verificar:
   - ✅ Nova imagem substituiu URL

### Cenário B: Produto com Upload
1. Criar produto com Upload
2. Editar produto
3. Trocar para URL
4. Salvar
5. Verificar:
   - ✅ URL substituiu imagem local

---

## ✅ Teste 6: Produto Sem Imagem

### Passos:
1. Criar produto
2. NÃO selecionar imagem (nem URL, nem Upload)
3. Salvar
4. Verificar:
   - ✅ Produto salvo com sucesso
   - ✅ Sem erro de validação

---

## 🐛 Possíveis Erros

### Erro 1: "Erro ao selecionar imagem"
**Causa**: Permissões do sistema  
**Solução**: Dar permissão de acesso a arquivos

### Erro 2: Preview não aparece
**Causa**: Caminho de arquivo inválido  
**Solução**: Tentar outra imagem

### Erro 3: Imagem muito grande (se implementado limite)
**Causa**: Arquivo > 5MB  
**Solução**: Comprimir imagem ou escolher menor

---

## 📊 Checklist Rápido

- [ ] Upload funciona
- [ ] Preview aparece
- [ ] Nome do arquivo mostra
- [ ] Botão remover funciona
- [ ] Alternância URL/Upload funciona
- [ ] Salvar produto com imagem local
- [ ] Editar produto trocando tipo de imagem
- [ ] Produto sem imagem funciona

---

## 📝 Notas

### Localização das Imagens Salvas:

**macOS**:
```
~/Library/Containers/com.sushigen.sushigen/Data/Documents/products/
```

**Windows**:
```
C:\Users\[seu_usuario]\AppData\Roaming\SushiGen\products\
```

### Para Verificar as Imagens:
```bash
# macOS
ls ~/Library/Containers/com.sushigen.sushigen/Data/Documents/products/

# Saída esperada:
product_1706977234567.jpg
product_1706977345678.png
...
```

---

## 🎉 Resultado Final

Se todos os testes passarem:
- ✅ Upload de imagens implementado
- ✅ Interface funcional e intuitiva
- ✅ Preview dinâmico funcionando
- ✅ Salvamento persistente

**Próximo passo**: Exibir as imagens na tela de vendas!
