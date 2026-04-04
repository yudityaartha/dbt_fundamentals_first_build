# dbt Personal Learning Project

A personal dbt project for building end-to-end, to hone and mastering proficiency in dbt, from core fundamentals through advanced patterns. This repo serves as both a learning sandbox, progress tracking and a living reference for dbt features, understanding the tools and best practices.

## About

This project is my hands-on workspace for mastering dbt with a structured environment where I work through courses, experiment with features, and build muscle memory with analytics engineering workflows. Everything here is learned by doing.

## Learning Milestones

### Completed

- **dbt Fundamentals** — Models, seeds, tests, documentation, sources, and deployment basics. First GitHub commit pushed from this project.
- **Jinja, Macros, and Packages** — Jinja templating, writing custom macros (`grant_select`, `clean_stale_models`, `union_tables_by_prefix`), installing and using dbt packages, `generate_schema_name` override, environment-based schema routing.

### Up Next

- Advanced Materializations
- Advanced Testing
- Advanced Deployment

## Project Structure

```
dbt_fundamentals/      -- root project, the contents can be added and modified later time
├── analysis/          -- ad hoc analytical queries
├── dbt_packages/      -- installed dbt packages
├── images_screencaps/ -- supporting images
├── macros/            -- custom Jinja macros
├── models/ 
│   ├── staging/       -- transformations model
│   └── marts/         -- final models
├── seeds/             -- CSV reference data
├── snapshots/         
├── target/            
├── tests/             -- custom data tests
└── dbt_project.yml
└── chapters_learning_notes.md -- My learning notes. Both to train my articulation and prove my understandings to what I've learnt
```

## Tools & Stack

- **dbt Core** (CLI via VS Code)
- **Snowflake** (course environment)
- **Git + GitHub** for version control
- **VS Code** as IDE

## Author

**Yuditya Artha** | GitHub: [yudityaartha](https://github.com/yudityaartha).  
Current role: Data Analyst | Analytics Engineer