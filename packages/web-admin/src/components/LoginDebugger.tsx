import { useState } from 'react'
import { Box, Button, TextField, Typography, Paper, Alert } from '@mui/material'
import { authService } from '@/services/auth.service'
import { signInWithEmail } from '@/services/firebaseAuth'

export function LoginDebugger() {
  const [email, setEmail] = useState('test@example.com')
  const [password, setPassword] = useState('Test123456@')
  const [logs, setLogs] = useState<string[]>([])
  const [error, setError] = useState<string>('')

  const addLog = (message: string) => {
    setLogs(prev => [...prev, `[${new Date().toLocaleTimeString()}] ${message}`])
  }

  const testFirebaseOnly = async () => {
    setError('')
    setLogs([])
    try {
      addLog('Testing Firebase authentication only...')
      const result = await signInWithEmail(email, password)
      addLog(`Firebase success! User: ${result.user.uid}`)
      addLog(`Got ID token: ${result.token.substring(0, 50)}...`)
    } catch (err: any) {
      addLog(`Firebase error: ${err.code} - ${err.message}`)
      setError(err.message)
    }
  }

  const testFullLogin = async () => {
    setError('')
    setLogs([])
    try {
      addLog('Starting full login process...')
      const result = await authService.login(email, password)
      addLog(`Login success! User: ${result.user.email}`)
      addLog(`Access token: ${result.accessToken.substring(0, 50)}...`)
      addLog('Tokens stored in localStorage')
    } catch (err: any) {
      addLog(`Login error: ${err.message}`)
      setError(err.message)
    }
  }

  const checkTokens = () => {
    const accessToken = localStorage.getItem('@SingleClin:accessToken')
    const refreshToken = localStorage.getItem('@SingleClin:refreshToken')
    const user = localStorage.getItem('@SingleClin:user')
    
    addLog('=== Local Storage Check ===')
    addLog(`Access Token: ${accessToken ? 'Present' : 'Missing'}`)
    addLog(`Refresh Token: ${refreshToken ? 'Present' : 'Missing'}`)
    addLog(`User Data: ${user ? 'Present' : 'Missing'}`)
    
    if (user) {
      try {
        const userData = JSON.parse(user)
        addLog(`User Email: ${userData.email}`)
        addLog(`User Role: ${userData.role}`)
      } catch (e) {
        addLog('Failed to parse user data')
      }
    }
  }

  const clearAll = () => {
    localStorage.clear()
    setLogs([])
    setError('')
    addLog('Cleared all localStorage data')
  }

  return (
    <Paper sx={{ p: 3, mt: 2 }}>
      <Typography variant="h6" gutterBottom>
        Login Debugger
      </Typography>
      
      <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
        <TextField
          size="small"
          label="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
        <TextField
          size="small"
          label="Password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
      </Box>

      <Box sx={{ display: 'flex', gap: 1, mb: 2 }}>
        <Button variant="outlined" size="small" onClick={testFirebaseOnly}>
          Test Firebase Only
        </Button>
        <Button variant="outlined" size="small" onClick={testFullLogin}>
          Test Full Login
        </Button>
        <Button variant="outlined" size="small" onClick={checkTokens}>
          Check Tokens
        </Button>
        <Button variant="outlined" size="small" color="error" onClick={clearAll}>
          Clear All
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Box sx={{ 
        bgcolor: 'grey.100', 
        p: 2, 
        borderRadius: 1,
        maxHeight: 300,
        overflow: 'auto',
        fontFamily: 'monospace',
        fontSize: '0.875rem'
      }}>
        {logs.length === 0 ? (
          <Typography variant="body2" color="text.secondary">
            No logs yet. Click a button to start testing.
          </Typography>
        ) : (
          logs.map((log, index) => (
            <div key={index}>{log}</div>
          ))
        )}
      </Box>
    </Paper>
  )
}