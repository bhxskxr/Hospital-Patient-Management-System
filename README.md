# Hospital-Patient-Management-System
A complete MS SQL Server database project for managing hospital operations, including doctors, patients, staff, appointments, prescriptions, rooms, and billing with triggers, functions, cursors, and stored procedures.

# Hospital Patient Management System (MS SQL Server)

This project implements a **Hospital Patient Management System** using **MS SQL Server**.  
It covers database creation, table structures, relationships, triggers, stored procedures, functions, and sample queries to manage hospital operations.

## **Features**
- Doctor, patient, and staff management
- Contact, address, and department mapping
- Appointments and prescriptions
- Medical tests, procedures, and room assignments
- Triggers for data integrity
- Stored procedures for modular operations
- Functions for data retrieval
- Cursors for iterative operations

## **Technologies Used**
- Microsoft SQL Server (T-SQL)
- SQL Server Management Studio (SSMS)

## **How to Run**
1. Open SQL Server Management Studio (SSMS).
2. Create a new database using:
   ```sql
   IF DB_ID('HMS1') IS NULL
       CREATE DATABASE HMS1;
   GO
   USE HMS1;
   GO
