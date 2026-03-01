# NutriLogger Brainstorming

## Current workflow

1. Estimate portion of the current meal
2. Copy template from page in copilot
3. Update meal type, date, time, items and portions
4. Copy TSV output from copilot
5. Paste TSV output into Excel

## How to improve the process prgrammatically

- Can portions be estimated better?
- Can I have a template that is easier to access?
- Can the template be a form that I can use?
- Can I make replacement of values easier with drop downs, prefilled info, estimated inputs?
- Can the information be verified using outside sources?
- Can the copying be automated to the correct database?

## What I need

- A database
- A logging input
- Access to a database of nutrition both online and offline
- A syncing engine
- Estimator
- LLM for help in estimation

### Database

- SQLite for quick development
- MariaDB for next steps for added security
- Database with my info is encrypted at rest
- Data is encrypted when sent to it
- Use current tables in Excel
- Tables for data, views for calculated and aggregate data
- Stored procedures needed?
- Functions for lookups
- Separate DB for food, update this as needed

### Sync Engine

- Local DNS? Syncthing? External service?
- There needs to be an encrypted way to access this

### Logging Template

- CLI for development
- Android app or tasker for production?
- Seach for previous meal?
- Ask to fill?
- Logging engine in python?

### Nutrition Database

- Use API for online checks
- Use DB for offline
- When online, check to update offline DB if there is something missing
- Add custom foods, meals and groupings to offline DB

### LLM

- Add support for this last that can do all the work

## Development notes

- Start with database translation
- Add logging engine
- Create front end
- Finalize sync engine
- Create agentic AI usage to do entire workflow