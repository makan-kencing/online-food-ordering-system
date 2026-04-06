insert into SHOPGRAB.MEMBER (USERNAME, EMAIL, CREATED_AT)
values  ('gregory22', 'vmcdonald@gmail.com', TIMESTAMP '2026-02-04 00:26:52.000000'),
        ('dgriffin', 'ibrown@yahoo.com', TIMESTAMP '2026-01-29 08:54:15.000000'),
        ('allen75', 'sgaines@yahoo.com', TIMESTAMP '2026-02-10 15:39:05.000000'),
        ('nicholas49', 'pjenkins@yahoo.com', TIMESTAMP '2026-01-16 08:16:03.000000'),
        ('randerson', 'julie07@hotmail.com', TIMESTAMP '2026-01-30 04:22:37.000000'),
        ('nbradley', 'jacobsonmargaret@hotmail.com', TIMESTAMP '2026-01-16 14:05:48.000000'),
        ('perrybonnie', 'christina34@hotmail.com', TIMESTAMP '2026-01-03 21:00:43.000000'),
        ('paulward', 'powelllatoya@gmail.com', TIMESTAMP '2026-02-27 02:55:05.000000'),
        ('colemanian', 'susan00@yahoo.com', TIMESTAMP '2026-02-26 04:09:11.000000'),
        ('graydenise', 'tylerpowell@hotmail.com', TIMESTAMP '2026-02-28 15:33:53.000000'),
        ('peterteo', 'peterparker@hotmail.com', TIMESTAMP '2024-06-01 14:20:00'),
        ('graceyap', 'graceyapping@hotmail.com', TIMESTAMP '2024-06-10 08:50:00');

insert into SHOPGRAB.ADDRESS (NAME, CONTACT_NO, ADDRESS_1, ADDRESS_2, ADDRESS_3, CITY, STATE, POSTCODE, COUNTRY)
values  ('Jennifer Harvey', '4097524647', '56350 Riley Green Suite 753', null, null, 'North Dustin', 'North Dustin', '10100', 'United States'),
        ('David Ingram', '(953)583-8266', '01014 Mckee Tunnel Suite 909', null, null, 'Lake Bradley', 'Lake Bradley', '10100', 'United States'),
        ('Shannon White', '(599)471-3764', '63343 Natalie Lane', null, null, 'Markhaven', 'Markhaven', '10100', 'United States'),
        ('Jeffrey Hays', '3534686302', '7998 Arnold Brook Apt. 521', null, null, 'East Kimchester', 'East Kimchester', '10100', 'United States'),
        ('Tyler Baker', '(217)781-4536', '78841 Melissa Turnpike', null, null, 'South Charlesberg', 'South Charlesberg', '10100', 'United States'),
        ('Dawn Carey MD', '3287046888', '0250 Rebecca Manor', null, null, 'Jacksonville', 'Jacksonville', '10100', 'United States'),
        ('Shawn Sparks', '(403)359-9178', '0856 Frank Junction', null, null, 'Melendeztown', 'Melendeztown', '10100', 'United States'),
        ('Lisa Thompson', '(791)617-6437', '56452 Victoria Extensions Apt. 380', null, null, 'West Cindyside', 'West Cindyside', '10100', 'United States'),
        ('Rachel Fernandez MD', '4894223777', '8916 Dennis Pines Suite 421', null, null, 'Nortonside', 'Nortonside', '10100', 'United States'),
        ('Jessica Brown', '(859)679-1453', '481 Samuel Meadow', null, null, 'Garystad', 'Garystad', '10100', 'United States'),
        ('Ricardo Fernandez', '4894223377', '8986 Dennis Suite 423', null, null, 'Nortonside', 'Nortonside', '10100', 'United States'),
        ('Alan Turing', '48942212377', '8916 Ohio Suite Boss 421', null, null, 'Nortonside', 'Nortonside', '10100', 'United States');

insert into SHOPGRAB.MEMBER_ADDRESS (MEMBER_ID, ADDRESS_ID, IS_PRIMARY)
values  (1, 1, false),
        (2, 2, false),
        (3, 3, false),
        (4, 4, false),
        (5, 5, false),
        (6, 6, false),
        (7, 7, false),
        (8, 8, false),
        (9, 9, false),
        (10, 10, false),
        (11, 11, false),
        (12, 12, false);

ALTER TABLE SHOPGRAB.MEMBER
    MODIFY ID GENERATED ALWAYS AS IDENTITY (START WITH 1);

ALTER TABLE SHOPGRAB.ADDRESS
    MODIFY ID GENERATED ALWAYS AS IDENTITY (START WITH 1);

COMMIT;

SELECT sequence_name, column_name
FROM user_tab_identity_cols
WHERE table_name IN ('MEMBER', 'ADDRESS');

ALTER SEQUENCE "ISEQ$$_74434" RESTART START WITH 1;
ALTER SEQUENCE "ISEQ$$_74440" RESTART START WITH 1;

DELETE FROM MEMBER;
DELETE FROM ADDRESS;
DELETE FROM MEMBER_ADDRESS;