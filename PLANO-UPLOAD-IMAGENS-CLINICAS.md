# Plano Técnico: Upload de Imagens para Clínicas
## Sistema SingleClin Healthcare Management

### 📋 Resumo Executivo

Este documento apresenta um plano técnico detalhado para implementar o sistema de upload de imagens das clínicas no SingleClin. O sistema permitirá que administradores façam upload de logotipos e imagens das clínicas através da interface web-admin, com armazenamento seguro no Azure Blob Storage.

---

## 🎯 Objetivos

- **Primário**: Implementar funcionalidade de upload de imagens para clínicas
- **Secundário**: Garantir integração eficiente entre frontend e backend
- **Terciário**: Estabelecer padrões de armazenamento seguros no Azure
- **Qualidade**: Manter performance e segurança do sistema

---

## 🏗️ Análise da Arquitetura Atual

### Backend (.NET 9)
- **Modelo**: `Clinic.cs` (packages/backend/Data/Models/)
- **DTOs**: `ClinicRequestDto.cs`, `ClinicResponseDto.cs`
- **Controller**: `ClinicController.cs` com endpoints CRUD completos
- **Configuração**: Firebase e JWT já implementados

### Frontend (React + MUI)
- **Tipos**: `clinic.ts` com interfaces TypeScript
- **Componentes**: `ClinicFormDialog.tsx` para formulários
- **Página**: `Clinics.tsx` para listagem
- **Serviços**: `clinic.service.ts` para API calls

### Infraestrutura
- **Storage**: Não configurado (necessário Azure Blob Storage)
- **Upload**: Não implementado
- **Validação**: Não implementada para arquivos

---

## 🚀 Sequência de Implementação

### ✅ Fase 1: Configuração da Infraestrutura Azure

#### ✅ 1.1 Configuração do Azure Blob Storage
```json
// ✅ CONCLUÍDO - Adicionado ao appsettings.json
"AzureStorage": {
  "ConnectionString": "{{AZURE_STORAGE_CONNECTION_STRING}}",
  "ContainerName": "clinic-images",
  "BaseUrl": "https://singleclin.blob.core.windows.net/",
  "MaxFileSize": 5242880,
  "AllowedFileTypes": ["jpg", "jpeg", "png", "webp"],
  "ImageQuality": 85,
  "MaxWidth": 1200,
  "MaxHeight": 800
}
```

#### 1.2 Pacotes NuGet Necessários
```xml
<PackageReference Include="Azure.Storage.Blobs" Version="12.19.1" />
<PackageReference Include="SixLabors.ImageSharp" Version="3.0.2" />
<PackageReference Include="SixLabors.ImageSharp.Web" Version="3.0.2" />
```

### Fase 2: Extensão do Modelo de Dados

#### 2.1 Atualização do Modelo Clinic
```csharp
// packages/backend/Data/Models/Clinic.cs
public class Clinic : BaseEntity
{
    // ... propriedades existentes ...
    
    /// <summary>
    /// URL da imagem/logo da clínica
    /// </summary>
    public string? ImageUrl { get; set; }
    
    /// <summary>
    /// Nome do arquivo da imagem no storage
    /// </summary>
    public string? ImageFileName { get; set; }
    
    /// <summary>
    /// Tamanho da imagem em bytes
    /// </summary>
    public long? ImageSize { get; set; }
    
    /// <summary>
    /// Tipo MIME da imagem
    /// </summary>
    public string? ImageContentType { get; set; }
}
```

#### 2.2 Migration para Banco de Dados
```csharp
// Nova migration
public partial class AddClinicImageFields : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(
            name: "ImageUrl",
            table: "Clinics",
            type: "text",
            nullable: true);
            
        migrationBuilder.AddColumn<string>(
            name: "ImageFileName", 
            table: "Clinics",
            type: "text",
            nullable: true);
            
        migrationBuilder.AddColumn<long>(
            name: "ImageSize",
            table: "Clinics", 
            type: "bigint",
            nullable: true);
            
        migrationBuilder.AddColumn<string>(
            name: "ImageContentType",
            table: "Clinics",
            type: "text", 
            nullable: true);
    }
}
```

### Fase 3: Serviços de Upload no Backend

#### 3.1 Interface do Serviço de Upload
```csharp
// packages/backend/Services/IImageUploadService.cs
public interface IImageUploadService
{
    Task<ImageUploadResult> UploadImageAsync(IFormFile file, string folder, CancellationToken cancellationToken = default);
    Task<bool> DeleteImageAsync(string fileName, string folder, CancellationToken cancellationToken = default);
    Task<string> GetImageUrlAsync(string fileName, string folder);
    Task<bool> ValidateImageAsync(IFormFile file);
}

public class ImageUploadResult
{
    public bool Success { get; set; }
    public string? FileName { get; set; }
    public string? Url { get; set; }
    public long Size { get; set; }
    public string? ContentType { get; set; }
    public string? ErrorMessage { get; set; }
}
```

#### 3.2 Implementação do Serviço
```csharp
// packages/backend/Services/ImageUploadService.cs
public class ImageUploadService : IImageUploadService
{
    private readonly BlobServiceClient _blobServiceClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ImageUploadService> _logger;
    
    // Implementação completa com:
    // - Validação de arquivo (tamanho, tipo, conteúdo)
    // - Redimensionamento automático
    // - Upload para Azure Blob Storage
    // - Geração de URLs públicas
    // - Tratamento de erros
}
```

#### 3.3 Extensão do ClinicService
```csharp
// Atualizar packages/backend/Services/ClinicService.cs
public async Task<ClinicResponseDto> UpdateImageAsync(Guid id, IFormFile imageFile)
{
    var clinic = await GetEntityByIdAsync(id);
    
    // Remover imagem anterior se existir
    if (!string.IsNullOrEmpty(clinic.ImageFileName))
    {
        await _imageUploadService.DeleteImageAsync(clinic.ImageFileName, "clinics");
    }
    
    // Upload nova imagem
    var uploadResult = await _imageUploadService.UploadImageAsync(imageFile, "clinics");
    
    if (uploadResult.Success)
    {
        clinic.ImageUrl = uploadResult.Url;
        clinic.ImageFileName = uploadResult.FileName;
        clinic.ImageSize = uploadResult.Size;
        clinic.ImageContentType = uploadResult.ContentType;
        clinic.UpdatedAt = DateTime.UtcNow;
        
        await _context.SaveChangesAsync();
    }
    
    return _mapper.Map<ClinicResponseDto>(clinic);
}
```
