/*
Goal: Compare high‑value returns from catalog and web channels by state and year, aggregating amounts and net loss while excluding addresses that also have low‑value returns.
*/
WITH catalog_pre AS (
    SELECT
        cr_returned_date_sk,
        cr_refunded_addr_sk,
        cr_returning_addr_sk,
        cr_reason_sk,
        cr_return_amount,
        cr_net_loss
    FROM catalog_returns
    WHERE cr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
),
web_pre AS (
    SELECT
        wr_returned_date_sk,
        wr_refunded_addr_sk,
        wr_returning_addr_sk,
        wr_reason_sk,
        wr_return_amt,
        wr_net_loss
    FROM web_returns
    WHERE wr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
),
catalog_joined AS (
    SELECT
        ca_refund.ca_address_sk   AS address_sk,
        ca_refund.ca_state        AS state,
        d_cat.d_year,
        r_cat.r_reason_desc,
        cr.cr_return_amount       AS total_amount,
        cr.cr_net_loss            AS net_loss,
        CASE WHEN cr.cr_return_amount > 100 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM catalog_pre cr
    JOIN date_dim d_cat
        ON cr.cr_returned_date_sk = d_cat.d_date_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return
        ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN reason r_cat
        ON cr.cr_reason_sk = r_cat.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d_cat.d_date_sk
    LEFT JOIN LATERAL (
        SELECT SUM(cr2.cr_return_amount) AS total_same_addr
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_addr_sk = ca_refund.ca_address_sk
    ) lat ON true
),
web_joined AS (
    SELECT
        ca_refund.ca_address_sk   AS address_sk,
        ca_refund.ca_state        AS state,
        d_web.d_year,
        r_web.r_reason_desc,
        wr.wr_return_amt          AS total_amount,
        wr.wr_net_loss            AS net_loss,
        CASE WHEN wr.wr_return_amt > 100 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM web_pre wr
    JOIN date_dim d_web
        ON wr.wr_returned_date_sk = d_web.d_date_sk
    JOIN customer_address ca_refund
        ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return
        ON wr.wr_returning_addr_sk = ca_return.ca_address_sk
    JOIN reason r_web
        ON wr.wr_reason_sk = r_web.r_reason_sk
    JOIN store s2
        ON s2.s_closed_date_sk = d_web.d_date_sk
    LEFT JOIN LATERAL (
        SELECT SUM(wr2.wr_return_amt) AS total_same_addr
        FROM web_returns wr2
        WHERE wr2.wr_refunded_addr_sk = ca_refund.ca_address_sk
    ) latw ON true
),
union_all AS (
    SELECT address_sk, state, d_year, r_reason_desc,
           total_amount, net_loss, amount_category
    FROM catalog_joined
    UNION DISTINCT
    SELECT address_sk, state, d_year, r_reason_desc,
           total_amount, net_loss, amount_category
    FROM web_joined
),
high_only AS (
    SELECT *
    FROM union_all ua
    WHERE ua.amount_category = 'HIGH'
      AND NOT EXISTS (
          SELECT 1
          FROM union_all ub
          WHERE ub.address_sk = ua.address_sk
            AND ub.amount_category = 'LOW'
      )
),
final_agg AS (
    SELECT
        ho.address_sk,
        ho.state,
        ho.d_year,
        COUNT(*)                          AS cnt_returns,
        SUM(ho.total_amount)              AS sum_amount,
        SUM(ho.net_loss)                  AS sum_net_loss,
        MAX(l.total_same_addr)            AS max_total_same_addr
    FROM high_only ho
    LEFT JOIN LATERAL (
        SELECT SUM(cr3.cr_return_amount) AS total_same_addr
        FROM catalog_returns cr3
        WHERE cr3.cr_refunded_addr_sk = ho.address_sk
    ) l ON true
    GROUP BY ho.address_sk, ho.state, ho.d_year
    HAVING SUM(ho.total_amount) > 500
)
SELECT *
FROM final_agg
EXCEPT
SELECT *
FROM (
    SELECT *
    FROM final_agg
    WHERE cnt_returns < 5
) sub
LIMIT 100
