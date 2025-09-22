-- Script para aplicar migration no banco de produção
-- Adicionar coluna credit_cost na tabela ClinicServices se não existir

DO $$
BEGIN
    -- Verificar se a coluna credit_cost já existe
    IF NOT EXISTS (
        SELECT FROM information_schema.columns
        WHERE table_name = 'ClinicServices'
        AND column_name = 'credit_cost'
    ) THEN
        -- Adicionar a coluna credit_cost
        ALTER TABLE "ClinicServices" ADD COLUMN credit_cost integer NOT NULL DEFAULT 1;

        RAISE NOTICE 'Coluna credit_cost adicionada com sucesso à tabela ClinicServices';
    ELSE
        RAISE NOTICE 'Coluna credit_cost já existe na tabela ClinicServices';
    END IF;

    -- Verificar se a tabela existe
    IF NOT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_name = 'ClinicServices'
    ) THEN
        RAISE NOTICE 'ATENÇÃO: Tabela ClinicServices não encontrada no banco de dados';
    ELSE
        RAISE NOTICE 'Tabela ClinicServices confirmada no banco de dados';
    END IF;
END $$;