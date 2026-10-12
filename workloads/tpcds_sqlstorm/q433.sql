WITH
sales_union AS (
    SELECT cs.cs_order_number AS order_number,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_ticket_number AS order_number,
           ss.ss_customer_sk AS customer_sk,
           ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_order_number AS order_number,
           ws.ws_bill_customer_sk AS customer_sk,
           ws.ws_sold_date_sk AS sold_date_sk,
           ws.ws_quantity AS quantity,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
),
returns_union AS (
    SELECT cr.cr_order_number AS order_number,
           cr.cr_refunded_customer_sk AS customer_sk,
           cr.cr_returned_date_sk AS returned_date_sk,
           cr.cr_return_quantity AS return_quantity,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_ticket_number AS order_number,
           sr.sr_customer_sk AS customer_sk,
           sr.sr_returned_date_sk AS returned_date_sk,
           sr.sr_return_quantity AS return_quantity,
           sr.sr_net_loss AS net_loss
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_order_number AS order_number,
           wr.wr_refunded_customer_sk AS customer_sk,
           wr.wr_returned_date_sk AS returned_date_sk,
           wr.wr_return_quantity AS return_quantity,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
),
sales_agg AS (
    SELECT
        COALESCE(c.c_customer_sk, s.customer_sk) AS customer_sk,
        d.d_year AS year,
        SUM(s.net_profit) AS total_profit,
        SUM(s.quantity) AS total_quantity,
        COUNT(DISTINCT s.order_number) AS distinct_orders,
        MAX(s.sold_date_sk) AS max_sold_date_sk,
        SUM(CASE WHEN s.quantity > 0 THEN s.net_profit * s.quantity END) AS weighted_profit
    FROM sales_union s
    LEFT JOIN customer c ON c.c_customer_sk = s.customer_sk
    LEFT JOIN date_dim d ON d.d_date_sk = s.sold_date_sk
    GROUP BY COALESCE(c.c_customer_sk, s.customer_sk), d.d_year
),
returns_agg AS (
    SELECT
        COALESCE(c.c_customer_sk, r.customer_sk) AS customer_sk,
        d.d_year AS year,
        SUM(r.net_loss) AS total_loss,
        SUM(r.return_quantity) AS total_return_qty,
        COUNT(DISTINCT r.order_number) AS distinct_return_orders
    FROM returns_union r
    LEFT JOIN customer c ON c.c_customer_sk = r.customer_sk
    LEFT JOIN date_dim d ON d.d_date_sk = r.returned_date_sk
    GROUP BY COALESCE(c.c_customer_sk, r.customer_sk), d.d_year
),
customer_last_order AS (
    SELECT
        s.customer_sk,
        MAX(d.d_date) AS last_order_date
    FROM sales_union s
    LEFT JOIN date_dim d ON d.d_date_sk = s.sold_date_sk
    GROUP BY s.customer_sk
),
final AS (
    SELECT
        COALESCE(sa.customer_sk, ra.customer_sk) AS customer_sk,
        COALESCE(sa.year, ra.year) AS year,
        COALESCE(sa.total_profit, 0) - COALESCE(ra.total_loss, 0) AS net_gain,
        COALESCE(sa.total_quantity, 0) AS sold_qty,
        COALESCE(ra.total_return_qty, 0) AS returned_qty,
        COALESCE(sa.distinct_orders, 0) AS orders,
        COALESCE(ra.distinct_return_orders, 0) AS return_orders,
        CASE
            WHEN COALESCE(sa.total_quantity, 0) = 0 THEN NULL
            ELSE (COALESCE(sa.total_quantity, 0) - COALESCE(ra.total_return_qty, 0)) * 1.0 / COALESCE(sa.total_quantity, 0)
        END AS return_rate,
        CASE
            WHEN sa.max_sold_date_sk IS NULL THEN 'N/A'
            ELSE CAST(dmax.d_date AS VARCHAR)
        END AS last_sold_date,
        COALESCE(cl.last_order_date, DATE '1900-01-01') AS last_order_date_actual,
        CONCAT('CUST', LPAD(CAST(COALESCE(sa.customer_sk, ra.customer_sk) AS VARCHAR), 9, '0')) AS cust_key,
        CASE
            WHEN (COALESCE(sa.total_profit, 0) - COALESCE(ra.total_loss, 0)) > 0 THEN 'POSITIVE'
            WHEN (COALESCE(sa.total_profit, 0) - COALESCE(ra.total_loss, 0)) < 0 THEN 'NEGATIVE'
            ELSE 'ZERO'
        END AS profit_status,
        RANK() OVER (PARTITION BY COALESCE(sa.year, ra.year) ORDER BY (COALESCE(sa.total_profit, 0) - COALESCE(ra.total_loss, 0)) DESC) AS net_gain_rank,
        (SELECT COUNT(DISTINCT ws.ws_promo_sk)
           FROM web_sales ws
           JOIN date_dim d_ws ON d_ws.d_date_sk = ws.ws_sold_date_sk
          WHERE ws.ws_bill_customer_sk = COALESCE(sa.customer_sk, ra.customer_sk)
            AND d_ws.d_year = COALESCE(sa.year, ra.year)
        ) AS promo_count,
        COALESCE(sa.total_profit, 0) / NULLIF(COALESCE(sa.total_quantity, 0), 0) AS profit_per_item,
        LOWER(REGEXP_REPLACE(COALESCE(c.c_last_name, ''), '[^a-z]', '')) AS normalized_last_name,
        TRY_CAST(FLOOR(COALESCE(sa.total_profit, 0)) AS INTEGER) AS profit_int
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
        ON sa.customer_sk = ra.customer_sk AND sa.year = ra.year
    LEFT JOIN date_dim dmax ON dmax.d_date_sk = sa.max_sold_date_sk
    LEFT JOIN customer_last_order cl ON cl.customer_sk = COALESCE(sa.customer_sk, ra.customer_sk)
    LEFT JOIN customer c ON c.c_customer_sk = COALESCE(sa.customer_sk, ra.customer_sk)
)
SELECT *
FROM final
WHERE (net_gain IS NOT NULL AND net_gain <> 0)
   OR (return_rate IS NOT NULL AND return_rate > 0.1)
ORDER BY net_gain DESC NULLS LAST
LIMIT 100
