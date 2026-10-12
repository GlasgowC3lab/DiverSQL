WITH cat_joined AS (
    SELECT
        ca.ca_state,
        r.r_reason_desc,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        CASE WHEN cr.cr_return_amount > 100 THEN 'high' ELSE 'low' END AS amount_category
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount IS NOT NULL
      AND cr.cr_return_amount >= 0
      AND cr.cr_net_loss > -1000
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND cr.cr_fee < 500
),
web_joined AS (
    SELECT
        ca.ca_state,
        r.r_reason_desc,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        CASE WHEN wr.wr_return_amt > 100 THEN 'high' ELSE 'low' END AS amount_category
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_return_amt IS NOT NULL
      AND wr.wr_return_amt >= 0
      AND wr.wr_net_loss > -1000
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND wr.wr_fee < 500
),
agg_catalog AS (
    SELECT
        ca_state,
        r_reason_desc,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) FILTER (WHERE amount_category = 'high') AS high_amount_cnt
    FROM cat_joined
    GROUP BY ca_state, r_reason_desc
),
agg_web AS (
    SELECT
        ca_state,
        r_reason_desc,
        SUM(wr_return_quantity) AS total_return_qty,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) FILTER (WHERE amount_category = 'high') AS high_amount_cnt
    FROM web_joined
    GROUP BY ca_state, r_reason_desc
),
combined AS (
    SELECT
        c.ca_state,
        c.r_reason_desc,
        c.total_return_qty AS cat_qty,
        c.total_return_amount AS cat_amount,
        c.total_net_loss AS cat_loss,
        w.total_return_qty AS web_qty,
        w.total_return_amount AS web_amount,
        w.total_net_loss AS web_loss,
        (c.high_amount_cnt + w.high_amount_cnt) AS high_amount_total
    FROM agg_catalog c
    JOIN agg_web w
        ON c.ca_state = w.ca_state
       AND c.r_reason_desc = w.r_reason_desc
)
SELECT
    comb.ca_state,
    comb.r_reason_desc,
    comb.cat_qty,
    comb.web_qty,
    comb.cat_amount,
    comb.web_amount,
    comb.high_amount_total,
    (
        SELECT COUNT(DISTINCT cr2.cr_refunded_customer_sk)
        FROM catalog_returns cr2
        JOIN customer_address ca2
            ON cr2.cr_refunded_addr_sk = ca2.ca_address_sk
        WHERE ca2.ca_state = comb.ca_state
    ) AS distinct_refunded_customers,
    dim.dim_value
FROM combined comb
CROSS JOIN (SELECT 'A' AS dim_value UNION ALL SELECT 'B' UNION ALL SELECT 'C') dim
WHERE comb.cat_loss + comb.web_loss > 0
  AND comb.high_amount_total >= 1
  AND comb.cat_qty > 10
  AND comb.web_qty > 5
  AND comb.ca_state IN ('CA', 'TX', 'NY', 'FL', 'WA')
  AND comb.r_reason_desc IS NOT NULL
ORDER BY comb.ca_state, comb.r_reason_desc
LIMIT 100
