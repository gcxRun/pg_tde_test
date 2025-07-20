# Kotlin Module Setup Instructions

This document provides instructions for setting up the kotlin-client as a proper Kotlin module in IntelliJ IDEA.

## Current Status

The kotlin-client directory has been configured as a Maven-based Kotlin module with:
- Complete Maven `pom.xml` configuration with Spring Boot and Kotlin dependencies
- Proper source directory structure (`src/main/kotlin`, `src/test/kotlin`)
- IntelliJ IDEA module configuration added to `.idea/modules.xml`

## IntelliJ IDEA Setup Steps

1. **Open Project**: Open the main `pg_tde_test` project in IntelliJ IDEA

2. **Import Maven Module**: 
   - The IDE should automatically detect the Maven module in `kotlin-client/`
   - If not detected automatically:
     - Right-click on the `kotlin-client` folder in the Project tree
     - Select "Import Maven Project" or "Add as Maven Project"

3. **Verify Module Configuration**:
   - Go to File → Project Structure → Modules
   - You should see both:
     - `pg_tde_test` (main module)
     - `kotlin-client` or `pg-tde-client` (Kotlin Maven module)

4. **Check Kotlin Configuration**:
   - In Project Structure → Modules → kotlin-client → Sources
   - Verify that:
     - `src/main/kotlin` is marked as Sources (blue folder icon)
     - `src/main/resources` is marked as Resources (yellow folder icon)
     - `src/test/kotlin` is marked as Test Sources (green folder icon)
     - `src/test/resources` is marked as Test Resources (yellow folder icon with test icon)

5. **Maven Integration**:
   - Open the Maven panel (View → Tool Windows → Maven)
   - You should see the `pg-tde-client` project listed
   - Click refresh if needed to sync dependencies

6. **Verify Kotlin Support**:
   - Open any `.kt` file in the kotlin-client module
   - Verify that syntax highlighting and IDE features work correctly
   - Check that Kotlin version 1.9.25 is being used (as configured in pom.xml)

## Module Details

- **Module Type**: Maven-based Kotlin module
- **Java Version**: 21
- **Kotlin Version**: 1.9.25
- **Spring Boot Version**: 3.2.1
- **Build Tool**: Maven
- **Main Package**: `com.example`

## Running the Application

From IntelliJ IDEA:
1. Navigate to `kotlin-client/src/main/kotlin/com/example/Application.kt`
2. Click the green arrow next to the `main` function or the `Application` class
3. Or use the Maven panel: `pg-tde-client` → Plugins → spring-boot → `spring-boot:run`

From command line:
```bash
cd kotlin-client
mvn spring-boot:run
```

## Troubleshooting

If the module doesn't load correctly:

1. **Reimport Maven Project**:
   - Right-click on `kotlin-client/pom.xml`
   - Select "Reimport"

2. **Invalidate Caches**:
   - File → Invalidate Caches and Restart

3. **Check Project SDK**:
   - File → Project Structure → Project
   - Ensure Project SDK is set to Java 21 or higher

4. **Verify Maven Configuration**:
   - File → Settings → Build, Execution, Deployment → Build Tools → Maven
   - Check that Maven home directory is properly configured