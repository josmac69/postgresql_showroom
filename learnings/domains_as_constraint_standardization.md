# Domains - standardization of constraints

If you need to ensure that the same constraints across application are really the same, then use so called “domain”.
It is public definition of constraint you can use repeatedly in whole application.

Example is of for simplicity taken from PG documentation because it is clear enough:
```
CREATE DOMAIN us_postal_code AS TEXT
CHECK(
   VALUE ~ '^\d{5}$'
OR VALUE ~ '^\d{5}-\d{4}$'
);

CREATE TABLE us_snail_addy (
  address_id SERIAL PRIMARY KEY,
  street1 TEXT NOT NULL,
  street2 TEXT,
  street3 TEXT,
  city TEXT NOT NULL,
  postal us_postal_code NOT NULL
);
```
