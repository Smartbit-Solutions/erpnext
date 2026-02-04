# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smartbits ERP (formerly ERPNext) is a comprehensive open-source ERP system built on the Frappe Framework. This is a rebrand of ERPNext to Smartbits ERP. The application handles accounting, inventory, manufacturing, CRM, projects, HR, and more.

**Tech Stack:**
- Backend: Python 3.14+ (Frappe Framework v17+)
- Frontend: JavaScript/Vue.js (Frappe UI)
- Database: MariaDB 10.6+
- Build Tool: Bench (Frappe's development tool)

## Development Environment Setup

This app requires the Frappe Framework and uses `bench` for development:

```bash
# Start the development server (from bench directory)
bench start

# Create a new site
bench new-site erpnext.localhost

# Install this app on a site
bench --site erpnext.localhost install-app erpnext

# Access at http://erpnext.localhost:8000/app
```

## Common Commands

### Testing
```bash
# Run all tests for the app
bench --site [sitename] run-tests --app erpnext

# Run tests for a specific doctype
bench --site [sitename] run-tests --doctype "Sales Invoice"

# Run tests for a specific module
bench --site [sitename] run-tests --module erpnext.accounts

# Run a specific test file
bench --site [sitename] run-tests --test erpnext.accounts.doctype.sales_invoice.test_sales_invoice

# Run parallel tests (used in CI)
bench --site [sitename] run-parallel-tests --app erpnext
```

### Code Quality
```bash
# Run linters (use pre-commit hooks)
pre-commit run --all-files

# Run ruff for Python linting
ruff check .

# Run ruff formatter
ruff format .

# Run prettier for JS/Vue
prettier --write "**/*.{js,vue,scss}"

# Run eslint
eslint "**/*.js"
```

### Database & Migrations
```bash
# Run database migrations
bench --site [sitename] migrate

# Clear cache
bench --site [sitename] clear-cache

# Rebuild doctype caches
bench --site [sitename] build

# Console access for debugging
bench --site [sitename] console
```

## Architecture

### Frappe Framework Foundation

This app is built on Frappe Framework, which provides:
- **DocTypes**: Core data models defined in JSON (`.json` files in `doctype/` directories)
- **Controllers**: Python classes extending `frappe.model.document.Document`
- **Hooks**: App configuration and event handlers defined in `hooks.py`
- **Client Scripts**: JavaScript for form customization (`.js` files alongside doctypes)

### Key Architectural Patterns

#### Controller Hierarchy
The `erpnext/controllers/` directory contains base controllers that provide shared functionality:

- **`accounts_controller.py`**: Base for all accounting transactions (invoices, payments, etc.)
  - Handles GL entries, party account validation, pricing rules, taxes & totals
  - Extended by Sales Invoice, Purchase Invoice, Payment Entry, etc.

- **`stock_controller.py`**: Base for stock transactions
  - Manages stock ledger entries, serial/batch numbers, warehouse transfers
  - Extended by Stock Entry, Delivery Note, Purchase Receipt, etc.

- **`buying_controller.py`**: Base for purchase transactions
  - Handles supplier-related logic, purchase pricing
  - Extended by Purchase Order, Purchase Receipt, Purchase Invoice

- **`selling_controller.py`**: Base for sales transactions
  - Handles customer-related logic, sales pricing, credit limits
  - Extended by Sales Order, Delivery Note, Sales Invoice

- **`taxes_and_totals.py`**: Calculates taxes and document totals
  - Used by both buying and selling controllers

- **`status_updater.py`**: Updates document status based on linked documents
  - E.g., marks Purchase Order as "Completed" when fully received

#### DocType Structure
Each DocType typically has:
```
doctype_name/
├── doctype_name.json          # Field definitions, permissions, properties
├── doctype_name.py            # Server-side controller (Python class)
├── doctype_name.js            # Client-side form script
├── test_doctype_name.py       # Unit tests
└── doctype_name_list.js       # (Optional) List view customization
```

#### Module Organization
```
erpnext/
├── accounts/          # Accounting, invoicing, payments
├── stock/             # Inventory, warehouses, stock movements
├── selling/           # Sales orders, customers, quotations
├── buying/            # Purchase orders, suppliers, RFQs
├── manufacturing/     # BOMs, work orders, production
├── projects/          # Project management, tasks, timesheets
├── crm/              # Leads, opportunities, campaigns
├── support/          # Issues, service level agreements
├── assets/           # Asset management, depreciation
├── setup/            # Company, employee, territory setup
├── controllers/      # Shared base controllers (see above)
├── regional/         # Country-specific customizations
└── patches/          # Database migration patches
```

### Hooks System

The `hooks.py` file is central to app configuration. Key hooks:

- **`doc_events`**: Trigger functions on document lifecycle events (validate, on_submit, on_cancel, etc.)
- **`scheduler_events`**: Background jobs (cron, hourly, daily)
- **`override_whitelisted_methods`**: Replace framework methods
- **`extend_doctype_class`**: Extend DocType classes
- **`regional_overrides`**: Country-specific function overrides

### Regional Customizations

Country-specific features are in `erpnext/regional/`. Use the `@erpnext.allow_regional` decorator to make functions regionally overridable based on company country.

## Code Style & Conventions

### Python
- Follow `pyproject.toml` Ruff configuration
- Use tabs for indentation (not spaces)
- Line length: 110 characters
- Import sorting: Use Ruff's isort
- Type hints: Use Frappe's DF typing module (`frappe.types.DF`)

### JavaScript
- Follow `.eslintrc` and `.stylelintrc` rules
- Use prettier for formatting
- Frappe's client-side API: `frappe.call()`, `frappe.db.get_value()`, etc.

### Naming Conventions
- DocTypes: CamelCase with spaces (e.g., "Sales Invoice")
- Python files: snake_case
- Python classes: CamelCase
- Functions/variables: snake_case

## Testing Philosophy

- Tests use `unittest` framework (not pytest)
- Test files are named `test_*.py`
- Tests create their own test data using Frappe's test utilities
- Use `frappe.set_user()` to simulate different user contexts
- Clean up test data in tearDown or use `frappe.db.rollback()`

Example test structure:
```python
import frappe
from frappe.tests.utils import FrappeTestCase

class TestSalesInvoice(FrappeTestCase):
    def test_sales_invoice_creation(self):
        # Test implementation
        pass
```

## Important Notes

### Branding
This is a rebrand from ERPNext to Smartbits ERP. User-facing strings should use "Smartbits ERP" but internal code references may still use "erpnext" for backward compatibility.

### Main Branch
- Main development branch: `develop` (not `main` or `master`)
- Never commit directly to `develop` (pre-commit hook blocks this)

### Frappe Framework Dependency
- Always check Frappe Framework documentation for framework-level features
- This app version 17.x requires Frappe Framework >= 17.0.0
- Many utilities come from Frappe (e.g., `frappe.utils`, `frappe.model.document`)

### DocType Modifications
- DocType JSON files are the source of truth for schema
- After modifying a DocType JSON, run `bench migrate` to apply changes
- Custom fields should be added via Custom Field DocType, not by editing JSON directly in production

### Performance Considerations
- Use `frappe.db.get_value()` instead of `frappe.get_doc()` for single field lookups
- Cache frequently accessed values in `frappe.local` or `frappe.flags`
- Use `frappe.get_cached_value()` for values that rarely change
- Be mindful of query performance in reports - use QB (query builder) for complex queries

### Scheduled Jobs
Background jobs in `scheduler_events` hook run automatically via `bench scheduler`. Test them locally using:
```bash
bench --site [sitename] execute erpnext.path.to.function
```
