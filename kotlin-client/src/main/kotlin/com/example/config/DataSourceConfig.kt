package com.example.config

import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.jdbc.DataSourceBuilder
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Primary
import javax.sql.DataSource

@Configuration
class DataSourceConfig {

    @Bean
    @ConfigurationProperties("tenant.datasources.tenant-001")
    fun tenant001DataSource(): DataSource {
        return DataSourceBuilder.create().build()
    }

    @Bean
    @ConfigurationProperties("tenant.datasources.tenant-002")
    fun tenant002DataSource(): DataSource {
        return DataSourceBuilder.create().build()
    }

    @Bean
    @ConfigurationProperties("tenant.datasources.tenant-003")
    fun tenant003DataSource(): DataSource {
        return DataSourceBuilder.create().build()
    }

    @Bean
    @Primary
    fun routingDataSource(): DataSource {
        val routingDataSource = TenantRoutingDataSource()
        
        val targetDataSources: MutableMap<Any, Any> = mutableMapOf(
            "001" to tenant001DataSource(),
            "002" to tenant002DataSource(),
            "003" to tenant003DataSource()
        )
        
        routingDataSource.setTargetDataSources(targetDataSources)
        routingDataSource.setDefaultTargetDataSource(tenant001DataSource())
        
        return routingDataSource
    }
}