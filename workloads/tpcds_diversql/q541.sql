WITH avg_scalar AS (
    SELECT AVG(cr_return_amount) AS avg_amt FROM catalog_returns
)
SELECT reason_desc, ship_mode_id, hour, total_return_amount
FROM (
    SELECT
        r.r_reason_desc AS reason_desc,
        sm.sm_ship_mode_id AS ship_mode_id,
        td.t_hour AS hour,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_return_amount > (SELECT avg_amt FROM avg_scalar)
    GROUP BY CUBE (r.r_reason_desc, sm.sm_ship_mode_id, td.t_hour)
) 
INTERSECT
SELECT reason_desc, ship_mode_id, hour, total_return_amount
FROM (
    SELECT
        r.r_reason_desc AS reason_desc,
        sm.sm_ship_mode_id AS ship_mode_id,
        td.t_hour AS hour,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE wr.wr_return_amt > (SELECT avg_amt FROM avg_scalar)
    GROUP BY CUBE (r.r_reason_desc, sm.sm_ship_mode_id, td.t_hour)
) 
ORDER BY reason_desc, ship_mode_id, hour
LIMIT 100
