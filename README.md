# ICT371 - Advanced PostgreSQL Assignment

**Institution:** Mulungushi University  
**Course:** ICT371 - Database Systems / PostgreSQL Development  
**Student Number:** 202402226  
**GitHub Username:** lwendongandu98-bot  

---

## 📌 Project Overview

This repository contains procedural PL/pgSQL solutions for four distinct operational database scenarios. Each SQL script implements relational schema design, procedural business logic, transactional control, conditional logic, loops, explicit cursors, and custom exception handling.

---

## 📁 Repository Structure

| File Name | Scenario Name | Primary Domain / Functionality |
| :--- | :--- | :--- |
| `scenario1_202402226.sql` | **Library System** | Book inventory management, loan issuing, and return handling. |
| `scenario2_202402226.sql` | **Lab Sessions** | Workstation reservation management and cancellation tracking. |
| `scenario3_202402226.sql` | **Hostel Allocation** | Room bed space allocation and checkout management. |
| `scenario4_202402226.sql` | **Clinic Dispensing** | Medicine stock monitoring, dispensing, and order reversal. |

---

## 🛠️ Implementation Requirements Addressed

Every `.sql` script follows a structured 9-step execution workflow:

1. **Schema & Data Definition:** Creation of primary/transactional tables with `CHECK` constraints, foreign key constraints, and seed data.
2. **Conditional Control (`IF...ELSIF...ELSE`):** Anonymous block (`DO $$`) reporting stock/capacity availability thresholds.
3. **Iterative Control (`WHILE` & `FOR`):** Execution of event loops running exactly 3 iterations each.
4. **Core Stored Procedures:** Transactional procedures using `FOR UPDATE` row-level locks to handle concurrencies and validate stock before state updates.
5. **Execution & State Queries:** Validating successful transactions as well as over-capacity error handling.
6. **Idempotent Reversals:** Safe state checks preventing redundant stock additions upon double reversals or returns.
7. **Explicit Cursors:** Life-cycle management (`DECLARE`, `OPEN`, `FETCH`, `EXIT WHEN NOT FOUND`, `CLOSE`) filtering low-capacity rows.
8. **Exception Handling:** Custom exception blocks capturing runtime constraint violations using `SQLERRM`.
9. **Verification Queries:** Final state output for validation.

---

## 🚀 Execution Instructions

1. Clone or download this repository:
   ```bash
   git clone [https://github.com/lwendongandu98-bot/ICT371-PostgreSQL-Assignment.git](https://github.com/lwendongandu98-bot/ICT371-PostgreSQL-Assignment.git)
