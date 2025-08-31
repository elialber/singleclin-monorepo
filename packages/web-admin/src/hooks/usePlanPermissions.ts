import { useAuth } from '@/hooks/useAuth'

/**
 * Hook para verificar permissões relacionadas a planos
 * @returns Objeto com permissões do usuário atual
 */
export function usePlanPermissions() {
  const { user } = useAuth()

  const permissions = {
    canViewPlans: user?.role === 'Administrator' || user?.role === 'ClinicOrigin',
    canCreatePlans: user?.role === 'Administrator',
    canEditPlans: user?.role === 'Administrator',
    canDeletePlans: user?.role === 'Administrator',
    canToggleStatus: user?.role === 'Administrator',
  }

  return {
    ...permissions,
    hasAnyPlanPermission: Object.values(permissions).some(Boolean),
  }
}