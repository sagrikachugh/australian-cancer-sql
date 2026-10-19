-- Rebuild the compact analytical schema with explicit types and table grain.
-- published_rate is age-specific for age bands and crude for All ages.

CREATE TABLE cancer_type (
  cancer_code VARCHAR PRIMARY KEY,
  cancer_name VARCHAR NOT NULL,
  icd10_codes VARCHAR,
  mortality_icd10_codes VARCHAR
);

CREATE TABLE incidence (
  cancer_code VARCHAR NOT NULL REFERENCES cancer_type(cancer_code),
  year INTEGER NOT NULL,
  sex VARCHAR NOT NULL,
  age_group VARCHAR NOT NULL,
  count INTEGER NOT NULL,
  published_rate DOUBLE,
  asr DOUBLE,
  is_projection BOOLEAN NOT NULL,
  PRIMARY KEY (cancer_code, year, sex, age_group)
);

CREATE TABLE mortality (
  cancer_code VARCHAR NOT NULL REFERENCES cancer_type(cancer_code),
  year INTEGER NOT NULL,
  sex VARCHAR NOT NULL,
  age_group VARCHAR NOT NULL,
  count INTEGER NOT NULL,
  published_rate DOUBLE,
  asr DOUBLE,
  is_projection BOOLEAN NOT NULL,
  PRIMARY KEY (cancer_code, year, sex, age_group)
);
