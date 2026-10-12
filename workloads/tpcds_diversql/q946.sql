WITH catalog_agg AS (
    SELECT
        i.i_item_id,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS return_level
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_current_price > 100
      AND ib.ib_lower_bound >= 50000
    GROUP BY GROUPING SETS (
        (i.i_item_id, r.r_reason_desc),
        (i.i_item_id),
        ()
    )
),
web_agg AS (
    SELECT
        i.i_item_id,
        r.r_reason_desc,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS return_level
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_current_price > 100
      AND ib.ib_lower_bound >= 50000
    GROUP BY GROUPING SETS (
        (i.i_item_id, r.r_reason_desc),
        (i.i_item_id),
        ()
    )
),
unioned AS (
    SELECT i_item_id, r_reason_desc, total_return_amount, total_net_loss, return_level
    FROM catalog_agg
    UNION
    SELECT i_item_id, r_reason_desc, total_return_amount, total_net_loss, return_level
    FROM web_agg
),
ranked AS (
    SELECT
        u.i_item_id,
        u.r_reason_desc,
        u.total_return_amount,
        u.total_net_loss,
        u.return_level,
        ROW_NUMBER() OVER (PARTITION BY u.return_level ORDER BY u.total_return_amount DESC) AS rnk,
        (SELECT AVG(ib_upper_bound) FROM income_band) AS avg_income_upper
    FROM unioned u
    WHERE EXISTS (
        SELECT 1 FROM reason r2
        WHERE r2.r_reason_desc = u.r_reason_desc
          AND r2.r_reason_desc LIKE '%price%'
    )
)
SELECT
    i_item_id,
    r_reason_desc,
    total_return_amount,
    total_net_loss,
    return_level,
    avg_income_upper
FROM ranked
WHERE rnk <= 5
ORDER BY total_return_amount DESC, i_item_id
LIMIT 100
