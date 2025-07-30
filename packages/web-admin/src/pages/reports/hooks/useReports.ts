import { useState, useCallback } from 'react'
import { useMutation } from '@tanstack/react-query'
import axios from 'axios'
import { format } from 'date-fns'
import {
  ReportType,
  ReportPeriod,
  ReportRequest,
  ReportResponse,
} from '../types'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000'

interface UseReportsReturn {
  filters: {
    reportType: ReportType
    period: ReportPeriod
    startDate: Date | null
    endDate: Date | null
    clinicIds: string[]
    planIds: string[]
    serviceTypes: string[]
  }
  setFilters: (filters: any) => void
  reportData: ReportResponse<any> | null
  loading: boolean
  error: string | null
  generateReport: () => void
  exportReport: (format: 'excel' | 'pdf') => Promise<void>
}

export function useReports(): UseReportsReturn {
  const [filters, setFilters] = useState({
    reportType: ReportType.UsageByPeriod,
    period: ReportPeriod.Monthly,
    startDate: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
    endDate: new Date(),
    clinicIds: [] as string[],
    planIds: [] as string[],
    serviceTypes: [] as string[],
  })

  const [reportData, setReportData] = useState<ReportResponse<any> | null>(null)
  const [error, setError] = useState<string | null>(null)

  const generateReportMutation = useMutation({
    mutationFn: async (request: ReportRequest) => {
      const endpoint = getReportEndpoint(request.type)
      const response = await axios.post(`${API_URL}/api/reports/${endpoint}`, request)
      return response.data.data
    },
    onSuccess: (data) => {
      setReportData(data)
      setError(null)
    },
    onError: (err: any) => {
      setError(err.response?.data?.message || 'Erro ao gerar relatório')
      setReportData(null)
    },
  })

  const generateReport = useCallback(() => {
    if (!filters.startDate || !filters.endDate) {
      setError('Selecione as datas de início e fim')
      return
    }

    const request: ReportRequest = {
      type: filters.reportType,
      period: filters.period,
      startDate: format(filters.startDate, 'yyyy-MM-dd'),
      endDate: format(filters.endDate, 'yyyy-MM-dd'),
      clinicIds: filters.clinicIds.length > 0 ? filters.clinicIds : undefined,
      planIds: filters.planIds.length > 0 ? filters.planIds : undefined,
      serviceTypes: filters.serviceTypes.length > 0 ? filters.serviceTypes : undefined,
      includeDetails: true,
      timeZone: 'America/Sao_Paulo',
    }

    generateReportMutation.mutate(request)
  }, [filters, generateReportMutation])

  const exportReport = useCallback(
    async (exportFormat: 'excel' | 'pdf') => {
      if (!filters.startDate || !filters.endDate) {
        setError('Selecione as datas de início e fim')
        return
      }

      try {
        const response = await axios.post(
          `${API_URL}/api/reports/export`,
          {
            format: exportFormat === 'excel' ? 0 : 1, // ExportFormat enum
            reportType: filters.reportType,
            startDate: format(filters.startDate, 'yyyy-MM-dd'),
            endDate: format(filters.endDate, 'yyyy-MM-dd'),
            timeZone: 'America/Sao_Paulo',
            languageCode: 'pt-BR',
            options: {
              includeCharts: true,
              includeSummary: true,
              includeDetails: true,
              includeFilters: true,
              paperSize: 0, // A4
              orientation: filters.reportType === ReportType.ClinicRanking ? 1 : 0, // Landscape for ranking
            },
          },
          {
            responseType: 'blob',
          }
        )

        // Create download link
        const blob = new Blob([response.data], {
          type:
            exportFormat === 'excel'
              ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
              : 'application/pdf',
        })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `relatorio_${filters.reportType}_${format(
          new Date(),
          'yyyyMMdd_HHmmss'
        )}.${exportFormat === 'excel' ? 'xlsx' : 'pdf'}`
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        window.URL.revokeObjectURL(url)
      } catch (err: any) {
        setError(err.response?.data?.message || `Erro ao exportar para ${exportFormat.toUpperCase()}`)
      }
    },
    [filters]
  )

  return {
    filters,
    setFilters,
    reportData,
    loading: generateReportMutation.isPending,
    error,
    generateReport,
    exportReport,
  }
}

function getReportEndpoint(type: ReportType): string {
  switch (type) {
    case ReportType.UsageByPeriod:
      return 'usage'
    case ReportType.ClinicRanking:
      return 'clinic-ranking'
    case ReportType.TopServices:
      return 'service'
    case ReportType.PlanUtilization:
      return 'plan-utilization'
    default:
      return 'generate'
  }
}