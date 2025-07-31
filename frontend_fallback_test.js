#!/usr/bin/env node

// Frontend Fallback System Test
// Tests the intelligent fallback system that serves mock data when backend returns 404

const axios = require('axios');
const fs = require('fs');

const FRONTEND_API_BASE = 'http://localhost:5290/api';

// Mock the frontend user service behavior
const mockApi = axios.create({
  baseURL: FRONTEND_API_BASE,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Simulate the frontend service fallback logic
class UserServiceTest {
  async getUsers(params = {}) {
    const queryParams = new URLSearchParams();
    
    if (params.page) queryParams.append('page', params.page.toString());
    if (params.limit) queryParams.append('limit', params.limit.toString());
    if (params.search) queryParams.append('search', params.search);
    if (params.role) queryParams.append('role', params.role);
    if (params.isActive !== undefined) queryParams.append('isActive', params.isActive.toString());
    if (params.clinicId) queryParams.append('clinicId', params.clinicId);

    try {
      const response = await mockApi.get(`/users?${queryParams.toString()}`);
      return { source: 'backend', data: response.data };
    } catch (error) {
      if (error.response?.status === 404) {
        // Return mock data if endpoint not implemented yet
        console.warn('Users endpoint not implemented, returning mock data');
        
        const mockUsers = [
          {
            id: '1',
            email: 'admin@singleclin.com',
            firstName: 'Admin',
            lastName: 'Sistema',
            fullName: 'Admin Sistema',
            role: 'Administrator',
            isActive: true,
            isEmailVerified: true,
            createdAt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '2',
            email: 'clinica.origem@singleclin.com',
            firstName: 'Maria',
            lastName: 'Silva',
            fullName: 'Maria Silva',
            role: 'ClinicOrigin',
            isActive: true,
            isEmailVerified: true,
            phoneNumber: '(11) 98765-4321',
            clinicId: 'clinic-1',
            createdAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '3',
            email: 'clinica.parceira@singleclin.com',
            firstName: 'João',
            lastName: 'Santos',
            fullName: 'João Santos',
            role: 'ClinicPartner',
            isActive: true,
            isEmailVerified: true,
            phoneNumber: '(21) 97654-3210',
            clinicId: 'clinic-2',
            createdAt: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '4',
            email: 'paciente1@email.com',
            firstName: 'Carlos',
            lastName: 'Oliveira',
            fullName: 'Carlos Oliveira',
            role: 'Patient',
            isActive: true,
            isEmailVerified: false,
            phoneNumber: '(31) 96543-2109',
            createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '5',
            email: 'paciente2@email.com',
            firstName: 'Ana',
            lastName: 'Costa',
            fullName: 'Ana Costa',
            role: 'Patient',
            isActive: false,
            isEmailVerified: true,
            phoneNumber: '(41) 95432-1098',
            createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '6',
            email: 'clinica.parceira2@singleclin.com',
            firstName: 'Pedro',
            lastName: 'Almeida',
            fullName: 'Pedro Almeida',
            role: 'ClinicPartner',
            isActive: true,
            isEmailVerified: true,
            phoneNumber: '(51) 94321-0987',
            clinicId: 'clinic-3',
            createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
        ];

        // Apply filters
        let filtered = [...mockUsers];
        
        if (params.search) {
          const searchLower = params.search.toLowerCase();
          filtered = filtered.filter(u => 
            u.fullName.toLowerCase().includes(searchLower) ||
            u.email.toLowerCase().includes(searchLower) ||
            (u.phoneNumber && u.phoneNumber.includes(params.search))
          );
        }
        
        if (params.role) {
          filtered = filtered.filter(u => u.role === params.role);
        }
        
        if (params.isActive !== undefined) {
          filtered = filtered.filter(u => u.isActive === params.isActive);
        }
        
        if (params.clinicId) {
          filtered = filtered.filter(u => u.clinicId === params.clinicId);
        }

        // Sort by creation date (newest first)
        filtered.sort((a, b) => 
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
        );

        // Pagination
        const page = params.page || 1;
        const limit = params.limit || 10;
        const start = (page - 1) * limit;
        const end = start + limit;
        const paginatedData = filtered.slice(start, end);

        return {
          source: 'mock',
          data: {
            data: paginatedData,
            total: filtered.length,
            page,
            limit,
          }
        };
      }
      throw error;
    }
  }

  async getUser(id) {
    try {
      const response = await mockApi.get(`/users/${id}`);
      return { source: 'backend', data: response.data.data };
    } catch (error) {
      if (error.response?.status === 404 || error.response?.status === 401) {
        // Try to find in mock data
        const users = await this.getUsers({ limit: 100 });
        const user = users.data.data.find(u => u.id === id);
        if (user) return { source: 'mock', data: user };
      }
      throw error;
    }
  }

  async createUser(data) {
    try {
      const response = await mockApi.post('/users', data);
      return { source: 'backend', data: response.data.data };
    } catch (error) {
      if (error.response?.status === 404 || error.response?.status === 401) {
        // Mock response for development
        console.warn('Create user endpoint not implemented, returning mock data');
        const newUser = {
          id: Date.now().toString(),
          email: data.email,
          firstName: data.firstName,
          lastName: data.lastName,
          fullName: `${data.firstName} ${data.lastName}`,
          role: data.role,
          phoneNumber: data.phoneNumber,
          clinicId: data.clinicId,
          isActive: true,
          isEmailVerified: false,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        return { source: 'mock', data: newUser };
      }
      throw error;
    }
  }
}

async function testFallbackSystem() {
  console.log('🧪 Testing Frontend Fallback System');
  console.log('=' .repeat(50));

  const userService = new UserServiceTest();
  const results = [];

  // Test 1: List users fallback
  console.log('\n📋 Test 1: List Users Fallback');
  try {
    const result = await userService.getUsers({ page: 1, limit: 5 });
    const isValid = result.data && 
                   Array.isArray(result.data.data) && 
                   typeof result.data.total === 'number' &&
                   result.data.data.length <= 5;
    
    console.log(`✅ Source: ${result.source}`);
    console.log(`✅ Users returned: ${result.data.data.length}`);
    console.log(`✅ Total count: ${result.data.total}`);
    console.log(`✅ Response format valid: ${isValid}`);
    
    results.push({
      test: 'List Users Fallback',
      pass: isValid && result.source === 'mock',
      source: result.source,
      details: `${result.data.data.length} users returned`
    });
  } catch (error) {
    console.log(`❌ Error: ${error.message}`);
    results.push({
      test: 'List Users Fallback',
      pass: false,
      source: 'error',
      details: error.message
    });
  }

  // Test 2: Search functionality in fallback
  console.log('\n🔍 Test 2: Search Functionality in Fallback');
  try {
    const result = await userService.getUsers({ search: 'Admin' });
    const hasAdminUser = result.data.data.some(u => u.fullName.includes('Admin'));
    
    console.log(`✅ Source: ${result.source}`);
    console.log(`✅ Search results: ${result.data.data.length}`);
    console.log(`✅ Found admin user: ${hasAdminUser}`);
    
    results.push({
      test: 'Search Functionality',
      pass: hasAdminUser && result.source === 'mock',
      source: result.source,
      details: `Found ${result.data.data.length} results for 'Admin'`
    });
  } catch (error) {
    console.log(`❌ Error: ${error.message}`);
    results.push({
      test: 'Search Functionality',
      pass: false,
      source: 'error',
      details: error.message
    });
  }

  // Test 3: Role filtering in fallback
  console.log('\n👥 Test 3: Role Filtering in Fallback');
  try {
    const result = await userService.getUsers({ role: 'Patient' });
    const allPatientsValid = result.data.data.every(u => u.role === 'Patient');
    
    console.log(`✅ Source: ${result.source}`);
    console.log(`✅ Patient users: ${result.data.data.length}`);
    console.log(`✅ All are patients: ${allPatientsValid}`);
    
    results.push({
      test: 'Role Filtering',
      pass: allPatientsValid && result.source === 'mock',
      source: result.source,
      details: `${result.data.data.length} patients filtered correctly`
    });
  } catch (error) {
    console.log(`❌ Error: ${error.message}`);
    results.push({
      test: 'Role Filtering',
      pass: false,
      source: 'error',
      details: error.message
    });
  }

  // Test 4: Status filtering in fallback
  console.log('\n🔄 Test 4: Status Filtering in Fallback');
  try {
    const result = await userService.getUsers({ isActive: false });
    const allInactiveValid = result.data.data.every(u => u.isActive === false);
    
    console.log(`✅ Source: ${result.source}`);
    console.log(`✅ Inactive users: ${result.data.data.length}`);
    console.log(`✅ All are inactive: ${allInactiveValid}`);
    
    results.push({
      test: 'Status Filtering',
      pass: allInactiveValid && result.source === 'mock',
      source: result.source,
      details: `${result.data.data.length} inactive users filtered correctly`
    });
  } catch (error) {
    console.log(`❌ Error: ${error.message}`);
    results.push({
      test: 'Status Filtering',
      pass: false,
      source: 'error',
      details: error.message
    });
  }

  // Test 5: Get single user fallback
  console.log('\n👤 Test 5: Get Single User Fallback');
  try {
    const result = await userService.getUser('1');
    const isValidUser = result.data && result.data.id === '1' && result.data.fullName;
    
    console.log(`✅ Source: ${result.source}`);
    console.log(`✅ User found: ${result.data.fullName}`);
    console.log(`✅ Valid user object: ${isValidUser}`);
    
    results.push({
      test: 'Get Single User',
      pass: isValidUser && result.source === 'mock',
      source: result.source,
      details: `User '${result.data.fullName}' retrieved`
    });
  } catch (error) {
    console.log(`❌ Error: ${error.message}`);
    results.push({
      test: 'Get Single User',
      pass: false,
      source: 'error',
      details: error.message
    });
  }

  // Test 6: Create user fallback
  console.log('\n➕ Test 6: Create User Fallback');
  try {
    const userData = {
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      role: 'Patient',
      password: 'testpassword123'
    };
    
    const result = await userService.createUser(userData);
    const isValidUser = result.data && 
                       result.data.email === userData.email &&
                       result.data.fullName === 'Test User';
    
    console.log(`✅ Source: ${result.source}`);
    console.log(`✅ User created: ${result.data.fullName}`);
    console.log(`✅ Valid user object: ${isValidUser}`);
    
    results.push({
      test: 'Create User',
      pass: isValidUser && result.source === 'mock',
      source: result.source,
      details: `User '${result.data.fullName}' created`
    });
  } catch (error) {
    console.log(`❌ Error: ${error.message}`);
    results.push({
      test: 'Create User',
      pass: false,
      source: 'error',
      details: error.message
    });
  }

  // Test 7: Pagination in fallback
  console.log('\n📄 Test 7: Pagination in Fallback');
  try {
    const page1 = await userService.getUsers({ page: 1, limit: 2 });
    const page2 = await userService.getUsers({ page: 2, limit: 2 });
    
    const page1Valid = page1.data.data.length === 2 && page1.data.page === 1;
    const page2Valid = page2.data.data.length === 2 && page2.data.page === 2;
    const noDuplicates = !page1.data.data.some(u1 => 
      page2.data.data.some(u2 => u1.id === u2.id)
    );
    
    console.log(`✅ Page 1 users: ${page1.data.data.length}`);
    console.log(`✅ Page 2 users: ${page2.data.data.length}`);
    console.log(`✅ No duplicates: ${noDuplicates}`);
    
    results.push({
      test: 'Pagination',
      pass: page1Valid && page2Valid && noDuplicates,
      source: page1.source,
      details: `Pagination working correctly across pages`
    });
  } catch (error) {
    console.log(`❌ Error: ${error.message}`);
    results.push({
      test: 'Pagination',
      pass: false,
      source: 'error',
      details: error.message
    });
  }

  // Test 8: Data consistency and structure
  console.log('\n🔧 Test 8: Data Consistency and Structure');
  try {
    const result = await userService.getUsers({ limit: 10 });
    const users = result.data.data;
    
    const allHaveIds = users.every(u => u.id);
    const allHaveEmails = users.every(u => u.email);
    const allHaveNames = users.every(u => u.fullName);
    const allHaveRoles = users.every(u => u.role);
    const allHaveTimestamps = users.every(u => u.createdAt && u.updatedAt);
    
    console.log(`✅ All have IDs: ${allHaveIds}`);
    console.log(`✅ All have emails: ${allHaveEmails}`);
    console.log(`✅ All have names: ${allHaveNames}`);
    console.log(`✅ All have roles: ${allHaveRoles}`);
    console.log(`✅ All have timestamps: ${allHaveTimestamps}`);
    
    const dataConsistent = allHaveIds && allHaveEmails && allHaveNames && 
                          allHaveRoles && allHaveTimestamps;
    
    results.push({
      test: 'Data Consistency',
      pass: dataConsistent,
      source: result.source,
      details: `All required fields present across ${users.length} users`
    });
  } catch (error) {
    console.log(`❌ Error: ${error.message}`);
    results.push({
      test: 'Data Consistency',
      pass: false,
      source: 'error',
      details: error.message
    });
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 FALLBACK SYSTEM TEST SUMMARY');
  console.log('='.repeat(50));

  const passed = results.filter(r => r.pass).length;
  const total = results.length;
  const successRate = total > 0 ? (passed / total * 100).toFixed(1) : 0;

  results.forEach(result => {
    const status = result.pass ? '✅ PASS' : '❌ FAIL';
    console.log(`${status} ${result.test} (${result.source}): ${result.details}`);
  });

  console.log(`\nOverall: ${passed}/${total} passed (${successRate}%)`);

  // Save results
  const report = {
    timestamp: new Date().toISOString(),
    summary: {
      totalTests: total,
      totalPassed: passed,
      successRate: parseFloat(successRate)
    },
    results
  };

  fs.writeFileSync('/tmp/fallback_test_results.json', JSON.stringify(report, null, 2));
  console.log('\n📄 Detailed results saved to /tmp/fallback_test_results.json');

  return report;
}

// Handle command line execution
if (require.main === module) {
  testFallbackSystem().catch(console.error);
}

module.exports = { testFallbackSystem };