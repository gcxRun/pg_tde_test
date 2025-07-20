package com.example.service

import com.example.config.TenantRoutingDataSource
import com.example.model.Patient
import com.example.repository.PatientRepository
import org.springframework.stereotype.Service
import java.util.*

@Service
class PatientService(
    private val patientRepository: PatientRepository
) {
    
    fun getAllPatients(tenantId: String): List<Patient> {
        return executeWithTenant(tenantId) {
            patientRepository.findAll()
        }
    }
    
    fun getPatientById(tenantId: String, id: Long): Patient? {
        return executeWithTenant(tenantId) {
            patientRepository.findById(id).orElse(null)
        }
    }
    
    private fun <T> executeWithTenant(tenantId: String, operation: () -> T): T {
        return try {
            TenantRoutingDataSource.setCurrentTenant(tenantId)
            operation()
        } finally {
            TenantRoutingDataSource.clear()
        }
    }
}