package com.example.config

import org.springframework.jdbc.datasource.lookup.AbstractRoutingDataSource

class TenantRoutingDataSource : AbstractRoutingDataSource() {
    
    companion object {
        private val TENANT_CONTEXT = ThreadLocal<String>()
        
        fun setCurrentTenant(tenant: String) {
            TENANT_CONTEXT.set(tenant)
        }
        
        fun getCurrentTenant(): String? {
            return TENANT_CONTEXT.get()
        }
        
        fun clear() {
            TENANT_CONTEXT.remove()
        }
    }
    
    override fun determineCurrentLookupKey(): Any? {
        return getCurrentTenant()
    }
}