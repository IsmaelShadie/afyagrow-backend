CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          VARCHAR(120) NOT NULL,
  email         VARCHAR(255) UNIQUE,
  phone         VARCHAR(20)  UNIQUE,
  password_hash VARCHAR(255),
  role          VARCHAR(20)  DEFAULT 'citizen' CHECK (role IN 
('citizen','chw','doctor','admin')),
  lang          VARCHAR(5)   DEFAULT 'rw',
  blood_type    VARCHAR(5),
  allergies     TEXT,
  province      VARCHAR(60),
  district      VARCHAR(60),
  sector        VARCHAR(60),
  mutuelle_id   VARCHAR(50),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS emergency_contacts (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
  name       VARCHAR(120) NOT NULL,
  phone      VARCHAR(20)  NOT NULL,
  relation   VARCHAR(60),
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_messages (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID REFERENCES users(id) ON DELETE CASCADE,
  role         VARCHAR(20) CHECK (role IN ('user','assistant')),
  content      TEXT NOT NULL,
  lang         VARCHAR(5) DEFAULT 'rw',
  is_emergency BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS symptom_checks (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  symptoms    JSONB NOT NULL,
  triage      VARCHAR(20) CHECK (triage IN ('mild','urgent','emergency')),
  ai_response TEXT,
  lat         DECIMAL(9,6),
  lon         DECIMAL(9,6),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS health_facilities (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name             VARCHAR(200) NOT NULL,
  type             VARCHAR(40) CHECK (type IN 
('hospital','health_center','clinic','pharmacy','district_hospital','referral_hospital')),
  province         VARCHAR(60),
  district         VARCHAR(60),
  sector           VARCHAR(60),
  address          TEXT,
  phone            VARCHAR(20),
  lat              DECIMAL(9,6),
  lon              DECIMAL(9,6),
  opening_hours    TEXT,
  accepts_mutuelle BOOLEAN DEFAULT TRUE,
  has_maternity    BOOLEAN DEFAULT FALSE,
  has_lab          BOOLEAN DEFAULT FALSE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS appointments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  facility_id UUID REFERENCES health_facilities(id),
  date        DATE NOT NULL,
  time        TIME NOT NULL,
  reason      TEXT,
  status      VARCHAR(20) DEFAULT 'pending' CHECK (status IN 
('pending','confirmed','completed','cancelled')),
  queue_no    INTEGER,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reminders (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
  medicine   VARCHAR(200) NOT NULL,
  dose       VARCHAR(100),
  frequency  VARCHAR(40) DEFAULT 'daily',
  times      JSONB DEFAULT '[]',
  start_date DATE,
  end_date   DATE,
  is_active  BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pregnancies (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID REFERENCES users(id) ON DELETE CASCADE,
  lmp_date       DATE NOT NULL,
  edd            DATE,
  gravida        INTEGER DEFAULT 1,
  para           INTEGER DEFAULT 0,
  anc_visits     JSONB DEFAULT '[]',
  danger_signs   JSONB DEFAULT '[]',
  birth_plan     TEXT,
  pmtct_enrolled BOOLEAN DEFAULT FALSE,
  is_active      BOOLEAN DEFAULT TRUE,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS children (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID REFERENCES users(id) ON DELETE CASCADE,
  name           VARCHAR(120) NOT NULL,
  dob            DATE NOT NULL,
  sex            VARCHAR(10),
  birth_weight   DECIMAL(4,2),
  vaccines_given JSONB DEFAULT '[]',
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS growth_records (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id   UUID REFERENCES children(id) ON DELETE CASCADE,
  date       DATE NOT NULL,
  weight_kg  DECIMAL(5,2),
  height_cm  DECIMAL(5,1),
  muac_cm    DECIMAL(4,1),
  notes      TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vitals (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  type        VARCHAR(40) CHECK (type IN 
('blood_pressure','glucose','temperature','weight','pulse_ox')),
  value_1     DECIMAL(6,2),
  value_2     DECIMAL(6,2),
  unit        VARCHAR(20),
  notes       TEXT,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS patients (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chw_id      UUID REFERENCES users(id),
  name        VARCHAR(120) NOT NULL,
  phone       VARCHAR(20),
  dob         DATE,
  sex         VARCHAR(10),
  village     VARCHAR(100),
  mutuelle_id VARCHAR(50),
  conditions  JSONB DEFAULT '[]',
  notes       TEXT,
  last_visit  DATE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS referrals (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_user_id UUID REFERENCES users(id),
  patient_id   UUID REFERENCES patients(id),
  to_facility  UUID REFERENCES health_facilities(id),
  reason       TEXT NOT NULL,
  urgency      VARCHAR(20) DEFAULT 'routine' CHECK (urgency IN 
('routine','urgent','emergency')),
  status       VARCHAR(20) DEFAULT 'pending' CHECK (status IN 
('pending','accepted','completed','rejected')),
  notes        TEXT,
  referred_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sos_events (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID REFERENCES users(id),
  lat               DECIMAL(9,6),
  lon               DECIMAL(9,6),
  triggered_by      VARCHAR(20) CHECK (triggered_by IN 
('double_tap','voice','manual')),
  contacts_notified JSONB,
  resolved          BOOLEAN DEFAULT FALSE,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS moh_alerts (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title        VARCHAR(255) NOT NULL,
  body         TEXT NOT NULL,
  severity     VARCHAR(20) DEFAULT 'info' CHECK (severity IN 
('info','warning','critical')),
  province     VARCHAR(60),
  district     VARCHAR(60),
  published_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS hmis_submissions (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chw_id              UUID REFERENCES users(id),
  period              VARCHAR(20),
  households_visited  INTEGER,
  new_pregnancies     INTEGER,
  under5_seen         INTEGER,
  malaria_cases       INTEGER,
  tb_suspects         INTEGER,
  data_json           JSONB,
  submitted_at        TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_chat_user     ON chat_messages(user_id, 
created_at DESC);
CREATE INDEX IF NOT EXISTS idx_vitals_user   ON vitals(user_id, type, 
recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_active ON moh_alerts(published_at, 
expires_at);

-- Seed: Rwanda health facilities
INSERT INTO health_facilities 
(name,type,district,lat,lon,phone,accepts_mutuelle,has_maternity) VALUES
  ('King Faisal 
Hospital','referral_hospital','Gasabo',-1.9342,30.0776,'+250788300000',TRUE,TRUE),
  ('CHUK University Teaching 
Hospital','referral_hospital','Nyarugenge',-1.9500,30.0588,'+250788301000',TRUE,TRUE),
  ('Kibagabaga 
Hospital','district_hospital','Gasabo',-1.9167,30.1167,'+250788302000',TRUE,TRUE),
  ('Kacyiru Health 
Center','health_center','Gasabo',-1.9380,30.0633,'+250788303000',TRUE,FALSE),
  ('Remera Health 
Center','health_center','Gasabo',-1.9500,30.1000,'+250788304000',TRUE,TRUE),
  ('Butaro District 
Hospital','district_hospital','Burera',-1.4733,29.8167,'+250788305000',TRUE,TRUE),
  ('Rwamagana Provincial 
Hospital','district_hospital','Rwamagana',-1.9500,30.4333,'+250788306000',TRUE,TRUE)
ON CONFLICT DO NOTHING;
