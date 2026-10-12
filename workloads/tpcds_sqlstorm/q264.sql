WITH sales_union AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_quantity AS quantity,
           cs.cs_ext_discount_amt AS discount_amt,
           'catalog' AS sales_channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_customer_sk,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_quantity AS quantity,
           ss.ss_ext_discount_amt AS discount_amt,
           'store' AS sales_channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_bill_customer_sk,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_quantity AS quantity,
           ws.ws_ext_discount_amt AS discount_amt,
           'web' AS sales_channel
    FROM web_sales ws
),
returns_union AS (
    SELECT cr.cr_returned_date_sk AS returned_date_sk,
           cr.cr_returning_customer_sk AS customer_sk,
           cr.cr_return_amount AS return_amount,
           cr.cr_net_loss AS net_loss,
           cr.cr_return_quantity AS return_quantity,
           'catalog' AS return_channel
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_customer_sk,
           sr.sr_return_amt AS return_amount,
           sr.sr_net_loss AS net_loss,
           sr.sr_return_quantity AS return_quantity,
           'store' AS return_channel
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_returning_customer_sk,
           wr.wr_return_amt AS return_amount,
           wr.wr_net_loss AS net_loss,
           wr.wr_return_quantity AS return_quantity,
           'web' AS return_channel
    FROM web_returns wr
),
customer_sales AS (
    SELECT
        s.customer_sk,
        d.d_year,
        SUM(s.net_paid) AS total_paid,
        SUM(s.net_profit) AS total_profit,
        SUM(s.quantity) AS total_quantity,
        SUM(s.discount_amt) AS total_discount,
        COUNT(DISTINCT s.sold_date_sk) AS active_days,
        SUM(CASE WHEN s.sales_channel = 'store' THEN 1 ELSE 0 END) AS store_sales_cnt,
        SUM(CASE WHEN s.sales_channel = 'web' THEN 1 ELSE 0 END) AS web_sales_cnt,
        SUM(CASE WHEN s.sales_channel = 'catalog' THEN 1 ELSE 0 END) AS catalog_sales_cnt
    FROM sales_union s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    GROUP BY s.customer_sk, d.d_year
),
customer_returns AS (
    SELECT
        r.customer_sk,
        d.d_year,
        SUM(r.return_amount) AS total_returned,
        SUM(r.net_loss) AS total_loss,
        SUM(r.return_quantity) AS total_return_qty
    FROM returns_union r
    JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
    GROUP BY r.customer_sk, d.d_year
),
customer_summary AS (
    SELECT
        cs.customer_sk,
        cs.d_year,
        cs.total_paid,
        cs.total_profit,
        cs.total_quantity,
        cs.total_discount,
        cs.active_days,
        cs.store_sales_cnt,
        cs.web_sales_cnt,
        cs.catalog_sales_cnt,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_loss, 0) AS total_loss,
        COALESCE(cr.total_return_qty, 0) AS total_return_qty,
        (cs.total_paid - COALESCE(cr.total_returned, 0)) AS net_sales,
        CASE WHEN cs.total_paid > 0 THEN (cs.total_profit / cs.total_paid) ELSE NULL END AS profit_margin,
        CASE WHEN cs.active_days > 0 THEN (cs.total_quantity / cs.active_days) ELSE NULL END AS avg_quantity_per_day,
        ROW_NUMBER() OVER (PARTITION BY cs.d_year ORDER BY cs.total_profit DESC) AS profit_rank_year,
        LAG(cs.total_profit) OVER (PARTITION BY cs.customer_sk ORDER BY cs.d_year) AS prev_year_profit,
        CASE
            WHEN LAG(cs.total_profit) OVER (PARTITION BY cs.customer_sk ORDER BY cs.d_year) IS NULL THEN NULL
            ELSE (cs.total_profit - LAG(cs.total_profit) OVER (PARTITION BY cs.customer_sk ORDER BY cs.d_year))
        END AS profit_delta_year
    FROM customer_sales cs
    LEFT JOIN customer_returns cr ON cs.customer_sk = cr.customer_sk AND cs.d_year = cr.d_year
),
final_result AS (
    SELECT
        c.c_customer_id,
        CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
        cs.d_year,
        cs.net_sales,
        cs.total_profit,
        cs.profit_margin,
        cs.avg_quantity_per_day,
        cs.profit_rank_year,
        cs.profit_delta_year,
        CASE
            WHEN cs.profit_margin IS NULL THEN 'UNKNOWN'
            WHEN cs.profit_margin < 0.05 THEN 'LOW'
            WHEN cs.profit_margin < 0.15 THEN 'MEDIUM'
            ELSE 'HIGH'
        END AS profit_category,
        COALESCE(cs.total_return_qty, 0) AS total_return_qty,
        cs.total_quantity,
        CASE
            WHEN cs.total_quantity = 0 THEN 0
            ELSE ROUND(CAST(cs.total_return_qty AS double) / cs.total_quantity, 4)
        END AS return_rate,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        (SELECT COALESCE(SUM(ss2.ss_net_paid), 0)
         FROM store_sales ss2
         JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
         WHERE ss2.ss_customer_sk = c.c_customer_sk
           AND d2.d_year = cs.d_year - 1) AS store_sales_last_year
    FROM customer_summary cs
    JOIN customer c ON cs.customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE cs.d_year = (SELECT MAX(d_year) FROM date_dim)
      AND cs.profit_margin IS NOT NULL
      AND cs.profit_margin > 0
)
SELECT
    full_name,
    d_year,
    net_sales,
    total_profit,
    profit_margin,
    avg_quantity_per_day,
    profit_rank_year,
    profit_delta_year,
    profit_category,
    return_rate,
    CASE
        WHEN profit_rank_year <= 10 THEN 'TOP10'
        WHEN profit_rank_year <= 100 THEN 'TOP100'
        ELSE 'OTHERS'
    END AS rank_bucket
FROM final_result
WHERE profit_rank_year <= 100
ORDER BY profit_rank_year
LIMIT 100
