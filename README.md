# Data Warehouse and Analytics Project

Welcome to the **Data Warehouse and Analytics Project** repository! 🚀  

This project demonstrates a comprehensive data warehousing and analytics solution, from building a data warehouse to generating actionable insights. Designed as a portfolio project, it highlights industry best practices in data engineering and analytics.

---
## 📖 Project Overview

This project involves:

1. **Data Architecture**: Designing a modern data warehouse using the Medallion Architecture, with **Bronze**, **Silver**, and **Gold** layers.
2. **ETL Pipelines**: Extracting, transforming, and loading data from source systems into the warehouse.
3. **Data Modeling**: Developing fact and dimension tables optimized for analytical queries.
4. **Analytics & Reporting**: Creating SQL-based reports and dashboards for actionable insights.

🎯 This repository is an excellent resource for professionals and students looking to showcase expertise in:
- SQL Development
- Data Architecture
- Data Engineering  
- ETL Pipeline Development  
- Data Modeling  
- Data Analytics  

---

## 🛠️ Tools Used

- **[SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-downloads):** Used to host the database and build the Bronze, Silver, and Gold layers.
- **[Docker](https://www.docker.com/):** Used to run SQL Server in a container on macOS, since SQL Server does not run natively on Mac.
- **[Visual Studio Code](https://code.visualstudio.com/):** Used to write and run the SQL scripts and manage the database, with the SQL Server (mssql) extension.
- **[Git Repository](https://github.com/):** Used to manage, version, and share the project code on GitHub.
- **[Draw.io](https://www.drawio.com/):** Used to design the data architecture, data models, and data flow diagrams.
- **[Notion](https://www.notion.com/):** Used for project management and organization.

---

## 🚀 Project Requirements

### Building the Data Warehouse (Data Engineering)

#### Objective
Develop a modern data warehouse using SQL Server to consolidate sales data, enabling analytical reporting and informed decision-making.

#### Specifications
- **Data Sources**: Import data from two source systems (ERP and CRM) provided as CSV files.
- **Data Quality**: Cleanse and resolve data quality issues prior to analysis.
- **Integration**: Combine both sources into a single, user-friendly data model designed for analytical queries.
- **Scope**: Focus on the latest dataset only, as historization of data is not required.
- **Documentation**: Provide clear documentation of the data model to support both business stakeholders and analytics teams.

---

### BI: Analytics & Reporting (Data Analysis)

#### Objective
Develop SQL-based analytics to deliver detailed insights into:
- **Customer Behavior**
- **Product Performance**
- **Sales Trends**

These insights empower stakeholders with key business metrics, enabling strategic decision-making.  

---

## 🏗️ Data Architecture

The data architecture follows the Medallion Architecture, which organizes data into **Bronze**, **Silver**, and **Gold** layers.

![Data Architecture](docs/Data%20Architecture.png)

- **Bronze Layer**: Stores raw data as-is from the source systems. Data is ingested from CSV files into the SQL Server database.
- **Silver Layer**: Includes cleansing, standardization, and normalization processes to prepare data for analysis.
- **Gold Layer**: Houses business-ready data modeled into a star schema required for reporting and analytics.

---

## 🛡️ License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution.

## 🌟 About Me

Hi, I'm **Akash Khizar**, a data analyst and engineer who loves working with numbers and turning them into insights that help businesses grow and run more efficiently. With a strong penchant for AI automation, I build workflows that replace repetitive, manual processes and improve productivity.
