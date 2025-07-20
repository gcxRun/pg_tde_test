package com.example.controller

import com.example.model.Patient
import com.example.service.PatientService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import org.springframework.web.bind.MissingRequestHeaderException

@RestController
@RequestMapping("/patients")
class PatientController(
    private val patientService: PatientService
) {
    
    companion object {
        private const val TENANT_HEADER = "X-Tenant-ID"
        private val VALID_TENANTS = setOf("001", "002", "003")
    }
    
    @GetMapping
    fun getAllPatients(@RequestHeader(TENANT_HEADER) tenantId: String): ResponseEntity<*> {
        return if (isValidTenant(tenantId)) {
            val patients = patientService.getAllPatients(tenantId)
            ResponseEntity.ok(patients)
        } else {
            ResponseEntity.badRequest().body(mapOf("error" to "Invalid tenant ID. Must be one of: ${VALID_TENANTS.joinToString(", ")}"))
        }
    }
    
    @GetMapping("/{id}")
    fun getPatientById(
        @RequestHeader(TENANT_HEADER) tenantId: String,
        @PathVariable id: Long
    ): ResponseEntity<*> {
        return if (isValidTenant(tenantId)) {
            val patient = patientService.getPatientById(tenantId, id)
            if (patient != null) {
                ResponseEntity.ok(patient)
            } else {
                ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(mapOf("error" to "Patient with ID $id not found for tenant $tenantId"))
            }
        } else {
            ResponseEntity.badRequest().body(mapOf("error" to "Invalid tenant ID. Must be one of: ${VALID_TENANTS.joinToString(", ")}"))
        }
    }
    
    @ExceptionHandler(MissingRequestHeaderException::class)
    fun handleMissingHeader(ex: MissingRequestHeaderException): ResponseEntity<Map<String, String>> {
        return ResponseEntity.badRequest().body(mapOf("error" to "Missing required header: $TENANT_HEADER"))
    }
    
    private fun isValidTenant(tenantId: String): Boolean {
        return tenantId in VALID_TENANTS
    }
}