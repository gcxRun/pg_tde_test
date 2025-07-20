package com.example.model

import jakarta.persistence.*
import java.time.LocalDate

@Entity
@Table(name = "patients")
data class Patient(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    
    @Column(name = "name", nullable = false, length = 100)
    val name: String,
    
    @Column(name = "date_of_birth", nullable = false)
    val dateOfBirth: LocalDate
)