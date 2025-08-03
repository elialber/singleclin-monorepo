import { Box } from '@mui/material';

interface SingleClinLogoProps {
  width?: number;
  height?: number;
  variant?: 'light' | 'dark';
}

export function SingleClinLogo({ 
  width = 48, 
  height = 48, 
  variant = 'dark' 
}: SingleClinLogoProps) {
  const primaryColor = variant === 'dark' ? '#005156' : '#FFFFFF';
  
  return (
    <Box
      component="svg"
      width={width}
      height={height}
      viewBox="0 0 100 100"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      sx={{
        display: 'block',
      }}
    >
      {/* Simplified medical cross with modern design */}
      <g>
        {/* Background circle */}
        <circle
          cx="50"
          cy="50"
          r="45"
          fill={primaryColor}
          opacity="0.1"
        />
        
        {/* Main cross shape with rounded corners */}
        <path
          d="M 40 30 
             C 40 25, 45 20, 50 20
             C 55 20, 60 25, 60 30
             L 60 40
             L 70 40
             C 75 40, 80 45, 80 50
             C 80 55, 75 60, 70 60
             L 60 60
             L 60 70
             C 60 75, 55 80, 50 80
             C 45 80, 40 75, 40 70
             L 40 60
             L 30 60
             C 25 60, 20 55, 20 50
             C 20 45, 25 40, 30 40
             L 40 40
             Z"
          fill={primaryColor}
        />
        
        {/* Center detail - small circle */}
        <circle
          cx="50"
          cy="50"
          r="8"
          fill={variant === 'dark' ? '#FFFFFF' : '#005156'}
        />
      </g>
    </Box>
  );
}

// Icon variant for smaller uses
export function SingleClinIcon({ 
  size = 24, 
  color = '#005156' 
}: { 
  size?: number; 
  color?: string; 
}) {
  return (
    <Box
      component="svg"
      width={size}
      height={size}
      viewBox="0 0 100 100"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      sx={{
        display: 'inline-block',
        verticalAlign: 'middle',
      }}
    >
      <path
        d="M 40 30 
           C 40 25, 45 20, 50 20
           C 55 20, 60 25, 60 30
           L 60 40
           L 70 40
           C 75 40, 80 45, 80 50
           C 80 55, 75 60, 70 60
           L 60 60
           L 60 70
           C 60 75, 55 80, 50 80
           C 45 80, 40 75, 40 70
           L 40 60
           L 30 60
           C 25 60, 20 55, 20 50
           C 20 45, 25 40, 30 40
           L 40 40
           Z"
        fill={color}
      />
    </Box>
  );
}