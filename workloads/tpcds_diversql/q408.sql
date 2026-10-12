WITH catalog_cd AS (
        SELECT DISTINCT cr.cr_refunded_cdemo_sk AS cd_demo_sk,
               cr.cr_ship_mode_sk,
               cr.cr_returned_time_sk
        FROM catalog_returns cr
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE regexp_like(sm.sm_carrier, '^A')
    ),
    web_cd AS (
        SELECT DISTINCT wr.wr_refunded_cdemo_sk AS cd_demo_sk
        FROM web_returns wr
        WHERE wr.wr_return_amt > 500
    ),
    filtered_cd AS (
        SELECT cd_demo_sk
        FROM catalog_cd
        EXCEPT
        SELECT cd_demo_sk FROM web_cd
    )
SELECT DISTINCT
       f.cd_demo_sk,
       sm.sm_carrier,
       td.t_hour,
       lc.carrier_prefix,
       CONCAT('Hour_', CAST(td.t_hour AS VARCHAR)) AS hour_label
FROM filtered_cd f
JOIN catalog_returns cr ON cr.cr_refunded_cdemo_sk = f.cd_demo_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
LEFT JOIN LATERAL (
        SELECT regexp_extract(sm.sm_carrier, '^(.{3})', 1) AS carrier_prefix
) lc ON true
WHERE td.t_hour BETWEEN 8 AND 12
  AND sm.sm_carrier LIKE '%A%'
ORDER BY td.t_hour DESC
LIMIT 100
