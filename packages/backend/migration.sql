CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

START TRANSACTION;
CREATE TABLE clinic (
    id uuid NOT NULL,
    name text NOT NULL,
    type integer NOT NULL,
    address text NOT NULL,
    phone_number text,
    email text,
    cnpj text,
    is_active boolean NOT NULL,
    latitude double precision,
    longitude double precision,
    image_url text,
    image_file_name text,
    image_size bigint,
    image_content_type text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT pk_clinic PRIMARY KEY (id)
);

CREATE TABLE plans (
    id uuid NOT NULL,
    name text NOT NULL,
    description text,
    credits integer NOT NULL,
    price numeric NOT NULL,
    original_price numeric,
    validity_days integer NOT NULL,
    is_active boolean NOT NULL,
    display_order integer NOT NULL,
    is_featured boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT pk_plans PRIMARY KEY (id)
);

CREATE TABLE users (
    id uuid NOT NULL,
    application_user_id uuid NOT NULL,
    email text NOT NULL,
    full_name text NOT NULL,
    role integer NOT NULL,
    first_name text,
    last_name text,
    display_name text,
    phone_number text,
    firebase_uid text,
    is_active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT pk_users PRIMARY KEY (id)
);

CREATE TABLE clinic_image (
    id uuid NOT NULL,
    clinic_id uuid NOT NULL,
    image_url character varying(2048) NOT NULL,
    file_name character varying(500) NOT NULL,
    storage_file_name character varying(500) NOT NULL,
    size bigint NOT NULL,
    content_type character varying(100) NOT NULL,
    alt_text character varying(500),
    description character varying(1000),
    display_order integer NOT NULL,
    is_featured boolean NOT NULL,
    width integer,
    height integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT pk_clinic_image PRIMARY KEY (id),
    CONSTRAINT fk_clinic_image_clinic_clinic_id FOREIGN KEY (clinic_id) REFERENCES clinic (id) ON DELETE CASCADE
);

CREATE TABLE user_plans (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    plan_id uuid NOT NULL,
    credits integer NOT NULL,
    credits_remaining integer NOT NULL,
    amount_paid numeric NOT NULL,
    expiration_date timestamp with time zone NOT NULL,
    is_active boolean NOT NULL,
    payment_method text,
    payment_transaction_id text,
    notes text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT pk_user_plans PRIMARY KEY (id),
    CONSTRAINT fk_user_plans_plans_plan_id FOREIGN KEY (plan_id) REFERENCES plans (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_plans_users_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE transactions (
    id uuid NOT NULL,
    code text NOT NULL,
    user_plan_id uuid NOT NULL,
    clinic_id uuid NOT NULL,
    status integer NOT NULL,
    credits_used integer NOT NULL,
    service_description text NOT NULL,
    validation_date timestamp with time zone,
    validated_by text,
    validation_notes text,
    ip_address text,
    user_agent text,
    latitude double precision,
    longitude double precision,
    cancellation_reason text,
    cancellation_date timestamp with time zone,
    qrtoken text,
    qrnonce text,
    service_type text,
    amount numeric NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT pk_transactions PRIMARY KEY (id),
    CONSTRAINT fk_transactions_clinic_clinic_id FOREIGN KEY (clinic_id) REFERENCES clinic (id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_user_plans_user_plan_id FOREIGN KEY (user_plan_id) REFERENCES user_plans (id) ON DELETE CASCADE
);

CREATE INDEX ix_clinic_image_clinic_id ON clinic_image (clinic_id);

CREATE INDEX ix_transactions_clinic_id ON transactions (clinic_id);

CREATE INDEX ix_transactions_user_plan_id ON transactions (user_plan_id);

CREATE INDEX ix_user_plans_plan_id ON user_plans (plan_id);

CREATE INDEX ix_user_plans_user_id ON user_plans (user_id);

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20250905123729_InitialMigration', '9.0.7');

COMMIT;

