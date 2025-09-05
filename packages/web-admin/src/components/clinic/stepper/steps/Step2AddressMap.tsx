import React from 'react'
import { Box, Typography } from '@mui/material'
import { StepComponentProps } from '../../../../types/stepper'

/**
 * Step 2: Endereço e Localização
 * 
 * Placeholder - será implementado na Fase 3
 */
function Step2AddressMap({ onNext, onPrev, isValid, isDirty }: StepComponentProps) {
  return (
    <Box>
      <Typography variant="h6" gutterBottom>
        🗺️ Step 2: Endereço e Localização
      </Typography>
      <Typography variant="body2" color="text.secondary">
        Este step será implementado na Fase 3 do desenvolvimento.
      </Typography>
    </Box>
  )
}

export default Step2AddressMap