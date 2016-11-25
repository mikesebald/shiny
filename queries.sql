-- Total number of records
SELECT COUNT(*) FROM record_actual;

-- Total number of source records
SELECT COUNT(*) FROM record_actual WHERE "_id.s" <> 'system';

-- Total number of golden records
SELECT COUNT(*) FROM record_actual WHERE "_id.s" = 'system';

-- Total number of valid source records
SELECT COUNT(*) FROM record_actual WHERE "_id.s" <> 'system' AND "validated.status" = 'valid';

-- Total number of invalid source records
SELECT COUNT(*) FROM record_actual WHERE "_id.s" <> 'system' AND "validated.status" = 'invalid';

-- Total number of source records of type person
SELECT COUNT(*) FROM record_actual WHERE "raw.type" = 'person';
SELECT COUNT(*) FROM record_actual_raw_person WHERE "raw.type" = 'person';
SELECT COUNT(*) FROM record_actual WHERE "validated.type" = 'person';
SELECT COUNT(*) FROM record_actual_validated_person WHERE "validated.type" = 'person';
-- !!! It is important to allways provide *.type = 'person' (for persons) since we can have both 
-- !!! organizations and persons in one record at the same time

-- Total number of source records of type organization
SELECT COUNT(*) FROM record_actual WHERE "raw.type" = 'organization';
SELECT COUNT(*) FROM record_actual_raw_organization WHERE "raw.type" = 'organization';
SELECT COUNT(*) FROM record_actual WHERE "validated.type" = 'organization';
SELECT COUNT(*) FROM record_actual_validated_organization WHERE "validated.type" = 'organization';

-- Total number of valid/invalid source records of type person
SELECT COUNT(*) FROM record_actual_validated_person WHERE "validated.status" = 'valid' AND "validated.type" = 'person';
SELECT COUNT(*) FROM record_actual_validated_person WHERE "validated.status" = 'invalid' AND "validated.type" = 'person';

-- (Number of) invalid addresses
SELECT * FROM record_actual_validated_postal_address_validation_message WHERE "validated.postal_address.validation_message.is_error" = 'true' AND "validated.postal_address.validation_message.type" = 'uniserv_address';
-- Number OF RECORDS with invalid addresses
SELECT COUNT(DISTINCT "_id.k") FROM record_actual_validated_postal_address_validation_message WHERE "validated.postal_address.validation_message.is_error" = 'true' AND "validated.postal_address.validation_message.type" = 'uniserv_address';
-- !!! Keep the check for validation_message.type" = 'uniserv_address' because of the origin copy system errors which we want to exclude

-- Number of persons with invalid addresses
SELECT COUNT(DISTINCT "_id.k") FROM record_actual_validated_postal_address_validation_message WHERE "validated.postal_address.validation_message.is_error" = 'true' AND "validated.postal_address.validation_message.type" = 'uniserv_address' AND "validated.type" = 'person';

-- Total number of GRs and source records of type person
SELECT COUNT(*) FROM record_actual WHERE "merged.type" = 'person' OR "validated.type" = 'person';

-- (Number of) invalid person names
SELECT * FROM record_actual_validated_person_validation_message WHERE "validated.person.validation_message.is_error" = 'true' AND "validated.person.validation_message.type" = 'uniserv_name';
-- Number of records with invalid person names
SELECT COUNT(DISTINCT "_id.k") FROM record_actual_validated_person_validation_message WHERE "validated.person.validation_message.is_error" = 'true' AND "validated.person.validation_message.type" = 'uniserv_name';

-- Point in time queries
-- ---------------------

-- Total number of valid/invalid source records of type person
SELECT COUNT(*) FROM record_actual_validated_person WHERE "validated.status" = 'valid' AND "validated.type" = 'person';
SELECT COUNT(*) FROM record_history_validated_person WHERE "validated.status" = 'valid' AND "validated.type" = 'person';
--  sanity check okay
SELECT COUNT(*) FROM record_history_validated_organization WHERE "validated.status" = 'valid' AND "validated.type" = 'organization' AND ("_id.r" >= 10 AND "_id.r" <= 19);
SELECT COUNT(*) FROM record_history_validated_organization WHERE "validated.status" = 'valid' AND "validated.type" = 'organization' AND ("_id.r" >= 10 AND "_id.r" <= 39);

-- (Number of) invalid addresses
SELECT * FROM record_history_validated_postal_address_validation_message WHERE "validated.postal_address.validation_message.is_error" = 'true' AND "validated.postal_address.validation_message.type" = 'uniserv_address' AND ("_id.r" >= 1 AND "_id.r" <= 10000);
-- Number OF RECORDS with invalid addresses
SELECT COUNT(DISTINCT "_id.k") FROM record_history_validated_postal_address_validation_message WHERE "validated.postal_address.validation_message.is_error" = 'true' AND "validated.postal_address.validation_message.type" = 'uniserv_address' AND ("_id.r" >= 1 AND "_id.r" <= 1506);
