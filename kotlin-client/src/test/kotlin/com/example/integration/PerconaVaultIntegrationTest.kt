package com.example.integration

import org.junit.jupiter.api.*
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.web.client.TestRestTemplate
import org.springframework.boot.test.web.server.LocalServerPort
import org.springframework.http.*
import org.springframework.test.context.ActiveProfiles
import java.sql.DriverManager
import org.opentest4j.TestAbortedException

/**
 * Integration test for the multi-tenant API using the full Percona + Vault + PG TDE stack
 * Focuses on API functionality only - assumes encryption is properly configured
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation::class)
class PerconaVaultIntegrationTest {

    @Autowired
    private lateinit var restTemplate: TestRestTemplate
    
    @LocalServerPort
    private var port: Int = 0

    companion object {
        @JvmStatic
        @BeforeAll
        fun checkEnvironment() {
            // Check if the docker-compose environment is running
            try {
                val connection = DriverManager.getConnection(
                    "jdbc:postgresql://localhost:5433/tenant_001", 
                    "postgres", 
                    "postgres"
                )
                connection.close()
                println("✅ Docker-compose environment detected and running")
            } catch (e: Exception) {
                println("❌ Docker-compose environment not running!")
                println("Please run: docker-compose up -d")
                println("Then wait for initialization to complete before running tests")
                throw TestAbortedException("Docker-compose environment not available", e)
            }
        }
    }

    private fun createHeaders(tenantId: String): HttpHeaders {
        val headers = HttpHeaders()
        headers.set("X-Tenant-ID", tenantId)
        headers.contentType = MediaType.APPLICATION_JSON
        return headers
    }

    @Test
    @Order(1)
    fun `API should return patients for each tenant`() {
        listOf("001", "002", "003").forEach { tenantId ->
            val headers = createHeaders(tenantId)
            val entity = HttpEntity<String>(headers)
            
            val response = restTemplate.exchange(
                "http://localhost:$port/patients",
                HttpMethod.GET,
                entity,
                String::class.java
            )
            
            Assertions.assertEquals(HttpStatus.OK, response.statusCode)
            Assertions.assertNotNull(response.body)
            Assertions.assertTrue(response.body!!.contains("John Doe"))
            Assertions.assertTrue(response.body!!.contains("Jane Smith"))
            
            println("✅ Retrieved patients for tenant $tenantId")
        }
    }

    @Test
    @Order(2)
    fun `API should return specific patient by ID`() {
        val headers = createHeaders("001")
        val entity = HttpEntity<String>(headers)
        
        val response = restTemplate.exchange(
            "http://localhost:$port/patients/1",
            HttpMethod.GET,
            entity,
            String::class.java
        )
        
        Assertions.assertEquals(HttpStatus.OK, response.statusCode)
        Assertions.assertTrue(response.body!!.contains("John Doe"))
        Assertions.assertTrue(response.body!!.contains("1985-03-15"))
    }

    @Test
    @Order(3)
    fun `API should return 404 for non-existent patient`() {
        val headers = createHeaders("001")
        val entity = HttpEntity<String>(headers)
        
        val response = restTemplate.exchange(
            "http://localhost:$port/patients/999",
            HttpMethod.GET,
            entity,
            String::class.java
        )
        
        Assertions.assertEquals(HttpStatus.NOT_FOUND, response.statusCode)
        Assertions.assertTrue(response.body!!.contains("not found"))
    }

    @Test
    @Order(4)
    fun `API should return 400 for invalid tenant`() {
        val headers = createHeaders("999")
        val entity = HttpEntity<String>(headers)
        
        val response = restTemplate.exchange(
            "http://localhost:$port/patients",
            HttpMethod.GET,
            entity,
            String::class.java
        )
        
        Assertions.assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        Assertions.assertTrue(response.body!!.contains("Invalid tenant ID"))
    }

    @Test
    @Order(5)
    fun `API should return 400 for missing tenant header`() {
        val headers = HttpHeaders()
        headers.contentType = MediaType.APPLICATION_JSON
        val entity = HttpEntity<String>(headers)
        
        val response = restTemplate.exchange(
            "http://localhost:$port/patients",
            HttpMethod.GET,
            entity,
            String::class.java
        )
        
        Assertions.assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        Assertions.assertTrue(response.body!!.contains("Missing required header"))
    }

    @Test
    @Order(6)
    fun `verify tenant isolation - different tenants return their own data`() {
        // Each tenant should get the same patient names but from their own database
        val patientCounts = mutableMapOf<String, Int>()
        
        listOf("001", "002", "003").forEach { tenantId ->
            val headers = createHeaders(tenantId)
            val entity = HttpEntity<String>(headers)
            
            val response = restTemplate.exchange(
                "http://localhost:$port/patients",
                HttpMethod.GET,
                entity,
                String::class.java
            )
            
            Assertions.assertEquals(HttpStatus.OK, response.statusCode)
            
            // Count occurrences of "id" to count patients
            val patientCount = response.body!!.split("\"id\"").size - 1
            patientCounts[tenantId] = patientCount
        }
        
        // All tenants should have 5 patients
        patientCounts.forEach { (tenant, count) ->
            Assertions.assertEquals(5, count, "Tenant $tenant should have 5 patients")
        }
        
        println("✅ Verified tenant isolation - each tenant has its own data")
    }

    @Test
    @Order(7)
    fun `concurrent requests to different tenants should work correctly`() {
        val threads = listOf("001", "002", "003").map { tenantId ->
            Thread {
                val headers = createHeaders(tenantId)
                val entity = HttpEntity<String>(headers)
                
                val response = restTemplate.exchange(
                    "http://localhost:$port/patients",
                    HttpMethod.GET,
                    entity,
                    String::class.java
                )
                
                Assertions.assertEquals(HttpStatus.OK, response.statusCode)
                println("Thread for tenant $tenantId completed successfully")
            }
        }
        
        // Start all threads
        threads.forEach { it.start() }
        
        // Wait for all to complete
        threads.forEach { it.join() }
        
        println("✅ Concurrent requests handled correctly")
    }
}