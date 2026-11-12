# Airbnb Analytics Warehouse with dbt and Snowflake

An analytics engineering project that transforms Airbnb-style listings, hosts, and bookings data into curated Snowflake models. It demonstrates a layered warehouse workflow with incremental ingestion, business transformations, reusable dbt macros, and snapshots for tracking changes over time.

## What it does

- Loads staged `listings`, `hosts`, and `bookings` source tables into incremental Bronze models, using `CREATED_AT` as the load watermark.
- Builds Silver models with standardized host names, host response quality bands, listing price tags, and calculated booking totals.
- Combines booking, listing, and host data into a Gold one-big-table (OBT) model for analysis.
- Defines ephemeral models and timestamp snapshots for bookings, listings, and hosts so historical dimension changes can be retained.
- Includes example SQL macros, a source-level data quality check, and dbt model configuration by layer.

## Data flow

```text
Snowflake AIRBNB.STAGING
  listings | hosts | bookings
              |
              v
Bronze: incremental source-aligned models
              |
              v
Silver: cleaned and enriched entities
              |
              v
Gold: joined booking analytics (OBT)
       + timestamp snapshots for history
```

The Gold layer also contains a `fact.sql` model that illustrates joining the OBT with snapshot dimensions. The ephemeral `bookings`, `listings`, and `hosts` models provide the snapshot inputs.

## Example transformations

- Booking total: rounded nightly rate multiplied by nights booked, plus cleaning and service fees.
- Host response quality: response rates are classified as `VERY GOOD`, `GOOD`, `FAIR`, or `POOR`.
- Listing price tag: nightly prices are grouped into `low`, `medium`, or `high` bands.
- Snapshots use timestamp strategies and `CREATED_AT`-based update timestamps to preserve historical versions.

## Tech stack

- dbt Core
- dbt-snowflake adapter
- Snowflake SQL
- Jinja macros
- Python 3.12 or newer (as specified in `pyproject.toml`)

## Project layout

```text
aws_dbt_project/
├── models/
│   ├── sources/       # Snowflake staging source declarations
│   ├── bronze/        # Incremental source-aligned models
│   ├── silver/        # Cleaned and enriched models
│   └── gold/          # Analytics models and ephemeral snapshot inputs
├── snapshots/         # Type 2 history for bookings, listings, and hosts
├── macros/            # Reusable SQL/Jinja helpers
├── tests/             # Data quality checks
└── dbt_project.yml    # Layer materializations and schemas
```

## Prerequisites

1. Python 3.12 or newer.
2. Access to a Snowflake account and an `AIRBNB.STAGING` schema containing `LISTINGS`, `HOSTS`, and `BOOKINGS` tables. The columns referenced by the models must be present, including `CREATED_AT`.
3. dbt Core and the Snowflake adapter. From the repository root, install the project dependencies with [uv](https://docs.astral.sh/uv/):

   ```bash
   uv sync
   ```

4. A dbt profile named `aws_dbt_project` in `~/.dbt/profiles.yml`, configured with your Snowflake account, user/authentication, role, warehouse, database, and schema. For example (replace values and authentication settings for your environment):

   ```yaml
   aws_dbt_project:
     target: dev
     outputs:
       dev:
         type: snowflake
         account: "<account_identifier>"
         user: "<username>"
         password: "<password>"
         role: "<role>"
         warehouse: "<warehouse>"
         database: AIRBNB
         schema: DEV
         threads: 4
   ```

   Keep credentials out of source control; use environment variables or your organization's approved authentication method.

## Run the project

Run these commands from the repository root:

```bash
cd aws_dbt_project
dbt debug
dbt run
dbt test
dbt snapshot
```

`dbt run` builds the models. `dbt test` runs the configured data quality check (the bookings amount check is configured with warning severity). `dbt snapshot` records changes using the snapshot definitions. The configured model schemas are `BRONZE`, `SILVER`, and `GOLD`; Snowflake permissions must allow dbt to create or update objects there.

## Notes

- The incremental Bronze and Silver models use `CREATED_AT`-based filters/keys. Late-arriving records with older timestamps may need a lookback window or another reconciliation strategy in a production pipeline.
- The repository includes Snowflake/dbt configuration; it does not currently define AWS services or infrastructure. Despite the repository name, an AWS deployment is not documented by the project files.
- `fact.sql` uses explicit fully qualified relation names. If you use it, confirm those relations and snapshot naming conventions match your Snowflake environment.

## Potential real-world use

This pattern is useful for a short-term rental marketplace or property manager that needs consistent booking revenue metrics, host and listing dimensions, and a history of changes. Analysts can use curated Gold data to compare revenue, occupancy-related booking activity, property types, locations, and host performance over time.
