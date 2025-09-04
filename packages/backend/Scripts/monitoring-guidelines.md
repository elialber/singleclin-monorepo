# Diretrizes de Monitoramento - Upload de Imagens

## Métricas Chave

### 1. Performance de Upload
- **Tempo médio de upload**: < 5 segundos para arquivos < 2MB
- **Taxa de sucesso**: > 99% dos uploads
- **Throughput**: Uploads simultâneos suportados

### 2. Uso de Armazenamento
- **Storage Azure**: Monitorar uso do container `clinic-images`
- **Quota de armazenamento**: Alertas quando > 90% da cota
- **Custos**: Monitoramento mensal do Azure Blob Storage

### 3. Logs Estruturados

#### Logs de Sucesso
```csharp
_logger.LogInformation("Image uploaded successfully", 
    new { 
        ClinicId = clinicId, 
        FileName = fileName, 
        FileSize = fileSize,
        UploadDurationMs = duration 
    });
```

#### Logs de Erro
```csharp
_logger.LogError("Image upload failed", 
    new { 
        ClinicId = clinicId, 
        ErrorMessage = ex.Message, 
        FileSize = fileSize 
    });
```

## Application Insights Configuração

### Custom Metrics
```csharp
// Adicionar ao ImageUploadService
_telemetryClient.TrackMetric("ImageUpload.Duration", uploadDuration);
_telemetryClient.TrackMetric("ImageUpload.FileSize", fileSize);
_telemetryClient.TrackEvent("ImageUpload.Success", 
    new Dictionary<string, string> { 
        { "ClinicId", clinicId.ToString() } 
    });
```

### Custom Alerts
1. **Upload Failures**: > 5 falhas em 10 minutos
2. **High Latency**: Tempo médio > 10 segundos
3. **Storage Quota**: > 90% da capacidade

## Health Checks

### Adicionar ao Program.cs
```csharp
services.AddHealthChecks()
    .AddCheck<AzureStorageHealthCheck>("azure-storage")
    .AddCheck<ImageProcessingHealthCheck>("image-processing");
```

### Implementar Health Checks
```csharp
public class AzureStorageHealthCheck : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context, 
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Testar conectividade com Azure Blob Storage
            await _blobServiceClient.GetPropertiesAsync(cancellationToken);
            return HealthCheckResult.Healthy("Azure Storage is accessible");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Azure Storage is not accessible", ex);
        }
    }
}
```

## Alertas Recomendados

### 1. Críticos (PagerDuty/SMS)
- Azure Storage indisponível
- > 50 uploads falharam em 1 hora
- Aplicação indisponível

### 2. Warnings (Email/Slack)
- Taxa de erro > 5% em 1 hora
- Tempo médio de upload > 8 segundos
- 80% da quota de storage atingida

### 3. Informativos (Dashboard)
- Número de uploads por hora
- Tamanho médio dos arquivos
- Clínicas mais ativas no upload

## Dashboard Sugerido

### KPIs Principais
- **Uploads Today**: Contador do dia
- **Success Rate**: Porcentagem nas últimas 24h
- **Avg Upload Time**: Tempo médio nas últimas 24h
- **Storage Used**: Percentual da quota utilizada

### Gráficos
- Uploads por hora (últimas 24h)
- Distribuição de tamanhos de arquivo
- Top 10 clínicas por uploads
- Erros por tipo/categoria

## Queries Úteis (Application Insights)

### Taxa de Sucesso
```kusto
requests
| where name contains "UploadImage"
| summarize 
    Total = count(),
    Success = countif(resultCode == 200),
    SuccessRate = (countif(resultCode == 200) * 100.0) / count()
by bin(timestamp, 1h)
```

### Tempo Médio de Upload
```kusto
requests
| where name contains "UploadImage"
| summarize AvgDuration = avg(duration)
by bin(timestamp, 1h)
```

### Top Erros
```kusto
exceptions
| where outerMessage contains "Image"
| summarize Count = count() by outerMessage
| order by Count desc
```