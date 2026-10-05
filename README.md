# ResiDry

### Smart Laundry Service for Residential Buildings

ResiDry is a mobile application designed to provide a convenient laundry and drying service directly within residential buildings.

Many apartments have limited space for drying clothes, especially large items such as duvets, blankets, and large sheets. ResiDry addresses this problem through a network of **smart lockers** installed within residences.

Residents can deposit their laundry into an assigned locker. The laundry is then collected, transported to a partner laundry company, processed, and returned to the residence. The application provides management and tracking throughout the process.

The project combines **mobile development, IoT, and intelligent services** to improve the efficiency and automation of the laundry process.

---

## Project

**Project:** ResiDry
**Class:** 4IET_I4
**Team:** Ethivon
**Platform:** Mobile Application
**Development:** Flutter / Dart

---

## Team & Modules

Each team member is responsible for a dedicated module.

| Member                  | Responsibility                 | Module              |
| ----------------------- | ------------------------------ | ------------------- |
| Mohamed Khalil Marzouki | Locker Management              | `lockers`           |
| Ben Dziri Sabaa         | Intelligent Laundry Management | `laundry`           |
| Achwek Ourari           | Laundry Company Management     | `laundry_companies` |
| Aymen Abdellatif        | Delivery Driver Management     | `delivery_drivers`  |
| Mohamed Raed Boukari    | Resident Management            | `residents`         |
| Saber Ben Amira         | Order Management               | `orders`            |

---

## Project Structure

```text
lib/
│
├── features/
│   ├── lockers/
│   ├── laundry/
│   ├── laundry_companies/
│   ├── delivery_drivers/
│   ├── residents/
│   └── orders/
│
├── core/
├── database/
├── models/
├── services/
├── shared/
└── main.dart
```

Each module is developed independently and integrated into the main application through Git.

Shared database setup belongs in `database/`, reusable data models in `models/`,
cross-feature business and integration logic in `services/`, and reusable UI or
utilities in `shared/`.

---

# Git Workflow

To maintain a clean and stable codebase, **direct pushes to `main` are not allowed.**

Every feature must be developed on a dedicated branch and integrated through a Pull Request.

### Branches

Use the following naming convention:

```text
feature/<module>
```

Examples:

```text
feature/lockers
feature/laundry
feature/laundry-companies
feature/delivery-drivers
feature/residents
feature/orders
```

---

## Development Workflow

### 1. Update `main`

```bash
git checkout main
git pull origin main
```

### 2. Create your feature branch

```bash
git checkout -b feature/lockers
```

Replace `lockers` with your assigned module.

### 3. Develop your module

Work primarily inside your assigned directory:

```text
lib/features/<your-module>/
```

Avoid modifying another member's module unless the team has agreed on the change.

### 4. Commit your work

Use clear and descriptive commits:

```bash
git add .
git commit -m "feat(lockers): implement locker management"
```

Examples:

```text
feat(laundry): implement laundry tracking
feat(residents): add resident management
feat(orders): implement order creation
fix(lockers): fix locker availability status
```

### 5. Push your branch

```bash
git push -u origin feature/lockers
```

### 6. Create a Pull Request

Create a Pull Request on GitHub:

```text
feature/lockers → main
```

The Pull Request should briefly describe:

* What was implemented
* What was modified
* Any dependencies on another module
* Any issues that need attention

### 7. Review & Merge

The code should be reviewed and tested before being merged into `main`.

```text
Feature Branch
      ↓
Development
      ↓
Commit
      ↓
Push
      ↓
Pull Request
      ↓
Code Review
      ↓
Testing
      ↓
Merge → main
```

---

# Collaboration Rules

### Do

* Work on your assigned branch.
* Keep your module organized.
* Use meaningful commit messages.
* Pull the latest `main` regularly.
* Test your changes before creating a Pull Request.
* Keep Pull Requests focused on one feature or task.
* Communicate before modifying another member's module.

### Don't

* Push directly to `main`.
* Commit API keys, passwords, or private credentials.
* Make unrelated changes in your feature branch.
* Delete or modify another member's module without discussion.
* Create very large commits containing multiple unrelated features.

---

# Integration

The `main` branch represents the **integrated and stable version** of ResiDry.

Each module is developed independently and progressively integrated through Pull Requests.

The goal is to keep the project modular, maintainable, and easy for all team members to work on simultaneously.

---

## Technologies

* **Flutter**
* **Dart**
* **IoT**
* **Artificial Intelligence**
* **REST APIs**
* **Git / GitHub**

---

## Objective

ResiDry aims to provide a practical and connected laundry service within residential buildings by connecting:

```text
Residents
    ↓
Smart Lockers
    ↓
Delivery
    ↓
Laundry Companies
    ↓
Delivery
    ↓
Residents
```

The mobile application acts as the central interface for managing and monitoring this process.

---

### Team Ethivon

**4IET_I4 — ResiDry**

> Develop independently. Review collaboratively. Integrate safely.
