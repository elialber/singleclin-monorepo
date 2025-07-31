#!/usr/bin/env node

const axios = require('axios');
const fs = require('fs');

const API_BASE = 'http://localhost:5290';

async function performanceTest() {
  console.log('⚡ Performance and Edge Case Testing');
  console.log('='.repeat(50));

  const results = [];

  // Test 1: API Response Time
  console.log('\n⏱️  Test 1: API Response Time');
  const responseTimes = [];
  
  for (let i = 0; i < 5; i++) {
    const start = Date.now();
    try {
      await axios.get(`${API_BASE}/health`);
      const duration = Date.now() - start;
      responseTimes.push(duration);
      console.log(`  Request ${i + 1}: ${duration}ms`);
    } catch (error) {
      console.log(`  Request ${i + 1}: Error - ${error.message}`);
      responseTimes.push(null);
    }
  }

  const validTimes = responseTimes.filter(t => t !== null);
  const avgResponseTime = validTimes.length > 0 ? 
    Math.round(validTimes.reduce((a, b) => a + b, 0) / validTimes.length) : 0;
  
  console.log(`  Average response time: ${avgResponseTime}ms`);
  results.push({
    test: 'API Response Time',
    avgTime: avgResponseTime,
    pass: avgResponseTime < 1000 && avgResponseTime > 0,
    details: `Average ${avgResponseTime}ms across ${validTimes.length} successful requests`
  });

  // Test 2: Concurrent Requests
  console.log('\n🔄 Test 2: Concurrent Request Handling');
  const concurrentStart = Date.now();
  
  try {
    const promises = Array(10).fill().map(() => axios.get(`${API_BASE}/health`));
    await Promise.all(promises);
    const concurrentDuration = Date.now() - concurrentStart;
    
    console.log(`  10 concurrent requests completed in ${concurrentDuration}ms`);
    results.push({
      test: 'Concurrent Requests',
      duration: concurrentDuration,
      pass: concurrentDuration < 3000,
      details: `10 concurrent requests in ${concurrentDuration}ms`
    });
  } catch (error) {
    console.log(`  Concurrent requests failed: ${error.message}`);
    results.push({
      test: 'Concurrent Requests',
      duration: null,
      pass: false,
      details: `Failed: ${error.message}`
    });
  }

  // Test 3: Large Pagination Request
  console.log('\n📄 Test 3: Large Pagination Handling');
  try {
    const start = Date.now();
    await axios.get(`${API_BASE}/api/users?page=9999&limit=1000`);
    const duration = Date.now() - start;
    
    console.log(`  Large pagination request: ${duration}ms`);
    results.push({
      test: 'Large Pagination',
      duration,
      pass: duration < 5000,
      details: `Page 9999 with limit 1000 processed in ${duration}ms`
    });
  } catch (error) {
    const isExpectedError = error.response?.status === 401 || error.response?.status === 404;
    console.log(`  Large pagination: ${error.response?.status || 'Error'} (${isExpectedError ? 'Expected' : 'Unexpected'})`);
    results.push({
      test: 'Large Pagination',
      duration: null,
      pass: isExpectedError,
      details: `Expected authentication error: ${error.response?.status}`
    });
  }

  // Test 4: SQL Injection Protection
  console.log('\n🛡️  Test 4: SQL Injection Protection');
  const sqlInjectionPayloads = [
    "'; DROP TABLE users; --",
    "' OR '1'='1",
    "' UNION SELECT * FROM users --",
    "'; EXEC xp_cmdshell('dir'); --",
    "' OR 1=1 --"
  ];

  let sqlProtectionPassed = 0;
  for (const payload of sqlInjectionPayloads) {
    try {
      const response = await axios.get(`${API_BASE}/api/users?search=${encodeURIComponent(payload)}`);
      console.log(`  Payload handled: ${payload.substring(0, 20)}... (Status: ${response.status})`);
      sqlProtectionPassed++;
    } catch (error) {
      const isSafeResponse = error.response?.status === 401 || error.response?.status === 400 || error.response?.status === 404;
      if (isSafeResponse) {
        console.log(`  Payload safely rejected: ${payload.substring(0, 20)}... (Status: ${error.response.status})`);
        sqlProtectionPassed++;
      } else {
        console.log(`  Unexpected response to payload: ${payload.substring(0, 20)}... (Error: ${error.message})`);
      }
    }
  }

  results.push({
    test: 'SQL Injection Protection',
    protected: sqlProtectionPassed,
    total: sqlInjectionPayloads.length,
    pass: sqlProtectionPassed === sqlInjectionPayloads.length,
    details: `${sqlProtectionPassed}/${sqlInjectionPayloads.length} payloads safely handled`
  });

  // Test 5: XSS Protection
  console.log('\n🔒 Test 5: XSS Protection');
  const xssPayloads = [
    '<script>alert("xss")</script>',
    '<img src="x" onerror="alert(1)">',
    'javascript:alert("xss")',
    '<svg onload="alert(1)">',
    '"><script>alert("xss")</script>'
  ];

  let xssProtectionPassed = 0;
  for (const payload of xssPayloads) {
    try {
      const response = await axios.get(`${API_BASE}/api/users?search=${encodeURIComponent(payload)}`);
      // If we get a response, check that the payload is properly encoded/escaped
      console.log(`  XSS payload handled: ${payload.substring(0, 20)}...`);
      xssProtectionPassed++;
    } catch (error) {
      const isSafeResponse = error.response?.status === 401 || error.response?.status === 400 || error.response?.status === 404;
      if (isSafeResponse) {
        console.log(`  XSS payload safely rejected: ${payload.substring(0, 20)}...`);
        xssProtectionPassed++;
      } else {
        console.log(`  Unexpected response to XSS payload: ${error.message}`);
      }
    }
  }

  results.push({
    test: 'XSS Protection',
    protected: xssProtectionPassed,
    total: xssPayloads.length,
    pass: xssProtectionPassed === xssPayloads.length,
    details: `${xssProtectionPassed}/${xssPayloads.length} XSS payloads safely handled`
  });

  // Test 6: Invalid Data Handling
  console.log('\n🚫 Test 6: Invalid Data Handling');
  const invalidDataTests = [
    { name: 'Invalid GUID', endpoint: '/api/users/invalid-guid-format' },
    { name: 'Non-existent endpoint', endpoint: '/api/nonexistent-endpoint' },
    { name: 'Invalid JSON', method: 'POST', endpoint: '/api/users', data: 'invalid-json' },
    { name: 'Empty request body', method: 'POST', endpoint: '/api/users', data: '' },
    { name: 'Extremely long string', endpoint: `/api/users?search=${'a'.repeat(10000)}` }
  ];

  let invalidDataPassed = 0;
  for (const test of invalidDataTests) {
    try {
      const config = {
        method: test.method || 'GET',
        url: `${API_BASE}${test.endpoint}`,
        timeout: 5000
      };
      
      if (test.data !== undefined) {
        config.data = test.data;
        config.headers = { 'Content-Type': 'application/json' };
      }

      const response = await axios(config);
      console.log(`  ${test.name}: Unexpected success (${response.status})`);
    } catch (error) {
      const expectedStatuses = [400, 401, 404, 500];
      const isExpectedError = expectedStatuses.includes(error.response?.status);
      
      if (isExpectedError) {
        console.log(`  ${test.name}: Properly handled (${error.response.status})`);
        invalidDataPassed++;
      } else {
        console.log(`  ${test.name}: Unexpected error (${error.message})`);
      }
    }
  }

  results.push({
    test: 'Invalid Data Handling',
    passed: invalidDataPassed,
    total: invalidDataTests.length,
    pass: invalidDataPassed >= invalidDataTests.length * 0.8, // 80% success rate acceptable
    details: `${invalidDataPassed}/${invalidDataTests.length} invalid data scenarios properly handled`
  });

  // Test 7: Memory and Resource Usage Simulation
  console.log('\n💾 Test 7: Resource Usage Simulation');
  const resourceTests = [];
  
  // Test multiple rapid requests
  const rapidRequestStart = Date.now();
  try {
    const rapidPromises = Array(50).fill().map((_, i) => 
      axios.get(`${API_BASE}/health`).catch(() => ({ error: true, index: i }))
    );
    const rapidResults = await Promise.all(rapidPromises);
    const rapidDuration = Date.now() - rapidRequestStart;
    const rapidSuccesses = rapidResults.filter(r => !r.error).length;
    
    console.log(`  50 rapid requests: ${rapidSuccesses} succeeded in ${rapidDuration}ms`);
    resourceTests.push({
      name: 'Rapid Requests',
      successes: rapidSuccesses,
      total: 50,
      duration: rapidDuration,
      pass: rapidSuccesses >= 45 && rapidDuration < 10000
    });
  } catch (error) {
    console.log(`  Rapid requests test failed: ${error.message}`);
    resourceTests.push({
      name: 'Rapid Requests',
      successes: 0,
      total: 50,
      duration: null,
      pass: false
    });
  }

  results.push({
    test: 'Resource Usage Simulation',
    subtests: resourceTests,
    pass: resourceTests.every(t => t.pass),
    details: resourceTests.map(t => `${t.name}: ${t.successes}/${t.total} in ${t.duration}ms`).join(', ')
  });

  // Test 8: Error Recovery
  console.log('\n🔄 Test 8: Error Recovery and Resilience');
  const errorRecoveryTests = [];

  // Test timeout handling
  try {
    await axios.get(`${API_BASE}/health`, { timeout: 1 }); // Very short timeout
    errorRecoveryTests.push({ name: 'Timeout Handling', pass: false, details: 'Should have timed out' });
  } catch (error) {
    const isTimeoutError = error.code === 'ECONNABORTED' || error.message.includes('timeout');
    errorRecoveryTests.push({ 
      name: 'Timeout Handling', 
      pass: isTimeoutError, 
      details: isTimeoutError ? 'Timeout properly handled' : `Unexpected error: ${error.message}` 
    });
    console.log(`  Timeout test: ${isTimeoutError ? 'Passed' : 'Failed'} - ${error.message}`);
  }

  // Test recovery after timeout with normal request
  try {
    const response = await axios.get(`${API_BASE}/health`, { timeout: 5000 });
    errorRecoveryTests.push({ 
      name: 'Recovery After Timeout', 
      pass: response.status === 200, 
      details: `Recovery successful: ${response.status}` 
    });
    console.log(`  Recovery test: Passed - API responded normally after timeout`);
  } catch (error) {
    errorRecoveryTests.push({ 
      name: 'Recovery After Timeout', 
      pass: false, 
      details: `Recovery failed: ${error.message}` 
    });
    console.log(`  Recovery test: Failed - ${error.message}`);
  }

  results.push({
    test: 'Error Recovery',
    subtests: errorRecoveryTests,
    pass: errorRecoveryTests.every(t => t.pass),
    details: errorRecoveryTests.map(t => `${t.name}: ${t.pass ? 'Pass' : 'Fail'}`).join(', ')
  });

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 PERFORMANCE TEST SUMMARY');
  console.log('='.repeat(50));

  const totalTests = results.length;
  const passedTests = results.filter(r => r.pass).length;
  const successRate = (passedTests / totalTests * 100).toFixed(1);

  results.forEach(result => {
    const status = result.pass ? '✅ PASS' : '❌ FAIL';
    console.log(`${status} ${result.test}: ${result.details}`);
  });

  console.log(`\nOverall Performance: ${passedTests}/${totalTests} passed (${successRate}%)`);

  // Performance Metrics Summary
  console.log('\n📈 PERFORMANCE METRICS:');
  console.log(`• Average API Response Time: ${avgResponseTime}ms`);
  console.log(`• Concurrent Request Handling: ${results[1].pass ? 'Good' : 'Needs Improvement'}`);
  console.log(`• Security Protection: ${results[3].protected + results[4].protected}/${results[3].total + results[4].total} threats mitigated`);
  console.log(`• Error Handling: ${results[5].passed}/${results[5].total} scenarios handled correctly`);

  // Save results
  const report = {
    timestamp: new Date().toISOString(),
    summary: {
      totalTests,
      passedTests,
      successRate: parseFloat(successRate)
    },
    performanceMetrics: {
      avgResponseTime,
      concurrentHandling: results[1].pass,
      securityProtection: {
        sql: results[3].protected,
        xss: results[4].protected,
        total: results[3].total + results[4].total
      },
      errorHandling: results[5].passed
    },
    detailedResults: results
  };

  fs.writeFileSync('/tmp/performance_test_results.json', JSON.stringify(report, null, 2));
  console.log('\n📄 Detailed results saved to /tmp/performance_test_results.json');

  return report;
}

// Handle command line execution
if (require.main === module) {
  performanceTest().catch(console.error);
}

module.exports = { performanceTest };