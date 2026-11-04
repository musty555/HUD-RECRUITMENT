select * from renters;

--  Clean view used by every query below

DROP VIEW IF EXISTS renters_clean;
CREATE VIEW renters_clean AS
SELECT
    state,
    name,
    regions,
    people_total,
    people_per_unit,
    people_total * 1.0 / people_per_unit      AS households,
    hh_income_year,
    hh_income_per_person,
    pct_female_head,
    pct_female_head_children,
    pct_disabled,
    pct_age_25_49,
    pct_minority,
    pct_black,
    pct_white,
    pct_hispanic,
    NULLIF(tract_pct_poverty, 0)              AS tract_pct_poverty,
    tract_pct_minority,
    NULLIF(tract_pct_owners, 0)               AS tract_pct_owners
FROM renters;
select * from renters_clean;



--  National profile of HUD-assisted renters (household-weighted)
-- ---------------------------------------------------------------------
SELECT
    SUM(people_total)                                                   AS total_people,
    ROUND(SUM(households), 0)                                           AS total_households,
    ROUND(SUM(hh_income_year * households) / SUM(households), 0)        AS avg_income,
    ROUND(SUM(people_total) / SUM(households), 1)                       AS avg_household_size,
    ROUND(SUM(pct_female_head * households) / SUM(households), 1)       AS pct_female_head,
    ROUND(SUM(pct_female_head_children * households) / SUM(households), 1) AS pct_female_head_kids,
    ROUND(SUM(pct_disabled * households) / SUM(households), 1)          AS pct_disabled,
    ROUND(SUM(pct_minority * households) / SUM(households), 1)          AS pct_minority,
    ROUND(SUM(pct_black * households) / SUM(households), 1)             AS pct_black
FROM renters_clean;






--  Regional profile 
-- ---------------------------------------------------------------------
SELECT
    regions,
    COUNT(*)                                                            AS n_states,
    SUM(people_total)                                                   AS total_people,
    ROUND(100.0 * SUM(people_total) / (SELECT SUM(people_total) FROM renters_clean), 1) AS pct_of_us_renters,
    ROUND(SUM(hh_income_year * households) / SUM(households), 0)        AS avg_income,
    ROUND(SUM(pct_age_25_49 * households) / SUM(households), 1)         AS pct_age_25_49,
    ROUND(SUM(pct_female_head_children * households) / SUM(households), 1) AS pct_female_head_kids,
    ROUND(SUM(pct_disabled * households) / SUM(households), 1)          AS pct_disabled,
    ROUND(SUM(pct_minority * households) / SUM(households), 1)          AS pct_minority,
    ROUND(SUM(pct_black * households) / SUM(households), 1)             AS pct_black,
    ROUND(SUM(pct_white * households) / SUM(households), 1)             AS pct_white,
    ROUND(SUM(pct_hispanic * households) / SUM(households), 1)          AS pct_hispanic,
    ROUND(SUM(tract_pct_poverty * households)
          / SUM(CASE WHEN tract_pct_poverty IS NOT NULL THEN households END), 1) AS tract_pct_poverty,
    ROUND(SUM(tract_pct_owners * households)
          / SUM(CASE WHEN tract_pct_owners IS NOT NULL THEN households END), 1)  AS tract_pct_owners
FROM renters_clean
GROUP BY regions
ORDER BY total_people DESC;



-- Q3. Which region is most racially/ethnically diverse?
--     Diversity index = 1 - sum of squared shares (Black, White, Hispanic,
--     all other). 

WITH region_mix AS (
    SELECT
        regions,
        SUM(pct_black    * households) / SUM(households) AS b,
        SUM(pct_white    * households) / SUM(households) AS w,
        SUM(pct_hispanic * households) / SUM(households) AS h
    FROM renters_clean
    GROUP BY regions
)
SELECT
    regions,
    ROUND(b, 1)                     AS pct_black,
    ROUND(w, 1)                     AS pct_white,
    ROUND(h, 1)                     AS pct_hispanic,
    ROUND(100 - b - w - h, 1)       AS pct_other,
    ROUND(1 - (b*b + w*w + h*h + (100-b-w-h)*(100-b-w-h)) / 10000.0, 3) AS diversity_index
FROM region_mix
ORDER BY diversity_index DESC;



-- States with the most HUD-assisted renters 

SELECT
    state,
    regions,
    people_total,
    ROUND(100.0 * people_total / (SELECT SUM(people_total) FROM renters_clean), 1) AS pct_of_us_renters,
    hh_income_year,
    pct_age_25_49,
    pct_female_head_children,
    pct_minority,
    pct_black
FROM renters_clean
ORDER BY people_total DESC
LIMIT 15;


 
 -- Priority for recruitment, Which states have a large renter pool, lower income, and many working-age heads?
SELECT state, regions, people_total, hh_income_year, pct_age_25_49
FROM renters_clean
WHERE people_total   > (SELECT AVG(people_total)   FROM renters_clean)
  AND hh_income_year < (SELECT AVG(hh_income_year) FROM renters_clean)
  AND pct_age_25_49  > (SELECT AVG(pct_age_25_49)  FROM renters_clean)
ORDER BY people_total DESC;
 